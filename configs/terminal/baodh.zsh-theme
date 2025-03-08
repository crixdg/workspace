PROMPT='$(virtualenv_prompt_info) '
PROMPT+="%(?:%{$fg_bold[green]%}➜%{$reset_color%} :%{$fg_bold[red]%}➜%{$reset_color%} ) "
PROMPT+="%{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)"

ZSH_THEME_VIRTUALENV_PREFIX="%{$fg_bold[yellow]%}(%{$reset_color%}"
ZSH_THEME_VIRTUALENV_SUFFIX="%{$fg_bold[yellow]%})%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_bold[blue]%})%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""