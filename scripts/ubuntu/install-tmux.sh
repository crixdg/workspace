#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install -y tmux

if ! command -v tmux &>/dev/null; then
	echo "Error: tmux installation failed."
	exit 1
fi

cp -f "workspace/.tmux.conf" "$HOME/.tmux.conf"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

CONFIG_NAME="tmux"
CONFIG_CONTENT='if [[ -z "$SSH_CONNECTION" ]]; then
  if command -v tmux >/dev/null 2>&1; then
    if [ -z "$TMUX" ] \
      && [ -n "$TERM" ] \
      && [ "$TERM_PROGRAM" != "vscode" ] \
      && [ "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ]; then
      exec tmux new-session -AD
    fi
  fi
fi'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Tmux installation and configuration completed. You can start tmux by running the 'tmux' command."
