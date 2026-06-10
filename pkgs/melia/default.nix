{ stdenv, lib, fetchurl, appimageTools, copyDesktopItems, makeWrapper }:

let
  version = "1.1.170";
  sha256 = "9fff831262d3151ccddcdb4b5570978dad0fae904a0d3d2c8c1d8cd93bdf5279";
  pname = "melia";

  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = fetchurl {
      url = "https://github.com/buxjr311/box-app/releases/download/v${version}/box_${version}_x64.AppImage";
      inherit sha256;
    };
  };
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/buxjr311/box-app/releases/download/v${version}/box_${version}_x64.AppImage";
    inherit sha256;
  };

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor

    cp ${appimageContents}/*.desktop $out/share/applications/${pname}.desktop

    for size in 32 44 64 71 89 107 128 142 150 284 310; do
      mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
      icon="${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps"
      if [ -d "$icon" ]; then
        cp "$icon"/*.png $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png 2>/dev/null || true
      fi
    done

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}' \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=${pname} --no-sandbox' || true
  '';

  meta = with lib; {
    description = "A privacy-first desktop email client for Linux";
    homepage = "https://melia.buxjr.com";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = [ ];
  };
}
