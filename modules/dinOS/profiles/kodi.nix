{ config, pkgs, lib, ... }:

let
  kodiPackage = pkgs.kodi.withPackages (kodiPkgs: [
    kodiPkgs.jellyfin
  ]);
in {
  users.users.kodi = {
    isNormalUser = true;
    description = "Kodi";
    home = "/home/kodi";
    createHome = true;
    initialHashedPassword = "";
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "kodi";
  };

  systemd.user.services.kodi-autostart = {
    description = "Autostart Kodi for the kodi user session";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      ConditionUser = "kodi";
    };
    serviceConfig = {
      ExecStart = "${kodiPackage}/bin/kodi";
      Restart = "on-failure";
    };
  };

  environment.systemPackages = [
    pkgs.gnomeExtensions.no-overview
    kodiPackage
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/shell" = {
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "caffeine@patapon.info"
          "no-overview@fthx"
        ];
      };
      settings."org/gnome/desktop/screensaver" = {
        idle-activation-enabled = false;
        lock-enabled = false;
      };
      settings."org/gnome/desktop/session" = {
        idle-delay = lib.gvariant.mkUint32 0;
      };
      settings."org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };
    }
  ];
}
