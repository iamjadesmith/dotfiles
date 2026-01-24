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

  systemd.services.nextcloud-backup = {
    description = "Daily Nextcloud data and database backup";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      mkdir -p /mnt/data/mom_backup

      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      BACKUP_FILE="/mnt/data/mom-backup/nextcloud_$TIMESTAMP.tar.gz"

      tar -czf "$BACKUP_FILE" -C /mnt/sorserver nextcloud db_backups

      cd /mnt/data/mom-backup
      ls -t nextcloud_*.tar.gz | tail -n +8 | xargs -r rm --
    '';
  };

  systemd.timers.nextcloud-backup = {
    description = "Daily Nextcloud data and database backup timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
