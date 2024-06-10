{ config, pkgs, ... }:

{
  home.username = "joejad";
  home.homeDirectory = "/home/joejad";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
