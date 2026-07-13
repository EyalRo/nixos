{ stdenv, lib, fetchurl, appimageTools, copyDesktopItems, makeWrapper }:

let
  version = "1.17.18";
  sha256 = "sha256-FjRwg/tCrQ4A6NGaTETdWL6TSc3Qh/CI3SchRWj1pwQ=";
  pname = "opencode-desktop";

  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-x86_64.AppImage";
      inherit sha256;
    };
  };
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-x86_64.AppImage";
    inherit sha256;
  };

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor

    cp ${appimageContents}/ai.opencode.desktop.desktop $out/share/applications/opencode-desktop.desktop

    for size in 32 64 128; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      if [ -f "${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/ai.opencode.desktop.png" ]; then
        cp ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/ai.opencode.desktop.png $out/share/icons/hicolor/''${size}x''${size}/apps/opencode-desktop.png
      fi
    done

    substituteInPlace $out/share/applications/opencode-desktop.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=opencode-desktop --no-sandbox %U' \
      --replace-fail 'Icon=ai.opencode.desktop' 'Icon=opencode-desktop'
  '';

  meta = with lib; {
    description = "OpenCode Desktop - AI-powered coding assistant";
    homepage = "https://opencode.ai";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}