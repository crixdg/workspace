#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check-os.sh"

KEYD_VERSION="${KEYD_VERSION:-2.5.0}"

if ! command -v keyd >/dev/null || ! keyd --version | grep -q "v${KEYD_VERSION}"; then
	sudo apt install -y build-essential git
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	git clone --depth 1 --branch "v${KEYD_VERSION}" https://github.com/rvaiya/keyd "$tmp/keyd"
	make -C "$tmp/keyd"
	sudo make -C "$tmp/keyd" install
fi

sudo mkdir -p /etc/keyd
sudo cp "$REPO_ROOT/stuffs/ubuntu/keyd.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload

echo "keyd $(keyd --version) installed with stuffs/ubuntu/keyd.conf."
