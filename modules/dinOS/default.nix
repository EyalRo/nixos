{ config, pkgs, lib, ... }:

{
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = lib.mkDefault true;
  home-manager.sharedModules = [ ./home-manager.nix ];

  nix.package = lib.mkDefault pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  # Prefer newest kernel available in the pinned channel.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # kmscon disabled - causes display issues on some hardware
  # services.kmscon = {
  #   enable = true;
  # };

  # Enhanced console font setup for all TTYs  
  console = {
    earlySetup = true;
    packages = with pkgs; [ 
      kbd
    ];
    font = "lat9w-16";
    keyMap = lib.mkDefault "us";
  };
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = lib.mkDefault 5;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;



  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.dns = lib.mkDefault "systemd-resolved";
  networking.resolvconf.enable = lib.mkDefault false;
  security.sudo.enable = lib.mkDefault true;
  services.resolved.enable = lib.mkDefault true;

  # nsncd (nscd.service) can get restarted multiple times during activation when
  # NSS-related targets bounce; don't fail `switch-to-configuration` on start-limit.
  systemd.services.nscd.unitConfig.StartLimitIntervalSec = 0;

  services.avahi = {
    enable = lib.mkDefault true;
    publish = {
      enable = lib.mkDefault true;
      userServices = lib.mkDefault true;
    };
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  system.stateVersion = lib.mkDefault "25.11";

  # Persist baseline system state under /persist (impermanence).
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/lib/NetworkManager"
      "/var/lib/docker"
      "/var/lib/fprint"
      "/var/lib/nixos"
      "/var/log"
    ];
  };

  # Impermanence bind mounts require the source paths under /persist to exist
  # before the mount units run. Newer impermanence releases rely more on the
  # system to ensure these exist (rather than implicitly creating everything).
  systemd.tmpfiles.rules =
    let
      persistRoot = "/persist";
      mkDir = path: mode: user: group: "d ${path} ${mode} ${user} ${group} -";
      mkFile = path: mode: user: group: "f ${path} ${mode} ${user} ${group} - -";

      persistCfg = config.environment.persistence.${persistRoot} or {};
      dirEntries = persistCfg.directories or [];
      userDirEntries =
        let
          usersCfg = persistCfg.users or {};
        in
          lib.flatten (map (u: u.directories or [ ]) (lib.attrValues usersCfg));

      normalizeDirPath = p: lib.removeSuffix "/." p;

      mkPersistDir =
        entry:
          let
            e =
              if builtins.isString entry then {
                dirPath = entry;
                persistentStoragePath = persistRoot;
                user = "root";
                group = "root";
                mode = "0755";
              } else entry;
            storage = e.persistentStoragePath or persistRoot;
            dirPath = normalizeDirPath (e.dirPath or e.directory);
            fullPath = "${storage}${dirPath}";
            user = e.user or "root";
            group = if (e.group or null) == null then "root" else e.group;
            mode = e.mode or "0755";
          in
            mkDir fullPath mode user group;
    in
    [
    "d /persist 0755 root root -"
    "d /persist/etc 0755 root root -"
    (mkFile "/persist/etc/machine-id" "0644" "root" "root")
    "L+ /var/lib/dbus/machine-id - - - - /etc/machine-id"
    ]
    ++ map mkPersistDir (dirEntries ++ userDirEntries);

  # Shared wallpaper registered in GNOME backgrounds list.
  environment.systemPackages = let
    dinoWallpaper = pkgs.runCommandLocal "wallpaper-dinosaur-picnic" { } ''
      set -euo pipefail
      install -Dm644 "${./wallpaper}/Dinosaur Picnic on a Sunny Hill.png" \
        "$out/share/backgrounds/dinosaur-picnic.png"
      mkdir -p "$out/share/gnome-background-properties"
      cat > "$out/share/gnome-background-properties/dinosaur-picnic.xml" <<EOF
      <wallpapers>
        <wallpaper deleted="false">
          <name>Dinosaur Picnic</name>
          <filename>${"$"}{out}/share/backgrounds/dinosaur-picnic.png</filename>
          <filename-dark>${"$"}{out}/share/backgrounds/dinosaur-picnic.png</filename-dark>
          <options>scaled</options>
        </wallpaper>
      </wallpapers>
      EOF
    '';
    friendlyPalsWallpapers = pkgs.runCommandLocal "wallpaper-friendly-pals" { } ''
      set -euo pipefail
      install -Dm644 "${./wallpaper}/FriendlyPals-Day.png" \
        "$out/share/backgrounds/friendly-pals-day.png"
      install -Dm644 "${./wallpaper}/FriendlyPals-Night.png" \
        "$out/share/backgrounds/friendly-pals-night.png"
      mkdir -p "$out/share/gnome-background-properties"
      cat > "$out/share/gnome-background-properties/friendly-pals.xml" <<EOF
      <wallpapers>
        <wallpaper deleted="false">
          <name>Friendly Pals</name>
          <filename>${"$"}{out}/share/backgrounds/friendly-pals-day.png</filename>
          <filename-dark>${"$"}{out}/share/backgrounds/friendly-pals-night.png</filename-dark>
          <options>scaled</options>
        </wallpaper>
      </wallpapers>
      EOF
    '';
  in
    with pkgs; [
      dinoWallpaper
      friendlyPalsWallpapers
      distrobox
      distroshelf
      firefox
      fastfetch
      ghostty
      git
      helix
      gnome-browser-connector
      gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.caffeine
      gnomeExtensions.tiling-shell
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.ubuntu-mono
    ];

  # Provide a GNOME default wallpaper without forcing user overrides.
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings."org/gnome/desktop/background" = {
          picture-uri = "file:///run/current-system/sw/share/backgrounds/friendly-pals-day.png";
          picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/friendly-pals-night.png";
          picture-options = "scaled";
        };
      }
    ];
  };

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,il";
  services.xserver.desktopManager.xterm.enable = false;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];

  environment.gnome.excludePackages = with pkgs; [
    cheese
    decibels
    epiphany # GNOME Web
    geary
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-connections
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-tour
    gnome-weather
    rhythmbox
    simple-scan
    showtime
    totem
    yelp
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      nativeMessagingHosts = [ pkgs.gnome-browser-connector ];
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  virtualisation.docker.enable = true;

  services.fwupd.enable = true;
  services.printing.enable = false;
  services.blueman.enable = false;
}
