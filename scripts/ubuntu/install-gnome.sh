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

mkdir -p "$HOME/.config/fcitx5" "$HOME/.config/environment.d" "$HOME/.config/autostart" "$HOME/.local/share/fcitx5/inputmethod"
cp -f "$REPO_ROOT/stuffs/fcitx5-profile" "$HOME/.config/fcitx5/profile"
cp -f "$REPO_ROOT/stuffs/fcitx5-config" "$HOME/.config/fcitx5/config"
cp -f "$REPO_ROOT/stuffs/fcitx5-bamboo.conf" "$HOME/.local/share/fcitx5/inputmethod/bamboo.conf"
cp -f "$REPO_ROOT/stuffs/fcitx5-environment.conf" "$HOME/.config/environment.d/fcitx5.conf"
cp -f /usr/share/applications/org.fcitx.Fcitx5.desktop "$HOME/.config/autostart/"

make -C "$REPO_ROOT/stuffs" dconf-load

echo "GNOME configured. Log out and back in so newly installed extensions are loaded and enabled."
