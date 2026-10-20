{
  lib,
  pkgs,
  ...
}:

{
  networking.networkmanager.enable = lib.mkDefault true;
  networking.firewall.enable = lib.mkDefault true;

  programs.hyprland.enable = true;

  # darkman uses GeoClue for sunrise and sunset times instead of fixed coordinates.
  services.geoclue2 = {
    enable = true;
    appConfig.darkman = {
      isAllowed = true;
      isSystem = false;
    };
  };

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

  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    openmoji-color
  ];

  environment.systemPackages = with pkgs; [
    ansible
    apacheHttpd
    bitwarden-cli
    bitwarden-desktop
    black
    cmake
    discord
    ente-auth
    fastfetch
    luajit
    nextcloud-client
    obsidian
    openssl
    rose-pine-cursor
    swaynotificationcenter
    thunderbird
    unzip
    waybar
    wget
    wl-clipboard
    wofi
    yubikey-manager
    zulu
  ];
}
