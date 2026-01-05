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
    openiscsi
    nfs-utils
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/sbin/iscsiadm"
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
    53
    6443
    8888
    10250
  ];
  networking.firewall.allowedUDPPorts = [
    53
  ];

  # Ensure control plane can resolve node names without mDNS.
  networking.extraHosts = ''
    192.168.1.21 m710q-1
    192.168.1.22 m710q-2
  '';

  services.kubernetes.addonManager.bootstrapAddons = lib.mkIf rbacEnabled {
    coredns-config = {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "coredns";
        namespace = "kube-system";
        labels = {
          "addonmanager.kubernetes.io/mode" = "EnsureExists";
          "k8s-app" = "kube-dns";
          "kubernetes.io/cluster-service" = "true";
        };
      };
      data = {
        Corefile = ''
          .:10053 {
            errors
            health :10054
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :10055
            forward . 192.168.1.1
            cache 30
            loop
            reload
            loadbalance
          }
        '';
      };
    };

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
