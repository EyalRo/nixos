# ideapad3-g: Guest machine with XFCE auto-login
# Theming reference: https://github.com/grassmunk/Chicago95

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Temporary: SSH key propagation is stuck (this host's local nixos checkout
  # is behind, see debugging session 2026-07-23) so allow password login as a
  # manual fallback. No hashedPassword is declared for stags/guest anywhere in
  # this repo, so `passwd` must be run locally/at console first — this alone
  # doesn't open anything up until an account actually has a password set.
  # Revert once the archdino key is confirmed working over SSH.
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  # Temporary: root login over SSH with a password, so commands can be
  # copy-pasted in directly for the stags UID reconciliation (2026-07-23)
  # rather than done at console. NixOS defaults this to prohibit-password.
  # Revert once that's done - this is a real loosening (LAN-reachable root
  # password auth), not something to leave on long-term.
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

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
    # Chicago95's bundled panel layout (Chicago95_Panel_Preferences.tar.bz2)
    # declares a whiskermenu panel plugin (the Win95 Start button) but this
    # package was never installed, so xfce4-panel has no plugin to load into
    # that slot - it renders broken/empty instead of failing loudly.
    xfce4-whiskermenu-plugin
    # Not in nixpkgs at all - packaged from upstream source, see
    # pkgs/xfce4-indicator-plugin and the note below in the autostart script
    # about why the imported profile's 'indicator' type string needs fixing.
    xfce4-indicator-plugin
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

      # guest has no password (locked account, autologin-only), so
      # xfce4-screensaver's default lock screen is an unauthenticatable dead
      # end, and its default lock/logout/enabled=true then force-ends the
      # session entirely after being locked too long - reported as "getting
      # logged out on idle". Screen dimming/blanking (saver/idle-activation)
      # is unaffected and still kicks in normally.
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-screensaver -p /lock/enabled -n -t bool -s false || true
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-screensaver -p /lock/logout/enabled -n -t bool -s false || true

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

      # Chicago95's own layout declares plugin-7 as type 'indicator', from
      # whatever xfce4-indicator-plugin version was current when this
      # profile was captured (~2015-2016, going by the launcher .desktop
      # filenames' unix timestamps). nixpkgs never packaged this plugin at
      # all (checked pkgs.xfce.* and a full package search), so it was
      # packaged from upstream source (pkgs/xfce4-indicator-plugin) -
      # current upstream (2.5.0) registers its module as 'indicator-plugin'
      # (X-XFCE-Module in its .desktop), not 'indicator', so the imported
      # config needs that one string corrected or xfce4-panel can't
      # resolve the type even with the package installed.
      #
      # plugin-8 'statusnotifier' is different: it's explicitly deprecated
      # upstream (its own docs say the functionality was folded into
      # xfce4-panel's systray as of 4.15, this system runs 4.20) and never
      # packaged in nixpkgs either, so it's dropped rather than built.
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-panel -p /plugins/plugin-7 -s "indicator-plugin" || true
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-panel -p /panels/panel-0/plugin-ids \
        -n -a -t int -s 1 -t int -s 2 -t int -s 14 -t int -s 15 -t int -s 16 \
        -t int -s 9 -t int -s 13 -t int -s 3 -t int -s 4 -t int -s 6 \
        -t int -s 5 -t int -s 7 -t int -s 10 -t int -s 11 -t int -s 12 || true
      ${pkgs.xfconf}/bin/xfconf-query -c xfce4-panel -p /plugins/plugin-8 -r -R || true

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
