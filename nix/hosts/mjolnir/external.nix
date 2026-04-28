{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.nginx.virtualHosts = {
    "proxmox.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://10.47.59.5:8006";
      };
    };

    "opnsense.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://10.47.59.1:10443";
      };
    };

    "backup.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://10.47.59.47:8007";
      };
    };

    "scrypted.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://10.47.59.11:10443";
      };
    };

    "unifi.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://10.47.59.50:11443";
      };
    };

    "ha.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://10.47.59.10:8123";
      };
    };

    "kvm.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://10.47.59.21:80";
      };
    };
  };

  "default" = {
    rejectSSL = true;
    locations."/".return = "404";
  };
}
