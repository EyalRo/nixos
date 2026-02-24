{
  description = "NixOS configurations for dinOS with GNOME and impermanence defaults";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    agenix.url = "github:ryantm/agenix";
    opencode.url = "github:anomalyco/opencode/v1.2.9";
    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";
    commafiles.url = "github:Suya1671/commafiles";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, impermanence, agenix, opencode, niri-flake, commafiles, noctalia, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      overlays = {
        default = final: prev: {
          crystal-sysinfo = final.callPackage ./pkgs/crystal-sysinfo { crystal = pkgs-unstable.crystal; };
        };
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlays.default ];
      };
      
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        overlays = [ overlays.default ];
      };

      pkgs-aarch64 = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ overlays.default ];
      };

      hostDirs = lib.filterAttrs (name: v: v == "directory" && name != "types")
        (builtins.readDir ./hosts);

      hmDefaults = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
      };

      baseModules = [
        { nixpkgs.overlays = [ overlays.default inputs.niri-flake.overlays.niri ]; }
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
          profileModules.niri
        ];
      };

      profileModules = {
        headless = ./modules/dinOS/profiles/headless.nix;
        kodi = ./modules/dinOS/profiles/kodi.nix;
        server = ./modules/dinOS/profiles/server.nix;
        niri = ./modules/dinOS/profiles/niri.nix;
      };

      profileDeps = {
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

      mkSdImage = name: nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          (./hosts + "/${name}")
          ({ lib, pkgs, modulesPath, config, ... }: {
            imports = [
              "${nixos-hardware}/raspberry-pi/5"
              "${modulesPath}/installer/sd-card/sd-image.nix"
              "${modulesPath}/profiles/base.nix"
            ];
            
            nixpkgs.buildPlatform = "x86_64-linux";
            nixpkgs.config.allowUnfree = true;
            
            networking.hostName = lib.mkDefault name;
            
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            
            programs.fish.enable = true;
            users.defaultUserShell = pkgs.fish;
            
            boot.loader.grub.enable = false;
            boot.loader.generic-extlinux-compatible.enable = true;
            
            boot.consoleLogLevel = lib.mkDefault 7;
            boot.kernelParams = [
              "console=ttyAMA0,115200n8"
              "console=tty1"
            ];
            
            sdImage = {
              compressImage = false;
              
              populateFirmwareCommands = let
                configTxt = pkgs.writeText "config.txt" ''
                  [pi5]
                  kernel=kernel_2712.img
                  arm_64bit=1
                  enable_uart=1
                  uart_2ndstage=1
                  
                  [all]
                  arm_64bit=1
                  enable_uart=1
                  avoid_warnings=1
                '';
              in ''
                cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bootcode.bin firmware/ || true
                cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/fixup*.dat firmware/ || true
                cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/start*.elf firmware/ || true
                cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2712*.dtb firmware/ || true
                cp ${config.boot.kernelPackages.kernel}/Image firmware/kernel_2712.img
                cp ${configTxt} firmware/config.txt
              '';
              
              populateRootCommands = ''
                mkdir -p ./files/boot
                ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
              '';
            };
            
            services.openssh = {
              enable = true;
              settings.PermitRootLogin = "prohibit-password";
            };
            
            users.users.stags = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" ];
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQ3ueSjCunmENDU8CMOKwoT+igDTQcG9R9sgzMPCquo EyalRo@users.noreply.github.com"
              ];
            };
            
            security.sudo.wheelNeedsPassword = false;
            
            environment.systemPackages = with pkgs; [
              helix
              git
              parted
              e2fsprogs
              dosfstools
            ];
            
            system.stateVersion = "25.11";
          })
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
          opencode.packages.${system}.default
          pkgs-unstable.crystal
          pkgs-unstable.shards
          gtk4
          gtk4.dev
          glib.dev
          pkg-config
        ];

        shellHook = ''
          export STARSHIP_CONFIG=${./modules/dinOS/starship/develop.toml}
          if [ -z "$DIRENV_IN_ENVRC" ]; then
            exec ${pkgs.fish}/bin/fish -C 'set -g fish_greeting "" ; ${pkgs.starship}/bin/starship init fish | source'
          fi
        '';
      };

      sdImages = {
        rpi5-1 = (mkSdImage "rpi5-1").config.system.build.sdImage;
      };

    };
}
