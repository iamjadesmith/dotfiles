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

  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    bind = [ "$mod, F, exec, firefox" ", Print, exec, grimblast copy area" ]
      ++ (
        builtins.concatLists (builtins.genList (x:
          let
            ws = let c = (x + 1) / 10; in builtins.toString (x + 1 - (c * 10));
          in [
            "$mod, ${ws}, workspace, ${toString (x + 1)}"
            "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]) 10));
  };

  programs.home-manager.enable = true;
}
