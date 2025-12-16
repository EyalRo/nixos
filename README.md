# dinOS

EFI-only NixOS flake with GNOME defaults (Friendly Pals wallpaper), impermanence, and latest kernel from the pinned channel.

## Simple installation (EFI)

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/switch-to-dinos.sh | bash
```

---

Other outputs:
- `nixosConfigurations.dinOS-stags` – generic host with my personal user
- `nixosConfigurations.dinOS-installer` – minimal installer ISO profile
- `nixosConfigurations.ideapad3` – host-specific
- `nixosConfigurations.xps15` – host-specific

## Development tooling
- Run `npm run codex` to invoke the local `codex` CLI with `stylus@0.59.0` pinned to avoid circular dependency warnings about `lineno`/`filename`.
