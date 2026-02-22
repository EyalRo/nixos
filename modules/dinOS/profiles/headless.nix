{ lib, ... }:

{
  # Headless override: disable GNOME/Wayland/X for server nodes.
  services.xserver.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;
}
