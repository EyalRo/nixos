# dinOS

EFI-only NixOS flake with GNOME defaults (Friendly Pals wallpaper), impermanence, and latest kernel from the pinned channel.

## Simple installation (EFI)

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/switch-to-dinos.sh | bash
```

## Defaults
- GNOME with Friendly Pals wallpaper (light/dark) pre-registered and set as the system default; Dinosaur Picnic is also available in the picker. Users can change wallpaper and it persists.
- Impermanence baseline persisting key system state under `/persist` (ssh, NetworkManager, docker, nixos, logs) plus per-user persistence in user layers.
- Latest kernel from the pinned channel, GNOME shell with appindicator + caffeine extensions, and a slim base package set (firefox, git, distrobox, etc.).

## Developing
- Inspect outputs: `nix flake show`.
- Dry-run evaluation: `nixos-rebuild dry-run --flake .#xps15` (or another output) without `sudo`.

---

Other outputs:
- `nixosConfigurations.dinOS-stags` – generic host with my personal user
- `nixosConfigurations.dinOS-installer` – minimal installer ISO profile
- `nixosConfigurations.ideapad3` – host-specific
- `nixosConfigurations.xps15` – host-specific
