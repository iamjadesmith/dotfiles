{
  lib,
  pkgs,
  meta,
  modulesPath,
  ...
}:

let
  lanInterface = "ens18";
  ulaPrefix = "fd3a:3dab:51b8:50";
in

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
  ];

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";
  networking.firewall.checkReversePath = "loose";

  # Static addresses on the server VLAN; OPNsense keeps the matching host entries.
  # RAs still provide the GUA and the IPv6 default route.
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = lanInterface;
    address = [
      "10.3.0.3/24"
      "${ulaPrefix}::3/64"
    ];
    gateway = [ "10.3.0.1" ];
    dns = [
      "10.3.0.1"
      "${ulaPrefix}::1"
    ];
    domains = [ "joejad.lan" ];
    networkConfig.IPv6AcceptRA = true;
    ipv6AcceptRAConfig.UseDNS = false;
    linkConfig.RequiredForOnline = "routable";
  };
  services.resolved = {
    enable = true;
    # Avahi already handles mDNS.
    settings.Resolve = {
      LLMNR = false;
      MulticastDNS = false;
    };
  };

  # Tailscale's recommended UDP GRO settings for subnet routers and exit nodes.
  systemd.services.tailscale-udp-gro = {
    description = "Tune UDP GRO on ${lanInterface} for Tailscale";
    wantedBy = [ "sys-subsystem-net-devices-${lanInterface}.device" ];
    bindsTo = [ "sys-subsystem-net-devices-${lanInterface}.device" ];
    after = [ "sys-subsystem-net-devices-${lanInterface}.device" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K "${lanInterface}" rx-udp-gro-forwarding on rx-gro-list off
    '';
  };
  system.stateVersion = "23.11";
}
