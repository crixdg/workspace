#!/usr/bin/env zsh
set -e

echo -n "This script is intended for Ubuntu systems only. Continue? (y/n): "
read confirm
if [[ "$confirm" != "y" ]]; then
	echo "Aborted."
	exit 1
fi

rm -f "$HOME/.zshrc"

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

cp -f "workspace/keiron.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/keiron.zsh-theme"
cp -f "workspace/.zshrc" "$HOME/.zshrc"
rm -rf ~/.bash* || true
rm -rf ~/.profile || true
rm -rf ~/.zcomp* || true
rm -rf ~/.shell.pre-oh-my-zsh* || true
rm -rf ~/.zshrc.pre-oh-my-zsh* || true

echo "Zsh configuration updated. Please restart your terminal or run 'source ~/.zshrc' to apply the changes."
