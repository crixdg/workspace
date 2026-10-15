DCONF := \
	ptyxis-profiles:/org/gnome/Ptyxis/ \
	dash-to-panel:/org/gnome/shell/extensions/dash-to-panel/ \
	tiling-assistant:/org/gnome/shell/extensions/tiling-assistant/ \
	vitals:/org/gnome/shell/extensions/vitals/ \
	caffeine:/org/gnome/shell/extensions/caffeine/ \
	clipboard-indicator:/org/gnome/shell/extensions/clipboard-indicator/ \
	ding:/org/gnome/shell/extensions/ding/ \
	gnome-mutter:/org/gnome/mutter/

DESKTOP_KEYS := interface input-sources peripherals/touchpad peripherals/keyboard session privacy sound

.PHONY: machine-to-repo repo-to-machine dotfiles-dump dotfiles-load dconf-dump dconf-load

machine-to-repo: dotfiles-dump dconf-dump

repo-to-machine: dotfiles-load dconf-load

dotfiles-dump:
	cp ~/.config/nvim/init.lua neovim_init.lua
	cp ~/.config/nvim/lazy-lock.json neovim_lazy-lock.json
	cp ~/.tmux.conf .tmux.conf
	cp ~/.ideavimrc .ideavimrc
	cp ~/.gdbinit .gdbinit
	cp ~/.config/fcitx5/profile fcitx5-profile
	cp ~/.config/fcitx5/config fcitx5-config
	cp /etc/keyd/default.conf ubuntu/keyd.conf
	ls ~/.local/share/gnome-shell/extensions/ > ubuntu/gnome-extensions.txt

dotfiles-load:
	mkdir -p ~/.config/nvim
	cp neovim_init.lua ~/.config/nvim/init.lua
	cp neovim_lazy-lock.json ~/.config/nvim/lazy-lock.json
	cp .tmux.conf ~/.tmux.conf
	cp .ideavimrc ~/.ideavimrc
	cp .gdbinit ~/.gdbinit
	mkdir -p ~/.config/fcitx5 ~/.config/environment.d ~/.config/autostart ~/.local/share/fcitx5/inputmethod
	cp fcitx5-profile ~/.config/fcitx5/profile
	cp fcitx5-config ~/.config/fcitx5/config
	cp fcitx5-bamboo.conf ~/.local/share/fcitx5/inputmethod/bamboo.conf
	cp fcitx5-environment.conf ~/.config/environment.d/fcitx5.conf
	cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/

dconf-dump:
	@for e in $(DCONF); do dconf dump "$${e#*:}" > "$${e%%:*}.dconf"; done
	@for k in $(DESKTOP_KEYS); do dconf dump "/org/gnome/desktop/$$k/" | sed "s|^\[/\]$$|[$$k]|"; echo; done > gnome-desktop.dconf
	@printf '[/]\nenabled-extensions=%s\nfavorite-apps=%s\n' \
		"$$(dconf read /org/gnome/shell/enabled-extensions)" \
		"$$(dconf read /org/gnome/shell/favorite-apps)" > gnome-shell.dconf

dconf-load:
	@for e in $(DCONF); do dconf load "$${e#*:}" < "$${e%%:*}.dconf"; done
	dconf load /org/gnome/desktop/ < gnome-desktop.dconf
	dconf load /org/gnome/shell/ < gnome-shell.dconf
