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

    zen-browser.url = "github:MarceColl/zen-browser-flake";

  };

  outputs =
    {
      self,
      nixpkgs,
      alacritty-theme,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      meta = "joejadnix";
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
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.joejad = import ./home/home.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              inherit meta;
            };
          }
        ];
      };
    };
}
