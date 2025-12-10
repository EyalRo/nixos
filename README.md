# dinOS

dinOS is a layered NixOS configuration. It’s organized in three tiers:

- **OS layer (`dinOS`)**: Shared system and GNOME settings (no user, no host specifics).
- **OS + user (`dinOS-stags`)**: Adds the `stags` user and Home Manager configuration on top of the OS layer.
- **OS + user + host (`xps15`)**: Full stack for the xps15 hardware (drivers, mounts, secrets, wallpaper, user).

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
