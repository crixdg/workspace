#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

if [ ! -d "$HOME/.nvm" ]; then
	read -p "Enter the NVM version you want to install (e.g., v0.40.1): " NVM_VERSION
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash
	echo "NVM installed."
else
	echo "NVM already installed at $HOME/.nvm"
fi

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
echo "  nvm --version          # Check NVM version"
echo "  nvm install --lts     # Install latest LTS Node.js"
echo "  nvm install 20        # Install Node.js 20.x"
echo "  nvm use 20            # Use Node.js 20.x"
echo "  nvm ls                # List installed versions"
