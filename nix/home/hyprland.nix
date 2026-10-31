{ ... }:
{
  enable = true;
  settings = {
    # Super, not Alt: games use Alt, and Alt+Q here would close the game.
    "$mod" = "SUPER";
    bind = [
      "$mod, F, exec, firefox"
      "$mod, RETURN, exec, ghostty"
      "$mod+ALT, E, exit"
      "$mod, Q, killactive"
      "$mod, V, layoutmsg, togglesplit"
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"
      "$mod+SHIFT, H, movewindow, l"
      "$mod+SHIFT, L, movewindow, r"
      "$mod+SHIFT, K, movewindow, u"
      "$mod+SHIFT, J, movewindow, d"
      "$mod, Space, exec, wofi --show drun"
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
    # No connector name, so moving between HDMI and DisplayPort needs no change.
    monitor = [ ",3840x2160@239.99,0x0,1.5" ];
    # Variable refresh for fullscreen games only.
    misc.vrr = 2;
    exec-once = [ "ghostty" ];
    bindl = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ];
    xwayland.force_zero_scaling = true;
    cursor.no_hardware_cursors = true;
    env = [
      "MOZ_ENABLE_WAYLAND,1"
      "XDG_SESSION_TYPE,wayland"
      "GBM_BACKEND,nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME,nvidia"
      "NIXOS_OZONE_WL,1"
      # force_zero_scaling leaves XWayland apps unscaled, and Steam is one.
      "STEAM_FORCE_DESKTOPUI_SCALING,1.5"
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
