{ config, pkgs, lib, ... }:

let
  defaultTheme = ./starship/default.toml;
  developTheme = ./starship/develop.toml;
  gitTheme = ./starship/git.toml;
  configDir = config.xdg.configHome;
in {
  home.packages = with pkgs; [
    bat
    direnv
    lsd
    nix-direnv
    telegram-desktop
  ];

  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.direnv.enable = true;
  programs.direnv.silent = true;
  programs.direnv.nix-direnv.enable = true;
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting ""

      # Dynamically switch starship theme based on git repo detection.
      # Only switches when using default/git themes; preserves nix develop override.
      function _starship_switch_theme --on-variable PWD
        set -l base (basename "$STARSHIP_CONFIG" 2>/dev/null)
        if test -z "$base"; or test "$base" = "default.toml"; or test "$base" = "git.toml"
          if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set -gx STARSHIP_CONFIG "${configDir}/starship/git.toml"
          else
            set -gx STARSHIP_CONFIG "${configDir}/starship/default.toml"
          end
        end
      end
      # Initialize for the starting directory
      _starship_switch_theme

      # Synology NAS: use xterm-256color to avoid terminfo issues
      function ssh
        if test (count $argv) -gt 0
          switch $argv[1]
            case nas 192.168.0.100
              command ssh -t $argv "export TERM=xterm-256color; exec \$SHELL -l"
              return
          end
        end
        command ssh $argv
      end
    '';
  };
  xdg.configFile."fish/config.fish".force = true;

  xdg.configFile."fastfetch/afpp-ascii.txt".source = ./fastfetch/afpp-ascii.txt;
  xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # Point Starship at the default theme file instead of the root starship.toml.
    configPath = "${configDir}/starship/default.toml";
  };
  # develop.toml is read-only (noctalia doesn't touch it), so manage it normally.
  # default.toml must stay writable so noctalia's apply.sh can append the palette
  # section. Seed it only when it doesn't already exist (noctalia owns it after that).
  xdg.configFile."starship/develop.toml".source = developTheme;
  xdg.configFile."starship/git.toml".source = gitTheme;
  home.activation.seedStarshipDefaultTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${configDir}/starship/default.toml" ]; then
      $DRY_RUN_CMD mkdir -p "${configDir}/starship"
      $DRY_RUN_CMD install -m 644 ${defaultTheme} "${configDir}/starship/default.toml"
    fi
  '';

  # ghostty/config must be a writable regular file so noctalia's apply.sh can
  # append "theme = noctalia" to it. xdg.configFile would create a read-only symlink.
  home.activation.seedGhosttyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${configDir}/ghostty/config" ]; then
      $DRY_RUN_CMD mkdir -p "${configDir}/ghostty"
      $DRY_RUN_CMD install -m 644 /dev/stdin "${configDir}/ghostty/config" <<'EOF'
font-family = FiraCode Nerd Font
shell-integration-features = ssh-terminfo,ssh-env
EOF
    fi
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
        "paperwm@paperwm.github.com"
      ];
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-timeout = 0;
      sleep-inactive-battery-type = "nothing";
      idle-dim = false;
    };
  };
}
