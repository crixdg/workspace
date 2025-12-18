#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install -y git

cp -f "workspace/.gitconfig" "$HOME/.gitconfig"

read -p "Enter your Git user.name: " git_user_name
read -p "Enter your Git user.email: " git_user_email

git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"
