{
  config,
  pkgs,
  inputs,
  ...
}:

{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
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
    description = "Joejad";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ tree ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };
    users = {
      "joejad" = import ./home.nix;
    };
  };

  services.xserver.windowManager.i3.enable = true;
  services.displayManager = {
    defaultSession = "none+i3";
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;
  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

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
  ];

  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
      #   devices = [
      #     "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
      #     "/dev/input/by-id/usb-Framework_Laptop_16_Keyboard_Module_-_ANSI_FRAKDKEN0100000000-event-kbd"
      #     "/dev/input/by-id/usb-Framework_Laptop_16_Keyboard_Module_-_ANSI_FRAKDKEN0100000000-if02-event-kbd"
      #   ];
      #   extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
           caps
          )
          (defalias
           caps (tap-hold 100 100 esc esc)
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

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
