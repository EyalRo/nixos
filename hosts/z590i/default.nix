{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  nix.settings = {
    max-jobs = 2;
    cores = 2;
  };

  # Cloudflare Tunnel — exposes todo.virtualdino.com → localhost:7410
  #
  # Setup (run once on z590i):
  #   cloudflared tunnel create todo
  #   cloudflared tunnel route dns todo todo.virtualdino.com
  #   # Credentials JSON is saved to ~/.cloudflared/<tunnel-id>.json
  #   # Encrypt it: agenix -e secrets/cloudflared-todo-token.age < ~/.cloudflared/<id>.json
  #
  # cloudflared uses DynamicUser so the secret must be root-readable (mode 0400, owner root).
  age.secrets.cloudflaredTodoToken = {
    file = ../../secrets/cloudflared-todo-token.age;
    mode = "0400";
  };

  services.cloudflared = {
    enable = true;
    tunnels."todo" = {
      credentialsFile = config.age.secrets.cloudflaredTodoToken.path;
      default = "http_status:404";
      ingress = {
        "todo.virtualdino.com" = "http://localhost:7410";
      };
    };
  };
}
