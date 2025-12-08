{
  description = "NixOS configuration for xps15 with GNOME and impermanence";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, impermanence, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.xps15 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/xps15
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.stags = import ./home/stags;
          }
          impermanence.nixosModules.impermanence
        ];
      };
    };
}
