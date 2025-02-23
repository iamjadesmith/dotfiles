{
  inputs,
  outputs,
  lib,
  pkgs,
  meta,
  ...
}:

{

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable
      inputs.alacritty-theme.overlays.default
    ];
    config = {
      permittedInsecurePackages = [ "electron-25.9.0" ];
      allowUnfree = true;
    };
  };

  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.devices = [ "nodev" ];

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "btrfs";
  };

  networking.hostName = meta.hostname;
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    "d /var/lib/traefik/letsencrypt 0755 root root - -"
    "d /var/lib/gitea 0755 root root - -"
    "d /var/lib/adguard/conf 0755 root root - -"
    "d /var/lib/adguard/work 0755 root root - -"
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    logDriver = "json-file";
    daemon.settings.features.cdi = true;
    rootless.daemon.settings.features.cdi = true;
  };

  services.podman.networks = {
    traefik = {
      name = "traefik";
      labels = {
        "com.docker.network.driver.api.version" = "fixed"; # For Traefik
      };
    };
  };

  virtualisation.oci-containers.containers = {
    traefik = {
      image = "traefik:latest";
      ports = [
        "80:80"
        "443:443"
        "2222:2222"
      ];
      autoStart = true;
      networks = [ "traefik" ];
      volumes = [
        "/var/lib/traefik/letsencrypt:/letsencrypt"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      environmentFiles = [ "/var/lib/secrets/.env" ];
      cmd = [
        "--log.level=DEBUG"
        "--api.insecure=true"
        "--providers.docker=true"
        "--providers.docker.exposedbydefault=false"
        "--entryPoints.web.address=:80"
        "--entryPoints.websecure.address=:443"
        "--entryPoints.gitea-ssh.address=:2222"
        "--certificatesresolvers.myresolver.acme.dnschallenge=true"
        "--certificatesresolvers.myresolver.acme.dnschallenge.provider=cloudflare"
        "--certificatesresolvers.myresolver.acme.email=bill@joejad.com"
        "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
        "--certificatesresolvers.myresolver.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
        "--entrypoints.websecure.http.tls.domains[0].main=joejad.com"
        "--entrypoints.websecure.http.tls.domains[0].sans=*.joejad.com"
        "--entrypoints.web.http.redirections.entrypoint.to=websecure"
        "--entrypoints.web.http.redirections.entrypoint.scheme=https"
        "--entrypoints.websecure.http.tls.certResolver=myresolver"
      ];
    };
    gitea = {
      image = "gitea/gitea";
      autoStart = true;
      environment = {
        GITEA__server__SSH_PORT = "2222";
      };
      networks = [ "traefik" ];
      volumes = [
        "/var/lib/gitea:/data"
        "/etc/timezone:/etc/timezone:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.gitea.rule" = "Host(`gitea.joejad.com`)";
        "traefik.http.routers.gitea.entrypoints" = "websecure";
        "traefik.http.services.gitea.loadbalancer.server.port" = "3000";
        "traefik.tcp.routers.gitea.entrypoints" = "gitea-ssh";
        "traefik.tcp.routers.gitea.rule" = "HostSNI(`*`)";
        "traefik.tcp.services.gitea.loadbalancer.server.port" = "22";
      };
    };
    adguard = {
      image = "adguard/adguardhome";
      autoStart = true;
      networks = [ "traefik" ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "853:853/tcp"
        "853:853/udp"
        "3000:3000"
      ];
      volumes = [
        "/var/lib/adguard/work:/opt/adguardhome/work"
        "/var/lib/adguard/conf:/opt/adguardhome/conf"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.adguard.rule" = "Host(`ad3.joejad.com`)";
        "traefik.http.routers.adguard.entrypoints" = "websecure";
        "traefik.http.services.adguard.loadbalancer.server.port" = "3000";
      };
    };
  };

  users.users.joejad = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
      tree
    ];
    hashedPassword = "$y$j9T$zCosUIu8eNq21sMsgQ7ya.$0oQ.aynDLokO77HvIjV.EEMDrnI25n8VQJgEd3RlSx8";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIi5XbhWvuZU9HQ7zG06jCdBp1KikJVoqzBsjNpQP05 joejad@joejadnix"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoJ+uZAEo2H9IV4IbtL7u8maMd2tyTAUGl9l7/l9oe/ jadesmith@Jades-MacBook-Pro.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBA7ZrM16IHoMUHjoipAL7IhHtr9woN7gtyWy6gdQh0y Generated By Termius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbuKctCqNq2KDOsavoPDSZMbYdtrvZhPYda5c4pH19Y Generated By Termius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+EYcg6tzERSKh58WGnVhBQ0eNUGSHfEk2Uw1XizC1e Shortcuts on Jade’s iPhone"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgYIcGwg/BHL2nJ+DfZsa2nvGz+e6TgUzuvIGudKB+w Shortcuts on Jade’s iPad"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBreNu9nXnPthacxlodcL+dp81vmCLrI2U1D1u4zexV2 joejad@nixnas"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /home/joejad 10.47.59.0/24(rw,sync,no_root_squash,no_subtree_check)
  '';

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";
        "logging" = "file";
        "security" = "user";
        "panic action" = "/usr/share/samba/panic-action %d";
        "server role" = "standalone server";
        "obey pam restrictions" = "yes";
        "unix password sync" = "yes";
        "passwd program" = "/usr/bin/passwd %u";
        "passwd chat" =
          "*Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .";
        "pam password change" = "yes";
        "map to guest" = "bad user";
        "usershare allow guests" = "yes";
      };
      "private" = {
        "path" = "/home/joejad";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "joejad";
        "public" = "no";
        "writeable" = "yes";
      };
    };
  };

  services.logind.lidSwitch = "ignore";

  environment.systemPackages = with pkgs; [
    R
    bash
    cifs-utils
    fluxcd
    fzf
    gcc
    git
    gnumake
    helm
    kubectl
    lazygit
    lua
    lua-language-server
    luajitPackages.luarocks-nix
    nfs-utils
    nil
    nixfmt-rfc-style
    oh-my-posh
    postgresql_17
    ripgrep
    samba
    stow
    stylua
    tmux
    unstable.cargo
    unstable.neovim
    unstable.rustup
    zoxide
    zsh
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.enable = false;
  system.stateVersion = "23.11";
}
