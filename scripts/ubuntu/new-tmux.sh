#!/bin/bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

sudo apt update
sudo apt install -y tmux

if ! command -v tmux &>/dev/null; then
	echo "Error: tmux installation failed."
	exit 1
fi

cp -f "workspace/.tmux.conf" "$HOME/.tmux.conf"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Tmux installation and configuration completed. You can start tmux by running the 'tmux' command."
