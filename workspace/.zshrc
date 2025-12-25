# zmodload zsh/zprof # Uncomment to profile zsh startup time and add 'zprof' at the end of this file
# ===============================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$HOME/.cache/zsh"
export ZSH_CUSTOM="$ZSH/custom"

# ===============================================================================
# CONFIG

DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
ZSH_DISABLE_COMPFIX=true
DISABLE_COMPFIX="true"
DISABLE_AUTO_TITLE="true"
skip_global_compinit=1

if command -v hostname &>/dev/null; then
	hostname=$(hostname)
	echo -ne "\033]0;$hostname\007"
fi

[ -d "$ZSH_CACHE_DIR" ] || mkdir -p "$ZSH_CACHE_DIR"

# ===============================================================================
# THEME
ZSH_THEME="keiron"

# ===============================================================================
# PLUGIN
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1

plugins=(
	git
	docker
	z
)

[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && plugins+=(zsh-autosuggestions)
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && plugins+=(zsh-syntax-highlighting)

# ===============================================================================

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# ===============================================================================
# COMPINIT

ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

# ===============================================================================
# ALIAS
alias reload="exec zsh"

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

# ===============================================================================
# zprof  # Uncomment with zmodload above to profile zsh startup time
