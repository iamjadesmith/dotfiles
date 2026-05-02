{
  config,
  pkgs,
  lib,
  ...
}:

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
        name = "workout";
        ensureDBOwnership = true;
      }
    ];
  };

  # services.nextcloud = {
  #   enable = true;
  #   package = pkgs.nextcloud32;
  #   hostName = "cloud.sorenson-fam.com";
  #   https = true;
  #   database.createLocally = true;
  #   caching.redis = true;
  #   maxUploadSize = "16G";
  #   config = {
  #     dbtype = "pgsql";
  #     adminuser = "admin";
  #     adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
  #   };
  #   settings = {
  #     trusted_domains = [ "cloud.sorenson-fam.com" ];
  #     overwriteprotocol = "https";
  #     maintenance_window_start = "1";
  #     default_phone_region = "US";
  #     mail_smtpmode = "sendmail";
  #     mail_sendmailmode = "pipe";
  #   };
  #   phpOptions = lib.mkForce {
  #     "opcache.interned_strings_buffer" = "64";
  #     memory_limit = "2048M";
  #     post_max_size = "16G";
  #     upload_max_filesize = "16G";
  #     output_buffering = "0";
  #     max_input_time = "3600";
  #     max_execution_time = "3600";
  #   };
  # };

  # services.redis.servers.nextcloud = {
  #   enable = true;
  #   port = 6379;
  # };

  # services.nginx.virtualHosts."cloud.sorenson-fam.com" = {
  #   forceSSL = true;
  #   useACMEHost = "sorenson-fam.com";
  # };
  #
  # services.postgresqlBackup = {
  #   enable = true;
  #   databases = [ "nextcloud" ];
  #   location = "/var/lib/db_backups/nextcloud";
  # };

}
