{ config, pkgs, lib, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.niri-flake.overlays.niri
  ];

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  services.displayManager.sessionPackages = [ pkgs.niri ];

  systemd.services.nm-wake-reconnect = {
    description = "Reconnect WiFi after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = "${pkgs.networkmanager}/bin/nmcli networking on";
  };
}
