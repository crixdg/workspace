machine-to-repo:
	cp ~/.config/nvim/init.lua neovim_init.lua
	cp ~/.config/nvim/lazy-lock.json neovim_lazy-lock.json
	cp ~/.tmux.conf .tmux.conf
	dconf dump /org/gnome/Ptyxis/ > ptyxis-profiles.dconf
	dconf dump /org/gnome/shell/extensions/dash-to-panel/ > dash-to-panel.dconf
	dconf dump /org/gnome/shell/extensions/tiling-assistant/ > tiling-assistant.dconf
	dconf dump /org/gnome/shell/extensions/vitals/ > vitals.dconf
	dconf dump /org/gnome/shell/extensions/caffeine/ > caffeine.dconf
	dconf dump /org/gnome/shell/extensions/clipboard-indicator/ > clipboard-indicator.dconf

repo-to-machine:
	cp neovim_init.lua ~/.config/nvim/init.lua
	cp neovim_lazy-lock.json ~/.config/nvim/lazy-lock.json
	cp .tmux.conf ~/.tmux.conf
	dconf load /org/gnome/Ptyxis/ < ptyxis-profiles.dconf
	dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel.dconf
	dconf load /org/gnome/shell/extensions/tiling-assistant/ < tiling-assistant.dconf
	dconf load /org/gnome/shell/extensions/vitals/ < vitals.dconf
	dconf load /org/gnome/shell/extensions/caffeine/ < caffeine.dconf
	dconf load /org/gnome/shell/extensions/clipboard-indicator/ < clipboard-indicator.dconf
