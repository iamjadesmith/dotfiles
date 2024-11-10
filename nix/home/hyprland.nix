{ ... }:
let
in
{
  enable = true;
  settings = {
    "$mod" = "ALT";
    bind =
      [
        "$mod, F, exec, firefox"
        "$mod, RETURN, exec, alacritty"
        "$mod+SUPER, E, exit"
        "$mod+SUPER, S, exec, systemctl suspend"
        "$mod+SUPER, R, exec, systemctl restart"
        "$mod+SUPER, Q, exec, shutdown now"
        "$mod, Q, killactive"
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
        "$mod, Space, exec, wofi --show drun"
        "$mod+SUPER, H, resizeactive, -10 -10"
        "$mod+SUPER, L, resizeactive, 10 -10"
        "$mod+SUPER, K, resizeactive, 10 -10"
        "$mod+SUPER, J, resizeactive, -10 -10"
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
      "DP-3,3840x2160@239.99,0x0,1.5"
      "Unknown-1,disable"
    ];
    exec = [
      ''gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"   # for GTK3 apps''
      ''gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"   # for GTK4 apps''
      ''gsettings set org.gnome.desktop.interface cursor-size 12''
    ];
    xwayland.force_zero_scaling = true;
    env = [
      "MOZ_ENABLE_WAYLAND,1"
    ];
  };
}
