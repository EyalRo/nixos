#!/usr/bin/env bash
set -euo pipefail

OLD_UID=1000
NEW_UID=1026
USER=stags
NIXOS_CONFIG=/home/stags/Source/nixos

if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

echo "Killing all processes for $USER..."
pkill -u "$USER" || true
sleep 1

echo "Changing UID from $OLD_UID to $NEW_UID..."
usermod -u "$NEW_UID" "$USER"

echo "Fixing file ownership in /home/$USER..."
find "/home/$USER" -user "$OLD_UID" -exec chown -h "$NEW_UID" {} \;

echo "Switching NixOS configuration..."
nh os switch "$NIXOS_CONFIG" -- --cores 10
