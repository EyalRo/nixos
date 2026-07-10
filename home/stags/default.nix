{ config, pkgs, lib, inputs, ... }:

let
  # Claude Code reads MCP server definitions from the top-level "mcpServers"
  # key in ~/.claude.json (as written by `claude mcp add -s user`) — it does
  # NOT read them from settings.json. Keep this list separate so it can be
  # merged into ~/.claude.json without clobbering that file's mutable
  # runtime state (OAuth tokens, project history, usage counters).
  claudeMcpServers = {
    forgejo = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export FORGEJO_URL=https://forgejo.virtualdino.com; export FORGEJO_TOKEN; FORGEJO_TOKEN=$(cat /mnt/stags/.config/mcp-tokens/forgejo 2>/dev/null); exec forgejo-mcp" ];
    };
    todo = {
      type = "stdio";
      command = "sh";
      args = [ "-c" "export TODO_URL; TODO_URL=$(cat /mnt/stags/.config/mcp-tokens/todo-url 2>/dev/null); exec todo-mcp" ];
    };
    victorialogs = {
      type = "stdio";
      command = "victorialogs-mcp";
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
      bar.default = {
        end = [
          "stags/todo:widget"
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
      };
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
      plugin_settings."stags/mediawatch" = {
        base_url = "https://mediawatch.virtualdino.com";
      };
      plugins.source = [
        { kind = "git"; location = "https://github.com/noctalia-dev/community-plugins"; name = "community"; }
        { kind = "git"; location = "https://github.com/noctalia-dev/official-plugins"; name = "official"; }
        { kind = "git"; location = "https://forgejo.virtualdino.com/stags/noctalia-plugins"; name = "DinOS"; }
      ];
    };
  };

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
    melia
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
    jobhunt-mcp
    todo-mcp
    victorialogs-mcp
    mediawatch-mcp
    prowlarr-mcp
    proxmox-mcp
    radarr-mcp
    sonarr-mcp
    grammarly-mcp
    linkedin-mcp
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
          command = [ "sh" "-c" "export FORGEJO_URL=https://forgejo.virtualdino.com; export FORGEJO_TOKEN; FORGEJO_TOKEN=$(cat /mnt/stags/.config/mcp-tokens/forgejo 2>/dev/null); exec forgejo-mcp" ];
        };
        todo = {
          type = "local";
          command = [ "sh" "-c" "export TODO_URL; TODO_URL=$(cat /mnt/stags/.config/mcp-tokens/todo-url 2>/dev/null); exec todo-mcp" ];
        };
        victorialogs = {
          type = "local";
          command = [ "victorialogs-mcp" ];
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
      "forgejo.virtualdino.com" = {
        HostName = "192.168.0.37";
        User = "git";
        IdentityFile = "/mnt/stags/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
      "pve-node1" = {
        HostName = "192.168.0.11";
        User = "root";
        IdentityFile = "/mnt/stags/.ssh/id_ed25519_proxmox";
        IdentitiesOnly = "yes";
      };
      "pve-node2" = {
        HostName = "192.168.0.12";
        User = "root";
        IdentityFile = "/mnt/stags/.ssh/id_ed25519_proxmox";
        IdentitiesOnly = "yes";
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/friendly-pals-day.png";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/friendly-pals-night.png";
      picture-options = "scaled";
    };
    "org/gnome/shell" = {
      enabled-extensions = [
        "todo@stags.virtualdino.com"
        "mediawatch@stags.virtualdino.com"
      ];
    };
  };

  home.stateVersion = "25.11";
}
