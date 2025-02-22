{
  config,
  pkgs,
  lib,
  meta,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.username = "joejad";
  home.homeDirectory = "/home/joejad";
  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/nvim";

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs = {
    alacritty = import ./alacritty.nix {
      inherit
        config
        pkgs
        lib
        meta
        ;
    };
    zsh = import ./zsh.nix { inherit config; };
    fzf = import ./fzf.nix { inherit pkgs; };
    firefox = import ./firefox.nix;
    neovim = import ./neovim.nix { inherit config pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    zoxide = import ./zoxide.nix { inherit pkgs; };
  };

  wayland.windowManager = {
    hyprland = import ./hyprland.nix { inherit config; };
  };

}
