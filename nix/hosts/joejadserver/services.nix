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
}
