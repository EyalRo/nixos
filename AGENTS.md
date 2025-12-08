# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix`: entrypoint defining inputs (nixpkgs, home-manager, impermanence) and the `xps15` NixOS configuration.
- `hosts/xps15/`: system configuration (`default.nix`) plus hardware specifics.
- `home/stags/`: user-level configuration referenced by the flake.
- Persisted state is mounted under `/persist`; avoid adding mutable paths elsewhere.

## Build, Test, and Development Commands
- Dry-run the full system: `nixos-rebuild dry-run --flake .#xps15` (checks evaluation and shows downloads). Do not use `sudo`.
- Apply system changes is handled by maintainers; agents must not run privileged commands.
- Inspect flake outputs: `nix flake show`.
- Validate options quickly: `nixos-option services.xserver.xkb.layout` or other paths to confirm effective values.

## Coding Style & Naming Conventions
- Nix files use 2-space indentation; keep attribute sets alphabetized when it improves readability (e.g., package lists).
- Prefer concise comments only where intent is non-obvious; avoid redundant narration.
- Follow existing patterns: system settings live in `hosts/xps15/default.nix`; user-level packages and settings in `home/stags/default.nix`.
- Keep identifiers lowercase with hyphens or dots matching existing Nix module naming.

## Testing Guidelines
- Always run `nixos-rebuild dry-run --flake .#xps15` to validate evaluation; do not switch or apply.
- After layout/input changes, confirm via `nixos-option` or GNOME Settings; for package additions, ensure they appear in the dry-run fetch list.
- If adding services, ensure corresponding state is covered by `/persist` when needed.

## Commit & Pull Request Guidelines
- Repository lacks visible Git history; use concise, imperative commit messages (e.g., `Add Hebrew keyboard layout`, `Add bat and lsd to home profile`).
- Describe what changed and why in PRs; include relevant `nixos-rebuild dry-run` output summaries and mention any service restarts or migrations.
- Link issues if applicable; screenshots only when UI-facing changes occur.
