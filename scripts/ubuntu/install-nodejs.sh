#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

ask_version() {
	local default="$1" label="$2" answer=""
	if [ -t 0 ]; then
		read -r -p "Enter the ${label} version you want to install [${default}]: " answer || answer=""
	fi
	printf '%s' "${answer:-$default}"
}

NVM_VERSION="${NVM_VERSION:-$(ask_version "0.40.1" "NVM")}"
NODE_VERSION="${NODE_VERSION:-$(ask_version "24" "Node.js")}"

if [ ! -d "$HOME/.nvm" ]; then
	curl -LO https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh 2>/dev/null
	bash install.sh
	rm install.sh
	echo "NVM installed."
else
	echo "NVM already installed at $HOME/.nvm"
fi

export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

CONFIG_NAME="nvm"
CONFIG_CONTENT='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
source "$SCRIPT_DIR/add-auto-config.sh"

echo ""
echo "NVM configuration has been cleaned and fixed!"
echo "Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
echo ""
echo "After sourcing, you can use NVM commands:"
echo "  nvm --version         # Check NVM version"
echo "  nvm install --lts     # Install latest LTS Node.js"
echo "  nvm install 20        # Install Node.js 20.x"
echo "  nvm use 20            # Use Node.js 20.x"
echo "  nvm ls                # List installed versions"
