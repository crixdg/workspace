#!/bin/sh

mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh

# shellcheck disable=SC3046
# shellcheck disable=SC1090
source ~/miniconda3/bin/activate

conda init --all
conda config --set auto_activate_base false