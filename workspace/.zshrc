# zmodload zsh/zprof # Uncomment to profile zsh startup time and add 'zprof' at the end of this file

# ===============================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$HOME/.cache/zsh"
export ZSH_CUSTOM="$ZSH/custom"

# ===============================================================================
# CONFIG

# Uncomment the following line to disable auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable the warning about insecure directories.
DISABLE_COMPFIX="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

if command -v hostname &>/dev/null; then
	ip_address=$(hostname -I | awk '{print $1}')
	echo -ne "\033]0;IP: $ip_address\007"
fi

[ -d "$ZSH_CACHE_DIR" ] || mkdir -p "$ZSH_CACHE_DIR"

# ===============================================================================
# COMPINIT

autoload -Uz compinit
if [[ -z "$ZSH_COMPDUMP" ]]; then
  ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"
fi
compinit -C -d "$ZSH_COMPDUMP"

# Regenerate in background
{
  if [[ -f "$ZSH_COMPDUMP" && \
        (! -s "${ZSH_COMPDUMP}.zwc" || \
         "$ZSH_COMPDUMP" -nt "${ZSH_COMPDUMP}.zwc") ]]; then
    zcompile "$ZSH_COMPDUMP"
  fi
} &!

# ===============================================================================
# THEME
ZSH_THEME="keiron"

# ===============================================================================
# PLUGIN
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1

plugins=(
	git
	z
)

[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && plugins+=(zsh-autosuggestions)
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && plugins+=(zsh-syntax-highlighting)

# ===============================================================================

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# ===============================================================================
# ALIAS
alias reload="source ~/.zshrc"
alias vim=nvim

alias ll='ls -hlF'
alias la='ls -A'
alias l='ls -CF'

if [ -x /usr/bin/dircolors ] && [ -s "$HOME/.dircolors" ]; then
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
[ -d "$HOME/.local/bin/cppbin" ] && export PATH="$HOME/.local/bin/cppbin:$PATH"

# ===============================================================================
