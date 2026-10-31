{
  config,
  homeDirectory,
  meta,
  pkgs,
  ...
}:

{
  imports = [ ./home-server.nix ];

  xdg.configFile.wofi.source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/.dotfiles/.config/wofi";

  # Switches light/dark at sunrise and sunset. darkman also serves the
  # color-scheme portal setting that Ghostty follows; the script covers GTK apps.
  services.darkman = {
    enable = true;
    settings = {
      # Approximate location; only used to compute sunrise and sunset.
      lat = 41.9;
      lng = -87.6;
      usegeoclue = false;
    };
    scripts.gtk-theme = ''
      if [[ "$1" == "dark" ]]; then
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'"
      else
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
        ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
      fi
    '';
  };

  programs.firefox = import ./firefox.nix;
  programs.ghostty = import ./ghostty.nix { inherit meta pkgs; };

  wayland.windowManager.hyprland = import ./hyprland.nix { inherit config; };
}
