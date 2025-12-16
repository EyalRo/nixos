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
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = lib.mkDefault 5;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  networking.networkmanager.enable = lib.mkDefault true;
  security.sudo.enable = lib.mkDefault true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  system.stateVersion = lib.mkDefault "25.11";

  # Persist baseline system state under /persist (impermanence).
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/docker"
      "/var/lib/fprint"
      "/var/lib/nixos"
      "/var/log"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /persist 0755 root root -"
    "d /persist/home 0755 root root -"
    "d /persist/etc 0755 root root -"
  ];

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
      git
      gnome-browser-connector
      gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.caffeine
      nerd-fonts.fira-code
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
    nativeMessagingHosts.packages = [ pkgs.gnome-browser-connector ];
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
