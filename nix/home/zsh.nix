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
    proj = "source ~/.dotfiles/scripts/tmux-project-session.sh";
    o = "cd ~/Obsidian && nvim .";
  };
  initContent = ''
    # Cache brew shellenv (only regenerate if homebrew updates)
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      BREW_CACHE="$HOME/.cache/brew-shellenv.zsh"
      if [[ ! -f "$BREW_CACHE" ]] || [[ "/opt/homebrew/bin/brew" -nt "$BREW_CACHE" ]]; then
        /opt/homebrew/bin/brew shellenv > "$BREW_CACHE"
      fi
      source "$BREW_CACHE"
    fi

    ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
    if [ ! -d "$ZINIT_HOME" ]; then
       mkdir -p "$(dirname $ZINIT_HOME)"
       git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi

    source "$ZINIT_HOME/zinit.zsh"

    # Load syntax-highlighting synchronously (needed for proper display)
    zinit light zsh-users/zsh-syntax-highlighting

    # Defer other plugins - use wait'1' for less critical ones
    zinit ice wait lucid atload'_zsh_autosuggest_start'
    zinit light zsh-users/zsh-autosuggestions

    zinit ice wait lucid blockf
    zinit light zsh-users/zsh-completions

    zinit ice wait lucid
    zinit light Aloxaf/fzf-tab

    # Defer OMZ snippets even more
    zinit ice wait'1' lucid; zinit snippet OMZP::git
    zinit ice wait'1' lucid; zinit snippet OMZP::sudo
    zinit ice wait'1' lucid; zinit snippet OMZP::command-not-found

    # Optimized compinit with caching
    autoload -Uz compinit
    if [[ -n ''${ZDOTDIR:-~}/.zcompdump(#qN.mh+24) ]]; then
      compinit
    else
      compinit -C
    fi

    autoload -U edit-command-line
    zle -N edit-command-line
    bindkey '^x^e' edit-command-line

    zinit cdreplay -q

    # Cache oh-my-posh init output
    if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
      OMP_CACHE="$HOME/.cache/omp-init.zsh"
      OMP_CONFIG="$HOME/.dotfiles/.config/ohmyposh/zen.toml"
      if [[ ! -f "$OMP_CACHE" ]] || [[ "$OMP_CONFIG" -nt "$OMP_CACHE" ]]; then
        oh-my-posh init zsh --config "$OMP_CONFIG" > "$OMP_CACHE"
      fi
      source "$OMP_CACHE"
    fi

    bindkey -e
    bindkey '^p' history-search-backward
    bindkey '^n' history-search-forward
    bindkey '^[w' kill-region

    SAVEHIST=$HISTSIZE
    HISTDUP=erase
    setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
    zstyle ':completion:*' menu no
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

    # Cache fzf and zoxide init
    FZF_CACHE="$HOME/.cache/fzf-init.zsh"
    ZOXIDE_CACHE="$HOME/.cache/zoxide-init.zsh"

    [[ ! -f "$FZF_CACHE" ]] && fzf --zsh > "$FZF_CACHE"
    [[ ! -f "$ZOXIDE_CACHE" ]] && zoxide init --cmd cd zsh > "$ZOXIDE_CACHE"

    source "$FZF_CACHE"
    source "$ZOXIDE_CACHE"

    PATH="$HOME/.local/bin:$HOME/.dotfiles/scripts:$PATH"

    if [[ -d "/Users/jade/Library/Python" ]]; then
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
        if [[ -d "/Users/jade" ]] then
            darwin-rebuild switch --flake ~/.dotfiles/nix/darwin#mac
        else
            sudo nixos-rebuild switch --flake ~/.dotfiles/nix/#$(hostname)
        fi
    }
  '';
}
