if [ ! -d "$HOME/.tmux/plugins/tmp" ]; then
    git clone "https://github.com/tmux-plugins/tmp" "$HOME/.tmux/plugins/tmp"
fi

if [ ! -d "$HOME/.tmux/config" ]; then
    mkdir "$HOME/.tmux/config"
fi

if [ ! -e "$HOME/.tmux/config/options.conf" ]; then
    touch "$HOME/.tmux/config/options.conf"
fi
if [ ! -e "$HOME/.tmux/config/keybindings.conf" ]; then
    touch "$HOME/.tmux/config/keybindings.conf"
fi
if [ ! -e "$HOME/.tmux/config/theme.conf" ]; then
    touch "$HOME/.tmux/config/theme.conf"
fi
