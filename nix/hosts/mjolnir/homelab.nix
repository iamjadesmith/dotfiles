{
  config,
  pkgs,
  lib,
  ...
}:

let
  domain = "joejad.com";
  ssl = {
    useACMEHost = domain;
    forceSSL = true;
  };

  vpnNamespace = "vpn";
  vpnNamespacePath = "/run/netns/${vpnNamespace}";
  vpnHostAddress = "10.200.0.1/30";
  vpnNamespaceAddress = "10.200.0.2/30";
  vpnNamespaceIp = "10.200.0.2";
  vpnWireGuardInterface = "wg-vpn";
  vpnPeerName = "wg";

  vpnPeerPublicKey = "4zxWLHGjsKHn0Pw88uHTo78SULgbVMHpyKMqJFEpCHg=";
  vpnAddress = "10.5.0.2/32";
  vpnEndpointPort = 51820;
  vpnRecommendationsUrl = "https://api.nordvpn.com/v1/servers/recommendations?limit=10&filters%5Bservers_technologies%5D%5Bidentifier%5D=wireguard_udp";

  vpnDnsServers = [
    "103.86.96.100"
    "103.86.99.100"
  ];
  vpnResolvConf = pkgs.writeText "vpn-resolv.conf" (
    lib.concatMapStrings (server: "nameserver ${server}\n") vpnDnsServers
  );
  vpnResolvBindMount = "${vpnResolvConf}:/etc/resolv.conf";
  vpnNamespaceDependencies = [
    "vpn-namespace.service"
    "wireguard-${vpnWireGuardInterface}.service"
    "wireguard-${vpnWireGuardInterface}-peer-${vpnPeerName}.service"
    "vpn-ready.service"
  ];
