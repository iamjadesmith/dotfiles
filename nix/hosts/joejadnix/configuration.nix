{
  inputs,
  outputs,
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.hostname;
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs.hyprland.enable = true;

  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    openmoji-color
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    "d /var/lib/podman 0755 root root - -"
    "d /var/lib/podman/ollama 0755 root root - -"
    "d /var/lib/podman/open-webui 0755 root root - -"
  ];

  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    logDriver = "json-file";
    daemon.settings.features.cdi = true;
    rootless.daemon.settings.features.cdi = true;
  };

  virtualisation.oci-containers.containers = {
    ollama = {
      image = "ollama/ollama";
      ports = [ "11434:11434" ];
      volumes = [
        "/var/lib/podman/ollama:/root/.ollama"
      ];
      autoStart = true;
      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
    };
    open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      ports = [ "3000:8080" ];
      volumes = [
        "/var/lib/podman/open-webui:/app/backend/data"
      ];
      autoStart = true;
    };
    workout = {
      image = "localhost/workout:latest";
      autoStart = true;
      ports = [ "5000:5000" ];
    };
  };

  users.users.joejad = {
    isNormalUser = true;
    description = "joejad";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ tree ];
    hashedPassword = "$6$sI71vFKosWWmZeD3$04iWnWU3aXy/s9QOM6MDK8Zljnu9OaYuJGLMay.rix0TmT94W.fDQKVCmwdi.B0grPzDfpzkXVviPvEFY162T1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBreNu9nXnPthacxlodcL+dp81vmCLrI2U1D1u4zexV2 joejad@nixnas"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoJ+uZAEo2H9IV4IbtL7u8maMd2tyTAUGl9l7/l9oe/ jadesmith@Jades-MacBook-Pro.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBA7ZrM16IHoMUHjoipAL7IhHtr9woN7gtyWy6gdQh0y Generated By Termius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbuKctCqNq2KDOsavoPDSZMbYdtrvZhPYda5c4pH19Y Generated By Termius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+EYcg6tzERSKh58WGnVhBQ0eNUGSHfEk2Uw1XizC1e Shortcuts on Jade’s iPhone"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgYIcGwg/BHL2nJ+DfZsa2nvGz+e6TgUzuvIGudKB+w Shortcuts on Jade’s iPad"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  services.syncthing = {
    enable = true;
    group = "users";
    user = "joejad";
    configDir = "/home/joejad/.config/syncthing";
    guiAddress = "0.0.0.0:8384";
  };
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
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

  services.cron = {
    enable = true;
    systemCronJobs = [
      "* 4 * * *        joejad    . /etc/profile; /home/joejad/backups/pbbackup.sh"
      "* 4 * * *        joejad    . /etc/profile; /home/joejad/backups/nextcloud.sh"
    ];
  };

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /home/joejad 10.47.59.0/24(rw,sync,no_root_squash,no_subtree_check)
  '';

  environment.systemPackages = with pkgs; [
    R
    alacritty
    ansible
    apacheHttpd
    bash
    bitwarden-cli
    bitwarden-desktop
    black
    cargo
    cider
    cmake
    discord
    ente-auth
    fluxcd
    fzf
    gcc
    git
    gnumake
    helm
    kanata
    kubectl
    lazygit
    lua
    lua-language-server
    luajit
    luajitPackages.luarocks-nix
    inputs.rose-pine-hyprcursor
    neofetch
    neovim
    nextcloud-client
    nil
    nixfmt-rfc-style
    nodejs_22
    nvidia-container-toolkit
    obsidian
    oh-my-posh
    openssl
    postgresql_17
    prismlauncher
    ripgrep
    rustup
    stow
    stylua
    thunderbird
    tmux
    tree-sitter
    unzip
    waybar
    wget
    wl-clipboard
    wofi
    yubikey-manager
    zoxide
    zsh
    zulu
  ];

  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        config = ''
          (defsrc
           caps
          )
          (defalias
           caps esc
          )

          (deflayer base
           @caps
          )
        '';
      };
    };
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
    gamescopeSession = {
      enable = true;
    };
  };

  system.stateVersion = "24.05";
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      5000
      8384
    ];
  };

}
