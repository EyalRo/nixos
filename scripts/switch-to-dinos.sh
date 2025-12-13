#!/usr/bin/env bash
set -euo pipefail

sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
sudo nixos-rebuild switch --impure --flake github:EyalRo/nixos#dinOS
