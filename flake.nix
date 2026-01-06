{
  description = "NixOS configurations for dinOS with GNOME and impermanence defaults";

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
      overlays = {
        default = final: prev: {
          dinofetch = final.callPackage ./pkgs/dinofetch { };
        };
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlays.default ];
      };

      hostDirs = lib.filterAttrs (name: v: v == "directory" && name != "types")
        (builtins.readDir ./hosts);

      hmDefaults = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      };

      baseModules = [
        { nixpkgs.overlays = [ overlays.default ]; }
        self.nixosModules.dinOS
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
        hmDefaults
      ];

      genericHostModule = { lib, ... }:
        let
          isEfi = builtins.pathExists "/sys/firmware/efi";
        in {
          assertions = [
            {
              assertion = builtins.pathExists "/etc/nixos/hardware-configuration.nix";
              message = "Generate /etc/nixos/hardware-configuration.nix with `sudo nixos-generate-config` before switching to flake output dinOS.";
            }
            {
              assertion = isEfi;
              message = "Generic dinOS host assumes EFI firmware; use a host-specific config with GRUB settings on BIOS/legacy machines.";
            }
          ];

          imports = [
            /etc/nixos/hardware-configuration.nix
          ];

          networking.hostName = lib.mkDefault "dinOS";

          boot.loader.systemd-boot.enable = lib.mkDefault isEfi;
          boot.loader.efi.canTouchEfiVariables = lib.mkDefault isEfi;
        };

      mkSystemFor = system: extraModules: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = baseModules ++ extraModules;
      };

      mkSystem = extraModules: mkSystemFor system extraModules;

      mkInstaller = extraModules: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = extraModules ++ baseModules;
      };

      userLayers = {
        stags = [
          self.nixosModules.users-stags
        ];
      };

      profileModules = {
        headless = ./modules/dinOS/profiles/headless.nix;
        kodi = ./modules/dinOS/profiles/kodi.nix;
        k8s = ./modules/dinOS/profiles/k8s.nix;
        server = ./modules/dinOS/profiles/server.nix;
      };

      profileDeps = {
        k8s = [ "server" ];
      };

      profileUsers = {
        server = [ "stags" ];
      };

      hostUsers = {
        ideapad3 = [ "stags" ];
        nuc14 = [ "stags" ];
        xps15 = [ "stags" ];
      };

      hostProfiles = {
        m710q-1 = [ "k8s" "headless" ];
        m710q-2 = [ "k8s" "headless" ];
        nuc14 = [ "server" "kodi" ];
      };

      expandProfiles = profiles:
        lib.unique (profiles ++ lib.concatMap (profile: profileDeps.${profile} or []) profiles);

      mkHost = name:
        let
          requestedProfiles = hostProfiles.${name} or [];
          enabledProfiles = expandProfiles requestedProfiles;
          profileUserLayers = lib.concatMap (profile: profileUsers.${profile} or []) enabledProfiles;
          enabledUsers = lib.unique ((hostUsers.${name} or []) ++ profileUserLayers);
          modulesForUsers = lib.concatMap (user: userLayers.${user} or []) enabledUsers;
          modulesForProfiles = lib.concatMap (profile: [ profileModules.${profile} ]) enabledProfiles;
        in
          mkSystem ([
            (./hosts + "/${name}")
            {
              networking.hostName = lib.mkDefault name;
              system.nixos.label = builtins.concatStringsSep "-" ([ name ] ++ enabledProfiles);
            }
          ] ++ modulesForProfiles ++ modulesForUsers);

      baseConfigurations = {
        dinOS = mkSystem [
          genericHostModule
        ];
      };

    in {
      overlays = overlays;
      nixosModules.dinOS = ./modules/dinOS;
      nixosModules.users-stags = ./modules/users/stags.nix;

      inherit baseConfigurations;

      nixosConfigurations =
        # Device-agnostic base profiles.
        baseConfigurations
        # Per-host outputs (dinOS + optional users + host).
        // lib.mapAttrs (name: _: mkHost name) hostDirs;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          nixpkgs-fmt
          nodejs_20
          fish
          starship
        ];

        shellHook = ''
          export STARSHIP_CONFIG=${./modules/dinOS/starship/develop.toml}
          echo "Loaded nix develop shell with git, nixpkgs-fmt, nodejs_20, fish, and starship (develop theme)."
          exec ${pkgs.fish}/bin/fish -C 'set -g fish_greeting "" ; ${pkgs.starship}/bin/starship init fish | source'
        '';
      };

      packages.${system}.dinofetch = pkgs.dinofetch;
    };
}
