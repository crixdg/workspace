#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

DEFAULT_VERSION="1.25.5"
read -p "Enter the Go version you want to install [${DEFAULT_VERSION}]: " VERSION
VERSION=${VERSION:-$DEFAULT_VERSION}
FILENAME="go${VERSION}.linux-amd64.tar.gz"
if ! curl --silent --head "https://go.dev/dl/${FILENAME}" | grep -q "HTTP/2 302"; then
	echo "Go file ${FILENAME} not found online. Aborted."
	exit 1
fi

rm -rf $HOME/.local/go
mkdir -p $HOME/.local/go
wget https://go.dev/dl/${FILENAME} -O $HOME/.local/go/${FILENAME}
tar -C $HOME/.local -xzf $HOME/.local/go/${FILENAME}
rm $HOME/.local/go/${FILENAME}

CONFIG_NAME="golang"
CONFIG_CONTENT='export GOROOT="$HOME/.local/go"
if [ -d "$GOROOT" ]; then
    export PATH="$GOROOT/bin:$PATH"
fi

export GOPATH="$HOME/go"
if [ -d "$GOPATH" ]; then
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"
fi'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Go ${VERSION} installed and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
