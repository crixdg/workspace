#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install -y curl
mkdir -p "$HOME/.local/bin"

if ! command -v uv >/dev/null && [[ ! -x "$HOME/.local/bin/uv" ]]; then
	curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

if [[ ! -x "$HOME/.local/bin/claude" ]]; then
	curl -fsSL https://claude.ai/install.sh | bash
fi

echo "Tools installed: uv, claude."
