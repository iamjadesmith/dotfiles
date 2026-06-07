{
  config,
  pkgs,
  ...
}:

let
  dotfilesRepo = "https://github.com/iamjadesmith/dotfiles.git";
  deploymentPath = "/etc/nixos/dotfiles";
in
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
    path = [
      pkgs.coreutils
      pkgs.git
      pkgs.openssh
    ];
    preStart = ''
      install -d /etc/nixos

      if [ ! -d ${deploymentPath}/.git ]; then
        git clone ${dotfilesRepo} ${deploymentPath}
      fi

      cd ${deploymentPath}
      git fetch origin main
      git reset --hard origin/main
    '';
  };

  system.autoUpgrade = {
    enable = true;
    flake = "${deploymentPath}/nix#${config.networking.hostName}";
    flags = [
      "-L"
      "--accept-flake-config"
    ];
    dates = "Sun *-*-* 02:30:00";
    randomizedDelaySec = "45min";
    allowReboot = true;
  };
}
