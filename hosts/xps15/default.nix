{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/dinOS
  ];

  # Package the wallpaper and add it to the GNOME background list.
  environment.systemPackages = let
    dinoWallpaper = pkgs.runCommandLocal "wallpaper-dinosaur-picnic" { } ''
      set -euo pipefail
      install -Dm644 "${../../home/stags/wallpaper}/Dinosaur Picnic on a Sunny Hill.png" \
        "$out/share/backgrounds/dinosaur-picnic.png"
      mkdir -p "$out/share/gnome-background-properties"
      cat > "$out/share/gnome-background-properties/dinosaur-picnic.xml" <<EOF
      <wallpapers>
        <wallpaper deleted="false">
          <name>Dinosaur Picnic</name>
          <filename>${"$"}{out}/share/backgrounds/dinosaur-picnic.png</filename>
          <filename-dark>${"$"}{out}/share/backgrounds/dinosaur-picnic.png</filename-dark>
          <options>scaled</options>
        </wallpaper>
      </wallpapers>
      EOF
    '';
  in [ dinoWallpaper ];

  nixpkgs.config.allowUnfree = true;

  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems = [ "cifs" ];

  networking.hostName = "xps15";
  networking.networkmanager.enable = true;

  time.timeZone = lib.mkDefault "America/Los_Angeles";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
  hardware.graphics = {
    enable = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    prime.offload.enable = true;
    prime.offload.enableOffloadCmd = true;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,il";
  services.xserver.videoDrivers = [ "nvidia" "intel" ];
  # Add bus IDs for PRIME offloading if needed:
  # hardware.nvidia.prime = {
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };

  security.sudo.enable = true;

  users.users.stags = {
    isNormalUser = true;
    description = "stags";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  # Persist mutable state under /persist while keeping the system itself immutable.
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/lib/NetworkManager"
      "/var/lib/fprint"
      "/var/lib/tailscale"
      "/var/lib/nixos"
      "/var/log"
    ];
    users.stags = {
      directories = [ "." ];
    };
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  systemd.tmpfiles.rules = [
    "d /persist 0755 root root -"
    "d /persist/home 0755 root root -"
    "d /persist/etc 0755 root root -"
  ];

  age.identityPaths = [ "/home/stags/.config/age/keys.txt" ];
  age.secrets."smb-credentials-nas" = {
    file = ../../secrets/smb-credentials-nas.age;
    path = "/persist/etc/smb-credentials-nas";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  fileSystems."/home/stags/NAS" = {
    device = "//nas.isdino.com/home";
    fsType = "cifs";
    options = [
      "credentials=/persist/etc/smb-credentials-nas"
      "uid=1000"
      "gid=100"
      "file_mode=0640"
      "dir_mode=0750"
      "vers=3.0"
      "iocharset=utf8"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.device-timeout=10s"
      "nofail"
    ];
  };

  system.stateVersion = "25.11";
}
