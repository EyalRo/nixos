{ config, pkgs, ... }:

{
  home.username = "stags";
  home.homeDirectory = "/home/stags";

  home.packages = with pkgs; [
    ghostty
    protonvpn-gui
    tailscale-systray
    wl-clipboard
    # pkgs.crystal-sysinfo
  ];

  systemd.user.services.tailscale-systray = {
    Unit = {
      Description = "Tailscale system tray";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service.ExecStart = "${pkgs.tailscale-systray}/bin/tailscale-systray";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      compression = true;
      forwardAgent = false;
      hashKnownHosts = true;
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
    };
    matchBlocks."github.com" = {
      user = "git";
      identityFile = "/mnt/stags/.ssh/id_ed25519_github";
      identitiesOnly = true;
    };
  };

  home.stateVersion = "25.11";
}
