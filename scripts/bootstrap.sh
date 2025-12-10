#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-${1:-my-laptop}}"
REPO="${REPO:-https://github.com/EyalRo/nixos.git}"
CHECKOUT="${CHECKOUT:-$HOME/nixos}"

info() { echo "==> $*"; }

if [[ -e "$CHECKOUT" ]]; then
  echo "Target checkout path already exists: $CHECKOUT" >&2
  exit 1
fi

info "Cloning $REPO to $CHECKOUT"
nix run nixpkgs#git -- clone --depth 1 "$REPO" "$CHECKOUT"

cd "$CHECKOUT"

if [[ $EUID -ne 0 ]]; then
  info "Generating hardware config for host '$HOST' (sudo)..."
  sudo nix run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
else
  info "Generating hardware config for host '$HOST'..."
  nix run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
fi

info "Switching to flake output $HOST..."
sudo nix run nixpkgs#nixos-rebuild -- switch --flake .#"${HOST}"

info "Done. Adjust hosts/$HOST/default.nix or modules/users/stags.nix as needed, then rerun nixos-rebuild."
