#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

sudo apt update
sudo apt install build-essential -y
sudo apt install cmake ninja-build -y
sudo apt install clang clangd lldb llvm -y

DEFAULT_BAZELISK_VERSION="1.28.1"
read -p "Enter the Bazelisk version you want to install [${DEFAULT_BAZELISK_VERSION}]: " VERSION
BAZELISK_VERSION=${BAZELISK_VERSION:-$DEFAULT_BAZELISK_VERSION}
curl -LO https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-amd64.deb 2>/dev/null
sudo dpkg -i bazelisk-amd64.deb
rm bazelisk-amd64.deb

DEFAULT_BAZEL_BUILDTOOLS_VERSION="8.5.1"
read -p "Enter the Bazel Buildtools version you want to install [${DEFAULT_BAZEL_BUILDTOOLS_VERSION}]: " VERSION
BAZEL_BUILDTOOLS_VERSION=${BAZEL_BUILDTOOLS_VERSION:-$DEFAULT_BAZEL_BUILDTOOLS_VERSION}
curl -LO https://github.com/bazelbuild/buildtools/releases/download/v${BAZEL_BUILDTOOLS_VERSION}/buildifier-linux-amd64 2>/dev/null
chmod +x buildifier-linux-amd64
sudo mv buildifier-linux-amd64 "$HOME/.local/bin/buildifier"

mkdir -p "$HOME/.local/bin/cppbin"
cp -r "workspace/cppbin/." "$HOME/.local/bin/cppbin/"
cp -f "workspace/.clang-format" "$HOME/.clang-format"

CONFIG_NAME="c++"
CONFIG_CONTENT='path=("$HOME/.local/bin/cppbin" $path)'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "C++ workspace initialized and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
