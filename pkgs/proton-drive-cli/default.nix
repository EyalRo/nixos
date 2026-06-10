{ stdenv, lib, fetchurl, installShellFiles }:

let
  version = "0.4.3";
  sha512 = "6430b087477587852eb1e44c6f9eebdf04a125fa4f66521f17acdd2ed3917a0f124a84fe56caa4242ec3a6f4a2330be4d04a7bba989359e3aefeb7cf0098a15a";
in
stdenv.mkDerivation {
  pname = "proton-drive-cli";
  inherit version;

  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
    sha512 = sha512;
  };

  sourceRoot = ".";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/proton-drive
    chmod +x $out/bin/proton-drive
    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line interface for Proton Drive cloud storage";
    homepage = "https://proton.me/drive";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = [ ];
  };
}
