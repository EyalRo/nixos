# ideapad3-g: Guest machine with XFCE auto-login
# Theming reference: https://github.com/grassmunk/Chicago95

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # stags is the sudoer admin user
  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "wheel" "networkmanager" ];
    home = "/home/stags";
    uid = 1026;
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQ3ueSjCunmENDU8CMOKwoT+igDTQcG9R9sgzMPCquo EyalRo@users.noreply.github.com"
    ];
  };

  # Guest user for auto-login
  users.users.guest = {
    isNormalUser = true;
    description = "Guest";
    home = "/home/guest";
    createHome = true;
  };

  security.sudo.wheelNeedsPassword = false;

  # XFCE desktop with auto-login as guest
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "guest";

  # Google Chrome
  environment.systemPackages = with pkgs; [
    google-chrome
  ];

  # Chrome desktop shortcut for guest user
  systemd.tmpfiles.rules = [
    "d /home/guest/Desktop 0755 guest users -"
    "L+ /home/guest/Desktop/google-chrome.desktop - guest users - /run/current-system/sw/share/applications/google-chrome.desktop"
  ];

  time.timeZone = "America/Los_Angeles";
}
