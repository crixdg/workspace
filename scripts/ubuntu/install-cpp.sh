#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

bash "$SCRIPT_DIR/check-os.sh"

# Toolchain policy for this machine:
#
#   System-installed, version-pinned  -> LLVM/Clang, CMake, Ninja, GCC
#   Hermetic, per-project             -> Bazel via Bazelisk (pin with .bazelversion)
#
# Editor tooling (clangd, clang-format, clang-tidy) must exist on PATH outside of
# any build system, so it is installed system-wide and pinned here. Bazelisk stays
# for projects that want a hermetic build; it does not replace the system toolchain.
#
# Every version below is a single variable. Bump it here, re-run on every machine.
# Each can be overridden from the environment for unattended runs, e.g.
#   LLVM_VERSION=22 ./install-cpp.sh </dev/null

# Prompt only when stdin is a terminal, so this stays usable in CI and pipes.
ask_version() {
	local default="$1" label="$2" answer=""
	if [ -t 0 ]; then
		read -r -p "Enter the ${label} version you want to install [${default}]: " answer || answer=""
	fi
	printf '%s' "${answer:-$default}"
}

LLVM_VERSION="${LLVM_VERSION:-$(ask_version "21" "LLVM")}"
BAZELISK_VERSION="${BAZELISK_VERSION:-$(ask_version "1.29.0" "Bazelisk")}"
BAZEL_BUILDTOOLS_VERSION="${BAZEL_BUILDTOOLS_VERSION:-$(ask_version "8.5.1" "Bazel Buildtools")}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

sudo apt update
sudo apt install -y build-essential curl wget gnupg lsb-release software-properties-common

CODENAME="$(lsb_release -cs)"
HOST_ARCH="$(dpkg --print-architecture)"

# --- CMake + Ninja -------------------------------------------------------------
# Ubuntu ships an old CMake (24.04 -> 3.28). Kitware's repo tracks upstream.

if [ ! -f /usr/share/keyrings/kitware-archive-keyring.gpg ]; then
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null |
		gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
fi

KITWARE_LIST="/etc/apt/sources.list.d/kitware.list"
KITWARE_LINE="deb [arch=${HOST_ARCH} signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${CODENAME} main"

if [ ! -f "$KITWARE_LIST" ] || ! grep -qxF "$KITWARE_LINE" "$KITWARE_LIST"; then
	if [ -f "$KITWARE_LIST" ]; then
		echo "Kitware list does not match codename '${CODENAME}'. Rewriting."
	fi
	echo "$KITWARE_LINE" | sudo tee "$KITWARE_LIST" >/dev/null
	sudo apt update
fi

sudo apt install -y cmake ninja-build

# --- LLVM / Clang --------------------------------------------------------------
# llvm.sh adds the apt.llvm.org repo and installs the core packages.
# It does not install clang-format or clang-tidy, so those are named explicitly.

if [ ! -f "/usr/bin/clang-${LLVM_VERSION}" ]; then
	curl -fsSL -o "$WORK_DIR/llvm.sh" https://apt.llvm.org/llvm.sh
	chmod +x "$WORK_DIR/llvm.sh"
	sudo "$WORK_DIR/llvm.sh" "$LLVM_VERSION"
fi

sudo apt install -y \
	"clang-${LLVM_VERSION}" \
	"clang-format-${LLVM_VERSION}" \
	"clang-tidy-${LLVM_VERSION}" \
	"clang-tools-${LLVM_VERSION}" \
	"clangd-${LLVM_VERSION}" \
	"lldb-${LLVM_VERSION}" \
	"lld-${LLVM_VERSION}"

UNVERSIONED_LLVM_PKGS=(clang clang-format clang-tidy clang-tools clangd lld lldb llvm)
TO_PURGE=()
for pkg in "${UNVERSIONED_LLVM_PKGS[@]}"; do
	if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "^install ok installed$"; then
		TO_PURGE+=("$pkg")
	fi
done

