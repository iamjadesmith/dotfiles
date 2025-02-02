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
  ];
  virtualisation.docker.logDriver = "json-file";

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  users.users.joejad = {
    isNormalUser = true;
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
    unstable.neovim
    cifs-utils
    nfs-utils
    git
    samba
    zsh
    tmux
    kubectl
    helm
    fluxcd
    fzf
    zoxide
    lua
    stow
    ripgrep
    nil
    R
    lua-language-server
    stylua
    nixfmt-rfc-style
    oh-my-posh
    unstable.rustup
    unstable.cargo
    lazygit
    postgresql_17
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
