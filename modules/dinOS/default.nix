{ config, pkgs, lib, ... }:

{
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

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
    ];
  };

  environment.systemPackages = with pkgs; [
    firefox
    git
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnome-browser-connector
  ];
}
