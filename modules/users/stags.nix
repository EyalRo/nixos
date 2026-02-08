{ config, lib, ... }:

{
  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    uid = 1026;
    group = "stags";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
  };

  users.groups.stags = {
    gid = 1026;
  };

  time.timeZone = lib.mkDefault "America/Los_Angeles";

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Persist tailscale state.
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale"
    ];
    users.stags = {
      directories = [ "." ];
    };
  };

  age.identityPaths = [ "/home/stags/.config/age/keys.txt" ];

  home-manager.users.stags = import ../../home/stags;
}
