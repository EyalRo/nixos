# dinOS

Layered NixOS configs with two device-agnostic profiles:
- `dinOS`: OS-only desktop defaults (GNOME, fish/starship, wallpaper, impermanence defaults, Nix settings).
- `dinOS-stags`: OS + personal `stags` user (Home Manager, tailscale, NAS mount/secret, age key path).

A host-specific output (`xps15`) is provided for that machine; other hosts can be generated on demand.

## Install on a new machine (recommended path)

Run the bootstrap script on the target machine. It will clone the repo, generate hardware config for host `dinOS`, and switch to that output (includes the `stags` user):

```bash
# on the new machine
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
```

Afterward, tweak `hosts/dinOS/default.nix` or `modules/users/stags.nix` if needed (e.g., `/persist`, NAS mount, age key path) and rerun `nixos-rebuild switch --flake .#dinOS` if you make changes.

## Apply on an existing NixOS system (reuse current disks)

If you already have NixOS running with sudo and just want to adopt this flake (no disk changes), use a single `HOST` variable to set the new hostname/output name:

```bash
NIX_FLAGS="--extra-experimental-features 'nix-command flakes'"
HOST=peppa   # change this to your desired hostname/output

nix $NIX_FLAGS run nixpkgs#git -- clone https://github.com/EyalRo/nixos.git ~/nixos
cd ~/nixos

mkdir -p hosts/$HOST
sudo cp /etc/nixos/hardware-configuration.nix hosts/$HOST/
cat > hosts/$HOST/default.nix <<EOF
{ lib, ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "${HOST}";
}
EOF

sudo nixos-rebuild switch --flake .#$HOST
```
