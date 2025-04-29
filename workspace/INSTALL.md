# Shell

### Zsh
```shell
sudo apt update
sudo apt install zsh -y
[ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Custom Zsh
```shell
sudo apt install git neovim -y
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
```

---
# Config

### Zsh Config
```shell
cp -rf "workspace/keiron.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/keiron.zsh-theme"
cp -rf "workspace/.zshrc" "$HOME/.zshrc"
rm -rf ~/.bash*
rm -rf ~/.profile
rm -rf ~/.zcomp*
rm -rf ~/.shell.pre-oh-my-zsh
source "$HOME/.zshrc"
```

### Git Config
```shell
cp -rf "workspace/.gitconfig" "$HOME/.gitconfig"
```

### Clang-Format
```shell
cp -rf "workspace/.clang-format" "$HOME/.clang-format"
```

### GDB Config
```shell
cp -rf "workspace/.gdbinit" "$HOME/.gdbinit"
```