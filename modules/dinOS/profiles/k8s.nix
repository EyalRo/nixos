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
  boot.kernel.sysctl."vm.max_map_count" = lib.mkForce 262144;

  swapDevices = lib.mkForce [ ];

  services.openiscsi.enable = true;
  services.openiscsi.name = lib.mkDefault "iqn.2024-01.dino:${config.networking.hostName}";

  services.kubernetes.apiserver.allowPrivileged = true;
  services.kubernetes.controllerManager.extraOpts = lib.mkAfter ''
    --cluster-signing-cert-file=/var/lib/cfssl/ca.pem
    --cluster-signing-key-file=/var/lib/cfssl/ca-key.pem
  '';
  services.kubernetes.kubelet.extraOpts = lib.mkAfter "--cluster-dns=10.0.0.254";

  virtualisation.containerd.settings.plugins."io.containerd.grpc.v1.cri".sandbox_image =
    "registry.k8s.io/pause:3.9";

  environment.systemPackages = with pkgs; [
    openiscsi
    nfs-utils
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/sbin/iscsiadm"
    "d /var/lib/cfssl 0750 cfssl kubernetes - -"
    "f /var/lib/cfssl/ca.pem 0644 cfssl kubernetes - -"
    "f /var/lib/cfssl/ca-key.pem 0640 cfssl kubernetes - -"
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
    192.168.1.23 rpi5-1
    192.168.1.240 nfs-share.nfs-share.svc.cluster.local nfs-share
  '';

  services.kubernetes.addonManager.bootstrapAddons = lib.mkMerge [
    {
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

      coredns-deployment = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = "coredns";
          namespace = "kube-system";
          labels = {
            "addonmanager.kubernetes.io/mode" = "Reconcile";
            "k8s-app" = "kube-dns";
            "kubernetes.io/cluster-service" = "true";
            "kubernetes.io/name" = "CoreDNS";
          };
        };
        spec = {
          replicas = 2;
          selector = {
            matchLabels = {
              "k8s-app" = "kube-dns";
            };
          };
          strategy = {
            rollingUpdate = {
              maxUnavailable = 1;
            };
            type = "RollingUpdate";
          };
          template = {
            metadata = {
              labels = {
                "k8s-app" = "kube-dns";
              };
            };
            spec = {
              containers = [
                {
                  name = "coredns";
                  image = "coredns/coredns:1.10.1";
                  imagePullPolicy = "IfNotPresent";
                  args = [
                    "-conf"
                    "/etc/coredns/Corefile"
                  ];
                  livenessProbe = {
                    failureThreshold = 5;
                    httpGet = {
                      path = "/health";
                      port = 10054;
                      scheme = "HTTP";
                    };
                    initialDelaySeconds = 60;
                    periodSeconds = 10;
                    successThreshold = 1;
                    timeoutSeconds = 5;
                  };
                  ports = [
                    {
                      containerPort = 10053;
                      name = "dns";
                      protocol = "UDP";
                    }
                    {
                      containerPort = 10053;
                      name = "dns-tcp";
                      protocol = "TCP";
                    }
                    {
                      containerPort = 10055;
                      name = "metrics";
                      protocol = "TCP";
                    }
                  ];
                  resources = {
                    limits = {
                      memory = "170Mi";
                    };
                    requests = {
                      cpu = "100m";
                      memory = "70Mi";
                    };
                  };
                  securityContext = {
                    allowPrivilegeEscalation = false;
                    capabilities = {
                      drop = [ "all" ];
                    };
                    readOnlyRootFilesystem = true;
                  };
                  volumeMounts = [
                    {
                      mountPath = "/etc/coredns";
                      name = "config-volume";
                      readOnly = true;
                    }
                  ];
                }
              ];
              dnsPolicy = "Default";
              nodeSelector = {
                "beta.kubernetes.io/os" = "linux";
              };
              serviceAccountName = "coredns";
              tolerations = [
                {
                  effect = "NoSchedule";
                  key = "node-role.kubernetes.io/master";
                }
                {
                  key = "CriticalAddonsOnly";
                  operator = "Exists";
                }
              ];
              volumes = [
                {
                  name = "config-volume";
                  configMap = {
                    name = "coredns";
                    items = [
                      {
                        key = "Corefile";
                        path = "Corefile";
                      }
                    ];
                  };
                }
              ];
            };
          };
        };
      };
    }
    (lib.mkIf rbacEnabled {
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
    })
  ];
}
