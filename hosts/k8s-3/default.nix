{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ];

  dinOS.profiles.k3s = {
    enable = true;
    role = "agent";
    # Set these when joining the cluster:
    # serverUrl = "https://k8s-1:6443";
    # tokenFile = "/persist/etc/k3s-token";
  };

  # Hardware-specific filesystem configuration
  # Adjust these to match your actual partition layout
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_BOOT";
    fsType = "vfat";
  };

  # NVMe SSD configuration (if using PCIe HAT for boot)
  # The nixos-hardware profile already loads nvme and pcie-brcmstb initrd modules

  # Bootloader — RPi5 uses extlinux, not systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Networking
  networking.hostName = "k8s-3";
  networking.networkmanager.enable = true;

  # SSH access for remote management
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  # Passwordless SSH for stags user
  users.users.stags.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQ3ueSjCunmENDU8CMOKwoT+igDTQcG9R9sgzMPCquo EyalRo@users.noreply.github.com"
  ];

  # Passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # GPU/display not needed for headless k8s node
  services.xserver.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;
  services.desktopManager.gnome.enable = lib.mkForce false;

  # Minimal environment for server nodes
  environment.systemPackages = with pkgs; [
    git
    helix
    kubectl
  ];

  # Persist essential state
  environment.etc."machine-id".source = "/persist/etc/machine-id";

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/k3s"
    ];
  };

  system.stateVersion = "25.11";
}
