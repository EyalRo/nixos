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
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  xdg.configFile."starship.toml".source = ./gruvbox-rainbow.toml;

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
    };
    "org/gnome/shell" = {
      enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" ];
    };
  };

  home.stateVersion = "25.11";
}
