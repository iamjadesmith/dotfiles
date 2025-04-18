{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      alacritty-theme,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      dark_mode = true;
      hosts = [
        {
          name = "joejadnix";
          server = false;
        }
        {
          name = "nixnas";
          server = true;
        }
        {
          name = "nixvostro";
          server = true;
        }
        {
          name = "agent-1";
          server = true;
        }
        {
          name = "agent-2";
          server = true;
        }
        {
          name = "agent-3";
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
              };
            };
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/${host.name}/configuration.nix
              ./hosts/${host.name}/hardware-configuration.nix
              ./hosts/${host.name}/disko-config.nix
              inputs.home-manager.nixosModules.default
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.joejad =
                  if host.server == true then
                    import ./home/home-server.nix
                  else if dark_mode == true then
                    import ./home/home.nix
                  else
                    import ./home/home-light.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs;
                  meta = host;
                };
              }
            ];
          };
        }) hosts
      );
    };
}
