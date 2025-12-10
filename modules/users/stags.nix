{ config, pkgs, ... }:

{
  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  home-manager.users.stags = import ../../home/stags;
}
