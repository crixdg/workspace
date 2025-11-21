# ===============================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CACHE_DIR="$HOME/.cache/zsh"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"
export ZSH_CUSTOM="$ZSH/custom"

# ===============================================================================
autoload -Uz compinit
[ -d "$ZSH_CACHE_DIR" ] || mkdir -p "$ZSH_CACHE_DIR"
if [[ ! -s "$ZSH_COMPDUMP" || "$ZSH_COMPDUMP" -ot ~/.zshrc ]]; then
	compinit -i -d "$ZSH_COMPDUMP"
else
	compinit -d "$ZSH_COMPDUMP"
fi

# ===============================================================================
# THEME
ZSH_THEME="keiron"

# ===============================================================================
# PLUGIN
plugins=(
	man
	git
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
setopt nullglob
for dir in "$HOME/bin" "$HOME/.local/bin"; do
	if [ -d "$dir" ]; then
		for subdir in "$dir"/*/; do
			[ -d "$subdir" ] && export PATH="$subdir:$PATH"
		done
	fi
done
unsetopt nullglob

# ===============================================================================
