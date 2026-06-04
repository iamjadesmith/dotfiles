{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.groups.github-runner = { };
  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
    home = "/var/lib/github-runner";
    createHome = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/github-runner-work 0750 github-runner github-runner - -"
    "d /var/lib/github-runner-work/joejadserver 0750 github-runner github-runner - -"
  ];

  services.github-runners.joejadserver = {
    enable = true;
    name = "joejadserver";
    url = "https://github.com/iamjadesmith/dotfiles";
    tokenFile = config.sops.secrets.github-runner-token.path;
    user = "github-runner";
    group = "github-runner";
    workDir = "/var/lib/github-runner-work/joejadserver";
    serviceOverrides = {
      InaccessiblePaths = lib.mkForce [ "-/run/secrets/github-runner-token" ];
      WorkingDirectory = lib.mkForce "%S/github-runner/joejadserver";
    };
    extraLabels = [
      "joejadserver"
    ];
    extraPackages = [
      pkgs.git
      pkgs.jq
      pkgs.nixVersions.latest
    ];
  };

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
