{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable networking for remote access
  networking = {
    hostName = "nuc14";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Allow Kodi remote control (HTTP/JSON API) and SSH for remote management
      allowedTCPPorts = [ 22 8080 ];
      allowedUDPPorts = [ 8080 ];
    };
  };

  # SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    openFirewall = lib.mkDefault false; # Already handled by networking.firewall
  };

  # Hardware acceleration for Intel GPU
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Performance tuning for media playback
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # Power management for always-on HTPC
  powerManagement.enable = false; # Disable suspend for Kodi

  # Persistence setup
  environment.etc."machine-id".source = "/persist/etc/machine-id";

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/bluetooth"
    ];
    users.kodi = {
      home = "/home/kodi";
      directories = [ "." ];
    };
    users.root = {
      home = "/root";
      directories = [ ".ssh" ];
    };
  };

  # System packages for remote management
  environment.systemPackages = with pkgs; [
    # Remote access tools
    openssh
    networkmanager
    # Monitoring
    htop
    intel-gpu-tools
    # Filesystem
    nfs-utils
    cifs-utils  # For network shares
  ];

  # Time sync for media server communication
  services.timesyncd.enable = true;

  # Bluetooth for remote controllers (optional)
  hardware.bluetooth.enable = true;
  services.blueman.enable = lib.mkForce false;
}
