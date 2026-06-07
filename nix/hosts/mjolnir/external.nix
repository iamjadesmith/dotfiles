{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.nginx.virtualHosts = {
    "scrypted.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://10.26.27.13:10443";
      };
    };

    "ha.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://10.26.27.2:8123";
        proxyWebsockets = true;
      };
    };

    "git.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 512M;
      '';
      locations."/" = {
        proxyPass = "http://10.3.0.3:3000";
        proxyWebsockets = true;
      };
    };

    "catchall" = {
      serverName = "_";
      default = true;
      addSSL = true;
      useACMEHost = "joejad.com";
      locations."/".return = "404";
    };
  };
}
