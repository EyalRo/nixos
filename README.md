# dinOS

Opinionated, layered NixOS flake.

## Layers

- **dinOS** (`modules/dinOS/`): public, generic desktop OS defaults meant to work for anyone. It owns GNOME, theme/wallpaper, core packages, Nix settings, and baseline impermanence.
- **stags** (`modules/users/stags.nix` + `home/stags/`): my personal user layer, intended to run on any of my devices. It owns my user account, personal packages/services, secrets, and per‑user persistence.
- **hosts** (`hosts/<name>/`): per‑device configuration for a single machine (hardware, bootloader, drivers, machine‑id).

## Flake Outputs

- `dinOS`: generic OS-only profile (no personal user).
- `dinOS-stags`: dinOS plus my `stags` user layer.
- `xps15`: configuration for my Dell XPS 15; composes dinOS + stags and adds hardware specifics.

## Install on a New Machine (generic dinOS)

Run the bootstrap script on the target machine. It clones the repo, generates a `hosts/dinOS/hardware-configuration.nix`, and switches to `dinOS`:

```bash
curl -fsSL https://raw.githubusercontent.com/EyalRo/nixos/main/scripts/bootstrap.sh | bash
```

Afterward, tweak `hosts/dinOS/default.nix` if you need host‑specific overrides, then rerun `nixos-rebuild switch --flake .#dinOS`.

## Apply on an Existing NixOS System

To adopt this flake without repartitioning, create a new host and switch to it:

```bash
NIX_FLAGS="--extra-experimental-features 'nix-command flakes'"
HOST=peppa   # desired hostname/output

nix $NIX_FLAGS run nixpkgs#git -- clone https://github.com/EyalRo/nixos.git ~/nixos
cd ~/nixos

mkdir -p hosts/$HOST
sudo cp /etc/nixos/hardware-configuration.nix hosts/$HOST/
cat > hosts/$HOST/default.nix <<EOF
{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "${HOST}";
}
EOF

sudo nixos-rebuild switch --flake .#$HOST
```

## Adapting dinOS for Your Own User

The `stags` layer is personal and not meant for reuse. To add your own user layer:

1. Copy `modules/users/stags.nix` to `modules/users/<you>.nix` and edit it for your username/services/secrets.
2. Add a matching Home Manager config under `home/<you>/`.
3. Wire your module into `flake.nix` and any outputs you want (similar to how `dinOS-stags` is composed).

Persist mutable state only under `/persist`, and keep host‑specific tweaks in `hosts/<name>/`.
