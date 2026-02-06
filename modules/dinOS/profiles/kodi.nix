{ config, pkgs, lib, ... }:

let
  # Standard Kodi package with optimizations
  kodiPackage = pkgs.kodi.withPackages (kodiPkgs: [
    kodiPkgs.jellyfin
  ]);
  
  # Optimized FFmpeg for Intel Quick Sync
  ffmpeg-optimized = pkgs.ffmpeg.override {
    withVdpau = false;
    withVaapi = true;
    withNvdec = false;
    withNvenc = false;
    withLibfdk_aac = true;
  };
  
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
in {
  users.users.kodi = {
    isNormalUser = true;
    description = "Kodi";
    home = "/home/kodi";
    createHome = true;
    initialHashedPassword = "";
    extraGroups = [ "audio" "video" "render" ];
  };

  # Cage kiosk mode for Wayland
  services.cage = {
    enable = true;
    user = "kodi";
    program = "${kodiPackage}/bin/kodi-standalone";
    extraArguments = [
      "-d"  # DRM/GBM backend
    ];
  };

  # Auto-login to tty for cage
  services.displayManager.autoLogin = {
    enable = true;
    user = "kodi";
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
  ];

  # Jellyfin configuration files
  environment.etc."kodi/userdata/advancedsettings.xml".source = jellyfin-config;
  environment.etc."kodi/userdata/sources.xml".text = ''
    <sources>
      <video>
        <default pathversion="1"></default>
        <source>
          <name>Jellyfin</name>
          <path pathversion="1">jellyfin://</path>
          <allowsharing>true</allowsharing>
        </source>
      </video>
    </sources>
  '';

  # Enable hardware acceleration (main config already has intel-media-driver)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver  # Fixed package name
      libvdpau-va-gl
    ];
  };

  # Performance tuning (these can be overridden in host configs)
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 10;
    "vm.vfs_cache_pressure" = lib.mkDefault 50;
  };

  # Systemd user service autostart
  systemd.user.services.cage-kodi-after-graphical = {
    description = "Start Cage Kodi after graphical session";
    after = [ "graphical-session-pre.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user start cage-kodi";
      RemainAfterExit = true;
    };
  };
}
