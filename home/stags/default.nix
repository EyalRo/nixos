{ config, pkgs, inputs, ... }:

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
          command = [ "noctalia-shell" ];
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
            spawn-sh = "noctalia-shell ipc call launcher toggle";
          };
          hotkey-overlay.title = "Open launcher";
        };
        "Super+Alt+L" = {
          action = {
            spawn-sh = "noctalia-shell ipc call lockScreen lock";
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
            spawn-sh = "noctalia-shell ipc call controlCenter toggle";
          };
          hotkey-overlay.title = "Open control center";
        };
        "XF86AudioRaiseVolume" = {
          action = {
            spawn = [ "noctalia-shell" "ipc" "call" "volume" "increase" ];
          };
          hotkey-overlay.title = "Increase volume";
        };
        "XF86AudioLowerVolume" = {
          action = {
            spawn = [ "noctalia-shell" "ipc" "call" "volume" "decrease" ];
          };
          hotkey-overlay.title = "Decrease volume";
        };
        "XF86AudioMute" = {
          action = {
            spawn = [ "noctalia-shell" "ipc" "call" "volume" "muteOutput" ];
          };
          hotkey-overlay.title = "Mute volume";
        };
        "XF86MonBrightnessUp" = {
          action = {
            spawn = [ "noctalia-shell" "ipc" "call" "brightness" "increase" ];
          };
          hotkey-overlay.title = "Increase brightness";
        };
        "XF86MonBrightnessDown" = {
          action = {
            spawn = [ "noctalia-shell" "ipc" "call" "brightness" "decrease" ];
          };
          hotkey-overlay.title = "Decrease brightness";
        };
      };
    };
  };

  programs.noctalia-shell = {
    enable = true;
    settings = {
      settingsVersion = 0;
      bar = {
        position = "top";
        density = "compact";
        widgets = {
          left = [
            { id = "Launcher"; }
            { id = "plugin:niri-keyboard-layout"; }
            { id = "Clock"; formatHorizontal = "hh:mm a"; useMonospacedFont = true; }
            { id = "SystemMonitor"; }
            { id = "plugin:tailscale"; }
          ];
          center = [
            { id = "Workspace"; hideUnoccupied = false; }
          ];
          right = [
            { id = "Tray"; }
            { id = "Battery"; alwaysShowPercentage = false; }
            { id = "Network"; }
            { id = "ControlCenter"; }
          ];
        };
      };
      location = {
        name = "Seattle, WA";
        useFahrenheit = true;
        use12hourFormat = true;
      };
      ui = {
        use12hourFormat = true;
        clockStyle = "digital";
        clockFormat = "hh:mm a";
      };
      general = {
        lockScreenAnimations = true;
        allowPasswordWithFprintd = true;
        compactLockScreen = false;
        showSessionButtonsOnLockScreen = true;
        clockStyle = "digital";
        passwordChars = true;
      };
      wallpaper = {
        enabled = true;
        automationEnabled = true;
        wallpaperChangeMode = "random";
        randomIntervalSec = 300;
        skipStartupTransition = true;
      };
      colorSchemes = {
        useWallpaperColors = true;
        predefinedScheme = "vibrant";
      };
      dock = {
        enable = false;
      };
      launcher = {
        showCategories = false;
      };
      nightLight = {
        enabled = true;
        temperature = 4000;
        schedule = {
          enabled = true;
          from = "20:00";
          to = "07:00";
        };
      };
      power = {
        showTimer = false;
      };
      sessionMenu = {
        enableCountdown = false;
      };
    };
  };

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
    celluloid
    ghostty
    protonvpn-gui
    tailscale-systray
    wl-clipboard
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

  home.file = {
    ".config/noctalia/plugins.json" = {
      source = ./plugins/noctalia-plugins.json;
      force = true;
    };
    ".config/noctalia/plugins/niri-keyboard-layout" = {
      source = ../../modules/dinOS/plugins/niri-keyboard-layout;
      recursive = true;
      force = true;
    };
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
