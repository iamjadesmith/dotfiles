{
  config,
  inputs,
  lib,
  meta,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.server;
in
{
  options.dotfiles.server = {
    enable = lib.mkEnableOption "shared server defaults";

    firewall.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the firewall for server hosts.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix = {
      package = pkgs.nixVersions.latest;
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    nixpkgs = {
      overlays = [
        inputs.alacritty-theme.overlays.default
      ];
      config = {
        permittedInsecurePackages = [ "electron-25.9.0" ];
        allowUnfree = true;
      };
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = meta.hostname;
    networking.networkmanager.enable = lib.mkDefault true;
    networking.firewall.enable = lib.mkDefault cfg.firewall.enable;

    time.timeZone = "America/Chicago";

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    systemd.tmpfiles.rules = [
      "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    ];

    security.sudo.wheelNeedsPassword = false;
    programs.zsh.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
