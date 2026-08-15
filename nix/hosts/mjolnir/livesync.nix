{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "joejad.com";
  ssl = {
    useACMEHost = domain;
    forceSSL = true;
  };

  couchdbPort = 5984;
  databaseName = "obsidian";
  databaseUser = "livesync";
  stateDir = "/var/lib/livesync-cli";
  databaseDir = "${stateDir}/database";
  vaultDir = "${stateDir}/vault";
  settingsFile = "${databaseDir}/.livesync/settings.json";
  lockFile = "/run/lock/livesync-cli.lock";

  # Stable ownership is required for the rootful Podman bind mounts.
  livesyncUid = 328;
  livesyncGid = 328;

  cliImage = "ghcr.io/vrtmrz/livesync-cli:1.0.5-cli@sha256:71739b64a34968c7c77ebf925f9074052938aed911113a211199c56fe3ab00b2";
  cliService = "${config.virtualisation.oci-containers.containers.livesync-cli.serviceName}.service";

  couchdbProxy = {
    proxyPass = "http://127.0.0.1:${toString couchdbPort}";
    extraConfig = ''
      proxy_buffering off;
      proxy_request_buffering off;
      proxy_read_timeout 3600s;
      proxy_send_timeout 3600s;
    '';
  };

  couchdbProvision = pkgs.writeShellApplication {
    name = "couchdb-livesync-provision";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      couchdb_url="http://127.0.0.1:${toString couchdbPort}"
      database_url="$couchdb_url/${databaseName}"
      user_url="$couchdb_url/_users/org.couchdb.user%3A${databaseUser}"

      admin_config="$RUNTIME_DIRECTORY/admin.curlrc"
      user_config="$RUNTIME_DIRECTORY/user.curlrc"
      user_document="$RUNTIME_DIRECTORY/user.json"
      updated_user_document="$RUNTIME_DIRECTORY/updated-user.json"
      security_document="$RUNTIME_DIRECTORY/security.json"

      cleanup() {
        rm -f \
          "$admin_config" \
          "$user_config" \
          "$user_document" \
          "$updated_user_document" \
          "$security_document"
      }
      trap cleanup EXIT

      printf 'user = "admin:%s"\n' "$(< ${config.sops.secrets.couchdb_livesync_admin_password.path})" > "$admin_config"
      printf 'user = "${databaseUser}:%s"\n' "$(< ${config.sops.secrets.couchdb_livesync_user_password.path})" > "$user_config"
      chmod 600 "$admin_config" "$user_config"

      curl_admin=(curl --silent --show-error --config "$admin_config")
      curl_user=(curl --silent --show-error --config "$user_config")

      ready=false
      for _ in {1..60}; do
        if "''${curl_admin[@]}" --fail --output /dev/null "$couchdb_url/_up"; then
          ready=true
          break
        fi
        sleep 1
      done
      if [[ "$ready" != true ]]; then
        echo "CouchDB did not become ready" >&2
        exit 1
      fi

      database_status="$(
        "''${curl_admin[@]}" \
          --output /dev/null \
          --write-out '%{http_code}' \
          --request PUT \
          "$database_url"
      )"
      case "$database_status" in
        201|202|412) ;;
        *)
          echo "Creating CouchDB database failed with HTTP $database_status" >&2
          exit 1
          ;;
      esac

      if ! "''${curl_user[@]}" --fail --output /dev/null "$database_url"; then
        user_status="$(
          "''${curl_admin[@]}" \
            --output "$user_document" \
            --write-out '%{http_code}' \
            "$user_url"
        )"
        case "$user_status" in
          200)
            revision="$(jq --raw-output '._rev' "$user_document")"
            ;;
          404)
            revision=""
            ;;
          *)
            echo "Reading CouchDB user failed with HTTP $user_status" >&2
            exit 1
            ;;
        esac

        jq \
          --null-input \
          --arg name "${databaseUser}" \
          --arg revision "$revision" \
          --rawfile password ${config.sops.secrets.couchdb_livesync_user_password.path} \
          '{
            name: $name,
            password: ($password | rtrimstr("\n")),
            roles: [],
            type: "user"
          } + if $revision == "" then {} else { _rev: $revision } end' \
          > "$updated_user_document"

        user_update_status="$(
          "''${curl_admin[@]}" \
            --header 'Content-Type: application/json' \
            --data-binary "@$updated_user_document" \
            --output /dev/null \
            --write-out '%{http_code}' \
            --request PUT \
            "$user_url"
        )"
        case "$user_update_status" in
          201|202) ;;
          *)
            echo "Creating or updating CouchDB user failed with HTTP $user_update_status" >&2
            exit 1
            ;;
        esac
      fi

      jq \
        --null-input \
        --arg user "${databaseUser}" \
        '{
          admins: { names: [$user], roles: [] },
          members: { names: [$user], roles: [] }
        }' \
        > "$security_document"

      security_status="$(
        "''${curl_admin[@]}" \
          --header 'Content-Type: application/json' \
          --data-binary "@$security_document" \
          --output /dev/null \
          --write-out '%{http_code}' \
          --request PUT \
          "$database_url/_security"
      )"
      case "$security_status" in
        200|201|202) ;;
        *)
          echo "Applying CouchDB database security failed with HTTP $security_status" >&2
          exit 1
          ;;
      esac
    '';
  };

  settingsConfigured = pkgs.writeShellScript "livesync-cli-settings-configured" ''
    exec ${pkgs.jq}/bin/jq --exit-status '.isConfigured == true' ${lib.escapeShellArg settingsFile} > /dev/null
  '';

  couchdbReset = pkgs.writeShellApplication {
    name = "livesync-couchdb-reset";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      if (( EUID != 0 )); then
        echo "Run this helper with sudo." >&2
        exit 1
      fi

      if [[ "$#" -ne 1 || "$1" != "--confirm-delete-${databaseName}" ]]; then
        echo "This permanently deletes the ${databaseName} CouchDB database." >&2
        echo "Re-run with --confirm-delete-${databaseName} only when an existing vault is authoritative." >&2
        exit 2
      fi

      exec 9>${lockFile}
      flock 9
      systemctl stop ${cliService}

      install -d -m 0750 -o livesync -g livesync ${stateDir}
      quarantine_dir="$(mktemp --directory --tmpdir=${stateDir} reset-backup.XXXXXXXXXX)"
      chown livesync:livesync "$quarantine_dir"
      chmod 0700 "$quarantine_dir"

      if [[ -d ${databaseDir} ]]; then
        mv ${databaseDir} "$quarantine_dir/database"
      fi
      if [[ -d ${vaultDir} ]]; then
        mv ${vaultDir} "$quarantine_dir/vault"
      fi
      install -d -m 0700 -o livesync -g livesync ${databaseDir}
      install -d -m 2770 -o livesync -g livesync ${vaultDir}

      admin_config="$(mktemp)"
      cleanup() {
        rm -f "$admin_config"
      }
      trap cleanup EXIT

      printf 'user = "admin:%s"\n' "$(< ${config.sops.secrets.couchdb_livesync_admin_password.path})" > "$admin_config"
      chmod 600 "$admin_config"

      couchdb_url="http://127.0.0.1:${toString couchdbPort}"
      database_url="$couchdb_url/${databaseName}"
      delete_status="$(
        curl \
          --silent \
          --show-error \
          --config "$admin_config" \
          --output /dev/null \
          --write-out '%{http_code}' \
          --request DELETE \
          "$database_url"
      )"
      case "$delete_status" in
        200|202|404) ;;
        *)
          echo "Deleting CouchDB database failed with HTTP $delete_status" >&2
          exit 1
          ;;
      esac

      systemctl restart couchdb-livesync-provision.service

      curl \
        --silent \
        --show-error \
        --fail \
        --config "$admin_config" \
        "$database_url" \
        | jq --exit-status '.doc_count == 0' > /dev/null

      echo "Reset and re-provisioned the empty ${databaseName} database."
      echo "Previous CLI state was quarantined at $quarantine_dir."
    '';
  };

  livesyncCli = pkgs.writeShellApplication {
    name = "livesync-cli";
    runtimeInputs = [
      pkgs.podman
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      if (( EUID != 0 )); then
        echo "Run this helper with sudo so it can use the system Podman store." >&2
        exit 1
      fi

      exec 9>${lockFile}
      flock 9

      if systemctl is-active --quiet ${cliService}; then
        echo "Stop ${cliService} before running one-off CLI commands." >&2
        exit 1
      fi

      tty_args=()
      if [[ -t 0 && -t 1 ]]; then
        tty_args+=(--tty)
      fi

      exec podman run \
        --rm \
        --interactive \
        "''${tty_args[@]}" \
        --pull=missing \
        --network=host \
        --user=${toString livesyncUid}:${toString livesyncGid} \
        --env=HOME=/data \
        --read-only \
        --tmpfs=/tmp:rw,nosuid,nodev,noexec,size=64m \
        --security-opt=no-new-privileges \
        --cap-drop=ALL \
        --pids-limit=512 \
        --umask=0002 \
        --volume=${databaseDir}:/data \
        --volume=${vaultDir}:/vault \
        ${lib.escapeShellArg cliImage} "$@"
    '';
  };
in
{
  sops.secrets = {
    couchdb_livesync_admin_password = {
      sopsFile = ../../secrets/mjolnir/livesync.yaml;
      owner = "couchdb";
      group = "couchdb";
      mode = "0400";
      restartUnits = [
        "couchdb.service"
        "couchdb-livesync-provision.service"
      ];
    };
    couchdb_livesync_user_password = {
      sopsFile = ../../secrets/mjolnir/livesync.yaml;
      owner = "couchdb";
      group = "couchdb";
      mode = "0400";
      restartUnits = [ "couchdb-livesync-provision.service" ];
    };
  };
  sops.templates."couchdb-livesync-admin.ini" = {
    content = ''
      [admins]
      admin = ${config.sops.placeholder.couchdb_livesync_admin_password}
    '';
    owner = "couchdb";
    group = "couchdb";
    mode = "0400";
  };

  services.couchdb = {
    enable = true;
    package = pkgs.couchdb3;
    bindAddress = "127.0.0.1";
    port = couchdbPort;
    configFile = "/run/couchdb/local.ini";
    extraConfigFiles = [ config.sops.templates."couchdb-livesync-admin.ini".path ];
    extraConfig = {
      couchdb = {
        single_node = "true";
        max_document_size = "50000000";
        uuid = "f9b8bde39c1a4d529eab4d57c14eada5";
      };
      chttpd = {
        require_valid_user = "true";
        enable_cors = "true";
        max_http_request_size = "4294967296";
      };
      chttpd_auth.require_valid_user = "true";
      httpd = {
        "WWW-Authenticate" = ''Basic realm="couchdb"'';
        enable_cors = "true";
      };
      cors = {
        credentials = "true";
        origins = "app://obsidian.md,capacitor://localhost,http://localhost";
      };
    };
  };

  systemd.services.couchdb.preStart = lib.mkBefore ''
    : > ${config.services.couchdb.configFile}
  '';

  systemd.services.couchdb.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    UMask = "0077";

    CapabilityBoundingSet = "";
    LockPersonality = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectSystem = "strict";
    ReadWritePaths = [
      "/run/couchdb"
      "/var/lib/couchdb"
      "/var/log/couchdb.log"
    ];
    RestrictAddressFamilies = [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
  };

  systemd.services.couchdb-livesync-provision = {
    description = "Provision the Self-hosted LiveSync CouchDB database";
    wantedBy = [ "multi-user.target" ];
    requires = [ "couchdb.service" ];
    after = [ "couchdb.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "couchdb";
      Group = "couchdb";
      RuntimeDirectory = "couchdb-livesync-provision";
      RuntimeDirectoryMode = "0700";
      ExecStart = "${couchdbProvision}/bin/couchdb-livesync-provision";
      UMask = "0077";

      CapabilityBoundingSet = "";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
    };
  };

  services.nginx.virtualHosts."livesync.${domain}" = ssl // {
    extraConfig = ''
      client_max_body_size 64M;
    '';
    locations = {
      "= /" = couchdbProxy;
      "= /_session" = couchdbProxy;
      "= /_up" = couchdbProxy;
      "= /_uuids" = couchdbProxy;
      "= /${databaseName}" = couchdbProxy;
      "^~ /${databaseName}/" = couchdbProxy;
      "/".return = "404";
    };
  };

  users.groups.livesync.gid = livesyncGid;
  users.users = {
    jade.extraGroups = [ "livesync" ];
    livesync = {
      description = "Self-hosted LiveSync CLI";
      isSystemUser = true;
      uid = livesyncUid;
      group = "livesync";
      home = stateDir;
    };
  };

  systemd.tmpfiles.rules = lib.mkAfter [
    "d ${stateDir} 0750 livesync livesync - -"
    "d ${databaseDir} 0700 livesync livesync - -"
    "d ${vaultDir} 2770 livesync livesync - -"
    "f ${lockFile} 0600 root root - -"
    "z /var/log/couchdb.log 0640 couchdb couchdb - -"
  ];

  virtualisation.oci-containers.containers.livesync-cli = {
    image = cliImage;
    pull = "missing";
    autoStart = true;
    user = "${toString livesyncUid}:${toString livesyncGid}";
    environment.HOME = "/data";
    volumes = [
      "${databaseDir}:/data"
      "${vaultDir}:/vault"
    ];
    networks = [ "host" ];
    cmd = [
      "--vault"
      "/vault"
      "daemon"
    ];
    capabilities.ALL = false;
    extraOptions = [
      "--read-only"
      "--tmpfs=/tmp:rw,nosuid,nodev,noexec,size=64m"
      "--security-opt=no-new-privileges"
      "--pids-limit=512"
      "--umask=0002"
    ];
  };

  systemd.services.${config.virtualisation.oci-containers.containers.livesync-cli.serviceName} = {
    requires = [
      "couchdb.service"
      "couchdb-livesync-provision.service"
      "nginx.service"
    ];
    after = [
      "couchdb.service"
      "couchdb-livesync-provision.service"
      "nginx.service"
    ];
    unitConfig.ConditionPathExists = settingsFile;
    serviceConfig = {
      LimitNOFILE = 65536;
      ExecCondition = settingsConfigured;
      RestartSec = "10s";
      TimeoutStartSec = lib.mkForce "300s";
    };
  };

  environment.systemPackages = [
    couchdbReset
    livesyncCli
  ];
}
