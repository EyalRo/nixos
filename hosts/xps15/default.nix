{ config, pkgs, inputs, lib, ... }:

let
  unstable-pkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Use systemd from unstable to fix double-suspend bug in v258
  systemd.package = unstable-pkgs.systemd;

  boot.kernelPackages = unstable-pkgs.linuxPackages;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rd.udev.log_level=3"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaPersistenced = true;
    prime.offload.enable = true;
    prime.offload.enableOffloadCmd = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    package = unstable-pkgs.linuxPackages.nvidiaPackages.latest;
  };
  services.xserver.videoDrivers = [ "nvidia" "intel" ];
  # Add bus IDs for PRIME offloading if needed:
  # hardware.nvidia.prime = {
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    InhibitDelayMaxSec = 5;
  };

  systemd.user.services.swayidle = {
    description = "Idle manager for Wayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 1800 'niri msg action power-off-monitors' timeout 3600 'systemctl suspend'";
      Restart = "on-failure";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  # Disable PS/2 mouse driver to prevent elantech errors
  # Touchpad uses I2C interface instead
  # Disable MEI to prevent hardware ready errors
  boot.blacklistedKernelModules = [ "psmouse" "mei_me" "mei_hdcp" "mei_pxp" ];
}
