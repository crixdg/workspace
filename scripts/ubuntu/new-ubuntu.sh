#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 1
fi

sudo apt update

sudo apt install -y git
sudo apt install -y neovim
sudo apt install -y zip unzip

sudo apt install -y iproute2
sudo apt install -y iputils-ping
sudo apt install -y curl wget
sudo apt install -y nmap
sudo apt install -y ufw

sudo apt install -y zsh
if ! command -v zsh &>/dev/null; then
    echo "Error: zsh installation failed."
    exit 1
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh is already installed."
fi
