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
  # wayland.windowManager.hyprland.settings = {
  #   "$mod" = "SUPER";
  #   bind =
  #     [
  #       "$mod, F, exec, firefox"
  #       ", Print, exec, grimblast copy area"
  #     ]
  #     ++ (
  #       # workspaces
  #       # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  #       builtins.concatLists (builtins.genList (
  #           x: let
  #             ws = let
  #               c = (x + 1) / 10;
  #             in
  #               builtins.toString (x + 1 - (c * 10));
  #           in [
  #             "$mod, ${ws}, workspace, ${toString (x + 1)}"
  #             "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
  #           ]
  #         )
  #         10)
  #     );
  # };
}
