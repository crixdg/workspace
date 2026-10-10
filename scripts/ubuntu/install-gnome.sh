#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check-os.sh"

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
	echo "Run this script from inside a GNOME session (not over SSH)." >&2
	exit 1
fi

sudo apt install -y pipx dconf-cli
pipx install gnome-extensions-cli >/dev/null 2>&1 || pipx upgrade gnome-extensions-cli
GEXT="$HOME/.local/bin/gext"

while read -r uuid; do
	[[ -z "$uuid" || "$uuid" == \#* ]] && continue
	if [[ -d "$HOME/.local/share/gnome-shell/extensions/$uuid" ]]; then
		echo "Extension already installed: $uuid"
	else
		"$GEXT" --filesystem install "$uuid"
	fi
done <"$REPO_ROOT/stuffs/ubuntu/gnome-extensions.txt"

make -C "$REPO_ROOT/stuffs" dconf-load

echo "GNOME configured. Log out and back in so newly installed extensions are loaded and enabled."
