{
  config,
  pkgs,
  lib,
  ...
}:

let
  vpnNamespace = "vpn";
  vpnNamespacePath = "/run/netns/${vpnNamespace}";
  vpnHostAddress = "10.200.0.1/30";
  vpnNamespaceAddress = "10.200.0.2/30";
  vpnNamespaceIp = "10.200.0.2";
  vpnWireGuardInterface = "wg-vpn";
  vpnPeerName = "wg";

  vpnPeerPublicKey = "4zxWLHGjsKHn0Pw88uHTo78SULgbVMHpyKMqJFEpCHg=";
  vpnAddress = "10.5.0.2/32";

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
  ];
in
{
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
    environmentFile = [ config.sops.secrets.vaultwarden_env.path ];
  };

  services.nginx.virtualHosts."vault.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8000";
      proxyWebsockets = true;
    };
  };

  services.uptime-kuma.enable = true;

  services.nginx.virtualHosts."uptime.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3001";
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = false;
    authentication = lib.mkForce ''
      local all postgres peer map=postgres
      local all all peer
    '';
    ensureDatabases = [
      "budget"
      "food"
      "freshrss"
      "golf"
      "receipt"
      "workout"
    ];
    ensureUsers = [
      {
        name = "budget";
        ensureDBOwnership = true;
      }
      {
        name = "food";
        ensureDBOwnership = true;
      }
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
      {
        name = "golf";
        ensureDBOwnership = true;
      }
      {
        name = "receipt";
        ensureDBOwnership = true;
      }
      {
        name = "workout";
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

  services.nginx.virtualHosts."rss.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
  };

  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  services.jellyfin.enable = true;
  users.groups.media = { };
  users.users.jellyfin.extraGroups = [ "media" ];

  services.nginx.virtualHosts."jellyfin.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
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

  systemd.services.vpn-namespace = {
    description = "Shared VPN namespace";
    path = [ pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip link del vpn0 2>/dev/null || true
      ip netns del ${vpnNamespace} 2>/dev/null || true

      ip netns add ${vpnNamespace}
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
    preSetup = ''
      if ! wg pubkey < ${config.sops.secrets.nordvpn_wireguard_private_key.path} >/dev/null 2>&1; then
        echo "nordvpn_wireguard_private_key must contain only the raw base64 private key" >&2
        exit 1
      fi

      nordvpnEndpoint=$(< ${config.sops.secrets.nordvpn_wireguard_endpoint.path})
      case "$nordvpnEndpoint" in
        *:*) ;;
        *)
          echo "nordvpn_wireguard_endpoint must look like hostname:port or ip:port" >&2
          exit 1
          ;;
      esac
    '';
    postSetup = ''
      nordvpnEndpoint=$(< ${config.sops.secrets.nordvpn_wireguard_endpoint.path})
      nordvpnHost=''${nordvpnEndpoint%:*}
      nordvpnPort=''${nordvpnEndpoint##*:}

      case "$nordvpnPort" in
        ""|*[!0-9]*)
          echo "nordvpn_wireguard_endpoint must end with a numeric port" >&2
          exit 1
          ;;
      esac

      case "$nordvpnHost" in
        *[!0-9.]*)
          nordvpnHostIp=$(getent ahostsv4 "$nordvpnHost" | awk 'NR == 1 { print $1; exit }')
          if [ -z "$nordvpnHostIp" ]; then
            echo "failed to resolve NordVPN endpoint host: $nordvpnHost" >&2
            exit 1
          fi
          ;;
        *)
          nordvpnHostIp="$nordvpnHost"
          ;;
      esac

      ip netns exec ${vpnNamespace} wg set ${vpnWireGuardInterface} peer "${vpnPeerPublicKey}" endpoint "$nordvpnHostIp:$nordvpnPort"
    '';
    peers = [
      {
        name = vpnPeerName;
        publicKey = vpnPeerPublicKey;
        allowedIPs = [ "0.0.0.0/0" ];
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services."wireguard-${vpnWireGuardInterface}" = {
    after = [ "vpn-namespace.service" ];
    bindsTo = [ "vpn-namespace.service" ];
    requires = [ "vpn-namespace.service" ];
    path = [
      pkgs.gawk
      pkgs.getent
      pkgs.wireguard-tools
    ];
  };

  services.deluge = {
    enable = true;
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

  services.nginx.virtualHosts."deluge.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${vpnNamespaceIp}:${toString config.services.deluge.web.port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };

  services.prowlarr.enable = true;
  services.nginx.virtualHosts."prowlarr.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9696";
      proxyWebsockets = true;
    };
  };

  services.radarr.enable = true;
  users.users.radarr.extraGroups = [ "media" ];
  services.nginx.virtualHosts."radarr.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:7878";
      proxyWebsockets = true;
    };
  };

  services.sonarr.enable = true;
  users.users.sonarr.extraGroups = [ "media" ];
  services.nginx.virtualHosts."sonarr.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8989";
      proxyWebsockets = true;
    };
  };

  services.readarr.enable = true;
  users.users.readarr.extraGroups = [ "media" ];
  services.nginx.virtualHosts."readarr.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8787";
      proxyWebsockets = true;
    };
  };

  services.lidarr.enable = true;
  users.users.lidarr.extraGroups = [ "media" ];
  services.nginx.virtualHosts."lidarr.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8686";
      proxyWebsockets = true;
    };
  };

  services.seerr.enable = true;
  services.nginx.virtualHosts."seerr.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5055";
      proxyWebsockets = true;
    };
  };

  services.flaresolverr.enable = true;

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
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

  services.nginx.virtualHosts."cloud.joejad.com" = {
    forceSSL = true;
    useACMEHost = "joejad.com";
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

  services.nginx.virtualHosts."immich.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
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

  services.cloudflared = {
    enable = true;
    tunnels = {
      "1d6ffc99-27ce-4866-98d5-a104e1ab5784" = {
        credentialsFile = config.sops.secrets.cloudflared_creds.path;
        default = "http_status:404";
      };
    };
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [
      "llama3.1:8b"
      "llama3.2-vision"
    ];
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    guiPasswordFile = config.sops.secrets.syncthing_pass.path;
    settings.gui.user = "jade";
  };

  services.nginx.virtualHosts."sync.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8384";
      proxyWebsockets = true;
    };
  };

}
