{
  pkgs,
  config,
  lib,
  ...
}:

let
  domain = "sorenson-fam.com";
  lanInterface = "enp5s0";
  ulaSitePrefix = "fd6e:61d0:82c";
  staticUlaIp = "${ulaSitePrefix}:3d10::3";
  staticUlaAddress = "${staticUlaIp}/64";
  addStaticUla = ''
    ${pkgs.iproute2}/bin/ip -6 addr replace "${staticUlaAddress}" dev "${lanInterface}"
  '';
  staticUlaDispatcher = pkgs.writeShellScript "sorserver-static-ula" ''
    if [[ "$1" != "${lanInterface}" ]]; then
      exit 0
    fi

    case "$2" in
      up|dhcp6-change)
        ${addStaticUla}
        ;;
    esac
  '';
  ssl = {
    useACMEHost = domain;
    forceSSL = true;
  };
in
{
  imports = [
    ./nextcloud.nix
  ];

  dotfiles.sops = {
    enable = true;
    secrets = {
      nextcloud_admin_pass = { };
      cloudflared_token = {
        mode = "0400";
        restartUnits = [ "docker-cloudflared.service" ];
      };
    };
  };

  dotfiles.jade = {
    enable = true;
    hashedPassword = "$6$lGy6iRAdcwvnkJ2X$GPvLqm5DGX/HBD9iZ.Z.UOcxkU5k3lYc/Izw8vnPWC0X.tpE4087.U1V4AGjXduJHjFu76fKXJe3pK9YgmNue1";
    extraAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmO691Ujio3I1tNUGEnSnyhjl0vLCBNi3Q/u0P+UvEX joejad@joejadserver"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZ5aNpSeVxB5GzWYHlsR0zPCvQzVJIC48ViFxJSmsJ+ jade@mjolnir"
    ];
  };

  dotfiles.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.cloudflared = {
      image = "cloudflare/cloudflared:latest";
      autoStart = true;
      user = "0:0";
      volumes = [
        "${config.sops.secrets.cloudflared_token.path}:/run/secrets/cloudflared_token:ro"
      ];
      cmd = [
        "tunnel"
        "run"
        "--token-file"
        "/run/secrets/cloudflared_token"
      ];
      capabilities.ALL = false;
      extraOptions = [
        "--security-opt=no-new-privileges"
      ];
    };

    containers.scrypted = {
      image = "ghcr.io/koush/scrypted@sha256:294be875371dc4f2897174120ce707c43bde8d18e41545077c4c6c88911af990";
      autoStart = true;
      volumes = [
        "/var/lib/scrypted:/server/volume"
      ];
      devices = [ "/dev/dri:/dev/dri" ];
      environment.SCRYPTED_DOCKER_AVAHI = "true";
      log-driver = "none";
      extraOptions = [
        "--network=host"
        "--dns=1.1.1.1"
        "--dns=8.8.8.8"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/scrypted 0750 root root -"
  ];

  # Scrypted's internal Avahi must own port 5353 for HomeKit discovery.
  services.avahi.enable = lib.mkForce false;

  dotfiles.borg = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVsEFRjD6qbbvmt6ZuLHmrKOXCPe/2odzOA08TZA+y1 borg@mjolnir"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzV9hRmrCdQvofmglcIftsYllcHAHJ//nhhY3Zc2T4/ borg@joejadserver"
    ];
    jobs.sorserver = {
      paths = [
        "/var/lib/nextcloud"
        "/var/lib/db_backups"
        "/var/lib/immich"
        "/var/lib/scrypted"
      ];
      repo = "borg@mjolnir:/var/lib/borg/sorserver";
    };
  };

  services.nginx.virtualHosts."immich.${domain}" = ssl // {
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };

  services.nginx.virtualHosts."scrypted.${domain}" = ssl // {
    locations."/" = {
      proxyPass = "https://127.0.0.1:10443";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };

  boot.kernelParams = [
    "module_blacklist=nouveau"
    "tpm_tis.interrupts=0"
    "reboot=pci"
  ];

  system.autoUpgrade.allowReboot = false;

  hardware.enableRedistributableFirmware = true;

  networking.search = [ "joejad.lan" ];
  networking.nameservers = [ "127.0.0.1" ];
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

  environment.systemPackages = with pkgs; [
    ethtool
    networkd-dispatcher
  ];

  system.stateVersion = "23.11";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraSetFlags = [
      "--accept-dns=false"
      "--accept-routes=true"
    ];
  };
  networking.firewall.checkReversePath = "loose";
  services = {
    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = [ "routable" ];
        script = ''
          ethtool -K enp5s0 rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
  };

  services.unbound = {
    enable = true;
    settings = {
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
          "fd7a:115c:a1e0::/48 allow"
          "192.168.86.0/24 allow"
          "100.64.0.0/10 allow"
        ];
        private-domain = [ "joejad.lan" ];
        domain-insecure = [ "joejad.lan" ];
        local-zone = "\"sorenson-fam.com.\" redirect";
        local-data = [
          "\"sorenson-fam.com. IN A 192.168.86.3\""
          "\"sorenson-fam.com. IN AAAA ${staticUlaIp}\""
        ];
      };
      forward-zone = [
        {
          name = "joejad.lan.";
          forward-addr = [
            "100.75.221.122"
          ];
        }
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
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "joejadjavajim@icloud.com";
    certs = {
      "sorenson-fam.com" = {
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        environmentFile = "/var/lib/acme/.secrets/cert.env";
        group = "nginx";
        domain = "*.sorenson-fam.com";
        extraDomainNames = [ "sorenson-fam.com" ];
      };
    };
  };

  services.immich = {
    enable = true;
    port = 2283;
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

}
