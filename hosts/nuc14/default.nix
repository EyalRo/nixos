{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Kodi appliance mode: no GNOME, no greeter, no Xorg on this host.
  services.xserver.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;
  services.displayManager.autoLogin.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;

  # Prefer HDMI sinks as the default when available. This helps a lot on HTPC
  # setups where the analog sink exists but isn't used.
  services.pipewire.wireplumber.extraConfig."51-prefer-hdmi" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_output\\..*hdmi.*"; }
        ];
        actions = {
          update-props = {
            # Sinks are typically ~600-1000; keep this below 1500.
            "priority.session" = 1200;
          };
        };
      }
    ];
  };


  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  hardware.firmware = with pkgs; [
    sof-firmware
  ];

  # Alder Lake-N PCH audio (8086:54c8): the SOF DSP driver (snd_sof_pci_intel_tgl) claims this
  # device via its wildcard alias but intermittently fails to initialize the Realtek ALC256 codec,
  # leaving no sound card registered. snd_hda_intel drives the HDA codec directly and reliably.
  boot.blacklistedKernelModules = [ "snd_sof_pci_intel_tgl" ];

  environment.etc."modprobe.d/nuc14-audio.conf".text = ''
    options snd_hda_intel power_save=0
  '';

  # Route to K8s cluster network via xps15 (dual-homed on 192.168.0.x and 192.168.88.x)
  networking.routes = [{
    address = "192.168.88.0";
    prefixLength = 24;
    via = "192.168.0.62";
  }];

  fileSystems."/mnt/nas-k8s" = {
    device = "nas:/volume1/k8s";
    fsType = "nfs4";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "soft"
      "noatime"
    ];
  };

  fileSystems."/media" = {
    device = "/mnt/nas-k8s/media-media-library-pvc-be51baa2-d7e2-4676-9de6-9961383f11bb";
    fsType = "none";
    options = [
      "bind"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
    ];
  };

  systemd.services.nuc14-media-retry = {
    description = "Retry NFS automounts for /media";
    serviceConfig = {
      Type = "oneshot";
    };
    path = with pkgs; [
      systemd
      util-linux
    ];
    script = ''
      set -euo pipefail
      systemctl reset-failed mnt-nas\\x2dk8s.automount || true
      systemctl reset-failed media.automount || true
      if ! mountpoint -q /media; then
        mount /media || true
      fi
    '';
  };

  systemd.timers.nuc14-media-retry = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  environment.persistence."/persist" = {
    users.kodi = {
      directories = [ "." ];
    };
  };
}
