{ config, pkgs, ... }:

{
  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
  };

  boot.supportedFilesystems = [ "cifs" ];

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Persist tailscale state and NAS credentials.
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale"
    ];
    users.stags = {
      directories = [ "." ];
    };
  };

  age.identityPaths = [ "/home/stags/.config/age/keys.txt" ];
  age.secrets."smb-credentials-nas" = {
    file = ../../secrets/smb-credentials-nas.age;
    path = "/persist/etc/smb-credentials-nas";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  fileSystems."/home/stags/NAS" = {
    device = "//nas.isdino.com/home";
    fsType = "cifs";
    options = let
      stagsUid = toString config.users.users.stags.uid;
      stagsGid = toString config.users.groups.${config.users.users.stags.group}.gid;
    in [
      "credentials=/persist/etc/smb-credentials-nas"
      "uid=${stagsUid}"
      "gid=${stagsGid}"
      "file_mode=0640"
      "dir_mode=0750"
      "vers=3.0"
      "iocharset=utf8"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.device-timeout=10s"
      "nofail"
    ];
  };

  home-manager.users.stags = import ../../home/stags;
}
