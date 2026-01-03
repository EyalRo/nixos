{ lib, pkgs, ... }:
let
  kubeMasterIP = "192.168.1.21";
  kubeMasterHostname = "k8s-1.dino.home";
  kubeMasterAPIServerPort = 6443;
in
{
  # Resolve master hostname for bootstrap.
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  # Admin tooling on the node.
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes
  ];

  # Use containerd (disable Docker on this host).
  virtualisation.containerd.enable = true;
  virtualisation.docker.enable = lib.mkForce false;

  services.kubernetes = {
    roles = [ "node" ];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
  };
}
