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
      locations."/".proxyPass = "https://scrypted.joejad.lan:10443";
    };

    "ha.${domain}" = ssl // {
      locations."/" = {
        proxyPass = "http://homeassistant.joejad.lan:8123";
        proxyWebsockets = true;
      };
    };

    "git.${domain}" = ssl // {
      extraConfig = ''
        client_max_body_size 512M;
      '';
      locations."/" = {
        proxyPass = "http://joejadserver.joejad.lan:3000";
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
