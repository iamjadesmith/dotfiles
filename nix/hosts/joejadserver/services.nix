{
  config,
  lib,
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
      host = "postgres";
    };
    api.enable = true;
    baseUrl = "https://rss.joejad.com";
    passwordFile = config.sops.secrets.freshrss_pass.path;
  };

  services.uptime-kuma.enable = true;
  services.uptime-kuma.settings.UPTIME_KUMA_HOST = "0.0.0.0";

  services.forgejo = {
    enable = true;
    database.type = "postgres";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "git.joejad.com";
        ROOT_URL = "https://git.joejad.com/";
        HTTP_PORT = 3000;
        SSH_PORT = lib.head config.services.openssh.ports;
        SSH_DOMAIN = "joejadserver.joejad.lan";
      };
      service.DISABLE_REGISTRATION = false;
      mailer = {
        ENABLED = true;
        PROTOCOL = "smtp+starttls";
        SMTP_ADDR = "smtp.mail.me.com";
        SMTP_PORT = 587;
      };
    };
    secrets = {
      mailer.USER = config.sops.secrets.forgejo-mailer-user.path;
      mailer.FROM = config.sops.secrets.forgejo-mailer-from.path;
      mailer.PASSWD = config.sops.secrets.forgejo-mailer-password.path;
    };
  };
}
