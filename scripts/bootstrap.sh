#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-$(hostname)}"
PROFILE="${PROFILE:-}" # set to dinOS or dinOS-stags to use base outputs; empty to build a host output
REPO="${REPO:-https://github.com/EyalRo/nixos.git}"
CHECKOUT="${CHECKOUT:-$HOME/nixos}"

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--host NAME] [--profile dinOS|dinOS-stags] [--repo URL] [--checkout PATH]
Defaults: host=$(hostname), profile=<host output>, repo=https://github.com/EyalRo/nixos.git, checkout=~/nixos
When profile is set (dinOS or dinOS-stags), the script does a dry-run build only; to switch, generate a host output.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --checkout) CHECKOUT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

# Ensure nix-command/flakes are enabled even on minimal installs.
export NIX_CONFIG="${NIX_CONFIG:-extra-experimental-features = nix-command flakes}"

info() { echo "==> $*"; }

NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')

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
nix "${NIX_FLAGS[@]}" run nixpkgs#git -- clone --depth 1 "$REPO" "$CHECKOUT"

cd "$CHECKOUT"

if [[ -z "$PROFILE" ]]; then
  if [[ $EUID -ne 0 ]]; then
    info "Generating hardware config for host '$HOST' (sudo)..."
    sudo env "NIX_CONFIG=$NIX_CONFIG" nix "${NIX_FLAGS[@]}" run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
  else
    info "Generating hardware config for host '$HOST'..."
    nix "${NIX_FLAGS[@]}" run nixpkgs#bash -- ./scripts/new-host.sh "$HOST"
  fi

  info "Switching to flake output $target..."
  sudo env "NIX_CONFIG=$NIX_CONFIG" nix "${NIX_FLAGS[@]}" run nixpkgs#nixos-rebuild -- switch --refresh --flake .#"${target}"
  info "Done. Adjust hosts/$HOST/default.nix or modules/users/stags.nix as needed, then rerun nixos-rebuild."
else
  info "Using base profile $PROFILE (no host generation)."
  info "Performing dry-run for $target..."
  nix "${NIX_FLAGS[@]}" run nixpkgs#nixos-rebuild -- dry-run --refresh --flake .#"${target}"
  info "Base profiles are device-agnostic; generate a host (run without PROFILE) to switch on this machine."
fi
