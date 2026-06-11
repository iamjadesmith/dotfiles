{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      alacritty-theme,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      linuxUser = "jade";
      linuxHomeDirectory = "/home/${linuxUser}";
      hosts = [
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
        }
      ];
    in
    {
      overlays = import ./overlays { inherit inputs; };
      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host.name;
          value = nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs outputs;
              meta = {
                hostname = host.name;
                inherit (host) server;
              };
            };
            system = "x86_64-linux";
            modules = [
              ./modules/nix-maintenance.nix
              ./modules/common-packages.nix
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              ./hosts/${host.name}/configuration.nix
              ./hosts/${host.name}/hardware-configuration.nix
              ./hosts/${host.name}/disko-config.nix
              inputs.home-manager.nixosModules.default
              home-manager.nixosModules.home-manager
              {
                nixpkgs.overlays = [
                  outputs.overlays.modifications
                ];
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.${linuxUser} =
                  if host.server == true then import ./home/home-server.nix else import ./home/home.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs;
                  meta = host;
                  user = linuxUser;
                  homeDirectory = linuxHomeDirectory;
                };
              }
            ];
          };
        }) hosts
      );
    };
}
