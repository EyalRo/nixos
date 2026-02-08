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

  # Avatar configuration for stags
  environment.etc."avatars/stags.png".source = ./stags-avatar.png;
  environment.etc."skel/.face".source = ./stags-avatar.png;
  systemd.tmpfiles.rules = [
    "L+ /home/stags/.face - - - - /etc/avatars/stags.png"
    "L+ /var/lib/AccountsService/icons/stags - - - - /etc/avatars/stags.png"
  ];
  
  # Add stags avatar to system faces directory for GNOME avatar picker
  environment.systemPackages = [
    (pkgs.runCommand "stags-avatar" {} ''
      mkdir -p $out/share/pixmaps/faces
      cp ${./stags-avatar.png} $out/share/pixmaps/faces/stags.png
    '')
    pkgs.nh
  ];
  
  # GDM login screen avatar configuration
  environment.etc."accountsservice/users/stags".text = ''
[User]
Language=
Session=gnome
XSession=gnome
Icon=/var/lib/AccountsService/icons/stags
SystemAccount=false
'';

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

  systemd.services.nfs-mounts-retry = {
    description = "Retry NFS automounts for /mnt/stags and /mnt/shared";
    serviceConfig = {
      Type = "oneshot";
    };
    path = [
      pkgs.systemd
      pkgs.util-linux
    ];
    script = ''
      set -euo pipefail
      systemctl reset-failed mnt-stags.automount mnt-shared.automount || true
      if ! mountpoint -q /mnt/stags; then
        mount /mnt/stags || true
      fi
      if ! mountpoint -q /mnt/shared; then
        mount /mnt/shared || true
      fi
    '';
  };

  systemd.timers.nfs-mounts-retry = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };

  # Persist tailscale state.
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/tailscale"
    ];
    users.stags = {
      directories = [ "" ];
    };
  };

  home-manager.users.stags = import ../../home/stags;
}
