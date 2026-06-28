- Split the big let in flake.nix into named sections: profiles, users, hosts,
  helpers, and keep nixosConfigurations as a short composition at the end.
- Extract the shared "k8s node" host settings into a small module (e.g., hosts/
  common/k8s-node.nix) and import it from hosts/m710q-2/k8s.nix and hosts/rpi5-1/
  k8s.nix to avoid duplication.
- Consider grouping host profile/user mappings into a single attrset with per-
  host keys (e.g., { profiles = [...]; users = [...]; }), then have mkHost read
  from that; reduces cross-referencing.
- Keep baseConfigurations and nixosConfigurations definitions adjacent and
  minimal; remove intermediate inherit and just inline where it's used.
