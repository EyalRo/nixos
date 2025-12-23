{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
    home = "/home/stags";
    uid = 1026;
    createHome = true;
  };

  time.timeZone = lib.mkDefault "America/Los_Angeles";

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  services.nfs.idmapd.settings = {
    General = {
      Domain = "localdomain";
    };
  };

  age.identityPaths = [
    "/mnt/stags/.config/age/keys.txt"
  ];

  fileSystems."/mnt/stags" = {
    device = "nas.dino.home:/volume1/homes/Eyal";
    fsType = "nfs4";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
    ];
  };

  fileSystems."/mnt/shared" = {
    device = "nas.dino.home:/volume1/Shared";
    fsType = "nfs4";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
    ];
  };

  # Persist tailscale state.
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale"
    ];
    users.stags = {
      home = "/home/stags";
      directories = [ "." ];
    };
  };

  home-manager.users.stags = import ../../home/stags;
}
