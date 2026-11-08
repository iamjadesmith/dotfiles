{
  config,
  homeDirectory,
  meta,
  pkgs,
  ...
}:

{
  imports = [ ./home-server.nix ];

  xdg.configFile.waybar.source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/.dotfiles/.config/waybar";
  xdg.configFile.fuzzel.source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/.dotfiles/.config/fuzzel";

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
    # Waybar and fuzzel import colors.css / colors.ini; point them at the palette
    # matching Ghostty's theme. The links are gitignored.
    scripts.bar-theme = ''
      if [[ "$1" == "dark" ]]; then
        palette=tokyonight-night
      else
        palette=catppuccin-latte
      fi
      ln -sfn "$palette.css" "${homeDirectory}/.dotfiles/.config/waybar/colors.css"
      ln -sfn "$palette.ini" "${homeDirectory}/.dotfiles/.config/fuzzel/colors.ini"
      ${pkgs.procps}/bin/pkill -SIGUSR2 -x waybar || true
    '';
  };

  # 96 * 1.5, matching the monitor scale in hyprland.lua. Hyprland loads this
  # with xrdb at startup so XWayland apps such as Steam scale to match.
  xresources.properties."Xft.dpi" = 144;

  programs.firefox = import ./firefox.nix;
  programs.ghostty = import ./ghostty.nix { inherit meta pkgs; };

  wayland.windowManager.hyprland = import ./hyprland.nix { inherit config; };
}
