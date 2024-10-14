# ZSH
# export ZDOTDIR=$HOME by default
export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

# ============================================================

# CUSTOM

ZSH_CUSTOM=$ZSH/custom

# ============================================================

# THEME

ZSH_THEME="robbyrussell"

# ------------------------------------------------------------

# CUSTOM THEME

# ============================================================

# PLUGIN

plugins=(
    man
    git
    mvn
    npm
    yarn
    python

    z
)

# ------------------------------------------------------------

# CUSTOM PLUGIN

if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  plugins+=(zsh-autosuggestions)
fi

if [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
  plugins+=(zsh-syntax-highlighting)
fi

# ============================================================

# CONFIG

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

local ip_address=$(hostname -I | awk '{print $1}')
echo -ne "\033]0;IP: $ip_address\007"

# ============================================================

source $ZSH/oh-my-zsh.sh

# ============================================================

# ALIAS

alias reload="source ~/.zshrc"

## In WSL Ubuntu, use wsl-open instead of xdg-open

alias vim=nvim

## enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -hlF'
alias la='ls -A'
alias l='ls -CF'

# ============================================================

# BIND_KEY

# ============================================================

# PATH

if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

export PATH=$PATH

# ============================================================

# NODE VERSION MANAGER

if [ -d "$HOME/.nvm" ] ; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# ============================================================
