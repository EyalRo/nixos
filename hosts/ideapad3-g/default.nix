# ideapad3-g: Guest machine with XFCE auto-login
# Theming reference: https://github.com/grassmunk/Chicago95

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Guest user for auto-login
  users.users.guest = {
    isNormalUser = true;
    description = "Guest";
    home = "/home/guest";
    createHome = true;
  };

  # XFCE desktop with auto-login as guest
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "guest";

  # Chicago95 theme configuration
  environment.systemPackages = with pkgs; [
    google-chrome
    chicago95
    xfce4-panel-profiles
  ];

  # Apply Chicago95 theme via xfconf-query at login
  systemd.services.chicago95-theme = {
    description = "Apply Chicago95 XFCE theme";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "guest";
      RemainAfterExit = true;
    };
    script = ''
      export DISPLAY=:0
      export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u guest)/bus
      
      # Wait for xfconfd to be ready
      sleep 2
      
      # Set GTK theme
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Net/ThemeName -s "Chicago95" || true
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Net/IconThemeName -s "Chicago95" || true
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Chicago95 Standard Cursors" || true
      ${pkgs.xfconf}/bin/xfconf-query -c xsettings -p /Gtk/DialogsUseHeader -s false || true
      
      # Set window manager theme
      ${pkgs.xfconf}/bin/xfconf-query -c xfwm4 -p /general/theme -s "Chicago95" || true
      ${pkgs.xfconf}/bin/xfconf-query -c xfwm4 -p /general/title_font -s "Sans Bold 8" || true
      
      # Set notification theme
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-notifyd -p /theme -s "Chicago95" || true
      
      # Set desktop background to teal (Win95 style)
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/color1 -s "#008080" || true
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/color-style -t int -s 0 || true
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style -t int -s 0 || true
    '';
  };

  # Plymouth boot splash with Chicago95 theme
  boot.plymouth.enable = true;
  boot.plymouth.theme = "Chicago95";
  boot.plymouth.themePackages = [ pkgs.chicago95 ];

  # Chrome desktop shortcut for guest user
  systemd.tmpfiles.rules = [
    "d /home/guest/Desktop 0755 guest users -"
    "L+ /home/guest/Desktop/google-chrome.desktop - guest users - /run/current-system/sw/share/applications/google-chrome.desktop"
  ];

  time.timeZone = "America/Los_Angeles";
}
