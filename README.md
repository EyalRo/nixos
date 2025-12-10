# dinOS

dinOS is a layered NixOS configuration. It’s organized in three tiers:

- **OS layer (`dinOS`)**: Shared desktop defaults (GNOME, fish + aliases, starship prompt, fastfetch, common apps, wallpaper, persistence defaults, Nix settings).
- **OS + user (`dinOS-stags`)**: Adds the `stags` user, Home Manager hook, tailscale client, and NAS mount/secret on top of the OS layer.
- **OS + user + host (`xps15`)**: Full stack for the xps15 hardware (boot/graphics, hostname/timezone, fprintd, machine-id bind).

## Switching configurations

Use `nixos-rebuild switch` with a flake output:

- OS only:
  ```
  sudo nixos-rebuild switch --flake github:EyalRo/nixos#dinOS
  ```
- OS + user:
  ```
  sudo nixos-rebuild switch --flake github:EyalRo/nixos#dinOS-stags
  ```
- OS + user + host:
  ```
  sudo nixos-rebuild switch --flake github:EyalRo/nixos#xps15
  ```

Note: the generic/user outputs currently include the xps15 hardware config; other machines need their own host-specific output.
