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
      lib = nixpkgs.lib;

      hostDirs = lib.filterAttrs (_: v: v == "directory") (builtins.readDir ./hosts);

      hmDefaults = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      };

      baseModules = [
        self.nixosModules.dinOS
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        hmDefaults
      ];

      mkSystem = extraModules: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = baseModules ++ extraModules;
      };

      mkInstaller = extraModules: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = extraModules ++ baseModules;
      };

      userLayers = {
        stags = [
          self.nixosModules.users-stags
          agenix.nixosModules.default
        ];
      };

      hostUsers = {
        xps15 = [ "stags" ];
      };

      mkHost = name:
        let
          enabledUsers = hostUsers.${name} or [];
          modulesForUsers = lib.concatMap (user: userLayers.${user} or []) enabledUsers;
        in
          mkSystem ([
            (./hosts + "/${name}")
            { networking.hostName = lib.mkDefault name; }
          ] ++ modulesForUsers);

      baseConfigurations = {
        dinOS-installer = mkInstaller [
          ({ modulesPath, ... }: {
            imports = [
              (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
            ];
          })
          { networking.hostName = "dinOS-installer"; }
        ];
      };
    in {
      nixosModules.dinOS = ./modules/dinOS;
      nixosModules.users-stags = ./modules/users/stags.nix;

      inherit baseConfigurations;

      nixosConfigurations =
        # Device-agnostic base profiles.
        baseConfigurations
        # Per-host outputs (dinOS + optional users + host).
        // lib.mapAttrs (name: _: mkHost name) hostDirs;
    };
}
