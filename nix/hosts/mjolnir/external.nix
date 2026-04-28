{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.nginx.virtualHosts."proxmox.joejad.com" = {
    useACMEHost = "joejad.com";
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://10.47.59.5:8006";
    };
  };
}
