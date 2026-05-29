{ config, pkgs, ... }:

{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    randomizedDelaySec = "1h";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  systemd.services.nixos-upgrade = {
    path = [ pkgs.git ];
    preStart = ''
      cd /etc/nixos/dotfiles
      git fetch origin main
      git reset --hard origin/main
    '';
  };

  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos/dotfiles/nix#${config.networking.hostName}";
    flags = [
      "-L"
      "--accept-flake-config"
    ];
    dates = "Sun *-*-* 02:30:00";
    randomizedDelaySec = "45min";
    allowReboot = true;
  };
}
