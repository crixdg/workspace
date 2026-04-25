#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install -y curl git mercurial make binutils bison gcc build-essential
if ! command -v gvm &>/dev/null; then
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
    source "$HOME/.gvm/scripts/gvm"
fi

CONFIG_NAME="golang"
CONFIG_CONTENT='[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "GVM installed. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
