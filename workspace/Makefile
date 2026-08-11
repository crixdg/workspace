diff-local-repo:
	diff ~/.config/nvim/init.lua neovim_init.lua

sync-local-repo:
	dconf dump /org/gnome/terminal/ > gnome-terminal-profiles.dconf
	dconf dump /org/gnome/shell/extensions/dash-to-panel/ > dash-to-panel.dconf

load-repo-local:
	dconf load /org/gnome/terminal/ < gnome-terminal-profiles.dconf
	dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel.dconf
