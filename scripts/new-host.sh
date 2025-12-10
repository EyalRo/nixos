#!/usr/bin/env bash
set -euo pipefail

export NIX_CONFIG="${NIX_CONFIG:-extra-experimental-features = nix-command flakes}"
NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host-name>" >&2
  exit 1
fi

host="$1"

if [[ $EUID -ne 0 ]]; then
  echo "Re-running with sudo for nixos-generate-config..." >&2
  exec sudo "$0" "$host"
fi

git_cmd() {
  nix "${NIX_FLAGS[@]}" run nixpkgs#git -- "$@"
}

repo_root="$(git_cmd rev-parse --show-toplevel)"
host_dir="$repo_root/hosts/$host"

if [[ -e "$host_dir" ]]; then
  echo "Host directory already exists: $host_dir" >&2
  exit 1
fi

mkdir -p "$host_dir"

echo "Generating hardware config for host '$host'..."
nixos-generate-config --show-hardware-config > "$host_dir/hardware-configuration.nix"

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
  # networking.hostName = "mylaptop";
  # time.timeZone = "America/Los_Angeles";
  # system.stateVersion = "25.11";
}
EOF

echo "Created host skeleton under $host_dir."
echo "Add any host-specific overrides to default.nix, then run:"
echo "  nixos-rebuild dry-run --flake .#$host"
