{ config, pkgs, lib, ... }:

{
  services.openssh.enable = true;
  
  networking.networkmanager.enable = true;
  
  system.stateVersion = "25.11";
}
