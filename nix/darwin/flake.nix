{
  description = "My Darwin Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";

  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      alacritty-theme,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      add-unstable-packages = final: _prev: {
        unstable = import inputs.nixpkgs {
          system = "aarch64-darwin";
        };
      };
      username = "jade";
      configuration =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            add-unstable-packages
            alacritty-theme.overlays.default
          ];
          environment.systemPackages = [
            pkgs.alacritty
            pkgs.git
            pkgs.unstable.go_1_23
            pkgs.lua-language-server
            pkgs.mkalias
            pkgs.neovim
            pkgs.nil
            pkgs.obsidian
            pkgs.ripgrep
            pkgs.stylua
            pkgs.tmux
            pkgs.zoxide
            pkgs.kubectl
            pkgs.fluxcd
            pkgs.lens
            pkgs.lazygit
            pkgs.postgresql_17
            pkgs.nixfmt-rfc-style
            pkgs.youtube-dl
          ];

          users.users.jade = {
            name = username;
            home = "/Users/jade";
          };

          homebrew = {
            enable = true;
            brews = [
              "mas"
              "helm"
            ];
            casks = [
              "alfred"
              "firefox"
              "discord"
              "nikitabobko/tap/aerospace"
            ];
            taps = [
              "nikitabobko/tap"
            ];
            masApps =
              {
              };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          system.defaults = {
            NSGlobalDomain.AppleShowAllExtensions = true;
            loginwindow.GuestEnabled = false;
            finder.FXPreferredViewStyle = "clmv";
            dock.autohide = true;
            dock.autohide-delay = 0.0;
          };

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          programs.zsh.enable = true;
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jade = import ./home.nix;
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mac".pkgs;
    };
}
