{ config, lib, ... }:
let
  rbacEnabled = lib.elem "RBAC" config.services.kubernetes.apiserver.authorizationMode;
in
{
  networking.firewall.allowedTCPPorts = [
    6443
    8888
  ];

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
