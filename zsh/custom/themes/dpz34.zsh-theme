# username@host
user() {
   echo "%{$fg_bold[green]%}$(whoami)@$(hostname)%{$reset_color%}"
}

# current directory
directory() {
   echo "%{$fg_bold[blue]%}%~"
}

# set the git info text
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[white]%}[%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[yellow]%}*%{$fg_bold[white]%}]"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[white]%}]"

# whole prompt
PROMPT='%B$(user):$(directory)$(git_prompt_info)%b$ '
