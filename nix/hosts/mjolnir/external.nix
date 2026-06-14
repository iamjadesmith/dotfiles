{
  ...
}:

let
  domain = "joejad.com";
  ssl = {
    useACMEHost = domain;
    forceSSL = true;
  };
in
{
  services.nginx.virtualHosts = {
    "scrypted.${domain}" = ssl // {
      locations."/".proxyPass = "https://10.26.27.13:10443";
    };

    "ha.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://10.26.27.2:8123";
        proxyWebsockets = true;
      };
    };

    "git.${domain}" = ssl // {
      extraConfig = ''
        client_max_body_size 512M;
      '';
      locations."/" = {
        proxyPass = "http://10.3.0.3:3000";
        proxyWebsockets = true;
      };
    };

    catchall = {
      serverName = "_";
      default = true;
      addSSL = true;
      useACMEHost = domain;
      locations."/".return = "404";
    };
  };
}
