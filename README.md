# dinOS

dinOS is the NixOS flake configuration I use around my home and for my
Kubernetes cluster.

You're welcome to use this repo as a template for your own setup. I'm
aiming for an idiomatic Nix flake layout and learning as I go.

Contributions are very welcome. If you want to add your own host or
configuration to this flake, I'm happy to include it so we can all
experiment together.

Layout:
- modules/dinOS/: public, generic OS/desktop defaults.
- modules/dinOS/profiles/: device-agnostic role bundles (SSH, k8s, etc).
- modules/users/: personal user layers (stags).
- hosts/: per-device hardware and host-specific overrides.

Build and switch commands:
```
sudo nixos-rebuild switch --flake .#dinOS --impure
sudo nixos-rebuild switch --flake .#xps15
```

Outputs: dinOS, ideapad3, nuc14, xps15, m710q-1, m710q-2, rpi5-1

## Package conventions

### External binary packages (`pkgs/<name>/`)

Packages that distribute pre-built binaries (e.g. `claude-code`, `opencode-desktop`,
`telegram-desktop`) follow a two-file layout:

- `manifest.json` — version pin and download URL/hash. **This is the only file to
  edit when bumping a version.** Update `version`, `url`, and `hash`, then run
  `nixos-rebuild switch`.
- `default.nix` — derivation that reads from `manifest.json` via `lib.importJSON`.
  Rarely needs to change.

To get the hash for a new release: download the asset's `SHASUMS256.txt`, take the
hex SHA-256 for the relevant file, then convert to SRI format:
```
printf '%b' "$(echo '<hex>' | sed 's/../\\x&/g')" | base64 -w0
# Prefix result with "sha256-"
```

### Source packages (`pkgs/mcp/`)

Go MCP servers are built from source via `buildGoModule`. The Nix store caches the
build output by content hash, so recompilation only happens when the source rev or
vendor hash changes — not on every switch.
