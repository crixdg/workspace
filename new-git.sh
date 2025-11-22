#!/usr/bin/env bash
set -e

read -p "This script is intended for Ubuntu systems only. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

sudo apt update
sudo apt install -y git

cp -f "workspace/.gitconfig" "$HOME/.gitconfig"

read -p "Enter your Git user.name: " git_user_name
read -p "Enter your Git user.email: " git_user_email

git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"
