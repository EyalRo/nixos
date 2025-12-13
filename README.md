# dinOS

EFI-only NixOS flake with GNOME defaults, impermanence, and latest kernel from the pinned channel.

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
