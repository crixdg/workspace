#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf ~/.local/nvim/nvim-linux-x86_64
mkdir -p ~/.local/nvim
sudo tar -C ~/.local/nvim -xzf nvim-linux-x86_64.tar.gz
sudo rm -rf nvim-linux-x86_64.tar.gz

mkdir -p "$HOME/.config/nvim"
cp -f "workspace/init.lua" "$HOME/.config/nvim/init.lua"

CONFIG_NAME="neovim"
CONFIG_CONTENT='export PATH="$HOME/.local/nvim/nvim-linux-x86_64/bin:$PATH"

alias vim="nvim"
alias vi="nvim"'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Neovim installation and configuration completed. You can start Neovim by running the "nvim" command."
