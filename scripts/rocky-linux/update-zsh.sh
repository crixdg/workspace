#!/bin/zsh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/check-os.sh"

rm -f "$HOME/.zshrc"
rm -rf ~/.bash* || true
rm -rf ~/.profile || true
rm -rf ~/.zcomp* || true
rm -rf ~/.shell.pre-oh-my-zsh* || true
rm -rf ~/.zshrc.pre-oh-my-zsh* || true

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

cp -f "workspace/keiron.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/keiron.zsh-theme"
cp -f "workspace/.zshrc" "$HOME/.zshrc"

echo "Zsh configuration updated. Please restart your terminal or run 'source ~/.zshrc' to apply the changes."
