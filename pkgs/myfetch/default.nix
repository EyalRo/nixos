{ stdenv, zig }:

stdenv.mkDerivation {
  pname = "myfetch";
  version = "0.1.0";

  src = ../../tools/myfetch;

  nativeBuildInputs = [ zig ];

  buildPhase = ''
    runHook preBuild
    zig build -Doptimize=ReleaseSafe
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 zig-out/bin/myfetch $out/bin/myfetch
    runHook postInstall
  '';

  meta.mainProgram = "myfetch";
}
