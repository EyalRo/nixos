{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "docker" "kvm" "networkmanager" "wheel" ];
    home = "/home/stags";
    uid = 1026;
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQ3ueSjCunmENDU8CMOKwoT+igDTQcG9R9sgzMPCquo EyalRo@users.noreply.github.com"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Avatar configuration for stags
  environment.etc."avatars/stags.png".source = ../../users/stags-avatar.png;
  environment.etc."skel/.face".source = ../../users/stags-avatar.png;
  systemd.tmpfiles.rules = [
    "L+ /home/stags/.face - - - - /etc/avatars/stags.png"
    "L+ /var/lib/AccountsService/icons/stags - - - - /etc/avatars/stags.png"
  ];
  
  # Add stags avatar to system faces directory for GNOME avatar picker
  # Terminal-only system packages
  environment.systemPackages = with pkgs; [
    (pkgs.runCommand "stags-avatar" {} ''
      mkdir -p $out/share/pixmaps/faces
      cp ${../../users/stags-avatar.png} $out/share/pixmaps/faces/stags.png
    '')
    pkgs.nh
    fastfetch
    claude-code
    distrobox
    distroshelf
    yt-dlp
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu-mono
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
    extraUpFlags = [ "--accept-routes" ];
  };

  services.nfs.idmapd.settings = {
    Domain = "localdomain";
  };

  age.identityPaths = [
    "/mnt/stags/.config/age/keys.txt"
  ];

  fileSystems."/mnt/stags" = {
    device = "192.168.0.100:/volume1/homes/Eyal";
    fsType = "nfs";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "vers=3"
    ];
  };

  fileSystems."/mnt/shared" = {
    device = "192.168.0.100:/volume1/Shared";
    fsType = "nfs";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "vers=3"
    ];
  };

  fileSystems."/mnt/media" = {
    device = "192.168.0.100:/volume1/k8s/media-media-library-pvc-be51baa2-d7e2-4676-9de6-9961383f11bb";
    fsType = "nfs";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "vers=3"
    ];
  };

  systemd.services.nfs-mounts-retry = {
    description = "Retry NFS automounts for /mnt/stags, /mnt/shared, and /mnt/media";
    serviceConfig = {
      Type = "oneshot";
    };
    path = [
      pkgs.systemd
      pkgs.util-linux
    ];
    script = ''
      set -euo pipefail
      systemctl reset-failed mnt-stags.automount mnt-shared.automount mnt-media.automount || true
      if ! mountpoint -q /mnt/stags; then
        mount /mnt/stags || true
      fi
      if ! mountpoint -q /mnt/shared; then
        mount /mnt/shared || true
      fi
      if ! mountpoint -q /mnt/media; then
        mount /mnt/media || true
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
}
