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
	python3 $(MY_SETUP_REPO)/operating_system/linux/apt/show.apt.installed.py

install-essential-linux-packages:
	$(MY_SETUP_REPO)/operating_system/linux/essential.linux.sh

# -------------------------------------------------------
# ZSH & OH MY ZSH

zsh-linux-install:
	$(MY_SETUP_REPO)/terminal/zsh/zsh.linux.install.sh

#zsh-macos-install:

zsh-linux-custom:
	$(MY_SETUP_REPO)/terminal/zsh/zsh.custom.sh
	yes | cp -rf $(MY_SETUP_REPO)/terminal/zsh/.zshrc ~/.zshrc
	yes | cp -rf $(MY_SETUP_REPO)/terminal/.dircolors ~/.dircolors
	$(MY_SETUP_REPO)/terminal/unnecessary.linux.sh
	/usr/bin/zsh

# -------------------------------------------------------
# TERMINAL CONFIG

push-terminal-config:
	yes | cp -rf $(MY_SETUP_REPO)/terminal/zsh/.zshrc ~/.zshrc
	yes | cp -rf $(MY_SETUP_REPO)/terminal/.dircolors ~/.dircolors

pull-terminal-config:
	yes | cp -rf ~/.zshrc $(MY_SETUP_REPO)/terminal/zsh/.zshrc
	yes | cp -rf ~/.dircolors $(MY_SETUP_REPO)/terminal/.dircolors

# -------------------------------------------------------
# GITCONFIG

push-gitconfig:
	yes | cp -rf $(MY_SETUP_REPO)/version_control/git/.gitconfig ~/.gitconfig

pull-gitconfig:
	yes | cp -rf ~/.gitconfig $(MY_SETUP_REPO)/version_control/git/.gitconfig

# -------------------------------------------------------
# CODE EDITOR: VSCODE (Can be synced by Github)

origin_windows_vscode := $(MY_WINDOWS_HOME)/AppData/Roaming/Code/User

local_vscode := $(MY_SETUP_REPO)/code_editor/vscode

push-vscode-settings:
	yes | cp -rf $(local_vscode)/*.json $(origin_windows_vscode)

pull-vscode-settings:
	yes | cp -rf $(origin_windows_vscode)/*.json $(local_vscode)