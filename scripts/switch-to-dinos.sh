#!/usr/bin/env bash
set -euo pipefail

pkexec env PATH="$PATH" bash -c 'nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix'
pkexec nixos-rebuild switch --impure --flake github:EyalRo/nixos#dinOS
