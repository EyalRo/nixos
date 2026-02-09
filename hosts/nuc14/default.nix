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

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  environment.persistence."/persist" = {
    users.kodi = {
      directories = [ "." ];
    };
  };
}
