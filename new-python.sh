#!/usr/bin/env bash
set -e

echo -n "This script is intended for Ubuntu systems only. Continue? (y/n): "
read confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

filename="Miniconda3-latest-Linux-x86_64.sh"
# Check if the file exists before downloading
url="https://repo.anaconda.com/miniconda/$filename"
if ! wget --spider "$url" 2>/dev/null; then
	echo "Error: $url is not accessible or does not exist."
	exit 1
fi

sudo apt update

rm -rf $HOME/miniconda3
mkdir -p $HOME/miniconda3
wget https://repo.anaconda.com/miniconda/$filename -O $HOME/miniconda3/miniconda.sh
bash $HOME/miniconda3/miniconda.sh -b -u -p $HOME/miniconda3
rm $HOME/miniconda3/miniconda.sh

source $HOME/miniconda3/bin/activate
if command -v zsh &>/dev/null; then
	conda init zsh
else
	echo "Warning: zsh is not installed or not found in PATH. Falling back to bash."
	conda init bash
fi
