#!/bin/bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

sudo apt install -y tmux

if ! command -v tmux &>/dev/null; then
	echo "Error: tmux installation failed."
	exit 1
fi

cp -f "workspace/.tmux.conf" "$HOME/.tmux.conf"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

START_MARK="# >>> tmux initialize >>>"
DESCRIPTION_MARK="# !! Contents within this block are managed by 'tmux auto configuration' !!"
END_MARK="# <<< tmux initialize <<<"

TMUX_BLOCK=$(
	cat <<EOF
$START_MARK
$DESCRIPTION_MARK
if command -v tmux >/dev/null 2>&1; then
  if [ -z "\$TMUX" ] && [ -n "\$TERM" ] && [ "\$TERM_PROGRAM" != "vscode" ] ; then
  	exec tmux new-session -AD
  fi
fi
$END_MARK
EOF
)

if [[ "$SHELL" =~ "zsh" ]]; then
	SHELL_RC="$HOME/.zshrc"
else
	SHELL_RC="$HOME/.bashrc"
fi

if grep -q "$START_MARK" "$SHELL_RC"; then
	# Replace existing block, ensure empty line before block
	awk -v block="$TMUX_BLOCK" -v start="$START_MARK" -v end="$END_MARK" '
        BEGIN {inblock=0}
        $0 ~ start {
            print block;
            inblock=1;
            next
        }
        $0 ~ end {
            inblock=0;
            next
        }
        inblock == 0 {print}
    ' "$SHELL_RC" >"$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"
else
	# Append new block with preceding empty line
	{
		echo ""
		echo "$TMUX_BLOCK"
	} >>"$SHELL_RC"
fi

echo "Tmux installation and configuration completed. You can start tmux by running the 'tmux' command."
