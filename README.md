# dinOS

Layered NixOS configs with two device-agnostic profiles:
- `dinOS`: OS-only desktop defaults (GNOME, fish/starship, wallpaper, impermanence defaults, Nix settings).
- `dinOS-stags`: OS + personal `stags` user (Home Manager, tailscale, NAS mount/secret, age key path).

A host-specific output (`xps15`) is provided for that machine; other hosts can be generated on demand.

## Install on a new machine (recommended path)

Run the bootstrap script on the target machine. It will clone the repo, generate hardware config, and switch to the new host output (includes the `stags` user):

```bash
# on the new machine
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh \
  | bash -s -- --host <your-hostname>
```

Afterward, tweak `hosts/<your-hostname>/default.nix` or `modules/users/stags.nix` if needed (e.g., `/persist`, NAS mount, age key path) and rerun `nixos-rebuild switch --flake .#<your-hostname>` if you make changes.
