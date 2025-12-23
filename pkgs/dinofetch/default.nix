{ stdenv, zig }:

stdenv.mkDerivation {
  pname = "dinofetch";
  version = "0.1.0";

  src = ../../source/dinofetch;

  nativeBuildInputs = [ zig ];

  buildPhase = ''
    runHook preBuild
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-cache"
    zig build -Doptimize=ReleaseSafe
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 zig-out/bin/dinofetch $out/bin/dinofetch
    runHook postInstall
  '';

  meta.mainProgram = "dinofetch";
}
