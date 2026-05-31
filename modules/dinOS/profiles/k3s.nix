{ config, pkgs, lib, ... }:

let
  cfg = config.dinOS.profiles.k3s;
in
{
  options.dinOS.profiles.k3s = {
    enable = lib.mkEnableOption "k3s Kubernetes node";

    role = lib.mkOption {
      type = lib.types.enum [ "server" "agent" ];
      default = "agent";
      description = "k3s role: server (control plane) or agent (worker node).";
    };

    serverUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "URL of the k3s server to join (required for agent role).";
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing the k3s cluster token.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra arguments to pass to k3s.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.k3s = {
      enable = true;
      role = cfg.role;
      clusterInit = cfg.role == "server";
      extraFlags = lib.concatStringsSep " " (
        lib.optional (cfg.serverUrl != null) "--server ${cfg.serverUrl}"
        ++ lib.optional (cfg.tokenFile != null) "--token-file ${cfg.tokenFile}"
        ++ cfg.extraArgs
      );
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.role == "server") [
      6443  # k3s API server
      2379  # etcd client
      2380  # etcd peers
    ];

    networking.firewall.allowedUDPPorts = [
      8472  # VXLAN (Flannel)
    ];

    # Disable swap for Kubernetes
    swapDevices = [];

    # Kernel params for cgroups (required by k3s)
    boot.kernelParams = [
      "cgroup_enable=cpuset"
      "cgroup_enable=memory"
      "cgroup_memory=1"
    ];

    # Containerd is bundled with k3s, but ensure cgroup v2 is enabled
    systemd.settings.Manager = {
      CPUAccounting = "yes";
      MemoryAccounting = "yes";
      IOAccounting = "yes";
    };

    # Minimal docs for server nodes
    documentation.enable = lib.mkIf (cfg.role == "agent") false;
    documentation.nixos.enable = lib.mkIf (cfg.role == "agent") false;
    documentation.man.enable = lib.mkIf (cfg.role == "agent") false;
    documentation.info.enable = lib.mkIf (cfg.role == "agent") false;
    documentation.doc.enable = lib.mkIf (cfg.role == "agent") false;
  };
}
