{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];


  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  environment.persistence."/persist" = {
    users.kodi = {
      home = "/home/kodi";
      directories = [ "." ];
    };
  };
}
