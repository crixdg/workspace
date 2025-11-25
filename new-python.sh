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

START_MARK="# >>> conda initialize >>>"
DESCRIPTION_MARK="# !! Contents within this block are managed by 'conda init' !!"
END_MARK="# <<< conda initialize <<<"

CONDA_BLOCK=$(
	cat <<EOF
$START_MARK
$DESCRIPTION_MARK
export MINICONDA_HOME="\$HOME/miniconda3"
if [ -d "\$MINICONDA_HOME" ]; then
	export PATH="\$MINICONDA_HOME/bin:\$PATH"
fi
$END_MARK
EOF
)

if [[ "$SHELL" =~ "zsh" ]]; then
	SHELL_RC="$HOME/.zshrc"
else
	SHELL_RC="$HOME/.bashrc"
fi

if grep -q "$START_MARK" "$SHELL_RC"; then
	# Replace existing block, ensure empty line before block
	awk -v block="$CONDA_BLOCK" -v start="$START_MARK" -v end="$END_MARK" '
        BEGIN {inblock=0}
        $0 ~ start {
            print block;
            inblock=1;
            next
        }
        $0 ~ end {
            inblock=0;
            next
        }
        inblock == 0 {print}
    ' "$SHELL_RC" >"$SHELL_RC.tmp" && mv "$SHELL_RC.tmp" "$SHELL_RC"
else
	# Append new block with preceding empty line
	{
		echo ""
		echo "$CONDA_BLOCK"
	} >>"$SHELL_RC"
fi


source $HOME/miniconda3/bin/activate
