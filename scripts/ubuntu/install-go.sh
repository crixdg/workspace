#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

ask_version() {
	local default="$1" label="$2" answer=""
	if [ -t 0 ]; then
		read -r -p "Enter the ${label} version you want to install [${default}]: " answer || answer=""
	fi
	printf '%s' "${answer:-$default}"
}

GO_VERSION="${GO_VERSION:-$(ask_version "1.26.3" "Go")}"

sudo apt install -y curl git mercurial make binutils bison gcc build-essential
if [ ! -s "$HOME/.gvm/scripts/gvm" ]; then
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
fi

set +e
source "$HOME/.gvm/scripts/gvm"
if ! gvm list | grep -q "go${GO_VERSION}\b"; then
    gvm install "go${GO_VERSION}" -B
fi
gvm use "go${GO_VERSION}" --default
set -e

CONFIG_NAME="golang"
CONFIG_CONTENT='export GVM_ROOT="$HOME/.gvm"
[[ -s "$GVM_ROOT/environments/default" ]] && source "$GVM_ROOT/environments/default"

gvm() {
	unset -f gvm
	source "$GVM_ROOT/scripts/gvm"
	gvm "$@"
}'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "GVM installed. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
