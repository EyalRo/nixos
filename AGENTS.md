# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix`: entrypoint defining inputs (nixpkgs, home-manager, impermanence, agenix) and flake outputs for the layers.
- `modules/dinOS/`: OS layer (GNOME, fish/starship, fastfetch, shared packages, wallpaper, persistence defaults, Nix settings, unfree allowance).
- `modules/users/`: user layers (e.g., `stags.nix` adds the user, tailscale, NAS secret/mount, per-user persistence).
- `hosts/xps15/`: host-specific configuration (hardware, bootloader, graphics, machine-id binding).
- Home config lives in `home/stags/` and is wired via Home Manager from the user layer.
- Persisted state mounts under `/persist`; add mutable paths there only.

## Build, Test, and Development Commands
- Dry-run the full system: `nixos-rebuild dry-run --flake .#xps15` (or the desired output). Do not use `sudo`.
- Apply system changes is handled by maintainers; agents must not run privileged commands.
- Inspect flake outputs: `nix flake show`.
- Validate options quickly: `nixos-option services.xserver.xkb.layout` or other paths to confirm effective values.

## Coding Style & Naming Conventions
- Nix files use 2-space indentation; keep attribute sets alphabetized when it improves readability (e.g., package lists).
- Prefer concise comments only where intent is non-obvious; avoid redundant narration.
- Follow existing patterns: shared system defaults in `modules/dinOS`; user additions in `modules/users/`; host-specific wiring in `hosts/xps15`.
- Keep identifiers lowercase with hyphens or dots matching existing Nix module naming.

## Testing Guidelines
- Always run `nixos-rebuild dry-run --flake .#xps15` to validate evaluation; do not switch or apply.
- After layout/input changes, confirm via `nixos-option` or GNOME Settings; for package additions, ensure they appear in the dry-run fetch list.
- If adding services, ensure corresponding state is covered by `/persist` when needed.

## Commit & Pull Request Guidelines
- Repository lacks visible Git history; use concise, imperative commit messages (e.g., `Add Hebrew keyboard layout`, `Add bat and lsd to home profile`).
- Describe what changed and why in PRs; include relevant `nixos-rebuild dry-run` output summaries and mention any service restarts or migrations.
- Link issues if applicable; screenshots only when UI-facing changes occur.
