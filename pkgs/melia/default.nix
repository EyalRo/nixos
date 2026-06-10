{ stdenv, lib, fetchurl, appimageTools }:

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
    mkdir -p $out/share/icons/hicolor/512x512/apps

    cat > $out/share/applications/${pname}.desktop <<EOF
    [Desktop Entry]
    Version=1.5
    Type=Application
    Name=Melia
    GenericName=Email Client
    Comment=A privacy-first desktop email client for Linux
    Exec=${pname}
    Icon=${pname}
    Categories=Network;Email;
    MimeType=message/rfc822;x-scheme-handler/mailto;
    Terminal=false
    EOF

    cp ${appimageContents}/usr/share/icons/hicolor/512x512/apps/box.png \
      $out/share/icons/hicolor/512x512/apps/${pname}.png
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
