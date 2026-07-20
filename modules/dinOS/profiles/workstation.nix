{ pkgs, lib, ... }:

let
  gdmHiddenUserConf = pkgs.writeText "accounts-service-system-account" ''
    [User]
    SystemAccount=true
  '';
  dinoWallpaper = pkgs.runCommandLocal "wallpaper-dinosaur-picnic" { } ''
    set -euo pipefail
    install -Dm644 "${../wallpaper}/Dinosaur Picnic on a Sunny Hill.png" \
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
    install -Dm644 "${../wallpaper}/FriendlyPals-Day.png" \
      "$out/share/backgrounds/friendly-pals-day.png"
    install -Dm644 "${../wallpaper}/FriendlyPals-Night.png" \
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
in {
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,il";
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    cheese
    decibels
    epiphany
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
      nativeMessagingHosts = [
        pkgs.gnome-browser-connector
        pkgs.ff2mpv
      ];
    };
  };

  programs.nix-ld.enable = true;

  virtualisation.docker.enable = true;
  services.fwupd.enable = true;
  services.printing.enable = false;
  services.blueman.enable = false;
  services.gvfs.enable = true;

  environment.persistence."/persist".directories = [
    "/var/lib/docker"
    "/var/lib/fprint"
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/AccountsService/users 0755 root root -"
    "C+ /var/lib/AccountsService/users/root 0644 root root - ${gdmHiddenUserConf}"
  ];

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

  environment.systemPackages = with pkgs; [
    dinoWallpaper
    friendlyPalsWallpapers
    distrobox
    distroshelf
    fastfetch
    ghostty
    gnome-browser-connector
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.paperwm
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu-mono
    claude-code
    # QEMU/KVM sandbox deps for claude-desktop's Cowork feature
    qemu_kvm
    OVMF
    virtiofsd
    yt-dlp
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];
}
