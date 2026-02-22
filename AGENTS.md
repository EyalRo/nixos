# NixOS Configuration

## Flake

Run `nix develop` to enter the development shell. The flake provides:
- `nixpkgs` (nixos-25.11)
- `nixpkgs-unstable` (nixos-unstable)
- `home-manager` (release-25.11)
- `opencode` (v1.1.56)
- `crystal` (unstable)
- `shards` (unstable)
- `gtk4` and dev libraries

## Commands

```bash
# Enter dev shell
nix develop

# Build the system
sudo nixos-rebuild switch --flake .#xps15

# Update flake
nix flake update
```

## Packages

Dev shell includes: git, nixpkgs-fmt, nodejs_20, fish, starship, opencode, crystal, shards, gtk4, glib, pkg-config.
