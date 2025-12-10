# dinOS

Layered NixOS configs with two device-agnostic profiles:
- `dinOS`: OS-only desktop defaults (GNOME, fish/starship, wallpaper, impermanence defaults, Nix settings).
- `dinOS-stags`: OS + personal `stags` user (Home Manager, tailscale, NAS mount/secret, age key path).

A host-specific output (`xps15`) is provided for that machine; other hosts can be generated on demand.

## Install via bootstrap script (recommended)

Fetch and run directly from GitHub. Defaults: `HOST=$(hostname)`, `PROFILE=` (generates a host output), checkout at `~/nixos`.

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
```

Options (environment variables):
- `PROFILE`: `dinOS` or `dinOS-stags` for base profiles (dry-run only). Leave empty to generate a host-specific output (runs `nixos-generate-config` and switches).
- `HOST`: defaults to your current hostname; used when generating a host output.
- `REPO`: repo URL (default `https://github.com/EyalRo/nixos.git`).
- `CHECKOUT`: local path for the clone (default `~/nixos`).

Examples:
- Personal stack on any machine (base profile dry-run):
  ```bash
  curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash -s -- --profile dinOS-stags
  ```
- Create a host-specific output named `zeus` (generates hardware config; includes `stags` user):
  ```bash
  curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash -s -- --host zeus
  ```
- Use the existing `xps15` host output directly (pre-existing host config):
  ```bash
  sudo nixos-rebuild switch --flake github:EyalRo/nixos#xps15
  ```

Base profiles are device-agnostic and use a placeholder root; generate a host output to apply on real hardware. After running the script, adjust `hosts/<host>/default.nix` or `modules/users/stags.nix` if needed (e.g., `/persist`, NAS mount, age key path), then rerun `nixos-rebuild`.
