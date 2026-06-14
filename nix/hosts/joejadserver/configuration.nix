{
  lib,
  pkgs,
  meta,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./services.nix
  ];

  dotfiles.sops = {
    enable = true;
    secrets = {
      forgejo-mailer-password = {
        owner = "forgejo";
        mode = "0400";
      };
      forgejo-mailer-user = {
        owner = "forgejo";
        mode = "0400";
      };
      forgejo-mailer-from = {
        owner = "forgejo";
        mode = "0400";
      };
    };
  };

  dotfiles.jade = {
    enable = true;
    hashedPassword = "$y$j9T$zCosUIu8eNq21sMsgQ7ya.$0oQ.aynDLokO77HvIjV.EEMDrnI25n8VQJgEd3RlSx8";
    extraAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZ5aNpSeVxB5GzWYHlsR0zPCvQzVJIC48ViFxJSmsJ+ jade@mjolnir"
    ];
  };

  dotfiles.docker.enable = true;

  dotfiles.borg = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDQXSAmgoIWDeMwrjqNpuEuLE8NJ7oRYdER5V7dkQ4t borg@sorserver"
    ];
    jobs.joejadserver = {
      paths = [
        "/var/lib/forgejo"
        "/var/lib/minecraft"
        "/var/lib/db_backups"
      ];
      repo = "borg@sorserver:/var/lib/borg/joejadserver";
      preHook = ''
        systemctl stop podman-minecraft.service
      '';
      postHook = ''
        systemctl start podman-minecraft.service
      '';
    };
  };

  services.qemuGuest.enable = lib.mkDefault true;

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/minecraft 0755 root root - -"
    "d /var/local/vaultwarden/backup 0750 vaultwarden vaultwarden - -"
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  };

  environment.systemPackages = with pkgs; [
    bind
    ethtool
    networkd-dispatcher
  ];

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";
  networking.firewall.checkReversePath = "loose";
  services = {
    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = [ "routable" ];
        script = ''
          ethtool -K ens18 rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
  };

  system.stateVersion = "23.11";
}
