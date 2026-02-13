{ stdenv, crystal, gtk4, shards }:

stdenv.mkDerivation {
  pname = "crystal-sysinfo";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ crystal shards git ];

  buildInputs = [ gtk4 ];

  crystalBuildFlags = [ "--release" ];

  buildPhase = ''
    runHook preBuild
    shards install
    crystal build src/helloworld.cr --release --linker=gcc -o crystal-sysinfo
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 crystal-sysinfo $out/bin/crystal-sysinfo
    runHook postInstall
  '';

  meta.mainProgram = "crystal-sysinfo";
  meta.platforms = [ "x86_64-linux" ];
}