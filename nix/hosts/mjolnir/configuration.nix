{
  pkgs,
  config,
  ...
}:

let
  dotfilesPath = "/home/jade/.dotfiles";
  lanInterface = "enp132s0";
  ulaSitePrefix = "fd3a:3dab:51b8";
  ulaPrefix = "${ulaSitePrefix}:50";
  staticUlaIp = "${ulaPrefix}::2";
  staticUlaAddress = "${staticUlaIp}/64";
  opnsenseUlaIp = "${ulaPrefix}::1";
  addStaticUla = ''
    ${pkgs.iproute2}/bin/ip -6 addr replace "${staticUlaAddress}" dev "${lanInterface}"
  '';
  staticUlaDispatcher = pkgs.writeShellScript "mjolnir-static-ula" ''
    if [[ "$1" != "${lanInterface}" ]]; then
      exit 0
    fi

    case "$2" in
      up|dhcp6-change)
        ${addStaticUla}
        ;;
    esac
  '';
in
{
  imports = [
    ./homelab.nix
    ./external.nix
    ./personal.nix
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
      nordvpn_wireguard_endpoint = { };
      unbound_gua_prefix = { };
      unbound_mjolnir_gua = { };
      unbound_opnsense_gua = { };
      vaultwarden_env = { };
      nextcloud_admin_pass = { };
      cloudflared_creds = { };
      syncthing_pass = { };
      opencode_server_password = {
        owner = "jade";
        group = "users";
        mode = "0400";
        restartUnits = [ "opencode-web.service" ];
      };
    };
  };

  sops.templates."unbound-private.conf" = {
    content = ''
      server:
        access-control: ${config.sops.placeholder.unbound_gua_prefix} allow
        local-data: "joejad.com. IN AAAA ${config.sops.placeholder.unbound_mjolnir_gua}"

      forward-zone:
        name: "joejad.lan."
        forward-addr: 10.3.0.1
        forward-addr: ${opnsenseUlaIp}
        forward-addr: ${config.sops.placeholder.unbound_opnsense_gua}
    '';
    owner = "unbound";
    group = "unbound";
    mode = "0400";
    restartUnits = [ "unbound.service" ];
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
        "/home/jade/.config/syncthing"
        "/var/lib/jellyfin"
        "/var/lib/prowlarr"
        "/var/lib/radarr/.config/Radarr"
        "/var/lib/sonarr/.config/NzbDrone"
        "/var/lib/readarr"
        "/var/lib/lidarr/.config/Lidarr"
        "/var/lib/jellyseerr"
        "/var/lib/deluge"
      ];
      repo = "borg@sorserver:/var/lib/borg/mjolnir";
    };
  };

  networking.networkmanager.unmanaged = [
    "interface-name:vpn0"
    "interface-name:vpn1"
  ];
  networking.search = [ "joejad.lan" ];
  networking.nameservers = [ "127.0.0.1" ];
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager.dispatcherScripts = [
    {
      source = staticUlaDispatcher;
      type = "basic";
    }
  ];

  systemd.services.static-ula-address = {
    description = "Add static ULA address to ${lanInterface}";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig.Type = "oneshot";
    script = addStaticUla;
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--accept-dns=false"
      "--advertise-routes=10.3.0.1/32,10.3.0.2/32"
    ];
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

  services.unbound = {
    enable = true;
    checkconf = false;
    settings = {
      include-toplevel = "\"${config.sops.templates."unbound-private.conf".path}\"";
      server = {
        interface = [
          "0.0.0.0"
          "::0"
        ];
        do-ip6 = true;
        access-control = [
          "127.0.0.1/32 allow"
          "::1/128 allow"
          "${ulaSitePrefix}::/48 allow"
          "10.3.0.0/24 allow"
          "10.10.10.0/24 allow"
          "10.26.27.0/24 allow"
          "10.47.59.0/24 allow"
          "100.64.0.0/10 allow"
        ];
        private-domain = [ "joejad.lan" ];
        domain-insecure = [ "joejad.lan" ];
        local-zone = "\"joejad.com.\" redirect";
        local-data = [
          "\"joejad.com. IN A 10.3.0.2\""
          "\"joejad.com. IN AAAA ${staticUlaIp}\""
        ];
        module-config = "'respip validator iterator'";
      };
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = "yes";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "2606:4700:4700::1111@853#cloudflare-dns.com"
            "8.8.8.8@853#dns.google.com"
            "2001:4860:4860::8888@853#dns.google.com"
          ];
        }
      ];
      rpz = [
        {
          name = "hageziPro";
          url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt";
        }
      ];
    };
  };

  systemd.services.unbound.preStart = ''
    ${config.services.unbound.package}/bin/unbound-checkconf /etc/unbound/unbound.conf
  '';

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

}
