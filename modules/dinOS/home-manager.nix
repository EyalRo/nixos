{ config, pkgs, ... }:

let
  defaultTheme = ./starship/default.toml;
  developTheme = ./starship/develop.toml;
  configDir = config.xdg.configHome;
in {
  home.packages = with pkgs; [
    bat
    direnv
    fastfetch
    ghostty
    helix
    lsd
    nix-direnv
    telegram-desktop
  ];

  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.fish = {
    enable = true;
    shellAliases = {
      cat = "bat";
    };
  };
  xdg.configFile."fish/config.fish".force = true;

  xdg.configFile."fastfetch/afpp-ascii.txt".source = ./fastfetch/afpp-ascii.txt;
  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  xdg.configFile = {
    "starship/default.toml".source = defaultTheme;
    "starship/develop.toml".source = developTheme;
    "starship.toml" = {
      force = true;
      text = ''
        # Managed by Nix.
        # Default theme: ${configDir}/starship/default.toml (set via STARSHIP_CONFIG).
        # Dev shell overrides STARSHIP_CONFIG to ${configDir}/starship/develop.toml.
      '';
    };
  };

  home.sessionVariables.STARSHIP_CONFIG = "${configDir}/starship/default.toml";

  xdg.configFile."ghostty/config".text = ''
    font-family = FiraCode Nerd Font
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      clock-format = "24h";
    };
    "org/gnome/shell/extensions/caffeine" = {
      user-enabled = true;
      toggle-state = true;
    };
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "caffeine@patapon.info"
      ];
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };
}
