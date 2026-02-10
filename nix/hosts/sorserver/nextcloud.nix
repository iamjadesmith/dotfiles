{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "cloud.sorenson-fam.com";
    https = true;
    database.createLocally = true;
    caching.redis = true;
    maxUploadSize = "16G";
    config = {
      dbtype = "pgsql";
      # adminuser = "admin";
      # adminpassFile = "/run/secrets/nextcloud-admin-pass";
    };
    settings = {
      trusted_domains = [ "cloud.sorenson-fam.com" ];
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

  services.nginx.virtualHosts."cloud.sorenson-fam.com" = {
    forceSSL = true;
    useACMEHost = "sorenson-fam.com";
  };

  services.postgresqlBackup = {
    enable = true;
    databases = [ "nextcloud" ];
    location = "/var/lib/db_backups/nextcloud";
  };

}
