{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./k8s.nix
  ];

  environment.etc."machine-id".source = "/persist/etc/machine-id";
}
