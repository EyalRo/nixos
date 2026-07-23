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

  # Apply Chicago95 theme via XDG autostart (runs in guest's XFCE session)
  environment.etc."xdg/autostart/chicago95-theme.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Chicago95 Theme
    Exec=${pkgs.writeShellScript "chicago95-theme" ''
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

      # The GTK/xfwm4/notifyd theme names above only restyle widgets and
      # window borders. The top/bottom panel's own layout (Win95 taskbar
      # with Start button, tray placement, etc.) is a separate panel
      # profile bundled by Chicago95 and has to be imported explicitly, or
      # the panels stay on XFCE's default vanilla layout.
      ${pkgs.xfce4-panel-profiles}/bin/xfce4-panel-profiles load \
        "${pkgs.chicago95}/share/xfce4-panel-profiles/layouts/Chicago95_Panel_Preferences.tar.bz2" || true

      # Bind Super to pop up the applications menu (Win95 Start-button
      # behavior). XFCE doesn't bind the Super key to anything by default,
      # so without this the key does nothing.
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/<Super>" -n -t string -s "xfce4-popup-applicationsmenu" || true
    ''}
    Terminal=false
    NoDisplay=true
    X-GNOME-Autostart-Phase=Applications
  '';

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
