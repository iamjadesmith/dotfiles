{ config, pkgs, ... }:
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

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    bind =
      [
        "$mod, F, exec, firefox"
        "$mod, RETURN, exec, alacritty"
        "$mod+SHIFT, E, exit"
        "$mod+SHIFT, Q, killactive"
        "$mod, Y, exec, nautilus"
        "$mod, V, togglesplit"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod+SHIFT, H, movewindow, l"
        "$mod+SHIFT, L, movewindow, r"
        "$mod+SHIFT, K, movewindow, u"
        "$mod+SHIFT, J, movewindow, d"
        "$mod, D, exec, wofi --show drun"
        "$mod+ALT, H, resizeactive, -10 -10"
        "$mod+ALT, L, resizeactive, 10 -10"
        "$mod+ALT, K, resizeactive, 10 -10"
        "$mod+ALT, J, resizeactive, -10 -10"
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          x:
          let
            ws =
              let
                c = (x + 1) / 10;
              in
              builtins.toString (x + 1 - (c * 10));
          in
          [
            "$mod, ${ws}, workspace, ${toString (x + 1)}"
            "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]
        ) 10
      ));
    monitor = [
      "HDMI-A-1,3840x2160,0x0,2"
      "DP-3,3440x1440@175,1920x0,1"
      "Unknown-1,disable"
    ];
    exec = [
      "gsettings set org.gnome.desktop.interface gtk-theme "
      "Adwaita"
      ""
      "gsettings set org.gnome.desktop.interface color-scheme "
      "prefer-dark"
      ""
    ];
    xwayland.force_zero_scaling = true;
  };

  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
    config = {
      modifier = "Mod4";
      gaps = {
        inner = 10;
        outer = 5;
      };
    };
  };

}
