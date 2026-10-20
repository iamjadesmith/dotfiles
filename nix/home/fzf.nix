{ pkgs, ... }: {
  enable = true;
  enableZshIntegration = true;
  tmux.enableShellIntegration = true;
  # Use the terminal's ANSI palette so fzf follows its light or dark theme.
  defaultOptions = [ "--color=16" ];
}
