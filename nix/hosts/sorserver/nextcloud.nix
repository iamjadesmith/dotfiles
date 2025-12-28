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
    maxUploadSize = "5G";
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud-admin-pass";
    };
    settings = {
      trusted_domains = [ "cloud.sorenson-fam.com" ];
      overwriteprotocol = "https";
      maintenance_window_start = "1";
      default_phone_region = "US";
    };
    phpOptions = lib.mkForce {
      "opcache.interned_strings_buffer" = "64";
      memory_limit = "512M";
      post_max_size = "1G";
      output_buffering = "0";
    };
  };

  services.redis.servers.nextcloud = {
    enable = true;
    port = 6379;
  };

  services.nginx = {
    enable = true;
    virtualHosts."cloud.sorenson-fam.com" = {
      forceSSL = true;
      useACMEHost = "sorenson-fam.com";
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

}
