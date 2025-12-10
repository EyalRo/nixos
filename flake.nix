{
  description = "NixOS configuration for xps15 with GNOME and impermanence";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, impermanence, agenix, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.dinOS = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/dinOS
          ./hosts/xps15/hardware-configuration.nix
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            nixpkgs.config.allowUnfree = true;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nix.settings.auto-optimise-store = true;
            networking.hostName = "dinOS";
            time.timeZone = "America/Los_Angeles";
            hardware.enableRedistributableFirmware = true;
            hardware.cpu.intel.updateMicrocode = nixpkgs.lib.mkDefault true;
            system.stateVersion = "25.11";
          }
        ];
      };

      nixosConfigurations.dinOS-stags = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/dinOS
          ./modules/users/stags.nix
          ./hosts/xps15/hardware-configuration.nix
          {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            nixpkgs.config.allowUnfree = true;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nix.settings.auto-optimise-store = true;
            networking.hostName = "dinOS-stags";
            time.timeZone = "America/Los_Angeles";
            hardware.enableRedistributableFirmware = true;
            hardware.cpu.intel.updateMicrocode = nixpkgs.lib.mkDefault true;
            system.stateVersion = "25.11";
          }
          impermanence.nixosModules.impermanence
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          impermanence.nixosModules.impermanence
        ];
      };

      nixosConfigurations.xps15 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/dinOS
          ./modules/users/stags.nix
          ./hosts/xps15
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          impermanence.nixosModules.impermanence
        ];
      };
    };
}
