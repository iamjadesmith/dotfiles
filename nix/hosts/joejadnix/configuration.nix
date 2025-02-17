{
  inputs,
  outputs,
  pkgs,
  config,
  meta,
  lib,
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

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  programs.hyprland.enable = true;
  services.displayManager.defaultSession = "hyprland";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs.unstable; [
    nerd-fonts.jetbrains-mono
    openmoji-color
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
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
        "/home/joejad/projects/ollama/ollama:/root/.ollama"
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
        "/home/joejad/projects/ollama/open-webui:/app/backend/data"
      ];
      autoStart = true;
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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  programs.zsh.enable = true;
  programs.firefox.enable = true;

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

  environment.systemPackages = with pkgs.unstable; [
    zsh
    wget
    neovim
    tmux
    git
    kubectl
    helm
    python314
    luajitPackages.luarocks-nix
    fzf
    obsidian
    neofetch
    alacritty
    cider
    zoxide
    luajit
    lua
    stow
    ripgrep
    gcc
    cmake
    nodejs_22
    nil
    R
    gnumake
    lua-language-server
    stylua
    nixfmt-rfc-style
    prismlauncher
    wofi
    oh-my-posh
    zulu
    kanata
    nextcloud-client
    thunderbird
    ansible
    fluxcd
    apacheHttpd
    openssl
    lazygit
    postgresql_17
    wl-clipboard
    rustup
    cargo
    tree-sitter
    sourcekit-lsp
    discord
    ente-auth
    bitwarden-desktop
    bitwarden-cli
    yubikey-manager
    nvidia-container-toolkit
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

}
