{
  description = "mjolnir personal flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    tree-sitter-src = {
      url = "github:tree-sitter/tree-sitter/v0.26.1";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";

    budget = {
      url = "git+https://git.joejad.com/jade/budget.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    foodLog = {
      url = "git+https://git.joejad.com/jade/food_log.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    golfRust = {
      url = "git+https://git.joejad.com/jade/golf_rust.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    receipt = {
      url = "git+https://git.joejad.com/jade/receipt.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    running = {
      url = "git+https://git.joejad.com/jade/running.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    workoutRust = {
      url = "git+https://git.joejad.com/jade/workout_rust.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      linuxUser = "jade";
      linuxHomeDirectory = "/home/${linuxUser}";
      meta = {
        hostname = "mjolnir";
        server = true;
      };
    in
    {
      overlays = import ../../overlays { inherit inputs; };

      nixosConfigurations.mjolnir = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs meta;
          personalInputs = {
            inherit (inputs)
              budget
              foodLog
              golfRust
              receipt
              running
              workoutRust
              ;
          };
        };
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./configuration.nix
          ./hardware-configuration.nix
          ./disko-config.nix
          ./personal.nix
          inputs.home-manager.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ outputs.overlays.modifications ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${linuxUser} = import ../../home/home-server.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs meta;
              user = linuxUser;
              homeDirectory = linuxHomeDirectory;
            };
          }
        ];
      };
    };
}
