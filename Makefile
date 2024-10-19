# .PHONY
# -------------------------------------------------------

TIME := $(shell date +"%Y-%m-%d %H:%M:%S")

commit:
	git add .
	git commit -m "update $(TIME)"
	git push

# -------------------------------------------------------
# VARIABLES (update it if needed)

MY_SETUP_REPO := $(CURDIR)

show-path:
	echo $$PATH | tr ':' '\n' | awk '{print "* " $$0}'

# -------------------------------------------------------
# APT PACKAGES

show-linux-packages:
	command -v python3 >/dev/null 2>&1 || { echo "python3 is not installed. Installing..."; sudo apt update && sudo apt install -y python3; }
	python3 $(MY_SETUP_REPO)/os/linux/apt/show.apt.installed.py

install-essential-linux-packages:
	sh $(MY_SETUP_REPO)/os/linux/essential.linux.sh

# -------------------------------------------------------
# ZSH & OH MY ZSH

zsh-linux-install:
	sh $(MY_SETUP_REPO)/terminal/zsh/zsh.linux.install.sh

#zsh-macos-install:

zsh-linux-custom:
	sh $(MY_SETUP_REPO)/terminal/zsh/zsh.custom.sh
	yes | cp -rf $(MY_SETUP_REPO)/terminal/zsh/.zshrc ~/.zshrc
	yes | cp -rf $(MY_SETUP_REPO)/terminal/.dircolors ~/.dircolors
	sh $(MY_SETUP_REPO)/terminal/unnecessary.linux.sh
	echo "Need to reload shell ..."

# -------------------------------------------------------
# TMUX

tmux-linux-install:
	sh $(MY_SETUP_REPO)/terminal/tmux/tmux.linux.install.sh

#tmux-macos-install:

tmux-linux-custom:
	sh $(MY_SETUP_REPO)/terminal/tmux/tmux.custom.sh
	yes | cp -rf $(MY_SETUP_REPO)/terminal/tmux/config ~/.tmux
	yes | cp -rf $(MY_SETUP_REPO)/terminal/tmux/.tmux.conf ~/.tmux.conf

# -------------------------------------------------------
# TERMINAL CONFIG

push-terminal-config:
	yes | cp -rf $(MY_SETUP_REPO)/terminal/zsh/.zshrc ~/.zshrc
	yes | cp -rf $(MY_SETUP_REPO)/terminal/.dircolors ~/.dircolors
	yes | cp -rf $(MY_SETUP_REPO)/terminal/tmux/.tmux.conf ~/.tmux.conf
	echo "Need to reload shell ..."

pull-terminal-config:
	yes | cp -rf ~/.zshrc $(MY_SETUP_REPO)/terminal/zsh/.zshrc
	yes | cp -rf ~/.dircolors $(MY_SETUP_REPO)/terminal/.dircolors
	yes | cp -rf ~/.tmux.conf $(MY_SETUP_REPO)/terminal/tmux/.tmux.conf

# -------------------------------------------------------
# GITCONFIG

push-gitconfig:
	yes | cp -rf $(MY_SETUP_REPO)/git/.gitconfig ~/.gitconfig

pull-gitconfig:
	yes | cp -rf ~/.gitconfig $(MY_SETUP_REPO)/git/.gitconfig
