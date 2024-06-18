{ config, pkgs, ... }:
let inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  home.username = "joejad";
  home.homeDirectory = "/home/joejad";
  xdg.enable = true;

  xdg.configFile.nvim.source =
    mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/nvim";

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;

  wayland.windowManager.hyprland.enable = true;
}
