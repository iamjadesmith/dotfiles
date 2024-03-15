alias c="clear"
alias vim='nvim'
alias ls='ls --color=auto'

export EDITOR="nvim"
export SHELL="zsh"

if ! type open > /dev/null ; then
  alias open=xdg-open
fi
