{ pkgs, lib }:

let
  mcpSrc = pkgs.fetchFromGitea {
    domain = "forgejo.virtualdino.com";
    owner = "stags";
    repo = "mcp";
    rev = "5a821a58d3a11023955d42589d4e973732371089";
    hash = "sha256-LoOEw08bFXDDcOq4lnH4u5cZfxAoGBxR1+ltw6XoU3Q=";
  };

  # All Go servers share the same dep set (mcp-go + transitive)
  commonVendorHash = "sha256-xascwNXqt4uS3Kvo+/qGpHLhZDxmv2q8ak1IQubeV3U=";

  mkGoMcp =
    {
      name,
      dir ? name,
      vendorHash ? commonVendorHash,
      subPackages ? null,
      postInstall ? null,
    }:
    let
      baseArgs = {
        pname = name;
        version = "unstable-2026-06-29";
        src = pkgs.runCommand "${name}-src" { } "cp -rT ${mcpSrc}/${dir} $out";
        inherit vendorHash;
        meta.mainProgram = name;
      };
      extras =
        lib.optionalAttrs (subPackages != null) { inherit subPackages; }
        // lib.optionalAttrs (postInstall != null) { inherit postInstall; };
    in
    pkgs.buildGoModule (baseArgs // extras);
in
{
  forgejo-mcp = mkGoMcp { name = "forgejo-mcp"; };
  todo-mcp = mkGoMcp { name = "todo-mcp"; };
  victorialogs-mcp = mkGoMcp { name = "victorialogs-mcp"; };
  mediawatch-mcp = mkGoMcp { name = "mediawatch-mcp"; };
  prowlarr-mcp = mkGoMcp { name = "prowlarr-mcp"; };
  proxmox-mcp = mkGoMcp { name = "proxmox-mcp"; };
  radarr-mcp = mkGoMcp { name = "radarr-mcp"; };
  sonarr-mcp = mkGoMcp { name = "sonarr-mcp"; };
  grammarly-mcp = mkGoMcp {
    name = "grammarly-mcp";
    dir = "grammarly-MCP";
    subPackages = [ "cmd" ];
    vendorHash = "sha256-3GXkOgSWHpQnEFSI5TG4CRuY/vBgy1eCYKwK4iPYE8M=";
    postInstall = "mv $out/bin/cmd $out/bin/grammarly-mcp";
  };
}
