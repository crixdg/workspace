#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check-os.sh"

PACKAGES_FILE="$REPO_ROOT/stuffs/ubuntu/apt-packages.txt"
CODENAME="$(lsb_release -cs)"

sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release software-properties-common

if [[ ! -f "/etc/apt/sources.list.d/bamboo-engine-ubuntu-ibus-bamboo-${CODENAME}.sources" ]]; then
	sudo add-apt-repository -y ppa:bamboo-engine/ibus-bamboo
fi

mapfile -t packages < <(sed 's/#.*//; /^\s*$/d' "$PACKAGES_FILE")
sudo apt install -y "${packages[@]}"

if ubuntu-drivers devices 2>/dev/null | grep -q recommended; then
	sudo ubuntu-drivers install
fi

echo "APT packages installed."
