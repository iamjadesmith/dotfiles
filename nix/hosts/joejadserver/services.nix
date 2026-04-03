{
  config,
  ...
}:

{
  virtualisation.oci-containers.containers = {
    minecraft = {
      image = "itzg/minecraft-server:latest";
      ports = [ "25565:25565" ];
      volumes = [
        "/var/lib/minecraft:/data"
      ];
      autoStart = true;
      extraOptions = [
        "--no-healthcheck"
      ];
      environment = {
        EULA = "TRUE";
        OPS = "JoeJad, Abbyb727";
        LEVEL = "Great World";
        MEMORY = "3G";
        MOTD = "Great World";
        DIFFICULTY = "normal";
        ICON = "https://img.freepik.com/premium-vector/cartoon-vector-illustration-cute-loving-bear-hugging_255358-3482.jpg";
        TZ = "US/Central";
        VERSION = "26.1-snapshot-9";
      };
    };
  };

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
    environmentFile = [ config.sops.secrets.vaultwarden_env.path ];
  };

  services.freshrss = {
    enable = true;
    database = {
      type = "pgsql";
      passFile = config.sops.secrets.freshrss_db_pass.path;
      port = 5432;
      user = "postgres";
    };
    api.enable = true;
    baseUrl = "https://rss.joejad.com";
    passwordFile = config.sops.secrets.freshrss_pass.path;
  };
}
