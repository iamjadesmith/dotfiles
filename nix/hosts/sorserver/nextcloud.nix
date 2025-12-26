{ config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions = {
          "DATABASE nextcloud" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "cloud.sorenson-fam.com";

    config = {
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud-admin-pass";
    };

    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      dbpassFile = "/run/secrets/nextcloud-db-pass";
    };

    caching.redis = true;
  };

  services.redis.servers.nextcloud = {
    enable = true;
    port = 6379;
  };

  services.nginx = {
    enable = true;
    virtualHosts."${config.services.nextcloud.hostName}" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://unix:/run/nextcloud/nextcloud.sock";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "joejadjavajim@icloud.com";

    certs = {
      "${config.services.nextcloud.hostName}" = {
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
