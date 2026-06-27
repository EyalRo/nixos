# dinOS

dinOS is the NixOS flake configuration I use around my home and for my
Kubernetes cluster.

You're welcome to use this repo as a template for your own setup. I'm
aiming for an idiomatic Nix flake layout and learning as I go.

Contributions are very welcome. If you want to add your own host or
configuration to this flake, I'm happy to include it so we can all
experiment together.

Layout:
- modules/dinOS/: public, generic OS/desktop defaults.
- modules/dinOS/profiles/: device-agnostic role bundles (SSH, k8s, etc).
- modules/users/: personal user layers (stags).
- hosts/: per-device hardware and host-specific overrides.

Build and switch commands:
```
sudo nixos-rebuild switch --flake .#dinOS --impure
sudo nixos-rebuild switch --flake .#xps15
```

Outputs: dinOS, ideapad3, nuc14, xps15, m710q-1, m710q-2, rpi5-1
