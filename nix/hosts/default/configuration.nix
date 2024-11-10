{
  inputs,
  outputs,
  pkgs,
  config,
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

  imports = [
    ./hardware-configuration.nix
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "joejadnix";
  networking.networkmanager.enable = true;

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
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    openmoji-color
  ];

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
  };

  security.sudo.wheelNeedsPassword = false;

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

  environment.systemPackages = with pkgs; [
    zsh
    wget
    neovim
    tmux
    git
    kubectl
    fzf
    obsidian
    neofetch
    alacritty
    cider
    zoxide
    stow
    ripgrep
    gcc
    nodejs_22
    nil
    R
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

  system.stateVersion = "24.05";
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # powerManagement.enable = true;
    # powerManagement.finegrained = false;
    open = true;
    # nvidiaSettings = true;
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #   version = "555.58.02";
    #   sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
    #   sha256_aarch64 = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
    #   openSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
    #   settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
    #   persistencedSha256 = lib.fakeSha256;
    # };
  };
}
