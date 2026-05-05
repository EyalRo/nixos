{ stdenv, lib, fetchurl, appimageTools, copyDesktopItems, makeWrapper }:

let
  version = "1.14.34";
  sha256 = "f56f0710e1ed530958aa1d11403d7def5a02e87b4e093ff8ee2ef0b9067ee241";
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

    cp ${appimageContents}/@opencode-aidesktop-electron.desktop $out/share/applications/opencode-desktop.desktop

    for size in 32 44 64 71 89 107 128 142 150 284 310; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      if [ -f "${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/@opencode-aidesktop-electron.png" ]; then
        cp ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/@opencode-aidesktop-electron.png $out/share/icons/hicolor/''${size}x''${size}/apps/opencode-desktop.png
      fi
    done

    substituteInPlace $out/share/applications/opencode-desktop.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=opencode-desktop --no-sandbox %U' \
      --replace-fail 'Icon=@opencode-aidesktop-electron' 'Icon=opencode-desktop'
  '';

  meta = with lib; {
    description = "OpenCode Desktop - AI-powered coding assistant";
    homepage = "https://opencode.ai";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}