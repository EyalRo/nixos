{ config, lib, pkgs, ... }:
let
  rbacEnabled = lib.elem "RBAC" config.services.kubernetes.apiserver.authorizationMode;
in
{
  boot.kernelModules = [
    "br_netfilter"
    "iscsi_tcp"
    "overlay"
  ];
  boot.kernel.sysctl."net.bridge.bridge-nf-call-iptables" = lib.mkDefault 1;
  boot.kernel.sysctl."net.bridge.bridge-nf-call-ip6tables" = lib.mkDefault 1;
  boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;

  swapDevices = lib.mkForce [ ];

  services.openiscsi.enable = true;
  services.openiscsi.name = lib.mkDefault "iqn.2024-01.dino:${config.networking.hostName}";

  services.kubernetes.apiserver.allowPrivileged = true;

  virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri".sandbox_image =
    "registry.k8s.io/pause:3.9";

  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  environment.persistence."/persist".directories = [
    "/etc/kubernetes"
    "/var/lib/cni"
    "/var/lib/containerd"
    "/var/lib/iscsi"
    "/var/lib/kubelet"
    "/var/lib/longhorn"
  ];

  networking.firewall.allowedTCPPorts = [
    6443
    8888
    10250
  ];

  # Ensure control plane can resolve node names without mDNS.
  networking.extraHosts = ''
    192.168.1.21 m710q-1
    192.168.1.22 m710q-2
  '';

  services.kubernetes.addonManager.bootstrapAddons = lib.mkIf rbacEnabled {
    flannel-cr = {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRole";
      metadata = {
        name = "flannel";
      };
      rules = lib.mkForce [
        {
          apiGroups = [ "" ];
          resources = [ "pods" ];
          verbs = [ "get" ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "nodes" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "nodes/status" ];
          verbs = [ "patch" ];
        }
      ];
    };

    flannel-crb = {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRoleBinding";
      metadata = {
        name = "flannel";
      };
      roleRef = {
        apiGroup = "rbac.authorization.k8s.io";
        kind = "ClusterRole";
        name = "flannel";
      };
      subjects = [
        {
          kind = "User";
          name = "flannel-client";
        }
      ];
    };
  };
}
