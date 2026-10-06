machine-to-repo:
	cp ~/.config/nvim/init.lua neovim_init.lua
	cp ~/.tmux.conf .tmux.conf
	dconf dump /org/gnome/Ptyxis/ > ptyxis-profiles.dconf
	dconf dump /org/gnome/shell/extensions/dash-to-panel/ > dash-to-panel.dconf

repo-to-machine:
	cp neovim_init.lua ~/.config/nvim/init.lua
	cp .tmux.conf ~/.tmux.conf
	dconf load /org/gnome/Ptyxis/ < ptyxis-profiles.dconf
	dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel.dconf
