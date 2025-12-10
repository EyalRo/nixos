# dinOS

Layered NixOS configs with two device-agnostic profiles:
- `dinOS`: OS-only desktop defaults (GNOME, fish/starship, wallpaper, impermanence defaults, Nix settings).
- `dinOS-stags`: OS + personal `stags` user (Home Manager, tailscale, NAS mount/secret, age key path).

A host-specific output (`xps15`) is provided for that machine; other hosts can be generated on demand.

## Install via bootstrap script (recommended)

Fetch and run directly from GitHub. Defaults: `PROFILE=dinOS`, `HOST=dinOS`, checkout at `~/nixos`.

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
```

Options (environment variables):
- `PROFILE`: `dinOS` (default) or `dinOS-stags`. Leave empty to generate a host-specific output (requires `HOST` and runs `nixos-generate-config`).
- `HOST`: defaults to `dinOS`; used when `PROFILE` is empty to name the host output.
- `REPO`: repo URL (default `https://github.com/EyalRo/nixos.git`).
- `CHECKOUT`: local path for the clone (default `~/nixos`).

Examples:
- Personal stack on any machine:
  ```bash
  PROFILE=dinOS-stags curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
  ```
- Create a host-specific output named `zeus` (generates hardware config; includes `stags` user):
  ```bash
  PROFILE= HOST=zeus curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
  ```
- Use the existing `xps15` host output directly (pre-existing host config):
  ```bash
  sudo nixos-rebuild switch --flake github:EyalRo/nixos#xps15
  ```

After running the script, adjust `hosts/<host>/default.nix` or `modules/users/stags.nix` if needed (e.g., `/persist`, NAS mount, age key path), then rerun `nixos-rebuild`.
