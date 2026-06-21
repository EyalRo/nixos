{ telegram-desktop, fetchFromGitHub, minizip }:

telegram-desktop.override {
  unwrapped = telegram-desktop.unwrapped.overrideAttrs (old: rec {
    version = "6.9.3";
    src = fetchFromGitHub {
      owner = "telegramdesktop";
      repo = "tdesktop";
      rev = "v${version}";
      fetchSubmodules = true;
      hash = "sha256-QCGtESg+38lHWCFcsevHdc0kQ7LKJQmJjUJWszphah8=";
    };
    buildInputs = [ minizip ] ++ (builtins.filter (p: (p.pname or "") != "minizip-ng") old.buildInputs);
  });
}
