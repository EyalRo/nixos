# dinOS

A personalized NixOS distribution with GNOME desktop environment and impermanence features.

## Overview

dinOS is a NixOS configuration that provides a clean, customizable desktop experience with system impermanence, profile-based configurations, and multi-host support.

## Features

- **GNOME Desktop Environment** with custom dinosaur-themed wallpapers
- **System Impermanence** - state persisted to `/persist` directory
- **Profile-based Configurations** for different use cases:
  - `headless` - Server without GUI
  - `kodi` - Media center with Kodi
  - `server` - General purpose server
- **Multi-host Support** - Device-specific configurations
- **Home-manager Integration** for user environment management
- **Development Shell** with pre-configured tools

## Repository Structure

```
├── flake.nix              # Main flake configuration
├── modules/
│   ├── dinOS/            # Core dinOS modules
│   │   ├── default.nix   # Base system configuration
│   │   ├── profiles/     # Profile-specific modules
│   │   ├── wallpaper/    # Custom wallpapers
│   │   └── starship/     # Shell prompt configs
│   └── users/            # User-specific configurations
├── hosts/                # Host-specific configurations
└── pkgs/                 # Custom packages (dinofetch)
```

## Supported Hosts

- `ideapad3` - Lenovo IdeaPad 3 laptop
- `nuc14` - Intel NUC 14 (server + Kodi profile)
- `xps15` - Dell XPS 15 laptop

## Usage

### Development Shell

Enter the development environment with useful tools:

```bash
nix develop
```

Includes: git, nixpkgs-fmt, nodejs_20, fish, starship, and opencode.

### Building Configurations

Build the generic dinOS configuration:

```bash
nix build .#nixosConfigurations.dinOS.config.system.build.toplevel
```

Build host-specific configuration:

```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

### Switching to dinOS

1. Generate hardware configuration:
   ```bash
   sudo nixos-generate-config
   ```

2. Switch to flake-based dinOS:
   ```bash
   sudo nixos-rebuild switch --flake .#dinOS
   ```

## Profiles

### headless
- No GUI components
- Optimized for server use
- Minimal resource footprint

### kodi
- Media center configuration
- Kodi media player
- Suitable for home theater PCs

### server
- General purpose server
- Docker support
- Essential services enabled

## Custom Packages

### dinofetch
A custom system information tool with dinosaur-themed output.

## Dependencies

- NixOS with flakes enabled
- EFI firmware (required for generic configuration)
- Hardware configuration at `/etc/nixos/hardware-configuration.nix`

## Nix Version

Uses NixOS 25.11 channel with experimental features enabled for flakes and nix-command.

## License

This configuration follows the same license as the included NixOS modules and packages.
