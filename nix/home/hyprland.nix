{ ... }:
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
    exec-once = [
      ''obsidian''
      ''firefox''
      ''alacritty''
    ];
    # exec = [
    #   ''gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"''
    #   ''gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"''
    # ];
    bindl = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ];
    windowrulev2 = [
      ''workspace 1, class:^(Alacritty)$''
      ''workspace 2, class:^(firefox)$''
      ''workspace 3, class:^(obsidian)$''
    ];
    xwayland.force_zero_scaling = true;
    cursor.no_hardware_cursors = true;
    env = [
      "MOZ_ENABLE_WAYLAND,1"
      "LIBVA_DRIVER_NAME,nvidia"
      "XDG_SESSION_TYPE,wayland"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "NIXOS_OZONE_WL,1"
    ];
  };
  extraConfig = ''
          device {
            name=logitech-g502-1
            sensitivity=-1.0
          }
          device {
            name=logitech-g502
            sensitivity=-1.0
          }
    		'';
}
