{
  config,
  pkgs,
  lib,
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
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "cloud.${domain}";
    https = true;
    database.createLocally = true;
    caching.redis = true;
    maxUploadSize = "16G";
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = config.sops.secrets.nextcloud_admin_pass.path;
    };
    settings = {
      trusted_domains = [ "cloud.${domain}" ];
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

  services.nginx.virtualHosts."cloud.${domain}" = ssl;

  services.postgresqlBackup = {
    enable = true;
    databases = [
      "nextcloud"
      "immich"
    ];
    location = "/var/lib/db_backups/nextcloud";
  };

}
