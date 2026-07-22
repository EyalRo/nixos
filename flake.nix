{
  description = "NixOS configurations for dinOS with GNOME and impermanence defaults";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    commafiles.url = "github:Suya1671/commafiles";
    commafiles.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    claude-desktop-debian.url = "github:aaddrick/claude-desktop-debian";
    claude-desktop-debian.inputs.nixpkgs.follows = "nixpkgs-unstable";
    pachy.url = "git+https://forgejo.virtualdino.com/stags/pachy.git";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, impermanence, agenix, niri-flake, commafiles, noctalia, nixos-hardware, claude-desktop-debian, pachy, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs-unstable-no-overlays = import nixpkgs-unstable {
        inherit system;
      };

      overlays = final: prev: {
        crystal-sysinfo = final.callPackage ./pkgs/crystal-sysinfo { crystal = pkgs-unstable.crystal; };
        claude-code = final.callPackage ./pkgs/claude-code { };
        claude-desktop = final.symlinkJoin {
          name = "claude-desktop";
          paths = [ claude-desktop-debian.packages.${final.stdenv.hostPlatform.system}.default ];
          nativeBuildInputs = [ final.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/claude-desktop --set NIXOS_OZONE_WL 1
          '';
          meta = claude-desktop-debian.packages.${final.stdenv.hostPlatform.system}.default.meta;
        };
        melia = final.callPackage ./pkgs/melia { };
        opencode-desktop = final.callPackage ./pkgs/opencode-desktop { };
        proton-drive-cli = final.callPackage ./pkgs/proton-drive-cli { };
        tailscale = pkgs-unstable-no-overlays.tailscale;
        telegram-desktop = final.callPackage ./pkgs/telegram-desktop-bin { inherit (prev) telegram-desktop fetchFromGitHub; };
        forgejo-mcp = pachy.packages.${final.stdenv.hostPlatform.system}.forgejo-mcp;
        victorialogs-mcp = pachy.packages.${final.stdenv.hostPlatform.system}.victorialogs-mcp;
        playwright-mcp = pachy.packages.${final.stdenv.hostPlatform.system}.playwright-mcp;
        inherit (final.callPackage ./pkgs/mcp { })
          todo-mcp mediawatch-mcp
          prowlarr-mcp proxmox-mcp radarr-mcp sonarr-mcp
          grammarly-mcp linkedin-mcp homepage-secrets-mcp;
      };
      specialArgs = { inherit inputs; };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlays ];
      };
      
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        overlays = [ overlays ];
      };

      hostDirs = lib.filterAttrs (name: v: v == "directory" && name != "types")
        (builtins.readDir ./hosts);

      hmDefaults = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = { inherit inputs; };
      };

      baseModules = [
        { nixpkgs.overlays = [ overlays inputs.niri-flake.overlays.niri ]; }
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
        specialArgs = { inherit inputs; };
        modules = baseModules ++ extraModules ++ [{ nixpkgs.hostPlatform = system; }];
      };

      mkSystem = extraModules: mkSystemFor system extraModules;

      mkInstaller = extraModules: lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = extraModules ++ baseModules ++ [{ nixpkgs.hostPlatform = system; }];
      };

      userLayers = {
        stags = [
          self.nixosModules.users-stags
          profileModules.workstation
          profileModules.niri
        ];
      };

      profileModules = {
        kodi = ./modules/dinOS/profiles/kodi.nix;
        niri = ./modules/dinOS/profiles/niri.nix;
        workstation = ./modules/dinOS/profiles/workstation.nix;
      };

      profileDeps = {
        niri = [ "workstation" ];
      };

      profileUsers = { };

      hostUsers = {
        ideapad3 = [ "stags" ];
        nuc14 = [ "stags" ];
        xps15 = [ "stags" ];
        z590i = [ "stags" ];
      };

      hostProfiles = {
        nuc14 = [ "kodi" ];
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
      overlays.default = overlays;
      packages.${system} = {
        inherit (pkgs) melia opencode-desktop proton-drive-cli;
      };
      packages.default = pkgs.opencode-desktop;
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
          nixpkgs-fmt
          nodejs_24
          pkgs-unstable.crystal
          pkgs-unstable.shards
          gtk4
          gtk4.dev
          glib.dev
          pkg-config
          opencode
        ];

        shellHook = ''
          export STARSHIP_CONFIG="$HOME/.config/starship/develop.toml"
        '';
      };

    };
}
