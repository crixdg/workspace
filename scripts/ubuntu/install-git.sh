#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/check-os.sh"

sudo apt install git -y

git_user_name="$(git config --global user.name 2>/dev/null || true)"
git_user_email="$(git config --global user.email 2>/dev/null || true)"
cp -f "$REPO_ROOT/stuffs/.gitconfig" "$HOME/.gitconfig"

git_user_name="${GIT_USER_NAME:-$git_user_name}"
git_user_email="${GIT_USER_EMAIL:-$git_user_email}"
[ -z "$git_user_name" ] && read -r -p "Enter your Git user.name: " git_user_name
[ -z "$git_user_email" ] && read -r -p "Enter your Git user.email: " git_user_email

git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"
