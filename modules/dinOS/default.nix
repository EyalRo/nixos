{ config, pkgs, lib, ... }:

{
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  home-manager.sharedModules = [ ./home-manager.nix ];

  nix.package = lib.mkDefault pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  # Persist baseline system state under /persist (impermanence).
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/lib/NetworkManager"
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
      install -Dm644 "${../../home/stags/wallpaper}/Dinosaur Picnic on a Sunny Hill.png" \
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
  in
    with pkgs; [
      firefox
      git
      gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.caffeine
      gnome-browser-connector
      nerd-fonts.fira-code
      dinoWallpaper
    ];

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,il";
  services.xserver.desktopManager.xterm.enable = false;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];

  environment.gnome.excludePackages = with pkgs; [
    decibels
    epiphany # GNOME Web
    geary
    gnome-calendar
    gnome-calculator
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-weather
    gnome-connections
    rhythmbox
    simple-scan
    showtime
    totem
    yelp
    cheese
    gnome-tour
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

  services.fwupd.enable = true;
  services.printing.enable = false;
  hardware.bluetooth.enable = true;
  services.blueman.enable = false;
}
