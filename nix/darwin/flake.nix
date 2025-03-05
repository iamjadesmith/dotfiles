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
      dark_mode = true;
      meta = "joejadmbp";
      configuration =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            add-unstable-packages
            alacritty-theme.overlays.default
          ];
          environment.systemPackages = with pkgs; [
            alacritty
            black
            ffmpeg-headless
            fluxcd
            git
            kubectl
            lazygit
            lua-language-server
            mkalias
            neovim
            nil
            nixfmt-rfc-style
            nodejs
            obsidian
            postgresql_17
            ripgrep
            ruby
            rustup
            stylua
            syncthing
            tmux
            tree
            tree-sitter
            yt-dlp
            yubikey-manager
            zoxide
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
              "vapor"
              "r"
              "pipx"
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
            masApps = {
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

          nix.settings.experimental-features = "nix-command flakes";
          programs.zsh.enable = true;
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 5;
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
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jade = if dark_mode == true then import ./home.nix else import ./home-light.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit meta;
            };
          }
        ];
      };
      darwinPackages = self.darwinConfigurations."mac".pkgs;
    };
}
