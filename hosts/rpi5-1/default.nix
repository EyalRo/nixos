{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./k8s.nix
  ];

  # /persist folders are created manually on this host.
}
