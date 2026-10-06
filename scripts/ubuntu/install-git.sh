#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install git -y

cp -f "$REPO_ROOT/stuffs/.gitconfig" "$HOME/.gitconfig"

read -p "Enter your Git user.name: " git_user_name
read -p "Enter your Git user.email: " git_user_email

git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"
