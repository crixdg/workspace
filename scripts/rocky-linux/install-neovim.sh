#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo dnf install -y curl tar gzip

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o "$TMP_DIR/nvim-linux-x86_64.tar.gz"
rm -rf ~/.local/nvim/nvim-linux-x86_64
mkdir -p ~/.local/nvim
tar -C ~/.local/nvim --no-same-owner -xzf "$TMP_DIR/nvim-linux-x86_64.tar.gz"

mkdir -p "$HOME/.config/nvim"
cp -f "$REPO_ROOT/stuffs/neovim_server_init.lua" "$HOME/.config/nvim/init.lua"
rm -f "$HOME/.config/nvim/lazy-lock.json"

CONFIG_NAME="neovim"
CONFIG_CONTENT='export PATH="$HOME/.local/nvim/nvim-linux-x86_64/bin:$PATH"

alias vim="nvim"
alias vi="nvim"'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Neovim installation and configuration completed. You can start Neovim by running the "nvim" command."
