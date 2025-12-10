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
      nixosModules.dinOS = ./modules/dinOS;
      nixosModules.users-stags = ./modules/users/stags.nix;

      nixosConfigurations.dinOS = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          self.nixosModules.dinOS
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = nixpkgs.lib.mkDefault false;
            boot.loader.grub.enable = nixpkgs.lib.mkDefault false;
            fileSystems."/" = {
              device = "tmpfs";
              fsType = "tmpfs";
              options = [ "mode=0755" "size=2G" ];
            };
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
          self.nixosModules.dinOS
          self.nixosModules.users-stags
          impermanence.nixosModules.impermanence
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = nixpkgs.lib.mkDefault false;
            boot.loader.grub.enable = nixpkgs.lib.mkDefault false;
            fileSystems."/" = {
              device = "tmpfs";
              fsType = "tmpfs";
              options = [ "mode=0755" "size=2G" ];
            };
            networking.hostName = "dinOS-stags";
            time.timeZone = "America/Los_Angeles";
            hardware.enableRedistributableFirmware = true;
            hardware.cpu.intel.updateMicrocode = nixpkgs.lib.mkDefault true;
            system.stateVersion = "25.11";
          }
        ];
      };

      nixosConfigurations.xps15 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/xps15
          self.nixosModules.dinOS
          self.nixosModules.users-stags
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
