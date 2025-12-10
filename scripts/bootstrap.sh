#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-${1:-my-laptop}}"
PROFILE="${PROFILE:-}" # set to dinOS or dinOS-stags to use base outputs
REPO="${REPO:-https://github.com/EyalRo/nixos.git}"
CHECKOUT="${CHECKOUT:-$HOME/nixos}"

info() { echo "==> $*"; }

if [[ -n "$PROFILE" ]]; then
  case "$PROFILE" in
    dinOS|dinOS-stags) target="$PROFILE" ;;
    *)
      echo "Invalid PROFILE: $PROFILE (expected empty, dinOS, or dinOS-stags)" >&2
      exit 1
      ;;
  esac
else
  target="$HOST"
fi

if [[ -e "$CHECKOUT" ]]; then
  echo "Target checkout path already exists: $CHECKOUT" >&2
  exit 1
fi

info "Cloning $REPO to $CHECKOUT"
nix run nixpkgs#git -- clone --depth 1 "$REPO" "$CHECKOUT"

cd "$CHECKOUT"

if [[ -z "$PROFILE" ]]; then
  if [[ $EUID -ne 0 ]]; then
    info "Generating hardware config for host '$HOST' (sudo)..."
    sudo nix run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
  else
    info "Generating hardware config for host '$HOST'..."
    nix run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
  fi
else
  info "Skipping hardware config generation (using base profile $PROFILE)"
fi

info "Switching to flake output $target..."
sudo nix run nixpkgs#nixos-rebuild -- switch --flake .#"${target}"

if [[ -z "$PROFILE" ]]; then
  info "Done. Adjust hosts/$HOST/default.nix or modules/users/stags.nix as needed, then rerun nixos-rebuild."
else
  info "Done. Using base profile $PROFILE. Adjust modules as needed, then rerun nixos-rebuild."
fi
