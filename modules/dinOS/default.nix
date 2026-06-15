{ config, pkgs, lib, ... }:

{
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = lib.mkDefault true;
  home-manager.sharedModules = [ ./home-manager.nix ];

  nix.package = lib.mkDefault pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  console = {
    earlySetup = true;
    packages = with pkgs; [ kbd ];
    font = "lat9w-16";
    keyMap = lib.mkDefault "us";
  };

  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = lib.mkDefault 5;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.dns = lib.mkDefault "systemd-resolved";
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "nm-dispatcher-dns" ''
        case "$2" in
          up)
            ${pkgs.systemd}/bin/resolvectl dns "$1" 192.168.0.30
            ;;
        esac
      '';
      type = "basic";
    }
    {
      source = pkgs.writeShellScript "nm-dispatcher-k8s-route" ''
        case "$2" in
          up)
            ${pkgs.iproute2}/bin/ip route replace 192.168.88.0/24 via 192.168.0.101 || true
            ;;
        esac
      '';
      type = "basic";
    }
  ];
  networking.nameservers = lib.mkDefault [ "192.168.0.30" ];
  networking.resolvconf.enable = lib.mkDefault false;
  security.sudo.enable = lib.mkDefault true;
  services.resolved.enable = lib.mkDefault true;

  # nsncd (nscd.service) can get restarted multiple times during activation when
  # NSS-related targets bounce; don't fail `switch-to-configuration` on start-limit.
  systemd.services.nscd.unitConfig.StartLimitIntervalSec = 0;

  services.avahi = {
    enable = lib.mkDefault true;
    publish = {
      enable = lib.mkDefault true;
      userServices = lib.mkDefault true;
    };
  };

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  system.stateVersion = lib.mkDefault "25.11";

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/ssh"
      "/var/lib/NetworkManager"
      "/var/lib/nixos"
      "/var/log"
    ];
  };

  systemd.tmpfiles.rules =
    let
      persistRoot = "/persist";
      mkDir = path: mode: user: group: "d ${path} ${mode} ${user} ${group} -";
      mkFile = path: mode: user: group: "f ${path} ${mode} ${user} ${group} - -";

      persistCfg = config.environment.persistence.${persistRoot} or {};
      dirEntries = persistCfg.directories or [];
      userDirEntries =
        let
          usersCfg = persistCfg.users or {};
        in
          lib.flatten (map (u: u.directories or [ ]) (lib.attrValues usersCfg));

      normalizeDirPath = p: lib.removeSuffix "/." p;

      mkPersistDir =
        entry:
          let
            e =
              if builtins.isString entry then {
                dirPath = entry;
                persistentStoragePath = persistRoot;
                user = "root";
                group = "root";
                mode = "0755";
              } else entry;
            storage = e.persistentStoragePath or persistRoot;
            dirPath = normalizeDirPath (e.dirPath or e.directory);
            fullPath = "${storage}${dirPath}";
            user = e.user or "root";
            group = if (e.group or null) == null then "root" else e.group;
            mode = e.mode or "0755";
          in
            mkDir fullPath mode user group;
    in
    [
      "d /persist 0755 root root -"
      "d /persist/etc 0755 root root -"
      (mkFile "/persist/etc/machine-id" "0644" "root" "root")
      "L+ /var/lib/dbus/machine-id - - - - /etc/machine-id"
    ]
    ++ map mkPersistDir (dirEntries ++ userDirEntries);

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings.PasswordAuthentication = false;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  # NFS client support
  boot.supportedFilesystems = [ "nfs4" ];
  services.rpcbind.enable = true;

  environment.systemPackages = with pkgs; [
    git
    helix
  ];
}
