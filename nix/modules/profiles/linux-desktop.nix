{ pkgs, ... }:

{
  # Started from the TTY with `Hyprland`, so nothing here runs until you log in.
  programs.hyprland.enable = true;

  # darkman (Home Manager) provides the light/dark color-scheme setting to apps.
  xdg.portal = {
    extraPortals = [ pkgs.darkman ];
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
    };
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  environment.systemPackages = [ pkgs.wofi ];
}
