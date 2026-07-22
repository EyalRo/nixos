{ pkgs, lib }:

let
  mcpSrc = pkgs.fetchFromGitea {
    domain = "forgejo.virtualdino.com";
    owner = "stags";
    repo = "mcp";
    rev = "18186da";
    hash = "sha256-QdsKopCSPpvb0jf1z1nKZnNJsb4yefxYuA9oOSwo3D4=";
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
  todo-mcp = mkGoMcp { name = "todo-mcp"; };
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
  linkedin-mcp = pkgs.writeShellScriptBin "linkedin-mcp" ''
    exec ${pkgs.nodejs}/bin/npx -y @pegasusheavy/linkedin-mcp "$@"
  '';
  homepage-secrets-mcp = pkgs.writeShellScriptBin "homepage-secrets-mcp" ''
    exec ${pkgs.deno}/bin/deno run --allow-net --allow-env ${mcpSrc}/homepage-secrets-mcp/mod.ts "$@"
  '';
}
