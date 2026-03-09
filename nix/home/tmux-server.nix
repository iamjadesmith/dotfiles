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
  shortcut = "b";
  terminal = "screen-256color";

  plugins = with pkgs.tmuxPlugins; [
    yank
    sensible
  ];

  extraConfig = ''
        setq -g status-utf8 on
        setw -g utf-8 on
        set -as terminal-features ",xterm-256color:RGB"
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

        bind L send-keys '^L'

    		set -g status-bg black
    		set -g status-fg white

        bind -n S-Left  previous-window
        bind -n S-Right next-window

        bind -n M-H previous-window
        bind -n M-L next-window

        set-window-option -g mode-keys vi

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        set -gu default-command
        set -g default-shell "$SHELL"
  '';
}
