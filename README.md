# dinOS

Opinionated NixOS flake with GNOME and impermanence defaults.

## Install

1. Install NixOS normally.
2. Run:

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
```

You’ll be prompted for sudo. The script clones this repo to `~/nixos`, creates a `hosts/dinOS/` entry from your hardware config, switches to the flake, and reboots.

After reboot, edit `~/nixos/hosts/dinOS/default.nix` for host-specific tweaks and rerun:

```bash
sudo nixos-rebuild switch --flake ~/nixos#dinOS
```
