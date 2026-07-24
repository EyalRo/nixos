{ config, pkgs, lib, inputs, ... }:

let
  wallpaperDayPath = "/run/current-system/sw/share/backgrounds/friendly-pals-day.png";
  wallpaperNightPath = "/run/current-system/sw/share/backgrounds/friendly-pals-night.png";

  # Noctalia's bar layout (widget arrangement, scale, spacing) has no IPC
  # command to set it, unlike wallpaper/plugins, so it can only be enforced
  # by directly rewriting its [bar.default] table in the mutable state file.
  # This is the single source of truth for that table, reused below both to
  # render config.toml's default and to build the snippet the activation
  # script splices into ~/.local/state/noctalia/settings.toml.
  noctaliaBarDefault = {
    start = [ "launcher" "media" ];
    center = [ "clock" "caffeine" "todo" "mediawatch" "life" ];
    end = [
      "keyboard_layout"
      "tray"
      "notifications"
      "clipboard"
      "network"
      "bluetooth"
      "volume"
      "brightness"
      "battery"
      "control-center"
      "session"
    ];
    background_opacity = 0.8;
    margin_ends = 10;
    scale = 1.25;
    widget_spacing = 10;
  };

  noctaliaBarDefaultToml =
    (pkgs.formats.toml { }).generate "noctalia-bar-default.toml" { bar.default = noctaliaBarDefault; };

  # bar.default above references widgets by plain id ("todo", "mediawatch",
  # "life"), which needs a matching [widget.<id>] table telling noctalia what
  # plugin entry to instantiate. Keeping these named — rather than inlining
  # the "author/plugin:entry" string directly in bar.default, as this used to
  # do for mediawatch — matters because re-splicing a literal type string on
  # every switch makes noctalia mint a fresh numbered widget_N key each time;
  # the previous approach left orphaned widget_3/widget_4 duplicates behind
  # after repeated switches. A stable name gets overwritten in place instead.
  noctaliaWidgetDefs = {
    todo = "stags/todo:widget";
    mediawatch = "stags/mediawatch:widget";
    life = "stags/life:widget";
  };

  noctaliaWidgetDefToml = name: type:
    (pkgs.formats.toml { }).generate "noctalia-widget-${name}.toml" { widget.${name} = { inherit type; }; };

  # The noctalia binary currently installed here still stores theme/template
  # state under the legacy [theme] table (theme.mode, theme.templates.*),
  # not the newer colorSchemes/templates schema used elsewhere in this file
  # (confirmed live: toggling theme-mode-set did not fire hooks.darkModeChange
  # above, and theme.templates.community_ids is what actually regenerates
  # ~/.config/telegram-desktop/themes/noctalia.tdesktop-theme). Declare
  # against the schema that's proven to work today; colorSchemes/hooks stay
  # in place for whenever noctalia updates past this build.
  noctaliaThemeTemplates = {
    builtin_ids = [ "gtk3" "gtk4" "ghostty" "helix" "niri" "starship" ];
    community_ids = [ "zed" "opencode" "pi-agent" "telegram" ];
  };

  noctaliaThemeTemplatesToml =
    (pkgs.formats.toml { }).generate "noctalia-theme-templates.toml" { theme.templates = noctaliaThemeTemplates; };

  # Replaces an arbitrary dotted TOML table (e.g. "bar.default" or
  # "theme.templates") in a noctalia settings.toml with the contents of a
  # freshly generated snippet, validating the result parses before writing
  # it back. Used for settings noctalia has no `msg` IPC command to set at
  # runtime (bar layout, template activation).
  spliceNoctaliaTomlSectionScript = pkgs.writeText "splice-noctalia-toml-section.py" ''
    import re, sys, tomllib, os

    target_path, snippet_path, section = sys.argv[1], sys.argv[2], sys.argv[3]

    with open(snippet_path) as f:
        new_block = f.read().rstrip("\n") + "\n"

    with open(target_path) as f:
        content = f.read()
    if content and not content.endswith("\n"):
        # Otherwise a section with no trailing newline (possible when it's
        # the last one in the file — noctalia's own writer doesn't always
        # add one) makes the content-line regex below fail to consume the
        # last line, leaving it behind as an orphaned duplicate key.
        content += "\n"

    escaped = re.escape(section)
    pattern = re.compile(rf"^[ \t]*\[{escaped}\]\n(?:(?!^[ \t]*\[).*\n)*", re.MULTILINE)
    if pattern.search(content):
        new_content = pattern.sub(lambda m: new_block, content, count=1)
    else:
        new_content = content.rstrip("\n") + "\n\n" + new_block

    tomllib.loads(new_content)  # validate before touching the real file

    tmp_path = target_path + ".tmp"
    with open(tmp_path, "w") as f:
        f.write(new_content)
    os.replace(tmp_path, target_path)
  '';

  # Claude Code reads MCP server definitions from the top-level "mcpServers"
  # key in ~/.claude.json (as written by `claude mcp add -s user`) — it does
  # NOT read them from settings.json. Keep this list separate so it can be
  # merged into ~/.claude.json without clobbering that file's mutable
  # runtime state (OAuth tokens, project history, usage counters).
  claudeMcpServers = {
    forgejo = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export FORGEJO_URL=https://forgejo.virtualdino.com; exec /home/stags/Source/proxmox/scripts/secrets-run.sh mcp-forgejo -- forgejo-mcp" ];
    };
    todo = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export TODO_URL; TODO_URL=$(cat /mnt/stags/.config/mcp-tokens/todo-url 2>/dev/null); exec todo-mcp" ];
    };
    victorialogs = {
      type = "stdio";
      command = "victorialogs-mcp";
      env.VICTORIALOGS_URL = "http://192.168.0.39:9428";
    };
    mediawatch = {
      type = "stdio";
      command = "mediawatch-mcp";
      env.MEDIAWATCH_URL = "https://mediawatch.virtualdino.com";
    };
    jobhunt = {
      type = "stdio";
      command = "jobhunt-mcp";
      env.JOBHUNT_URL = "https://jobhunt.virtualdino.com";
    };
    prowlarr = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export PROWLARR_URL; PROWLARR_URL=$(cat /mnt/stags/.config/mcp-tokens/prowlarr-url 2>/dev/null); export PROWLARR_API_KEY; PROWLARR_API_KEY=$(cat /mnt/stags/.config/mcp-tokens/prowlarr 2>/dev/null); exec prowlarr-mcp" ];
    };
    proxmox = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export PROXMOX_HOST; PROXMOX_HOST=$(cat /mnt/stags/.config/mcp-tokens/proxmox-host 2>/dev/null); export PROXMOX_TOKEN_ID; PROXMOX_TOKEN_ID=$(cat /mnt/stags/.config/mcp-tokens/proxmox-token-id 2>/dev/null); export PROXMOX_TOKEN_SECRET; PROXMOX_TOKEN_SECRET=$(cat /mnt/stags/.config/mcp-tokens/proxmox-token-secret 2>/dev/null); exec proxmox-mcp" ];
    };
    radarr = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export RADARR_URL; RADARR_URL=$(cat /mnt/stags/.config/mcp-tokens/radarr-url 2>/dev/null); export RADARR_API_KEY; RADARR_API_KEY=$(cat /mnt/stags/.config/mcp-tokens/radarr 2>/dev/null); exec radarr-mcp" ];
    };
    sonarr = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export SONARR_URL; SONARR_URL=$(cat /mnt/stags/.config/mcp-tokens/sonarr-url 2>/dev/null); export SONARR_API_KEY; SONARR_API_KEY=$(cat /mnt/stags/.config/mcp-tokens/sonarr 2>/dev/null); exec sonarr-mcp" ];
    };
    grammarly = {
      type = "stdio";
      command = "grammarly-mcp";
      args = [ "--cookies-file" "/mnt/stags/.config/mcp-tokens/grammarly-cookies" ];
    };
    linkedin = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export LINKEDIN_ACCESS_TOKEN; LINKEDIN_ACCESS_TOKEN=$(cat /mnt/stags/.config/mcp-tokens/linkedin 2>/dev/null); exec linkedin-mcp" ];
    };
    homepage-secrets = {
      type = "stdio";
      command = "homepage-secrets-mcp";
      env.HOMEPAGE_URL = "https://homepage.virtualdino.com";
    };
    playwright = {
      type = "stdio";
      command = "playwright-mcp";
    };
    cloudflare = {
      type = "sse";
      url = "https://mcp.cloudflare.com/mcp";
    };
    cloudflare-docs = {
      type = "sse";
      url = "https://docs.mcp.cloudflare.com/mcp";
    };
    cloudflare-bindings = {
      type = "sse";
      url = "https://bindings.mcp.cloudflare.com/mcp";
    };
    cloudflare-builds = {
      type = "sse";
      url = "https://builds.mcp.cloudflare.com/mcp";
    };
    cloudflare-observability = {
      type = "sse";
      url = "https://observability.mcp.cloudflare.com/mcp";
    };
  };

  claudeSettings = pkgs.writeText "claude-code-settings.json" (builtins.toJSON {
    enabledPlugins."superpowers@claude-plugins-official" = true;
    theme = "dark";
    skipAutoPermissionPrompt = true;
    effortLevel = "high";
    permissions.defaultMode = "auto";
  });

  claudeMcpServersJson = pkgs.writeText "claude-code-mcp-servers.json" (builtins.toJSON claudeMcpServers);

  sshConfigFile = pkgs.writeText "ssh-config" ''
    Host *
      AddKeysToAgent yes
      Compression yes
      ForwardAgent no
      HashKnownHosts yes
      ServerAliveInterval 60
      ServerAliveCountMax 3

    Host github.com
      User git
      IdentityFile /mnt/stags/.ssh/id_ed25519_github
      IdentitiesOnly yes

    Host nas
      HostName 192.168.0.100
      Port 5022
      User eyal

    Host forgejo.virtualdino.com
      HostName 192.168.0.37
      User git

    Host pve-node1
      HostName 192.168.0.11
      User root

    Host pve-node2
      HostName 192.168.0.12
      User root
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
          command = [ "awww-daemon" ];
        }
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
        {
          matches = [{ app-id = "io.stags.todo-panel"; }];
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
            spawn = [ "noctalia" "msg" "panel-toggle" "launcher" ];
          };
          hotkey-overlay.title = "Open launcher";
        };
        "Super+Alt+L" = {
          action = {
            spawn = [ "noctalia" "msg" "session" "lock" ];
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
            spawn = [ "noctalia" "msg" "panel-toggle" "control-center" ];
          };
          hotkey-overlay.title = "Open control center";
        };
        "Mod+N" = {
          action = {
            spawn-sh = "noctalia msg panel-toggle stags/todo:panel";
          };
          hotkey-overlay.title = "Open todo panel";
        };
        "XF86AudioRaiseVolume" = {
          action = {
            spawn = [ "noctalia" "msg" "volume-up" ];
          };
          hotkey-overlay.title = "Increase volume";
        };
        "XF86AudioLowerVolume" = {
          action = {
            spawn = [ "noctalia" "msg" "volume-down" ];
          };
          hotkey-overlay.title = "Decrease volume";
        };
        "XF86AudioMute" = {
          action = {
            spawn = [ "noctalia" "msg" "volume-mute" ];
          };
          hotkey-overlay.title = "Mute volume";
        };
        "XF86MonBrightnessUp" = {
          action = {
            spawn = [ "noctalia" "msg" "brightness-up" ];
          };
          hotkey-overlay.title = "Increase brightness";
        };
        "XF86MonBrightnessDown" = {
          action = {
            spawn = [ "noctalia" "msg" "brightness-down" ];
          };
          hotkey-overlay.title = "Decrease brightness";
        };
      };
    };
  };

  programs.noctalia = {
    enable = true;
    settings = {
      bar.default = noctaliaBarDefault;
      location = {
        auto_locate = false;
        address = "Seattle";
      };
      weather = {
        unit = "imperial";
      };
      nightlight = {
        enabled = true;
      };
      # Point the desktop image selector at the switch-managed background
      # symlink farm instead of the noctalia default (~/Pictures/Wallpapers).
      # /run/current-system/sw/share/backgrounds is rebuilt fresh from
      # environment.systemPackages on every switch, so the picker's list
      # resets to exactly the current generation's wallpapers automatically
      # — no separate activation script needed to keep it in sync.
      wallpaper = {
        directory = "/run/current-system/sw/share/backgrounds";
      };
      # Auto-toggle dark/light at real sunrise/sunset for this location
      # (location.address above), then swap the wallpaper to match.
      colorSchemes = {
        schedulingMode = "location";
      };
      hooks = {
        enabled = true;
        darkModeChange = ''
          if [ "$1" = "true" ]; then
            noctalia msg wallpaper-set ${wallpaperNightPath}
          else
            noctalia msg wallpaper-set ${wallpaperDayPath}
          fi
        '';
      };
      # Legacy schema (see noctaliaThemeTemplates above) — keeps the
      # telegram community template and builtin templates active.
      theme.templates = noctaliaThemeTemplates;
      plugin_settings."stags/mediawatch" = {
        base_url = "https://mediawatch.virtualdino.com";
      };
      plugin_settings."stags/todo" = {
        base_url = "https://todo.virtualdino.com";
      };
      plugins.enabled = [ "stags/mediawatch" "stags/todo" "stags/life" ];
      plugins.source = [
        { kind = "git"; location = "https://github.com/noctalia-dev/community-plugins"; name = "community"; }
        { kind = "git"; location = "https://github.com/noctalia-dev/official-plugins"; name = "official"; }
        { kind = "path"; location = "${inputs.pachy}/noctalia-plugins"; name = "DinOS"; }
      ];
    };
  };

  # Noctalia keeps the active wallpaper in mutable app state
  # (~/.local/state/noctalia/settings.toml), not in the config.toml rendered
  # above, so a GUI wallpaper pick sticks around forever. Reset it to the
  # dinOS day/night default on every switch. The hour check is just a
  # same-switch fallback (matches noctalia's
  # own default 06:30/18:30 manual sunrise/sunset) — once the app is running,
  # the hooks.darkModeChange script above takes over with real sunrise/sunset
  # times for this location. `wallpaper-set` with no connector applies to
  # every output and is a no-op if noctalia's IPC socket isn't up yet (e.g.
  # before first login).
  home.activation.resetNoctaliaWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    hour=$(date +%H)
    if [ "$hour" -ge 6 ] && [ "$hour" -lt 18 ]; then
      wallpaperPath=${wallpaperDayPath}
    else
      wallpaperPath=${wallpaperNightPath}
    fi
    $DRY_RUN_CMD ${lib.getExe config.programs.noctalia.package} msg wallpaper-set \
      "$wallpaperPath" 2>/dev/null || true
  '';

  # Plugin sources and enable/disable state live in the mutable state file
  # (~/.local/state/noctalia/settings.toml) and persist across switches.
  # The GUI can modify these, so we force-sync them on every switch to match
  # the declarative config. This ensures all sources are correct and all
  # DinOS plugins are automatically enabled.
  home.activation.resetNoctaliaPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NOCTALIA=${lib.getExe config.programs.noctalia.package}
    DINOS_PLUGINS=${inputs.pachy}/noctalia-plugins
    
    # Remove all existing sources and re-add them to match declarative config
    $DRY_RUN_CMD $NOCTALIA msg plugins source remove community 2>/dev/null || true
    $DRY_RUN_CMD $NOCTALIA msg plugins source remove official 2>/dev/null || true
    $DRY_RUN_CMD $NOCTALIA msg plugins source remove DinOS 2>/dev/null || true
    
    $DRY_RUN_CMD $NOCTALIA msg plugins source add community git https://github.com/noctalia-dev/community-plugins 2>/dev/null || true
    $DRY_RUN_CMD $NOCTALIA msg plugins source add official git https://github.com/noctalia-dev/official-plugins 2>/dev/null || true
    $DRY_RUN_CMD $NOCTALIA msg plugins source add DinOS path $DINOS_PLUGINS 2>/dev/null || true
    
    # Auto-enable all plugins from the DinOS source by parsing catalog.toml
    if [ -f "$DINOS_PLUGINS/catalog.toml" ]; then
      for plugin_id in $(grep -oP '(?<=^id = ")[^"]+' "$DINOS_PLUGINS/catalog.toml"); do
        $DRY_RUN_CMD $NOCTALIA msg plugins enable "$plugin_id" 2>/dev/null || true
      done
    fi
  '';

  # See noctaliaBarDefault/spliceNoctaliaTomlSectionScript above: no IPC
  # exists for bar layout, so force it by rewriting the state file's
  # [bar.default] table directly on every switch.
  home.activation.resetNoctaliaBar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${spliceNoctaliaTomlSectionScript} \
      "$HOME/.local/state/noctalia/settings.toml" ${noctaliaBarDefaultToml} bar.default 2>/dev/null || true
  '';

  # See noctaliaWidgetDefs above: force each named widget's [widget.<id>]
  # table too, so bar.default's plain-id references always resolve, without
  # minting new numbered keys on every switch the way a literal type string
  # in bar.default itself would.
  home.activation.resetNoctaliaWidgets = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatStrings (lib.mapAttrsToList (name: type: ''
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${spliceNoctaliaTomlSectionScript} \
        "$HOME/.local/state/noctalia/settings.toml" ${noctaliaWidgetDefToml name type} "widget.${name}" 2>/dev/null || true
    '') noctaliaWidgetDefs)
  );

  # Same story for template activation (see noctaliaThemeTemplates above):
  # no IPC to set which templates are active, so force it directly too.
  home.activation.resetNoctaliaTemplates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${spliceNoctaliaTomlSectionScript} \
      "$HOME/.local/state/noctalia/settings.toml" ${noctaliaThemeTemplatesToml} theme.templates 2>/dev/null || true
  '';

  # The three splices above edit settings.toml on disk, but noctalia is a
  # long-running shell (spawned once at niri login, not restarted by a
  # switch) that keeps its own in-memory copy of settings.toml and flushes
  # it back to disk on unrelated state changes (notifications, media,
  # usage counts, ...). If noctalia is still running from before this
  # switch, that stale in-memory copy clobbers our splices within about a
  # minute of activation, silently reverting bar.default/widget.*/
  # theme.templates and making newly-enabled plugins never show up on the
  # bar. `config-reload` makes the running instance re-read settings.toml
  # immediately, adopting the splices before it has a chance to overwrite
  # them; confirmed live (2026-07-23) that without this the bar layout
  # reverted ~40s after activation despite the splice succeeding. No-op if
  # noctalia isn't running yet (e.g. before first login).
  home.activation.reloadNoctaliaSettings = lib.hm.dag.entryAfter [
    "resetNoctaliaBar"
    "resetNoctaliaWidgets"
    "resetNoctaliaTemplates"
    "resetNoctaliaPlugins"
  ] ''
    $DRY_RUN_CMD ${lib.getExe config.programs.noctalia.package} msg config-reload 2>/dev/null || true
  '';

  home.activation.cloneGnomePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    plugins_dir="$HOME/.local/share/gnome-local-plugins"
    if [ ! -d "$plugins_dir/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://forgejo.virtualdino.com/stags/gnome-plugins.git "$plugins_dir"
    fi
  '';

  home.activation.linkGnomePlugins = lib.hm.dag.entryAfter [ "writeBoundary" "cloneGnomePlugins" ] ''
    ext_dir="$HOME/.local/share/gnome-shell/extensions"
    $DRY_RUN_CMD mkdir -p "$ext_dir"
    $DRY_RUN_CMD ln -sfn "$HOME/.local/share/gnome-local-plugins/todo@stags.virtualdino.com" "$ext_dir/todo@stags.virtualdino.com"
    $DRY_RUN_CMD ln -sfn "$HOME/.local/share/gnome-local-plugins/mediawatch@stags.virtualdino.com" "$ext_dir/mediawatch@stags.virtualdino.com"
  '';

  # GNOME manages IBus via systemd (NotShowIn=GNOME in the system autostart).
  # Suppress XDG autostart so IBus doesn't also start in niri sessions.
  home.file.".config/autostart/ibus-daemon.desktop".text = ''
    [Desktop Entry]
    Hidden=true
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

  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" ];
  };

  home.packages = with pkgs; [
    celluloid
    mpvpaper
    awww
    fractal
    tea
    ghostty
    claude-desktop
    geary
    opencode-desktop
    proton-drive-cli
    proton-vpn
    signal-desktop
    tailscale
    tailscale-systray
    wl-clipboard
    cliphist
    # MCP servers — secrets read from /mnt/stags/.config/mcp-tokens/<service>
    forgejo-mcp
    todo-mcp
    victorialogs-mcp
    mediawatch-mcp
    prowlarr-mcp
    proxmox-mcp
    radarr-mcp
    sonarr-mcp
    grammarly-mcp
    linkedin-mcp
    homepage-secrets-mcp
    playwright-mcp
  ];

  # Todo daemon — HTTP API on localhost:7410.
  # Secrets live in ~/.config/todo/env (not in git). Create it with:
  #   INBOX_TOKEN=<token>
  # App-level CF Access JWT auth is disabled: LAN clients bypass Cloudflare via
  # Technitium DNS. Edge-level CF Access Application handles external security.
  # AUD: 921a0fdf34b51fd434c3e408f4a1c74afddfc1454af6f83b6dba60e10fb468b8
  # Team: isdino.cloudflareaccess.com
  systemd.user.services.todo = {
    Unit = {
      Description = "Todo daemon";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "%h/.local/bin/todo serve --public-url https://todo.virtualdino.com";
      EnvironmentFile = [ "-%h/.config/todo/env" ];
      Environment = [
        "TODO_URL=http://localhost:7410"
        "LOG_NODE=todo"
        "LOG_LEVEL=info"
        "LOG_ENDPOINT=http://192.168.0.39:9428/insert/jsonline?_stream_fields=service,level,component&_msg_field=msg&_time_field=ts"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # home.file would create a read-only nix-store symlink; Claude Code needs
  # to write runtime state (MCP auth, server status) back to this file.
  # home.activation copies it as a regular writable file on each switch.
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -Dm644 ${claudeSettings} "$HOME/.claude/settings.json"
  '';

  # Claude Code does NOT read mcpServers from settings.json — it reads the
  # top-level "mcpServers" key in ~/.claude.json (the same file `claude mcp
  # add -s user` writes to). That file also holds mutable runtime state
  # (OAuth tokens, project history, usage counters), so merge our servers
  # into it with jq on each switch instead of overwriting the whole file.
  home.activation.claudeCodeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeJson="$HOME/.claude.json"
    tmp="$(mktemp)"
    if [ -f "$claudeJson" ]; then
      ${pkgs.jq}/bin/jq --slurpfile mcp ${claudeMcpServersJson} '.mcpServers = $mcp[0]' "$claudeJson" > "$tmp"
    else
      ${pkgs.jq}/bin/jq -n --slurpfile mcp ${claudeMcpServersJson} '{mcpServers: $mcp[0]}' > "$tmp"
    fi
    $DRY_RUN_CMD install -Dm600 "$tmp" "$claudeJson"
    rm -f "$tmp"
  '';

  home.file.".config/opencode/config.json" = {
    force = true;
    text = builtins.toJSON {
      plugin = [
        "@tarquinen/opencode-dcp"
        "harness-memory"
        "opencode-command-inject"
        "opencode-snip"
        "crewbee"
      ];
      mcp = {
        forgejo = {
          type = "local";
          command = [ "sh" "-c" "export FORGEJO_URL=https://forgejo.virtualdino.com; exec /home/stags/Source/proxmox/scripts/secrets-run.sh mcp-forgejo -- forgejo-mcp" ];
        };
        todo = {
          type = "local";
          command = [ "sh" "-c" "export TODO_URL; TODO_URL=$(cat /mnt/stags/.config/mcp-tokens/todo-url 2>/dev/null); exec todo-mcp" ];
        };
        victorialogs = {
          type = "local";
          command = [ "victorialogs-mcp" ];
          environment.VICTORIALOGS_URL = "http://192.168.0.39:9428";
        };
        mediawatch = {
          type = "local";
          command = [ "mediawatch-mcp" ];
          environment.MEDIAWATCH_URL = "https://mediawatch.virtualdino.com";
        };
        # jobhunt: bespoke resume storage and PDF rendering.
        # https://jobhunt.virtualdino.com, no auth (private network + Cloudflare edge).
        # Added 2026-07 with the resume_variants REST API.
        jobhunt = {
          type = "local";
          command = [ "jobhunt-mcp" ];
          environment.JOBHUNT_URL = "https://jobhunt.virtualdino.com";
        };
        prowlarr = {
          type = "local";
          command = [ "sh" "-c" "export PROWLARR_URL; PROWLARR_URL=$(cat /mnt/stags/.config/mcp-tokens/prowlarr-url 2>/dev/null); export PROWLARR_API_KEY; PROWLARR_API_KEY=$(cat /mnt/stags/.config/mcp-tokens/prowlarr 2>/dev/null); exec prowlarr-mcp" ];
        };
        proxmox = {
          type = "local";
          command = [ "sh" "-c" "export PROXMOX_HOST; PROXMOX_HOST=$(cat /mnt/stags/.config/mcp-tokens/proxmox-host 2>/dev/null); export PROXMOX_TOKEN_ID; PROXMOX_TOKEN_ID=$(cat /mnt/stags/.config/mcp-tokens/proxmox-token-id 2>/dev/null); export PROXMOX_TOKEN_SECRET; PROXMOX_TOKEN_SECRET=$(cat /mnt/stags/.config/mcp-tokens/proxmox-token-secret 2>/dev/null); exec proxmox-mcp" ];
        };
        radarr = {
          type = "local";
          command = [ "sh" "-c" "export RADARR_URL; RADARR_URL=$(cat /mnt/stags/.config/mcp-tokens/radarr-url 2>/dev/null); export RADARR_API_KEY; RADARR_API_KEY=$(cat /mnt/stags/.config/mcp-tokens/radarr 2>/dev/null); exec radarr-mcp" ];
        };
        sonarr = {
          type = "local";
          command = [ "sh" "-c" "export SONARR_URL; SONARR_URL=$(cat /mnt/stags/.config/mcp-tokens/sonarr-url 2>/dev/null); export SONARR_API_KEY; SONARR_API_KEY=$(cat /mnt/stags/.config/mcp-tokens/sonarr 2>/dev/null); exec sonarr-mcp" ];
        };
        grammarly = {
          type = "local";
          command = [ "grammarly-mcp" "--cookies-file" "/mnt/stags/.config/mcp-tokens/grammarly-cookies" ];
        };
        linkedin = {
          type = "local";
          command = [ "sh" "-c" "export LINKEDIN_ACCESS_TOKEN; LINKEDIN_ACCESS_TOKEN=$(cat /mnt/stags/.config/mcp-tokens/linkedin 2>/dev/null); exec linkedin-mcp" ];
        };
        homepage-secrets = {
          type = "local";
          command = [ "homepage-secrets-mcp" ];
          environment.HOMEPAGE_URL = "https://homepage.virtualdino.com";
        };
        playwright = {
          type = "local";
          command = [ "playwright-mcp" ];
        };
        # Cloudflare MCP servers (remote, OAuth-gated except docs).
        # Mirrors cloudflare entries in claudeSettings above. OAuth fires
        # on first tool use of each server. Type
        # "remote" matches the OpenCode docs' example for HTTPS MCP
        # servers; if your OpenCode build is older than the spec
        # transition, switch to type = "sse".
        cloudflare = {
          type = "remote";
          url = "https://mcp.cloudflare.com/mcp";
          enabled = true;
          oauth = { };
        };
        cloudflare-docs = {
          type = "remote";
          url = "https://docs.mcp.cloudflare.com/mcp";
          enabled = true;
        };
        cloudflare-bindings = {
          type = "remote";
          url = "https://bindings.mcp.cloudflare.com/mcp";
          enabled = true;
          oauth = { };
        };
        cloudflare-builds = {
          type = "remote";
          url = "https://builds.mcp.cloudflare.com/mcp";
          enabled = true;
          oauth = { };
        };
        cloudflare-observability = {
          type = "remote";
          url = "https://observability.mcp.cloudflare.com/mcp";
          enabled = true;
          oauth = { };
        };
      };
    };
  };

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

  systemd.user.services.ssh-keys-from-secrets = {
    Unit = {
      Description = "Load SSH keys from Homepage secrets service into ssh-agent";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "/home/stags/Source/nixos/scripts/ssh-keys-from-secrets.sh";
      Environment = [ "SECRETS_URL=https://secrets.virtualdino.com/graphql" ];
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # SSH requires the config file to be owned by the user and writable only by
  # them; home.file always symlinks into the nix store (owned by
  # nobody:nogroup there), which fails ssh's strict permission check no
  # matter what `force` is set to. Copy it in as a real file instead, same
  # as claudeCodeSettings above.
  home.activation.sshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD install -Dm600 ${sshConfigFile} "$HOME/.ssh/config"
  '';

  dconf.settings = {
    # No org/gnome/desktop/background entry here on purpose: GNOME's own
    # dconf-driven wallpaper was a second, competing wallpaper source next
    # to noctalia's native day/night handling (hooks.darkModeChange +
    # resetNoctaliaWallpaper above) — GDM's greeter would paint this one,
    # then niri+noctalia would immediately swap to its own, producing the
    # "one image flashes then gets replaced" symptom. Noctalia is the only
    # thing that should ever set the desktop wallpaper.
    "org/gnome/shell" = {
      enabled-extensions = [
        "todo@stags.virtualdino.com"
        "mediawatch@stags.virtualdino.com"
      ];
    };
  };

  home.stateVersion = "25.11";
}
