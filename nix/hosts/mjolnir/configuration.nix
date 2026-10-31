{
  pkgs,
  config,
  ...
}:

let
  dotfilesPath = "/home/jade/.dotfiles";
  # Onboard NIC; matched by MAC so a PCIe change cannot rename it out of its config.
  lanMac = "30:c5:99:d1:ff:a9";
  ulaPrefix = "fd3a:3dab:51b8:50";
in
{
  imports = [
    ../../modules/profiles/gaming.nix
    ../../modules/profiles/linux-desktop.nix
    ./dictation.nix
    ./homelab.nix
    ./external.nix
    ./livesync.nix
    ./personal.nix
    ./scans.nix
  ];

  dotfiles.sops = {
    enable = true;
    secrets = {
      acme_cloudflare_env = { };
      freshrss_pass = {
        owner = "freshrss";
        group = "freshrss";
        mode = "0400";
      };
      nordvpn_wireguard_private_key = { };
      vaultwarden_env = { };
      cloudflared_creds = { };
      searx_secret_key = { };
      wedding_preview_form_signing_key = { };
      wedding_preview_admin_password_hash = { };
      wedding_preview_admin_session_key = { };
      wedding_preview_backup_authentication_key = {
        owner = "wedding-preview";
        group = "wedding-preview";
        mode = "0400";
      };
    };
  };

  sops.templates."searx.env" = {
    content = ''
      SEARX_SECRET_KEY=${config.sops.placeholder.searx_secret_key}
    '';
    owner = "searx";
    group = "searx";
    mode = "0400";
    restartUnits = [
      "searx-init.service"
      "uwsgi.service"
    ];
  };

  sops.templates."wedding-preview.env" = {
    content = ''
      WEDDING_ADMIN_USERNAME=jade
      WEDDING_ADMIN_PASSWORD_HASH='${config.sops.placeholder.wedding_preview_admin_password_hash}'
      WEDDING_FORM_SIGNING_KEY='${config.sops.placeholder.wedding_preview_form_signing_key}'
      WEDDING_ADMIN_SESSION_KEY='${config.sops.placeholder.wedding_preview_admin_session_key}'
    '';
    owner = "wedding-preview";
    group = "wedding-preview";
    mode = "0400";
    restartUnits = [ "wedding-preview.service" ];
  };

  systemd.services.wedding-preview.serviceConfig.InaccessiblePaths = [
    config.sops.secrets.wedding_preview_backup_authentication_key.path
  ];

  systemd.services.borgbackup-job-wedding-preview = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  dotfiles.jade = {
    enable = true;
    hashedPassword = "$6$sDfLSHBDw34Mi75P$VZSvinODReSBLOAzjMqdjnY9bftEs1AwOOzZioZ4Pco86hGOFE.UKzrmAopU4zS6w.5Env15XgB5Lds1DqRjc0";
    extraAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmO691Ujio3I1tNUGEnSnyhjl0vLCBNi3Q/u0P+UvEX joejad@joejadserver"
    ];
  };

  dotfiles.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  dotfiles.borg = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDQXSAmgoIWDeMwrjqNpuEuLE8NJ7oRYdER5V7dkQ4t borg@sorserver"
    ];
    jobs.mjolnir = {
      paths = [
        "/var/lib/nextcloud"
        "/var/lib/immich"
        "/var/lib/db_backups"
        "/var/local/vaultwarden/backup"
        "/var/lib/freshrss"
        "/var/lib/uptime-kuma"
        "/var/lib/jellyfin"
        "/var/lib/prowlarr"
        "/var/lib/radarr/.config/Radarr"
        "/var/lib/sonarr/.config/NzbDrone"
        "/var/lib/readarr"
        "/var/lib/lidarr/.config/Lidarr"
        "/var/lib/jellyseerr"
        "/var/lib/deluge"
        "/var/lib/couchdb"
        "/var/lib/livesync-cli"
        "/var/lib/private/meal-planner"
        "/var/lib/private/receipt-breakdown"
      ];
      repo = "borg@sorserver:/var/lib/borg/mjolnir";
      preHook = ''
        exec 9>/run/lock/livesync-cli.lock
        ${pkgs.util-linux}/bin/flock 9
        systemctl stop podman-livesync-cli.service couchdb.service
      '';
      postHook = ''
        systemctl start couchdb.service podman-livesync-cli.service
      '';
    };
    jobs.wedding-preview = {
      paths = [
        "/var/lib/db_backups/postgres/wedding-preview.sql.gz"
        "/var/lib/wedding-preview/backups"
        "/var/lib/wedding-preview/exports"
        "/var/lib/wedding-preview/releases"
      ];
      repo = "borg@sorserver:/var/lib/borg/mjolnir";
      startAt = "*-*-* 03:15:00";
      persistentTimer = true;
      keepWeekly = 7;
      preHook = ''
        ${pkgs.systemd}/bin/systemctl start postgresqlBackup-wedding-preview.service
      '';
    };
  };

  # Push monitors on uptime.joejad.com; see modules/dotfiles/kuma-push.nix.
  dotfiles.kumaPush = {
    units = [
      "borgbackup-job-mjolnir"
      "borgbackup-job-wedding-preview"
      "backup-vaultwarden"
      "vpn-watchdog"
    ];
    postgresDumps.enable = true;
  };

  # Static addresses on the server VLAN; OPNsense keeps the matching host entries.
  # RAs still provide the GUA and the IPv6 default route.
  dotfiles.server.networkd.enable = true;
  # The NordVPN tunnel lives in a network namespace, which the networkd backend
  # does not support.
  networking.wireguard.useNetworkd = false;
  systemd.network.networks."10-lan" = {
    matchConfig = {
      MACAddress = lanMac;
      Type = "ether";
    };
    address = [
      "10.3.0.2/24"
      "${ulaPrefix}::2/64"
    ];
    gateway = [ "10.3.0.1" ];
    # OPNsense's Unbound serves the joejad.com and joejad.lan records for the whole network.
    dns = [
      "10.3.0.1"
      "${ulaPrefix}::1"
    ];
    networkConfig.IPv6AcceptRA = true;
    ipv6AcceptRAConfig.UseDNS = false;
    linkConfig.RequiredForOnline = "routable";
  };
  networking.search = [
    "joejad.lan"
    "taildfe4ce.ts.net"
  ];

  # OPNsense never sees same-VLAN, Tailscale, or tunnel traffic to mjolnir, so
  # keep app ports behind nginx. SSH, Samba, Avahi, Ollama, and Tailscale open
  # their own ports through their modules.
  dotfiles.server.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.checkReversePath = "loose";

  systemd.services.borgbackup-job-mjolnir.serviceConfig.ReadWritePaths = [
    "/run/lock/livesync-cli.lock"
  ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--accept-dns=false"
      "--advertise-routes=10.3.0.0/24,10.10.10.0/24,10.26.27.0/24,10.0.25.0/24,10.10.3.0/24,fd3a:3dab:51b8::/48"
    ];
  };

  # Tailscale DNS stays off so local names never depend on tailscaled. A resolved
  # delegate sends only tailnet names to MagicDNS; tailscaled resets tailscale0's
  # per-link DNS on every reconfig, so per-link settings would not stick.
  services.resolved.dnsDelegates.tailnet.Delegate = {
    DNS = "100.100.100.100";
    Domains = "taildfe4ce.ts.net";
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/036cff31-c5f3-4834-a626-07184f27055b";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

  systemd.services.update-nix-inputs = {
    description = "Update Nix flake inputs";
    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.nix
      pkgs.openssh
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "jade";
      Environment = "HOME=/home/jade";
      WorkingDirectory = dotfilesPath;
      ExecStart = "${dotfilesPath}/scripts/update-nix-inputs";
    };
  };

  systemd.timers.update-nix-inputs = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sat *-*-* 23:30:00";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    bind
    cloudflared
    ethtool
    networkd-dispatcher
  ];

  system.stateVersion = "25.11";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
    ];
  };
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };

  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "joejadjavajim@icloud.com";
    certs = {
      "joejad.com" = {
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        environmentFile = config.sops.secrets.acme_cloudflare_env.path;
        group = "nginx";
        domain = "*.joejad.com";
        extraDomainNames = [ "joejad.com" ];
        dnsResolver = "1.1.1.1:53";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  systemd.services.nginx = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

}
