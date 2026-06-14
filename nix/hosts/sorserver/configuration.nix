{
  pkgs,
  config,
  ...
}:

let
  domain = "sorenson-fam.com";
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
      wireguard_private_key = { };
      wireguard_endpoint = { };
      nextcloud_admin_pass = { };
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

  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "module_blacklist=nouveau"
    "tpm_tis.interrupts=0"
  ];

  networking.networkmanager.dns = "systemd-resolved";
  networking.resolvconf.enable = true;
  networking.resolvconf.useLocalResolver = true;
  networking.search = [ "joejad.lan" ];
  networking.nameservers = [
    "127.0.0.1"
  ];

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

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.extraUpFlags = [ "--accept-dns=false" ];
  networking.firewall.checkReversePath = "loose";
  services = {
    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = [ "routable" ];
        script = ''
          ethtool -K enp5s0 rx-udp-gro-forwarding on rx-gro-list o
        '';
      };
    };
  };

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.10.10.8/32" ];
      privateKeyFile = config.sops.secrets.wireguard_private_key.path;
      postUp = ''
        wg set wg0 peer NfwRlI/IFxEfmK6VmtemBYEUpLJ0wF07wpmdz598jGs= endpoint "$(cat ${config.sops.secrets.wireguard_endpoint.path})"
      '';
      peers = [
        {
          publicKey = "NfwRlI/IFxEfmK6VmtemBYEUpLJ0wF07wpmdz598jGs=";
          allowedIPs = [
            "10.10.10.0/24"
            "10.3.0.0/24"
            "10.26.27.0/24"
          ];
          persistentKeepalive = 25;
        }
      ];
    };
  };

  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "0.0.0.0" ];
        access-control = [
          "127.0.0.1/32 allow"
          "192.168.86.0/24 allow"
        ];
        private-domain = [ "joejad.lan" ];
        domain-insecure = [ "joejad.lan" ];
        local-zone = "\"sorenson-fam.com.\" redirect";
        local-data = [
          "\"sorenson-fam.com. IN A 192.168.86.3\""
          "\"sorenson-fam.com. IN AAAA ::ffff:192.168.86.3\""
        ];
      };
      forward-zone = [
        {
          name = "joejad.lan.";
          forward-addr = [
            "10.10.10.1"
          ];
        }
        {
          name = ".";
          forward-tls-upstream = "yes";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "8.8.8.8@853#dns.google.com"
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
