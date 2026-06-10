{ stdenv, lib, fetchurl, appimageTools }:

let
  version = "1.1.208";
  sha256 = "e5e17716b926ab9533bc3a31a18c35b662be98b634b08e8ef56685de524b10b0";
  pname = "melia";

  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = fetchurl {
      url = "https://github.com/buxjr311/melia-app/releases/download/v${version}/melia_${version}_x64.AppImage";
      inherit sha256;
    };
  };
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/buxjr311/melia-app/releases/download/v${version}/melia_${version}_x64.AppImage";
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
    Exec=${pname} %U
    Icon=${pname}
    Categories=Network;Email;
    MimeType=message/rfc822;x-scheme-handler/mailto;
    Terminal=false
    EOF

    cp ${appimageContents}/usr/share/icons/hicolor/512x512/apps/melia.png \
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
