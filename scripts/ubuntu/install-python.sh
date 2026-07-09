#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

filename="Miniconda3-latest-Linux-x86_64.sh"
url="https://repo.anaconda.com/miniconda/$filename"
if ! wget --spider "$url" 2>/dev/null; then
	echo "Error: $url is not accessible or does not exist."
	exit 1
fi

rm -rf $HOME/.miniconda
mkdir -p $HOME/.miniconda
wget https://repo.anaconda.com/miniconda/$filename -O $HOME/.miniconda/miniconda.sh
bash $HOME/.miniconda/miniconda.sh -b -u -p $HOME/.miniconda
rm $HOME/.miniconda/miniconda.sh

CONFIG_NAME="miniconda"
CONFIG_CONTENT='export MINICONDA_HOME="$HOME/.miniconda"
if [ -d "$MINICONDA_HOME" ]; then
	path=("$MINICONDA_HOME/bin" $path)
fi

alias start_conda="source $MINICONDA_HOME/bin/activate"
alias stop_conda="conda deactivate"'
source "$SCRIPT_DIR/add-auto-config.sh"

echo "Miniconda installed and configured. Please restart your terminal or run 'source $SHELL_RC' to apply the changes."
