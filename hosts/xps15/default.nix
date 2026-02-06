{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "rd.udev.log_level=3"
    "acpi_osi=!Linux" # Better ACPI compatibility
    "acpi_osi=Windows2015" # Windows compatibility for better power management
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
    open = false;
    nvidiaPersistenced = true;
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  # Sleep/wake fixes for XPS15
  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };
  
  # Disable PS/2 mouse driver to prevent elantech errors
  # Touchpad uses I2C interface instead
  # Disable MEI to prevent hardware ready errors
  boot.blacklistedKernelModules = [ "psmouse" "mei_me" "mei_hdcp" "mei_pxp" ];
  
  # Disable specific ACPI wake events that cause immediate wake
  systemd.sleep.extraConfig = ''
    SuspendState=mem
    HibernateState=disk
    HybridSleepState=mem
  '';
  
  # ACPI wake event management
  services.udev.extraRules = ''
    # Disable XHC (USB controller) from waking system
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x9ded", ATTR{power/wakeup}="disabled"
    # Disable PEGP (NVIDIA GPU) from waking system  
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{device}=="*", ATTR{power/wakeup}="disabled"
  '';
}
