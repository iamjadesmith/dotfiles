{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

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
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
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
      forAllSystems =
        fn: nixpkgs.lib.genAttrs systems (system: fn { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      overlays = import ./overlays { inherit inputs; };
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      nixosConfigurations.default = builtins.listToAttrs (
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
                  if host.server == true then import ./home/home-server.nix else import ./home/home.nix;
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
