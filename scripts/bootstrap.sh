#!/usr/bin/env bash
set -euo pipefail

HOST="dinOS"
REPO="${REPO:-https://github.com/EyalRo/nixos.git}"
CHECKOUT="${CHECKOUT:-$HOME/nixos}"

usage() {
  cat <<EOF
Usage: bootstrap.sh [--host NAME] [--repo URL] [--checkout PATH]
Defaults: host=dinOS, repo=https://github.com/EyalRo/nixos.git, checkout=~/nixos
Clones the repo, creates a new host using this machine's hardware config, switches to that output, then reboots.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
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

if [[ -e "$CHECKOUT" ]]; then
  echo "Target checkout path already exists: $CHECKOUT" >&2
  exit 1
fi

info "Cloning $REPO to $CHECKOUT"
nix "${NIX_FLAGS[@]}" run nixpkgs#git -- clone --depth 1 "$REPO" "$CHECKOUT"

cd "$CHECKOUT"

host_dir="$CHECKOUT/hosts/$HOST"

if [[ -e "$host_dir" ]]; then
  echo "Host directory already exists: $host_dir" >&2
  exit 1
fi

mkdir -p "$host_dir"

info "Saving hardware config for host '$HOST'..."
if [[ -f /etc/nixos/hardware-configuration.nix ]]; then
  if [[ $EUID -ne 0 ]]; then
    sudo cp /etc/nixos/hardware-configuration.nix "$host_dir/hardware-configuration.nix"
  else
    cp /etc/nixos/hardware-configuration.nix "$host_dir/hardware-configuration.nix"
  fi
else
  generate_hardware_config() {
    nixos-generate-config --show-hardware-config > "$host_dir/hardware-configuration.nix"
  }

  if [[ $EUID -ne 0 ]]; then
    sudo env "NIX_CONFIG=$NIX_CONFIG" bash -c "$(declare -f generate_hardware_config); generate_hardware_config"
  else
    generate_hardware_config
  fi
fi

cat > "$host_dir/default.nix" <<'EOF'
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Host-specific tweaks go here. By default, networking.hostName is set from
  # the flake (see mkHost in flake.nix) and modules/dinOS + modules/users/stags
  # are composed automatically.
  #
  # Example overrides:
  # networking.hostName = "dinOS";
  # time.timeZone = "America/Los_Angeles";
  # system.stateVersion = "25.11";
}
EOF

info "Switching to flake output $HOST..."
sudo env "NIX_CONFIG=$NIX_CONFIG" nix "${NIX_FLAGS[@]}" run nixpkgs#nixos-rebuild -- switch --refresh --flake .#"${HOST}"

info "Rebooting into the new configuration..."
if [[ $EUID -ne 0 ]]; then
  sudo reboot
else
  reboot
fi
