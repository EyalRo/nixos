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
# Decide boot loader based on firmware type.
if [[ -d /sys/firmware/efi ]]; then
  info "Detected EFI firmware; enabling systemd-boot."
  boot_loader_block=$(cat <<'EOF'
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
EOF
)
else
  root_device=$(findmnt -n -o SOURCE / || true)
  boot_device=""
  if [[ -n "$root_device" ]]; then
    boot_device=$(lsblk -no pkname "$root_device" 2>/dev/null | head -n 1 || true)
  fi

  if [[ -z "$boot_device" ]]; then
    cat <<'EOF' >&2
Could not detect a boot disk for BIOS installs.
Please set boot.loader.grub.devices manually in hosts/<host>/default.nix.
EOF
    exit 1
  fi

  info "Detected BIOS/legacy boot; enabling GRUB on /dev/${boot_device}."
  boot_loader_block=$(cat <<EOF
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/${boot_device}" ];
EOF
)
fi

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

cat > "$host_dir/default.nix" <<EOF
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

${boot_loader_block}
}
EOF

info "Switching to flake output $HOST..."
sudo env "NIX_CONFIG=$NIX_CONFIG" nix "${NIX_FLAGS[@]}" run nixpkgs#nixos-rebuild -- switch --refresh --flake "path:${CHECKOUT}#${HOST}"

info "Rebooting into the new configuration..."
if [[ $EUID -ne 0 ]]; then
  sudo reboot
else
  reboot
fi
