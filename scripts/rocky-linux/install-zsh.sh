#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo dnf install git -y
sudo dnf install zsh -y

if ! command -v zsh &>/dev/null; then
	echo "Error: zsh installation failed."
	exit 1
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo "Oh My Zsh is already installed."
fi

rm -f "$HOME/.zshrc"
