{ config, pkgs, lib, ... }:

let
  kodiPackage = pkgs.kodi-gbm.withPackages (kodiPkgs: [
    kodiPkgs.jellyfin
  ]);
in {
  users.users.kodi = {
    isNormalUser = true;
    description = "Kodi";
    home = "/home/kodi";
    createHome = true;
    initialHashedPassword = "";
    extraGroups = [
      "audio"
      "input"
      "render"
      "video"
    ];
  };

  # Reserve tty1 for Kodi (no getty prompt on the "TV" display).
  systemd.services."getty@tty1".enable = false;

  environment.systemPackages = [
    pkgs.alsa-utils
    kodiPackage
    # Ensure /run/current-system/sw/share/alsa-card-profile is present; WirePlumber
    # uses these profile-set files to create real HDMI/analog sinks.
    pkgs.pipewire
    pkgs.wireplumber # wpctl for debugging
  ];

  # Kodi as an appliance: no DE, no greeter, no Xorg; run directly on DRM/GBM.
  #
  # The PAM "login" session is important: it creates a proper logind session for
  # the user, grants device access (DRM/input/sound), and makes user services
  # like PipeWire / WirePlumber work as expected.
  systemd.services.kodi = {
    description = "Kodi (DRM/GBM)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-user-sessions.service"
      "network-online.target"
      "sound.target"
    ];
    wants = [ "network-online.target" ];
    conflicts = [ "getty@tty1.service" ];

    serviceConfig = {
      Type = "simple";
      User = "kodi";
      PAMName = "login";

      WorkingDirectory = "/home/kodi";
      Environment = [
        "HOME=/home/kodi"
      ];

      # Attach Kodi to tty1 (TV) and keep it "appliance-like".
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      StandardInput = "tty";

      ExecStart = "${kodiPackage}/bin/kodi";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
