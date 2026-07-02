# To update: edit manifest.json with the new version, url, and hash from
# https://github.com/anthropics/claude-code/releases — see README for hash conversion.
{
  stdenvNoCC,
  lib,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
  alsa-lib,
  procps,
  ripgrep,
  bubblewrap,
  socat,
  installShellFiles,
}:
let
  manifest = lib.importJSON ./manifest.json;
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit (manifest) version;

  src = fetchurl {
    inherit (manifest) url hash;
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    autoPatchelfHook
    installShellFiles
  ];

  buildInputs = [ alsa-lib ];

  sourceRoot = ".";

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 claude $out/bin/claude
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ alsa-lib ]} \
      --prefix PATH : ${lib.makeBinPath [ procps ripgrep bubblewrap socat ]}
    runHook postInstall
  '';

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    changelog = "https://github.com/anthropics/claude-code/releases/tag/v${manifest.version}";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
}
