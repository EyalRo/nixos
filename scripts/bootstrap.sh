#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-${1:-dinOS}}"
PROFILE="${PROFILE:-dinOS}" # set to dinOS or dinOS-stags for base outputs; empty to build a host output
REPO="${REPO:-https://github.com/EyalRo/nixos.git}"
CHECKOUT="${CHECKOUT:-$HOME/nixos}"

info() { echo "==> $*"; }

# Ensure nix-command/flakes are available even on minimal installs.
NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')
nix_run() { nix "${NIX_FLAGS[@]}" run "$@"; }
nix_rebuild() { nix "${NIX_FLAGS[@]}" run nixpkgs#nixos-rebuild -- "$@"; }

case "$PROFILE" in
  dinOS|dinOS-stags) target="$PROFILE" ;;
  "")
    target="$HOST"
    ;;
  *)
    echo "Invalid PROFILE: $PROFILE (expected empty, dinOS, or dinOS-stags)" >&2
    exit 1
    ;;
esac

if [[ -e "$CHECKOUT" ]]; then
  echo "Target checkout path already exists: $CHECKOUT" >&2
  exit 1
fi

info "Cloning $REPO to $CHECKOUT"
nix_run nixpkgs#git -- clone --depth 1 "$REPO" "$CHECKOUT"

cd "$CHECKOUT"

if [[ -z "$PROFILE" ]]; then
  if [[ $EUID -ne 0 ]]; then
    info "Generating hardware config for host '$HOST' (sudo)..."
    sudo nix_run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
  else
    info "Generating hardware config for host '$HOST'..."
    nix_run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
  fi
else
  info "Using base profile $PROFILE (no host generation)."
fi

info "Switching to flake output $target..."
sudo nix_rebuild switch --refresh --flake .#"${target}"

if [[ -z "$PROFILE" ]]; then
  info "Done. Adjust hosts/$HOST/default.nix or modules/users/stags.nix as needed, then rerun nixos-rebuild."
else
  info "Done. Using base profile $PROFILE. Adjust modules as needed, then rerun nixos-rebuild."
fi
