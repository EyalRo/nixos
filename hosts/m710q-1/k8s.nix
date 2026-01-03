{ lib, pkgs, ... }:
let
  kubeMasterIP = "192.168.1.21";
  kubeMasterHostname = "k8s-1.dino.home";
  kubeMasterAPIServerPort = 6443;
in
{
  # Resolve master hostname for bootstrap.
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  # Admin tooling on the control plane host.
  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
  ];

  # Use containerd (disable Docker on this host).
  virtualisation.containerd.enable = true;
  virtualisation.docker.enable = lib.mkForce false;

  services.kubernetes = {
    roles = [
      "master"
      "node"
    ];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };

    addons.dns.enable = true;
  };
}
