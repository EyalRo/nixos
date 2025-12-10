{ config, pkgs, ... }:

{
  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  home-manager.users.stags = import ../../home/stags;
}
