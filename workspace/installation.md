### Zsh
```shell
sudo apt update
sudo apt install zsh -y
sudo apt install git neovim -y
[ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

```shell
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
```

```shell
cp -f "workspace/keiron.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/keiron.zsh-theme"
cp -f "workspace/.zshrc" "$HOME/.zshrc"
rm -rf ~/.bash* ~/.profile ~/.zcomp* ~/.shell.pre-oh-my-zsh
source "$HOME/.zshrc"
```

```shell
cp -f "$HOME/.oh-my-zsh/custom/themes/keiron.zsh-theme" "workspace/keiron.zsh-theme"
cp -f "$HOME/.zshrc" "workspace/.zshrc"
```

### Git
```shell
cp -f "workspace/.gitconfig" "$HOME/.gitconfig"
```

```shell
cp -f "$HOME/.gitconfig" "workspace/.gitconfig"
```

### Vim
```shell
cp -f "$HOME/.config/nvim/init.vim" "workspace/.vimrc"
```

```shell
mkdir -p "$HOME/.config/nvim"
cp -f "workspace/.vimrc" "$HOME/.config/nvim/init.vim"
```

### C++
```shell
cp -f "$HOME/.clang-format" "workspace/.clang-format"
cp -f "$HOME/.gdbinit" "workspace/.gdbinit"
```

```shell
cp -f "workspace/.clang-format" "$HOME/.clang-format"
cp -f "workspace/.gdbinit" "$HOME/.gdbinit"
```

```shell
cp -f $HOME/.local/bin/* "workspace/bin/"
```

```shell
mkdir -p "$HOME/.local/bin/"
cp -f workspace/bin/* "$HOME/.local/bin/"
```
