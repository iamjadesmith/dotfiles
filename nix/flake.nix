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

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };

  outputs =
    {
      nixpkgs,
      disko,
      sops-nix,
      home-manager,
      ...
    }@inputs:
    let
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
              ./modules/dotfiles/server.nix
              ./modules/dotfiles/jade.nix
              ./modules/dotfiles/sops.nix
              ./modules/dotfiles/docker.nix
              ./modules/dotfiles/borg.nix
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
                  if host.server == true then import ./home/home-server.nix else import ./home/home-desktop.nix;
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
