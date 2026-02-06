{ config, pkgs, lib, ... }:

let
  # Stock nixpkgs Kodi. (Dolby Vision output is not supported on Linux Kodi, so
  # using upstream Kodi here implicitly prevents DV output while still allowing HDR10.)
  kodiPackage = pkgs.kodi.withPackages (kodiPkgs: [
    kodiPkgs.jellyfin
  ]);

  # PipeWire can remember sink volumes. If HDMI comes up quiet (e.g. 40%),
  # this wrapper forces the sink volume each time Kodi starts.
  #
  # Overrides (strings):
  # - KODI_HDMI_SINK_VOLUME: wpctl volume scalar (1.0 = 100%, 1.5 = 150%)
  # - KODI_STREAM_VOLUME: same, applied to the "Kodi" stream once it appears
  kodiWithVolume = pkgs.writeShellScript "kodi-with-volume" ''
    set -euo pipefail

    sink_vol="''${KODI_HDMI_SINK_VOLUME:-1.0}"
    stream_vol="''${KODI_STREAM_VOLUME:-1.0}"

    wpctl="${pkgs.wireplumber}/bin/wpctl"

    get_default_sink_id() {
      # Find the sink line marked with '*' and extract "<id>.".
      "$wpctl" status 2>/dev/null | sed -nE 's/^[[:space:]]*\\*[[:space:]]+([0-9]+)\\..*/\\1/p' | head -n1
    }

    get_kodi_stream_id() {
      # In Streams, Kodi typically shows as: "58. Kodi"
      "$wpctl" status 2>/dev/null | sed -nE 's/^[[:space:]]*([0-9]+)\\.[[:space:]]+Kodi$/\\1/p' | head -n1
    }

    # Wait briefly for PipeWire + WirePlumber to enumerate sinks.
    sink_id=""
    for _ in $(seq 1 50); do
      sink_id="$(get_default_sink_id || true)"
      [ -n "''${sink_id:-}" ] && break
      sleep 0.1
    done

    if [ -n "''${sink_id:-}" ]; then
      "$wpctl" set-volume "$sink_id" "$sink_vol" >/dev/null 2>&1 || true
    fi

    # Start Kodi, then (optionally) set the stream volume if it comes up low.
    ${kodiPackage}/bin/kodi-standalone &
    kodi_pid=$!

    if [ "''${stream_vol:-}" != "" ]; then
      stream_id=""
      for _ in $(seq 1 100); do
        stream_id="$(get_kodi_stream_id || true)"
        [ -n "''${stream_id:-}" ] && break
        sleep 0.1
      done
      if [ -n "''${stream_id:-}" ]; then
        "$wpctl" set-volume "$stream_id" "$stream_vol" >/dev/null 2>&1 || true
      fi
    fi

    wait "$kodi_pid"
  '';

  # Jellyfin configuration
  jellyfin-config = pkgs.writeText "jellyfin-config.xml" ''
    <advancedsettings>
      <network>
        <buffermode>1</buffermode>
        <cachemembuffersize>104857600</cachemembuffersize>
        <readbufferfactor>4.0</readbufferfactor>
      </network>
      <videolibrary>
        <importwatchedstate>true</importwatchedstate>
        <importresumepoint>true</importresumepoint>
      </videolibrary>
      <player>
        <usedvddevice>false</usedvddevice>
        <usebluray>false</usebluray>
      </player>
      <audio>
        <exclusiveAudio>true</exclusiveAudio>
        <resamplerquality>1</resamplerquality>
        <streamsilence>true</streamsilence>
      </audio>
      <gui>
        <debugloglevel>1</debugloglevel>
        <showloginfo>false</showloginfo>
      </gui>
    </advancedsettings>
  '';

  # Minimal Kodi sources. Jellyfin plugin will be configured from within Kodi UI.
  kodi-sources = pkgs.writeText "kodi-sources.xml" ''
    <sources>
      <video>
        <default pathversion="1"></default>
      </video>
      <music>
        <default pathversion="1"></default>
      </music>
      <pictures>
        <default pathversion="1"></default>
      </pictures>
      <files>
        <default pathversion="1"></default>
      </files>
    </sources>
  '';
in {
  users.users.kodi = {
    isNormalUser = true;
    description = "Kodi";
    home = "/home/kodi";
    createHome = true;
    initialHashedPassword = "";
    extraGroups = [ "audio" "video" "render" "input" ];
  };

  # Appliance mode: no full desktop environment.
  services.xserver.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;

  # Cage kiosk mode for Wayland
  services.cage = {
    enable = true;
    user = "kodi";
    program = "${kodiWithVolume}";
    extraArguments = [
      "-d"  # DRM/GBM backend
    ];
    environment = {
      # Prefer the modern Intel VAAPI driver (intel-media-driver).
      LIBVA_DRIVER_NAME = "iHD";
      # Enforce a sane default for HDMI volume each start (overrides remembered 40% cases).
      # You can bump this (e.g. "1.5") in a host config if needed.
      KODI_HDMI_SINK_VOLUME = "1.0";
      KODI_STREAM_VOLUME = "1.0";
    };
  };

  # Enable PipeWire for audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  environment.systemPackages = [
    kodiPackage
    pkgs.cage
    pkgs.libva-utils
  ];

  # Seed Kodi userdata on first boot (and keep user overrides after that).
  systemd.services.kodi-userdata-init = {
    description = "Initialize Kodi userdata (advancedsettings, sources) if missing";
    wantedBy = [ "graphical.target" ];
    before = [ "cage-tty1.service" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "kodi";
      Group = "users";
      ExecStart = pkgs.writeShellScript "kodi-userdata-init" ''
        set -euo pipefail
        ud="/home/kodi/.kodi/userdata"
        install -d -m 0755 "$ud"
        if [ ! -e "$ud/advancedsettings.xml" ]; then
          install -m 0644 ${jellyfin-config} "$ud/advancedsettings.xml"
        fi
        if [ ! -e "$ud/sources.xml" ]; then
          install -m 0644 ${kodi-sources} "$ud/sources.xml"
        fi
      '';
    };
  };

  # Enable hardware acceleration (main config already has intel-media-driver)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Performance tuning (these can be overridden in host configs)
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 10;
    "vm.vfs_cache_pressure" = lib.mkDefault 50;
  };

  # Removes the RTKit warning in `wpctl status` and improves scheduling for audio.
  security.rtkit.enable = true;
}
