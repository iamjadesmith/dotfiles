{
  config,
  pkgs,
  lib,
  meta,
  user,
  homeDirectory,
  ...
}:

{
  imports = [
    (import ./home.nix {
      inherit
        config
        pkgs
        lib
        meta
        user
        homeDirectory
        ;
      enableAlacritty = true;
      enableAlacrittyTheme = true;
      extraConfigFiles = {
        swaync = ".config/swaync";
        waybar = ".config/waybar";
        wofi = ".config/wofi";
      };
    })
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs.firefox = import ./firefox.nix;

  wayland.windowManager.hyprland = import ./hyprland.nix { inherit config; };
}
