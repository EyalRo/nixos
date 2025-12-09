{ config, pkgs, ... }:

{
  home.username = "stags";
  home.homeDirectory = "/home/stags";

  home.packages = with pkgs; [
    bat
    direnv
    firefox
    git
    ghostty
    helix
    lsd
    nix-direnv
    telegram-desktop
    protonvpn-gui
    tailscale-systray
    fastfetch
  ];

  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.fish = {
    enable = true;
    shellAliases = {
      cat = "bat";
      ls = "lsd";
    };
  };
  xdg.configFile."fish/config.fish".force = true;
  systemd.user.services.tailscale-systray = {
    Unit = {
      Description = "Tailscale system tray";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service.ExecStart = "${pkgs.tailscale-systray}/bin/tailscale-systray";
    Install.WantedBy = [ "graphical-session.target" ];
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  xdg.configFile."starship.toml".source = ./gruvbox-rainbow.toml;
  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;

  xdg.configFile."ghostty/config".text = ''
    font-family = FiraCode Nerd Font
  '';

  # Example GNOME settings (extend as needed).
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      clock-format = "24h";
    };
    "org/gnome/shell/extensions/caffeine" = {
      user-enabled = true;
      toggle-state = true;
    };
    "org/gnome/shell" = {
      enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" ];
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  home.stateVersion = "25.11";
}
