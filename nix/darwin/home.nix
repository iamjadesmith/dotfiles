{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  programs.home-manager.enable = true;

  home.username = "jade";
  home.homeDirectory = "/Users/jade";
  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/jade/.dotfiles/.config/nvim";

  home.stateVersion = "24.11";

  programs = {
    alacritty = import ../home/alacritty.nix { inherit config pkgs; };
    tmux = import ../home/tmux.nix {inherit pkgs;};
    zsh = import ../home/zsh.nix {inherit config pkgs lib; };
    zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    fzf = import ../home/fzf.nix {inherit pkgs;};
    git = import ../home/git.nix {inherit config pkgs;};
  };
}
