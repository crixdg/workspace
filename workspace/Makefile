sync-local-repo:
	cp ~/.config/nvim/init.lua neovim_init.lua
	cp ~/.tmux.conf .tmux.conf
	dconf dump /org/gnome/terminal/ > gnome-terminal-profiles.dconf
	dconf dump /org/gnome/shell/extensions/dash-to-panel/ > dash-to-panel.dconf

load-repo-local:
	cp neovim_init.lua ~/.config/nvim/init.lua
	cp .tmux.conf ~/.tmux.conf
	dconf load /org/gnome/terminal/ < gnome-terminal-profiles.dconf
	dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel.dconf
