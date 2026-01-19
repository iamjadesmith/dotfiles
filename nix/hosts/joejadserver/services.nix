{
  ...
}:

{
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";
  };

  services.freshrss = {
    enable = true;
    baseUrl = "https://rss.joejad.com";
    passwordFile = "/run/secrets/freshrss";
  };

  services.uptime-kuma.enable = true;
  services.uptime-kuma.settings.UPTIME_KUMA_HOST = "0.0.0.0";

  virtualisation.oci-containers.containers = {
    minecraft = {
      image = "itzg/minecraft-server";
      ports = [ "25565:25565" ];
      volumes = [
        "/var/lib/minecraft:/data"
      ];
      autoStart = true;
      environment = {
        EULA = "TRUE";
        OPS = "JoeJad, Abbyb727";
        LEVEL = "Great World";
        MEMORY = "3G";
        MOTD = "Great World";
        DIFFICULTY = "normal";
        ICON = "https://img.freepik.com/premium-vector/cartoon-vector-illustration-cute-loving-bear-hugging_255358-3482.jpg";
        TZ = "US/Central";
        VERSION = "26.1-snapshot-3";
      };
    };
  };
}
