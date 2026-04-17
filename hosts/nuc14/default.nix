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

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  environment.persistence."/persist" = {
    users.kodi = {
      directories = [ "." ];
    };
  };
}
