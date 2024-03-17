export PATH="/usr/local/bin:/usr/bin:$PATH"

if [ Darwin = `uname` ]; then
  source $HOME/.profile-macos
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload -Uz compinit && compinit

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

zinit light ohmyzsh/ohmyzsh
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

source $HOME/.profile
# source $HOME/.config/tmuxinator/tmuxinator.zsh

if [ Linux = `uname` ]; then
  source $HOME/.profile-linux
fi

setopt auto_cd

alias sudo='sudo '
export LD_LIBRARY_PATH=/usr/local/lib

# P10k customizations
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

bindkey "^P" up-line-or-beginning-search
bindkey "^N" down-line-or-beginning-search

# Capslock command
alias capslock="sudo killall -USR1 caps2esc"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export MOZ_ENABLE_WAYLAND=1
fi

zle_highlight=('paste:none')

# Bitwarden shell completion
eval "$(bw completion --shell zsh); compdef _bw bw;"

export BW_SESSION="5FYTVBL73xwR3Pq0LWSn/JA6yzXUjwSTweE6pX51ck5eFg10jpoXt8exCHUazpXQKQ9DHHQUHvyqE7eblw/PFA=="

bindkey "^J" autosuggest-execute
