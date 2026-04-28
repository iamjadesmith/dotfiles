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
  };
}