in
{
  services.nginx.virtualHosts = {
    "vault.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8000";
        proxyWebsockets = true;
      };
    };

    "uptime.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:3001";
    };

    "code.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://127.0.0.1:4096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_read_timeout 3600s;
        '';
      };
    };

    "rss.${domain}" = ssl;

    "jellyfin.${domain}" = ssl // {
      extraConfig = ''
        client_max_body_size 20M;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };

    "deluge.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://${vpnNamespaceIp}:${toString config.services.deluge.web.port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };

    "prowlarr.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://127.0.0.1:9696";
        proxyWebsockets = true;
      };
    };

    "radarr.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://[::1]:7878";
        proxyWebsockets = true;
      };
    };

    "sonarr.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://[::1]:8989";
        proxyWebsockets = true;
      };
    };

    "readarr.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://[::1]:8787";
        proxyWebsockets = true;
      };
    };

    "lidarr.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://[::1]:8686";
        proxyWebsockets = true;
      };
    };

    "seerr.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://[::1]:5055";
        proxyWebsockets = true;
      };
    };

    "search.${domain}" = ssl;

    "cloud.${domain}" = ssl;

    "immich.${domain}" = ssl // {
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

    "sync.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://[::1]:8384";
        proxyWebsockets = true;
      };
    };

    "study.${domain}" = ssl // {
      root = "/var/lib/study-html/current";
      locations."/" = {
        extraConfig = ''
          try_files $uri $uri/ =404;
          add_header Cache-Control "public, max-age=300";
          add_header X-Content-Type-Options "nosniff" always;
          add_header Referrer-Policy "no-referrer" always;
        '';
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/study-html 0755 jade nginx -"
  ];

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
    environmentFile = [ config.sops.secrets.vaultwarden_env.path ];
  };

  services.uptime-kuma.enable = true;

  systemd.services.opencode-web = {
    description = "OpenCode web interface";
    wantedBy = [ "multi-user.target" ];
    requires = [ "opencode-update.service" ];
    after = [ "opencode-update.service" ];
    environment = {
      HOME = "/home/jade";
      OPENCODE_SERVER_USERNAME = "opencode";
      PATH = lib.mkForce "/run/current-system/sw/bin";
      XDG_CACHE_HOME = "/home/jade/.cache";
      XDG_CONFIG_HOME = "/home/jade/.config";
      XDG_DATA_HOME = "/home/jade/.local/share";
      XDG_STATE_HOME = "/home/jade/.local/state";
    };
    script = ''
      export OPENCODE_SERVER_PASSWORD="$(< ${config.sops.secrets.opencode_server_password.path})"
      exec /home/jade/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096
    '';
    serviceConfig = {
      User = "jade";
      Group = "users";
      WorkingDirectory = "/home/jade";
      Restart = "on-failure";
      RestartSec = "5s";

      BindPaths = [
        "/home/jade/projects"
        "/home/jade/.dotfiles"
        "/home/jade/obsidian"
        "/home/jade/.cache/opencode"
        "/home/jade/.local/share/opencode"
        "/home/jade/.local/state/opencode"
      ];
      BindReadOnlyPaths = [
        "/home/jade/.config/git"
        "/home/jade/.config/opencode"
        "/home/jade/.opencode/bin"
      ];
      InaccessiblePaths = [
        "-/run/docker.sock"
        "-/var/run/docker.sock"
      ];

      CapabilityBoundingSet = "";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = "tmpfs";
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = false;
    authentication = lib.mkForce ''
      local all postgres peer map=postgres
      local wedding-preview wedding-preview peer
      local wedding_preview_restore_verify wedding-preview peer
      local all wedding-preview reject
      host all wedding-preview 127.0.0.1/32 reject
      host all wedding-preview ::1/128 reject
      local all all peer
    '';
    ensureDatabases = [
      "freshrss"
    ];
    ensureUsers = [
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
    ];
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [
      "budget"
      "food"
      "freshrss"
      "golf"
      "receipt"
      "workout"
      "nextcloud"
      "immich"
    ];
    location = "/var/lib/db_backups/postgres";
  };

  services.freshrss = {
    enable = true;
    virtualHost = "rss.joejad.com";
    database = {
      type = "pgsql";
      user = "freshrss";
      name = "freshrss";
      host = "/run/postgresql";
      tableprefix = "";
    };
    api.enable = true;
    baseUrl = "https://rss.joejad.com";
    passwordFile = config.sops.secrets.freshrss_pass.path;
  };

  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  services.jellyfin.enable = true;
  users.groups.media = { };
  users.users.jellyfin.extraGroups = [ "media" ];

  systemd.services.vpn-namespace = {
    description = "Shared VPN namespace";
    path = [
      pkgs.iproute2
      pkgs.procps
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip link del vpn0 2>/dev/null || true
      ip netns del ${vpnNamespace} 2>/dev/null || true

      ip netns add ${vpnNamespace}
      ip netns exec ${vpnNamespace} sysctl -qw net.ipv6.conf.all.disable_ipv6=1
      ip netns exec ${vpnNamespace} sysctl -qw net.ipv6.conf.default.disable_ipv6=1

      ip link add vpn0 type veth peer name vpn1
      ip link set vpn1 netns ${vpnNamespace}

      ip addr add ${vpnHostAddress} dev vpn0
      ip link set vpn0 up

      ip netns exec ${vpnNamespace} ip addr add ${vpnNamespaceAddress} dev vpn1
      ip netns exec ${vpnNamespace} ip link set lo up
      ip netns exec ${vpnNamespace} ip link set vpn1 up
    '';
    preStop = ''
      ip link del vpn0 2>/dev/null || true
      ip netns del ${vpnNamespace} 2>/dev/null || true
    '';
  };

  networking.wireguard.interfaces.${vpnWireGuardInterface} = {
    ips = [ vpnAddress ];
    privateKeyFile = config.sops.secrets.nordvpn_wireguard_private_key.path;
    interfaceNamespace = vpnNamespace;
    allowedIPsAsRoutes = false;
    preSetup = ''
      if ! wg pubkey < ${config.sops.secrets.nordvpn_wireguard_private_key.path} >/dev/null 2>&1; then
        echo "nordvpn_wireguard_private_key must contain only the raw base64 private key" >&2
        exit 1
      fi
    '';
    postSetup = ''
      ip netns exec ${vpnNamespace} ip -4 route replace default dev ${vpnWireGuardInterface}
    '';
    peers = [
      {
        name = vpnPeerName;
        publicKey = vpnPeerPublicKey;
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services."wireguard-${vpnWireGuardInterface}" = {
    after = [ "vpn-namespace.service" ];
    bindsTo = [ "vpn-namespace.service" ];
    requires = [ "vpn-namespace.service" ];
  };

  systemd.services.vpn-ready = {
    description = "Select a NordVPN endpoint and verify the VPN tunnel";
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "vpn-namespace.service"
      "wireguard-${vpnWireGuardInterface}.service"
      "wireguard-${vpnWireGuardInterface}-peer-${vpnPeerName}.service"
    ];
    bindsTo = [
      "vpn-namespace.service"
      "wireguard-${vpnWireGuardInterface}.service"
      "wireguard-${vpnWireGuardInterface}-peer-${vpnPeerName}.service"
    ];
    requires = [
      "vpn-namespace.service"
      "wireguard-${vpnWireGuardInterface}.service"
      "wireguard-${vpnWireGuardInterface}-peer-${vpnPeerName}.service"
    ];
    path = [
      pkgs.curl
      pkgs.gawk
      pkgs.iproute2
      pkgs.iputils
      pkgs.jq
      pkgs.wireguard-tools
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! nordvpnEndpoint=$(
        curl --fail --silent --show-error \
          --connect-timeout 10 \
          --max-time 30 \
          --retry 3 \
          --retry-all-errors \
          '${vpnRecommendationsUrl}' \
          | jq --exit-status --raw-output --arg publicKey '${vpnPeerPublicKey}' '
              [
                .[]
                | select(.status == "online")
                | . as $server
                | .technologies[]?
                | select(.identifier == "wireguard_udp" and .pivot.status == "online")
                | select(any(.metadata[]?; .name == "public_key" and .value == $publicKey))
                | $server.station
                | select(type == "string" and test("^[0-9]+(\\.[0-9]+){3}$"))
              ][0] // empty
            '
      ); then
        echo "failed to select an online NordVPN WireGuard endpoint" >&2
        exit 1
      fi

      ip netns exec ${vpnNamespace} wg set ${vpnWireGuardInterface} \
        peer '${vpnPeerPublicKey}' endpoint "$nordvpnEndpoint:${toString vpnEndpointPort}"

      for _ in {1..30}; do
        ip netns exec ${vpnNamespace} ping -c 1 -W 1 ${builtins.head vpnDnsServers} >/dev/null 2>&1 || true
        latestHandshake=$(
          ip netns exec ${vpnNamespace} wg show ${vpnWireGuardInterface} latest-handshakes \
            | awk -v publicKey='${vpnPeerPublicKey}' '$1 == publicKey { print $2 }'
        )
        now=$(date +%s)

        if [[ "$latestHandshake" =~ ^[0-9]+$ ]] && (( latestHandshake > 0 && now - latestHandshake <= 30 )); then
          echo "NordVPN tunnel established through $nordvpnEndpoint"
          exit 0
        fi

        sleep 1
      done

      echo "NordVPN endpoint $nordvpnEndpoint did not complete a WireGuard handshake" >&2
      exit 1
    '';
  };

  services.deluge = {
    enable = true;
    # Deluge 2.2.0 uses APIs removed by setuptools 82.
    package = pkgs.deluge-2_x.overrideAttrs (old: {
      propagatedBuildInputs = map (
        dependency:
        if (dependency.pname or "") == "setuptools" then pkgs.python3Packages.setuptools_80 else dependency
      ) old.propagatedBuildInputs;
    });
    web.enable = true;
  };

  users.users.deluge.extraGroups = [ "media" ];

  systemd.services.deluged = {
    after = vpnNamespaceDependencies;
    bindsTo = vpnNamespaceDependencies;
    requires = vpnNamespaceDependencies;
    serviceConfig = {
      NetworkNamespacePath = vpnNamespacePath;
      BindReadOnlyPaths = [ vpnResolvBindMount ];
    };
  };

  systemd.services.delugeweb = {
    after = vpnNamespaceDependencies;
    bindsTo = vpnNamespaceDependencies;
    requires = vpnNamespaceDependencies;
    serviceConfig = {
      NetworkNamespacePath = vpnNamespacePath;
      BindReadOnlyPaths = [ vpnResolvBindMount ];
      ExecStart = lib.mkForce ''
        ${config.services.deluge.package}/bin/deluge-web \
          --do-not-daemonize \
          --config ${config.services.deluge.dataDir}/.config/deluge \
          --port ${toString config.services.deluge.web.port} \
          --interface ${vpnNamespaceIp}
      '';
    };
  };

  services.prowlarr.enable = true;
  systemd.services.prowlarr = {
    wants = [
      "network-online.target"
      "podman-flaresolverr.service"
    ];
    after = [
      "network-online.target"
      "podman-flaresolverr.service"
    ];
    environment.DOTNET_SYSTEM_NET_DISABLEIPV6 = "1";
  };

  services.radarr.enable = true;
  users.users.radarr.extraGroups = [ "media" ];

  services.sonarr.enable = true;
  users.users.sonarr.extraGroups = [ "media" ];

  services.readarr.enable = true;
  users.users.readarr.extraGroups = [ "media" ];

  services.lidarr.enable = true;
  users.users.lidarr.extraGroups = [ "media" ];

  services.seerr.enable = true;

  services.searx = {
    enable = true;
    domain = "search.${domain}";
    environmentFile = config.sops.templates."searx.env".path;
    configureNginx = true;
    settings.server.secret_key = "$SEARX_SECRET_KEY";
    settings.search.formats = [
      "html"
      "json"
    ];
    uwsgiConfig = lib.mkForce {
      socket = "/run/searx/uwsgi.sock";
      chmod-socket = "660";
    };
  };

  virtualisation.oci-containers.containers = {
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = [ "127.0.0.1:8191:8191" ];
      autoStart = true;
      environment = {
        LOG_LEVEL = "info";
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud34;
    hostName = "cloud.joejad.com";
    https = true;
    database.createLocally = true;
    caching.redis = true;
    maxUploadSize = "16G";
    config = {
      dbtype = "pgsql";
      adminuser = "jade";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
    };
    settings = {
      trusted_domains = [ "cloud.joejad.com" ];
      overwriteprotocol = "https";
      maintenance_window_start = "1";
      default_phone_region = "US";
      mail_smtpmode = "sendmail";
      mail_sendmailmode = "pipe";
    };
    phpOptions = lib.mkForce {
      "opcache.interned_strings_buffer" = "64";
      memory_limit = "2048M";
      post_max_size = "16G";
      upload_max_filesize = "16G";
      output_buffering = "0";
      max_input_time = "3600";
      max_execution_time = "3600";
    };
  };

  services.redis.servers.nextcloud = {
    enable = true;
    port = 6379;
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

  services.cloudflared = {
    enable = true;
    tunnels = {
      "1d6ffc99-27ce-4866-98d5-a104e1ab5784" = {
        credentialsFile = config.sops.secrets.cloudflared_creds.path;
        default = "http_status:404";
      };
    };
  };

  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    environmentVariables.OLLAMA_KEEP_ALIVE = "30m";
    loadModels = [
      "llama3.1:8b"
      "llama3.2-vision"
      "qwen2.5-coder:7b"
    ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiPasswordFile = config.sops.secrets.syncthing_pass.path;
    settings.gui.user = "jade";
    guiAddress = "0.0.0.0:8384";
    user = "jade";
    group = "users";
    configDir = "/home/jade/.config/syncthing";
  };
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

}
