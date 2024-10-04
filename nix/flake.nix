{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";

    ags.url = "github:Aylur/ags";

  };

  outputs =
    {
      self,
      nixpkgs,
      alacritty-theme,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      inherit (self) outputs;

    in
    {
      overlays = import ./overlays { inherit inputs; };
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          ./hosts/default/configuration.nix
          inputs.home-manager.nixosModules.default

        ];
      };
    };
}
