{
  config,
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

    networkd.enable = lib.mkEnableOption "systemd-networkd instead of NetworkManager; hosts define their own static networks";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.networkd.enable {
        networking.networkmanager.enable = false;
        networking.useNetworkd = true;
        networking.useDHCP = false;
        # Tailscale, containers, and VPN namespaces add routes and rules networkd
        # does not own; leave them alone when networkd restarts.
        systemd.network.config.networkConfig = {
          ManageForeignRoutes = false;
          ManageForeignRoutingPolicyRules = false;
        };
        # Avahi already handles mDNS.
        services.resolved.settings.Resolve = {
          LLMNR = false;
          MulticastDNS = false;
        };
      })
      {
        nix = {
          package = pkgs.nixVersions.latest;
          settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          # Lets `nixos-rebuild --target-host` copy unsigned closures in. wheel
          # already has passwordless sudo, so this grants nothing new.
          settings.trusted-users = [ "@wheel" ];
        };

        nixpkgs = {
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
      }
    ]
  );
}
