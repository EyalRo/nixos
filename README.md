# dinOS

EFI-only NixOS flake with GNOME defaults (Friendly Pals wallpaper), impermanence, and latest kernel from the pinned channel.

## Secrets and keys (stags)

- Age identity lives on the NAS: `/mnt/stags/.config/age/keys.txt`.
- GitHub SSH key lives on the NAS: `/mnt/stags/.ssh/id_ed25519_github`.

## Simple installation (EFI)

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/switch-to-dinos.sh | bash
```

---

Example hosts:

```bash
nixos-rebuild switch --impure --flake github:EyalRo/nixos#dinOS
```

```bash
nixos-rebuild switch --flake github:EyalRo/nixos#ideapad3
```

```bash
nixos-rebuild switch --flake github:EyalRo/nixos#xps15
```