if [ ${#TO_PURGE[@]} -gt 0 ]; then
	echo "Removing unversioned distro LLVM packages that would shadow ${LLVM_VERSION}: ${TO_PURGE[*]}"
	sudo apt purge -y "${TO_PURGE[@]}"
fi

# Everything clang ships is registered as one group led by /usr/bin/clang, so a
# single --set switches the whole toolchain at once and the pieces can never
# drift to different versions.
#
# All of these follow the same naming pattern (/usr/bin/<name> ->
# /usr/bin/<name>-<version>), so the --slave arguments are generated rather than
# spelled out.
CLANG_SLAVES=(
	clang++
	clang-cpp
	clang-format
	clang-format-diff
	clang-tidy
	run-clang-tidy
	clang-apply-replacements
	clang-query
	clang-include-cleaner
	scan-build
	lld
	ld.lld
)

# update-alternatives refuses to demote a name that is already a master
# alternative of its own, which is the state an earlier version of this script
# (one --install per tool) left behind. Drop those groups so the clang group
# below can own them.
for name in "${CLANG_SLAVES[@]}"; do
	if update-alternatives --query "$name" >/dev/null 2>&1; then
		echo "Removing standalone '${name}' alternative so it can become a slave of clang"
		sudo update-alternatives --remove-all "$name"
	fi
done

SLAVE_ARGS=()
for name in "${CLANG_SLAVES[@]}"; do
	SLAVE_ARGS+=(--slave "/usr/bin/${name}" "$name" "/usr/bin/${name}-${LLVM_VERSION}")
done

sudo update-alternatives --install /usr/bin/clang clang "/usr/bin/clang-${LLVM_VERSION}" 100 \
	"${SLAVE_ARGS[@]}"

sudo update-alternatives --set clang "/usr/bin/clang-${LLVM_VERSION}"

# --- Bazelisk + Buildtools -----------------------------------------------------
# Bazelisk resolves the Bazel version per project from .bazelversion.
# Pin it in each repo; do not set USE_BAZEL_VERSION globally or it overrides every project.

INSTALLED_BAZELISK_VERSION="$(dpkg-query -W -f='${Version}' bazelisk 2>/dev/null || true)"

if [ -n "$INSTALLED_BAZELISK_VERSION" ]; then
	echo "Bazelisk ${INSTALLED_BAZELISK_VERSION} is already installed. Skipping installation."
	echo "  (to change it: sudo apt purge bazelisk, then re-run)"
else
	curl -fsSL -o "$WORK_DIR/bazelisk-amd64.deb" \
		"https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-amd64.deb"
	sudo dpkg -i "$WORK_DIR/bazelisk-amd64.deb"
fi

mkdir -p "$HOME/.local/bin"
curl -fsSL -o "$WORK_DIR/buildifier" \
	"https://github.com/bazelbuild/buildtools/releases/download/v${BAZEL_BUILDTOOLS_VERSION}/buildifier-linux-amd64"
chmod +x "$WORK_DIR/buildifier"
mv -f "$WORK_DIR/buildifier" "$HOME/.local/bin/buildifier"

# --- C++ helper scripts --------------------------------------------------------

mkdir -p "$HOME/.local/bin/cpp"
cp -rf "$REPO_ROOT/workspace/cpp/"* "$HOME/.local/bin/cpp/"

# --- Global clang-format -------------------------------------------------------

ln -sfn "$REPO_ROOT/workspace/.clang-format" "$HOME/.clang-format"

CONFIG_NAME="c++"
CONFIG_CONTENT='path=("$HOME/.local/bin/cpp" $path)'
source "$SCRIPT_DIR/add-auto-config.sh"

# Report what is actually on disk, not what was requested.
echo
echo "C++ toolchain installed:"
echo "  clang       $("/usr/bin/clang-${LLVM_VERSION}" --version | head -1)"
echo "  $(cmake --version | head -1)"
echo "  ninja       $(ninja --version)"
echo "  bazelisk    $(dpkg-query -W -f='${Version}' bazelisk 2>/dev/null || echo 'not installed')"
echo "  buildifier  $("$HOME/.local/bin/buildifier" --version 2>/dev/null | head -1 || echo 'not installed')"
echo
echo "C++ workspace initialized and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
