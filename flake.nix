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
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, impermanence, agenix, niri-flake, commafiles, noctalia, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs-unstable-no-overlays = import nixpkgs-unstable {
        inherit system;
      };

      overlays = final: prev: {
        crystal-sysinfo = final.callPackage ./pkgs/crystal-sysinfo { crystal = pkgs-unstable.crystal; };
        opencode-desktop = final.callPackage ./pkgs/opencode-desktop { };
        tailscale = pkgs-unstable-no-overlays.tailscale;
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

      pkgs-aarch64 = import nixpkgs {
        system = "aarch64-linux";
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
          profileModules.niri
        ];
      };

      profileModules = {
        headless = ./modules/dinOS/profiles/headless.nix;
        k3s = ./modules/dinOS/profiles/k3s.nix;
        kodi = ./modules/dinOS/profiles/kodi.nix;
        server = ./modules/dinOS/profiles/server.nix;
        niri = ./modules/dinOS/profiles/niri.nix;
      };

      profileDeps = {
        k3s = [ "headless" "server" ];
      };

      profileUsers = {
        server = [ "stags" ];
        k3s = [ "stags" ];
      };

      hostUsers = {
        ideapad3 = [ "stags" ];
        k8s-3 = [ "stags" ];
        k8s-4 = [ "stags" ];
        nuc14 = [ "stags" ];
        xps15 = [ "stags" ];
      };

      hostProfiles = {
        k8s-3 = [ "k3s" ];
        k8s-4 = [ "k3s" ];
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
        specialArgs = { inherit inputs; };
        modules = [
          ({ lib, pkgs, modulesPath, config, ... }: {
            nixpkgs.buildPlatform = "x86_64-linux";
            imports = [
              "${nixos-hardware}/raspberry-pi/5"
              "${modulesPath}/installer/sd-card/sd-image.nix"
            ];
            
            nixpkgs.hostPlatform = "aarch64-linux";
            nixpkgs.config.allowUnfree = true;
            
            networking.hostName = name;
            
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            
            boot.loader.grub.enable = false;
            boot.loader.generic-extlinux-compatible.enable = true;
            
            boot.consoleLogLevel = lib.mkDefault 7;
            boot.kernelParams = [
              "console=ttyAMA0,115200n8"
              "console=tty1"
              "cgroup_enable=cpuset"
              "cgroup_enable=memory"
              "cgroup_memory=1"
            ];

            boot.initrd.allowMissingModules = true;

            documentation.enable = false;
            documentation.nixos.enable = false;
            documentation.man.enable = false;
            documentation.info.enable = false;
            documentation.doc.enable = false;
            
            programs.bash.completion.enable = false;
            programs.fish.enable = false;
            
            services.openssh = {
              enable = true;
              settings.PermitRootLogin = "prohibit-password";
            };
            
            users.users.stags = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQ3ueSjCunmENDU8CMOKwoT+igDTQcG9R9sgzMPCquo EyalRo@users.noreply.github.com"
              ];
            };
            
            security.sudo.wheelNeedsPassword = false;
            
            environment.systemPackages = with pkgs; [
              git
              helix
            ];
            
            # Disable swap for Kubernetes
            swapDevices = [];
            
            sdImage = {
              compressImage = true;
              
              populateFirmwareCommands = let
                configTxt = pkgs.writeText "config.txt" ''
                  [pi5]
                  kernel=kernel_2712.img
                  arm_64bit=1
                  enable_uart=1
                  uart_2ndstage=1
                  
                  # PCIe/NVMe boot support
                  dtparam=pciex1
                  dtparam=pciex1_gen=3
                  
                  # USB power
                  usb_max_current_enable=1
                  
                  # NVMe boot overlay (uncomment if booting from NVMe)
                  # dtoverlay=pcie-32bit-dma
                  
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
            
            system.stateVersion = "26.05";
          })
        ];
      };

    in {
      overlays.default = overlays;
      packages.${system} = {
        inherit (pkgs) opencode-desktop;
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
        ];

        shellHook = ''
          export STARSHIP_CONFIG=${./modules/dinOS/starship/develop.toml}
        '';
      };

      raspi5 = (mkSdImage "raspi5").config.system.build.sdImage;

    };
}
