{
  config,
  ...
}:
{
  enable = true;
  history.size = 10000;
  history.path = "${config.xdg.dataHome}/zsh/history";
  shellAliases = {
    vim = "nvim";
    v = "nvim";
    ls = "ls --color";
    l = "ls -la";
    c = "clear";
    dot = "cd ~/.dotfiles && nvim .";
    k = "kubectl";
    h = "helm";
    rebmac = "darwin-rebuild switch --flake ~/.dotfiles/nix/darwin#mac";
    proj = "source ~/.scripts/project.sh";
    o = "cd ~/Obsidian && nvim .";
  };
  initExtra = ''
    if [[ -f "/opt/homebrew/bin/brew" ]] then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
    if [ ! -d "$ZINIT_HOME" ]; then
       mkdir -p "$(dirname $ZINIT_HOME)"
       git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi

    source "$ZINIT_HOME/zinit.zsh"

    zinit light zsh-users/zsh-syntax-highlighting
    zinit light zsh-users/zsh-completions
    zinit light zsh-users/zsh-autosuggestions
    zinit light Aloxaf/fzf-tab

    zinit snippet OMZP::git
    zinit snippet OMZP::sudo
    zinit snippet OMZP::command-not-found

    autoload -Uz compinit && compinit

    zinit cdreplay -q

    if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
        eval "$(oh-my-posh init zsh --config $HOME/.dotfiles/.config/ohmyposh/zen.toml)"
    fi

    bindkey -e
    bindkey '^p' history-search-backward
    bindkey '^n' history-search-forward
    bindkey '^[w' kill-region

    SAVEHIST=$HISTSIZE
    HISTDUP=erase
    setopt appendhistory
    setopt sharehistory
    setopt hist_ignore_space
    setopt hist_ignore_all_dups
    setopt hist_save_no_dups
    setopt hist_ignore_dups
    setopt hist_find_no_dups

    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
    zstyle ':completion:*' menu no
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

    eval "$(fzf --zsh)"
    eval "$(zoxide init --cmd cd zsh)"

    PATH="$HOME/.local/bin:$HOME/.scripts:$PATH"

    if [[ -d "/Users/jade/Library/Python" ]] then
      export PATH="$PATH:$HOME/Library/Python/3.9/bin"
    fi

    export EDITOR="nvim"

    function lgit() {
        git add .
        if [ "$1" != "" ]; then
            git commit -m "$1"
        else
            git commit -m 'update'
        fi
        git push -u origin main
    }

    function rebuild() {
        git add .
        if [ "$1" != "" ]; then
            git commit -m "$1"
        else
            git commit -m 'update'
        fi
        sudo nixos-rebuild switch --flake ~/.dotfiles/nix/#$(hostname)
    }

    function rebmac() {
        git add .
        if [ "$1" != "" ]; then
            git commit -m "$1"
        else
            git commit -m 'update'
        fi
        darwin-rebuild switch --flake ~/.dotfiles/nix/darwin#mac
    }
  '';
}
