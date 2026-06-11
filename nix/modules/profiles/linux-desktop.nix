{
  lib,
  pkgs,
  ...
}:

{
  networking.networkmanager.enable = lib.mkDefault true;
  networking.firewall.enable = lib.mkDefault true;

  programs.hyprland.enable = true;

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
    alacritty
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
