{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # mjolnir's personal apps on Forgejo. Inputs are fetched lazily, so only
    # building mjolnir needs Forgejo; see nix/README.md if it is down.
    budget = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/budget.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    foodLog = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/food_log.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    golfRust = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/golf_rust.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mealPlanner = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/meals.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    receiptBreakdown = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/receipt_breakdown.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    running = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/running.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stock = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/stock.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    study = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/study.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tallyRust = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/tally_rust.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    workoutRust = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/workout_rust.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yahtzeeRust = {
      url = "git+http://joejadserver.joejad.lan:3000/jade/yahtzee_rust.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      disko,
      sops-nix,
      home-manager,
      ...
    }@inputs:
    let
      linuxUser = "jade";
      linuxHomeDirectory = "/home/${linuxUser}";
      darwinUser = "jade";
      darwinHomeDirectory = "/Users/${darwinUser}";
      nixosHosts = [
        {
          name = "joejadserver";
          server = true;
        }
        {
          name = "sorserver";
          server = true;
        }
        {
          name = "mjolnir";
          server = true;
          desktop = true;
        }
      ];
      darwinHosts = [
        { name = "mini"; }
        { name = "joejadmbp"; }
      ];
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host.name;
          value = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs;
              meta = {
                hostname = host.name;
                inherit (host) server;
              };
            };
            system = "x86_64-linux";
            modules = [
              ./modules/dotfiles/mdns.nix
              ./modules/dotfiles/server.nix
              ./modules/dotfiles/jade.nix
              ./modules/dotfiles/sops.nix
              ./modules/dotfiles/docker.nix
              ./modules/dotfiles/borg.nix
              ./modules/dotfiles/kuma-push.nix
              ./modules/nix-maintenance.nix
              ./modules/common-packages.nix
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              ./hosts/${host.name}/configuration.nix
              ./hosts/${host.name}/hardware-configuration.nix
              ./hosts/${host.name}/disko-config.nix
              home-manager.nixosModules.home-manager
              {
                dotfiles.server.enable = host.server;
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${linuxUser} =
                  if host.desktop or false then import ./home/home-desktop.nix else import ./home/home-server.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs;
                  meta = host;
                  user = linuxUser;
                  homeDirectory = linuxHomeDirectory;
                };
              }
            ];
          };
        }) nixosHosts
      );

      darwinConfigurations = builtins.listToAttrs (
        map (host: {
          name = host.name;
          value = nix-darwin.lib.darwinSystem {
            specialArgs = {
              inherit inputs self;
              meta = host;
            };
            modules = [
              ./modules/common-packages.nix
              ./hosts/darwin/configuration.nix
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${darwinUser} = import ./home/home-darwin.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs;
                  meta = host;
                  user = darwinUser;
                  homeDirectory = darwinHomeDirectory;
                };
              }
            ];
          };
        }) darwinHosts
      );

    };
}
