#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo dnf install -y git curl zsh

if ! command -v zsh &>/dev/null; then
	echo "Error: zsh installation failed."
	exit 1
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
	RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	rm -f "$HOME/.zshrc"
else
	echo "Oh My Zsh is already installed."
fi

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
	sudo usermod -s "$(command -v zsh)" "$USER"
fi
