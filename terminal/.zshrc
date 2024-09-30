# ALIAS

alias reload="source ~/.zshrc"

alias rhosts="cat /etc/hosts"
alias rconfig="cat ~/.zshrc"

alias ehosts="code -n /etc/hosts"
alias econfig="code -n ~/.zshrc"

alias xdg-open="wsl-open"

# --------------------

# BINDKEY

# --------------------

# ZSH
export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

# --------------------

# CUSTOM
ZSH_CUSTOM=$HOME/.oh-my-zsh/custom
ZSH_THEME="robbyrussell"

# --------------------

# PLUGIN
plugins=(
    z
    git
    mvn
    npm
    yarn
    # git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    zsh-autosuggestions
    # git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    zsh-syntax-highlighting
)

# --------------------

# PATH

# If you come from bash you might have to change your $PATH.
SBIN=/usr/sbin:/usr/local/sbin
LOCALBIN=$HOME/bin:$HOME/.local/bin:/usr/local/bin
export PATH=$SBIN:$LOCALBIN:$PATH

# --------------------

# CONFIG

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# --------------------

source $ZSH/oh-my-zsh.sh

# --------------------

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# VCCODE="/mnt/c/Users/baodh/AppData/Local/Programs/Microsoft VS Code/bin"
# export PATH=$VSCODE:$PATH
# export PATH="$PATH:/mnt/c/Users/baodh/AppData/Local/Programs/Microsoft VS Code/bin"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias vim=nvim