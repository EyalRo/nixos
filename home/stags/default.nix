{ config, pkgs, lib, inputs, ... }:

let
  mediawatchPanelEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);
  mediawatch-panel = pkgs.writeShellScriptBin "mediawatch-panel" ''
    export GI_TYPELIB_PATH="${pkgs.gtk4-layer-shell}/lib/girepository-1.0:''${GI_TYPELIB_PATH:-}"
    exec ${mediawatchPanelEnv}/bin/python3 "$HOME/.local/share/noctalia-local-plugins/mediawatch/panel.py" "$@"
  '';
in

{
  imports = [
    inputs.noctalia.homeModules.default
    inputs.niri-flake.homeModules.niri
  ];

  home.username = "stags";
  home.homeDirectory = "/home/stags";

  programs.niri = {
    package = pkgs.niri-unstable;
    settings = {
      spawn-at-startup = [
        {
          command = [ "noctalia" ];
        }
      ];
      input = {
        keyboard = {
          xkb = {
            layout = "us,il";
          };
        };
        touchpad = {
          click-method = "clickfinger";
        };
      };
      gestures = {
        hot-corners = {
          enable = false;
        };
      };
      outputs = {
        "DP-5" = {
          position = { x = 0; y = 0; };
        };
        "eDP-1" = {
          position = { x = 0; y = 1080; };
        };
      };
      window-rules = [
        {
          matches = [{ app-id = "io.stags.mediawatch-panel"; }];
          open-floating = true;
        }
      ];
      binds = {
        "Super+Space" = {
          action = {
            spawn-sh = "current=$(niri msg keyboard-layouts | grep '\\*' | head -1 | grep -o '[0-9]\\+'); niri msg action switch-layout $((1 - current))";
          };
          hotkey-overlay.title = "Switch keyboard layout";
        };
        "Mod+Shift+Slash" = {
          action = {
            show-hotkey-overlay = { };
          };
          hotkey-overlay.title = "Show important hotkeys";
        };
        "Mod+T" = {
          action = {
            spawn-sh = "ghostty";
          };
          hotkey-overlay.title = "Open terminal";
        };
        "Mod+D" = {
          action = {
            spawn-sh = "noctalia msg panel-toggle launcher";
          };
          hotkey-overlay.title = "Open launcher";
        };
        "Super+Alt+L" = {
          action = {
            spawn-sh = "noctalia msg session lock";
          };
          hotkey-overlay.title = "Lock screen";
        };
        "Mod+Q" = {
          action = {
            close-window = { };
          };
        };
        "Mod+H" = {
          action = {
            focus-column-left = { };
          };
        };
        "Mod+L" = {
          action = {
            focus-column-right = { };
          };
        };
        "Mod+J" = {
          action = {
            focus-window-down = { };
          };
        };
        "Mod+K" = {
          action = {
            focus-window-up = { };
          };
        };
        "Mod+Left" = {
          action = {
            focus-column-left = { };
          };
        };
        "Mod+Right" = {
          action = {
            focus-column-right = { };
          };
        };
        "Mod+Down" = {
          action = {
            focus-window-down = { };
          };
        };
        "Mod+Up" = {
          action = {
            focus-window-up = { };
          };
        };
        "Mod+Control+H" = {
          action = {
            move-column-left = { };
          };
        };
        "Mod+Control+L" = {
          action = {
            move-column-right = { };
          };
        };
        "Mod+Control+J" = {
          action = {
            move-window-down = { };
          };
        };
        "Mod+Control+K" = {
          action = {
            move-window-up = { };
          };
        };
        "Mod+Control+Left" = {
          action = {
            move-column-left = { };
          };
        };
        "Mod+Control+Right" = {
          action = {
            move-column-right = { };
          };
        };
        "Mod+Control+Down" = {
          action = {
            move-window-down = { };
          };
        };
        "Mod+Control+Up" = {
          action = {
            move-window-up = { };
          };
        };
        "Mod+Shift+H" = {
          action = {
            focus-monitor-left = { };
          };
        };
        "Mod+Shift+L" = {
          action = {
            focus-monitor-right = { };
          };
        };
        "Mod+Shift+J" = {
          action = {
            focus-monitor-down = { };
          };
        };
        "Mod+Shift+K" = {
          action = {
            focus-monitor-up = { };
          };
        };
        "Mod+Shift+Left" = {
          action = {
            focus-monitor-left = { };
          };
        };
        "Mod+Shift+Right" = {
          action = {
            focus-monitor-right = { };
          };
        };
        "Mod+Shift+Down" = {
          action = {
            focus-monitor-down = { };
          };
        };
        "Mod+Shift+Up" = {
          action = {
            focus-monitor-up = { };
          };
        };
        "Mod+Control+Shift+H" = {
          action = {
            move-column-to-monitor-left = { };
          };
        };
        "Mod+Control+Shift+L" = {
          action = {
            move-column-to-monitor-right = { };
          };
        };
        "Mod+Control+Shift+J" = {
          action = {
            move-column-to-monitor-down = { };
          };
        };
        "Mod+Control+Shift+K" = {
          action = {
            move-column-to-monitor-up = { };
          };
        };
        "Mod+Control+Shift+Left" = {
          action = {
            move-column-to-monitor-left = { };
          };
        };
        "Mod+Control+Shift+Right" = {
          action = {
            move-column-to-monitor-right = { };
          };
        };
        "Mod+Control+Shift+Down" = {
          action = {
            move-column-to-monitor-down = { };
          };
        };
        "Mod+Control+Shift+Up" = {
          action = {
            move-column-to-monitor-up = { };
          };
        };
        "Mod+U" = {
          action = {
            focus-workspace-down = { };
          };
        };
        "Mod+I" = {
          action = {
            focus-workspace-up = { };
          };
        };
        "Mod+Control+U" = {
          action = {
            move-column-to-workspace-down = { };
          };
        };
        "Mod+Control+I" = {
          action = {
            move-column-to-workspace-up = { };
          };
        };
        "Mod+Shift+U" = {
          action = {
            move-workspace-down = { };
          };
        };
        "Mod+Shift+I" = {
          action = {
            move-workspace-up = { };
          };
        };
        "Mod+BracketLeft" = {
          action = {
            consume-or-expel-window-left = { };
          };
        };
        "Mod+BracketRight" = {
          action = {
            consume-or-expel-window-right = { };
          };
        };
        "Mod+O" = {
          action = {
            toggle-overview = { };
          };
          hotkey-overlay.title = "Toggle overview";
        };
        "Mod+R" = {
          action = {
            switch-preset-column-width = { };
          };
        };
        "Mod+Shift+R" = {
          action = {
            switch-preset-window-height = { };
          };
        };
        "Mod+F" = {
          action = {
            maximize-column = { };
          };
        };
        "Mod+C" = {
          action = {
            center-column = { };
          };
        };
        "Mod+Minus" = {
          action = {
            set-column-width = "-10%";
          };
        };
        "Mod+Equal" = {
          action = {
            set-column-width = "+10%";
          };
        };
        "Mod+Shift+Minus" = {
          action = {
            set-window-height = "-10%";
          };
        };
        "Mod+Shift+Equal" = {
          action = {
            set-window-height = "+10%";
          };
        };
        "Mod+Control+R" = {
          action = {
            reset-window-height = { };
          };
        };
        "Mod+V" = {
          action = {
            toggle-window-floating = { };
          };
        };
        "Mod+Shift+V" = {
          action = {
            switch-focus-between-floating-and-tiling = { };
          };
        };
        "Print" = {
          action = {
            screenshot = { };
          };
        };
        "Alt+Print" = {
          action = {
            screenshot-window = { };
          };
        };
        "Control+Print" = {
          action = {
            screenshot-screen = { };
          };
        };
        "Mod+Shift+E" = {
          action = {
            quit = { };
          };
        };
        "Control+Alt+Delete" = {
          action = {
            quit = { };
          };
        };
        "Super+Return" = {
          action = {
            spawn-sh = "ghostty";
          };
          hotkey-overlay.title = "Open terminal";
        };
        "Mod+B" = {
          action = {
            spawn-sh = "gtk-launch firefox 2>/dev/null || gtk-launch org.mozilla.firefox 2>/dev/null || nohup firefox &";
          };
          hotkey-overlay.title = "Open browser";
        };
        "Mod+S" = {
          action = {
            spawn-sh = "noctalia msg panel-toggle control-center";
          };
          hotkey-overlay.title = "Open control center";
        };
        "XF86AudioRaiseVolume" = {
          action = {
            spawn-sh = "noctalia msg volume-up";
          };
          hotkey-overlay.title = "Increase volume";
        };
        "XF86AudioLowerVolume" = {
          action = {
            spawn-sh = "noctalia msg volume-down";
          };
          hotkey-overlay.title = "Decrease volume";
        };
        "XF86AudioMute" = {
          action = {
            spawn-sh = "noctalia msg volume-mute";
          };
          hotkey-overlay.title = "Mute volume";
        };
        "XF86MonBrightnessUp" = {
          action = {
            spawn-sh = "noctalia msg brightness-up";
          };
          hotkey-overlay.title = "Increase brightness";
        };
        "XF86MonBrightnessDown" = {
          action = {
            spawn-sh = "noctalia msg brightness-down";
          };
          hotkey-overlay.title = "Decrease brightness";
        };
      };
    };
  };

  programs.noctalia = {
    enable = true;
    settings = {
      bar.default.end = [
        "stags/mediawatch:widget"
        "media"
        "tray"
        "notifications"
        "clipboard"
        "network"
        "bluetooth"
        "keyboard-layout"
        "volume"
        "brightness"
        "battery"
        "control-center"
        "session"
      ];
      "plugin_settings"."stags/mediawatch" = {
        base_url = "https://mediawatch.virtualdino.com";
      };
    };
  };

  # Clone the personal noctalia plugins repo on first setup; leave it alone on rebuilds
  # so local edits and git history are preserved.
  home.activation.cloneNoctaliaPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    plugins_dir="$HOME/.local/share/noctalia-local-plugins"
    if [ ! -d "$plugins_dir/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://forgejo.virtualdino.com/stags/noctalia-plugins.git "$plugins_dir"
    fi
  '';

  # Noctalia scans ~/.config/noctalia/plugins/ (configDir + "plugins"), not the XDG data dir.
  # Symlink each plugin subdirectory so edits are reflected immediately without a nixos-rebuild.
  home.activation.linkNoctaliaPlugins = lib.hm.dag.entryAfter [ "writeBoundary" "cloneNoctaliaPlugins" ] ''
    plugin_dir="${config.xdg.configHome}/noctalia/plugins"
    $DRY_RUN_CMD mkdir -p "$plugin_dir"
    $DRY_RUN_CMD ln -sfn "$HOME/.local/share/noctalia-local-plugins/mediawatch" "$plugin_dir/mediawatch"
  '';

  xdg.configFile."niri/noctalia.kdl".text = ''
    layout {

        focus-ring {
            active-color   "#e46c67"
            inactive-color "#291514"
            urgent-color   "#94413e"
        }

        border {
            active-color   "#e46c67"
            inactive-color "#291514"
            urgent-color   "#94413e"
        }

        shadow {
            color "#29151470"
        }

        tab-indicator {
            active-color   "#e46c67"
            inactive-color "#8d110c"
            urgent-color   "#94413e"
        }

        insert-hint {
            color "#e46c6780"
        }
    }

    recent-windows {
        highlight {
            active-color "#e46c67"
            urgent-color "#94413e"
        }
    }
  '';

  # niri/config.kdl is a read-only nix-store symlink generated by programs.niri.settings.
  # Noctalia's apply.sh can't append "include noctalia.kdl" to it. After each rebuild
  # home-manager re-creates the symlink, so we replace it with a writable copy + include.
  home.activation.addNiriNoctaliaInclude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    niri_config="${config.xdg.configHome}/niri/config.kdl"
    if [ -L "$niri_config" ]; then
      resolved=$(readlink -f "$niri_config")
      tmp="$niri_config.tmp"
      $DRY_RUN_CMD install -m 644 "$resolved" "$tmp"
      printf '\ninclude "noctalia.kdl"\n' >> "$tmp"
      $DRY_RUN_CMD mv -f "$tmp" "$niri_config"
    fi
  '';

  programs.mpv = {
    enable = true;
    config = {
      hwdec = "vaapi";
      vo = "gpu";
      gpu-context = "wayland";
      vaapi-device = "/dev/dri/renderD128";
    };
  };

  home.packages = with pkgs; [
    mediawatch-panel
    celluloid
    fractal
    tea
    ghostty
    melia
    opencode-desktop
    proton-drive-cli
    proton-vpn
    signal-desktop
    tailscale
    tailscale-systray
    wl-clipboard
    cliphist
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

  systemd.user.services.cliphist-watcher = {
    Unit = {
      Description = "Cliphist clipboard watcher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };


  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        Compression = "yes";
        ForwardAgent = "no";
        HashKnownHosts = "yes";
        ServerAliveInterval = "60";
        ServerAliveCountMax = "3";
      };
      "github.com" = {
        User = "git";
        IdentityFile = "/mnt/stags/.ssh/id_ed25519_github";
        IdentitiesOnly = "yes";
      };
      "nas" = {
        HostName = "192.168.0.100";
        Port = "5022";
        User = "eyal";
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/friendly-pals-day.png";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/friendly-pals-night.png";
      picture-options = "scaled";
    };
  };

  home.stateVersion = "25.11";
}
