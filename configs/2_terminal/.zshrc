# ===============================================================================
# ZSH
export ZDOTDIR="${ZDOTDIR:-$HOME}"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$ZDOTDIR/.cache/zsh"
[ -d "$ZSH_CACHE_DIR" ] || mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"

autoload -Uz compinit
[[ -s "$ZSH_COMPDUMP" ]] && compinit -d "$ZSH_COMPDUMP" || compinit
# ===============================================================================
# CUSTOM
export ZSH_CUSTOM="$ZSH/custom"
# ===============================================================================
# THEME
# ZSH_THEME="robbyrussell"
# -------------------------------------------------------------------------------
# CUSTOM THEME
ZSH_THEME="baodh"
# ===============================================================================
# PLUGIN
plugins=(
    man
    git
    mvn
    npm
    yarn
    python
    virtualenv
    z
)

[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && plugins+=(zsh-autosuggestions)
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && plugins+=(zsh-syntax-highlighting)
# ===============================================================================
# CONFIG
# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"
# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

if command -v hostname &>/dev/null; then
    ip_address=$(hostname -I | awk '{print $1}')
    echo -ne "\033]0;IP: $ip_address\007"
fi
# ===============================================================================
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"
# ===============================================================================
# ALIAS

alias reload="source ~/.zshrc"
## In WSL Ubuntu, use wsl-open instead of xdg-open
alias vim=nvim
alias time='/usr/bin/time -f "\nreal\t%es\nuser\t%Us\nsys\t%Ss"'

alias ll='ls -hlF'
alias la='ls -A'
alias l='ls -CF'

## enable color support of ls and also add handy aliases
if command -v dircolors &>/dev/null; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
# ===============================================================================
# BIND_KEY
# ===============================================================================
# PATH
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
# ===============================================================================
# NODE VERSION MANAGER
if [ -d "$HOME/.nvm" ] ; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
# ===============================================================================
# MINICONDA
[ -d "$HOME/miniconda3" ] && export PATH="$HOME/miniconda3/bin:$PATH"
# ===============================================================================