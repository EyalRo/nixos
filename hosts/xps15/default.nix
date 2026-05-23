{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

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
    nvidiaPersistenced = lib.mkDefault false;
    prime.offload.enable = true;
    prime.offload.enableOffloadCmd = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
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

  # Route to K8s cluster network via MikroTik (USB Ethernet to 88.x is temporary)
  systemd.services.add-k8s-route = {
    description = "Add route to K8s cluster network via MikroTik";
    wantedBy = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.iproute2}/bin/ip route replace 192.168.88.0/24 via 192.168.0.101 || true
    '';
  };
}
