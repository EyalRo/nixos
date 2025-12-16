# Repository Guidelines

## Layering Model
This flake is intentionally split into three layers with different audiences:

- `modules/dinOS/` (dinOS): public, generic OS/desktop defaults for anyone.
  - Owns: GNOME desktop + theme, wallpapers/backgrounds, core system packages, Nix settings, baseline impermanence/persistence, and global system defaults (firmware, `system.stateVersion`, etc).
  - Must not: assume a particular username, home network, secrets, or hardware model.

- `modules/users/stags.nix` + `home/stags/` (stags): personal user layer for stags, intended to work on any of my devices.
  - Owns: the `stags` user account, personal packages and services (tailscale/NAS/etc), timezone, age/agenix secrets, and per‑user persistence.
  - Should stay device‑agnostic; no hardware‑specific tweaks here.

- `hosts/<name>/`: per-device configuration for a single machine.
  - Owns: `hardware-configuration.nix`, bootloader/disk layout, graphics/drivers, CPU microcode, machine‑id binding, and any quirks unique to that box.
  - Keep minimal to avoid duplicating dinOS or user defaults.

Persisted state mounts under `/persist`; add mutable paths there only.

## GNOME & Wallpapers
- Wallpaper assets live in `modules/dinOS/wallpaper`. Register backgrounds in dinOS only; do not pin wallpapers via per-user dconf in `home-manager` so user changes persist.
- Default wallpaper is Friendly Pals (day/night variants) set through system dconf defaults; Dinosaur Picnic remains available in GNOME’s background picker.

## Build, Test, and Development Commands
- Dry-run evaluation: `nixos-rebuild dry-run --flake .#xps15` (or another output). Do not use `sudo`.
- Privileged switches are handled by maintainers; agents must not run privileged commands.
- Inspect flake outputs: `nix flake show`.
- Validate effective options: `nixos-option <path>`.

## Coding Style & Naming Conventions
- Nix files use 2-space indentation; alphabetize lists/attrsets when it improves readability.
- Prefer concise intent‑level comments; avoid redundant narration.
- Put changes in the right layer (dinOS vs user vs host); avoid cross‑layer coupling.
- Keep identifiers lowercase with hyphens/dots matching existing module naming.

## Testing Guidelines
- Always run `nixos-rebuild dry-run --flake .#<output>` after changes.
- After input/layout changes, confirm via `nixos-option` or GNOME Settings.
- If adding services, ensure required mutable state is persisted under `/persist`.

## Commit & Pull Request Guidelines
- Use concise, imperative commit messages.
- PRs should state what/why, include `dry-run` notes, and mention any migrations or service restarts.
