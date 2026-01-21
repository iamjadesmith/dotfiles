{ pkgs, ... }:
{
  enable = true;

  aggressiveResize = true;
  baseIndex = 1;
  disableConfirmationPrompt = true;
  keyMode = "vi";
  newSession = true;
  secureSocket = true;
  shell = "${pkgs.zsh}/bin/zsh";
  shortcut = "space";
  terminal = "screen-256color";

  plugins = with pkgs.tmuxPlugins; [
    yank
    sensible
  ];

  extraConfig = ''
        # set-default colorset-option -ga terminal-overrides ",xterm-256color:Tc"
        set -as terminal-features ",xterm-256color:RGB"
        # set-option -sa terminal-overrides ",xterm*:Tc"
        set -g mouse on

        bind -r ^ last-window
        bind -r k select-pane -U
        bind -r j select-pane -D
        bind -r h select-pane -L
        bind -r l select-pane -R

        set -g base-index 1
        set -g pane-base-index 1
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on

        # Bind clearing the screen
        bind L send-keys '^L'

    		set -g status-bg black
    		set -g status-fg white

        # Shift arrow to switch windows
        bind -n S-Left  previous-window
        bind -n S-Right next-window

        # Shift Alt vim keys to switch windows
        bind -n M-H previous-window
        bind -n M-L next-window

        # set vi-mode
        set-window-option -g mode-keys vi

        # keybindings
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        set -gu default-command
        set -g default-shell "$SHELL"

        # Project session launcher (prefix + o for open project)
        bind o run-shell "$HOME/.dotfiles/scripts/tmux-project-session.sh"
  '';
}
