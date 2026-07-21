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

  # Trusts bridge-gateway's self-signed cert (CT 204, 192.168.0.50) system-wide
  # so mail clients (Geary, etc.) don't need a per-app "accept self-signed"
  # toggle - several don't reliably surface one during account setup.
  # bridge-gateway regenerates its cert if its files ever go missing on CT 204
  # (see stags/pachy Specs-2026-07-21-Bridge-Gateway-Design); if that happens,
  # re-fetch it and replace this file:
  #   openssl s_client -connect 192.168.0.50:1143 -starttls imap </dev/null 2>/dev/null | openssl x509 -outform PEM > hosts/z590i/certs/bridge-gateway.pem
  security.pki.certificateFiles = [ ./certs/bridge-gateway.pem ];
}
