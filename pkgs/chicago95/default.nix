{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "chicago95";
  version = "3.0.1";

  src = fetchFromGitHub {
    owner = "grassmunk";
    repo = "Chicago95";
    rev = "v${version}";
    hash = "sha256-EHcDIct2VeTsjbQWnKB2kwSFNb97dxuydAu+i/VquBA=";
  };

  installPhase = ''
    runHook preInstall

    # GTK Theme
    mkdir -p $out/share/themes/Chicago95
    cp -r Theme/Chicago95/* $out/share/themes/Chicago95/

    # Icon themes
    mkdir -p $out/share/icons
    cp -r Icons/Chicago95 $out/share/icons/
    cp -r Icons/Chicago95-tux $out/share/icons/

    # Cursor themes
    for cursor_dir in Cursors/*; do
      if [ -d "$cursor_dir" ]; then
        cp -r "$cursor_dir" "$out/share/icons/"
      fi
    done

    # Plymouth themes
    mkdir -p $out/share/plymouth/themes
    cp -r Plymouth/Chicago95 $out/share/plymouth/themes/
    cp -r Plymouth/RetroTux $out/share/plymouth/themes/

    # Fonts
    mkdir -p $out/share/fonts/truetype
    cp -r Fonts/* $out/share/fonts/truetype/

    # Sounds
    mkdir -p $out/share/sounds
    cp -r sounds/Chicago95 $out/share/sounds/

    # XFCE panel profiles
    mkdir -p $out/share/xfce4-panel-profiles/layouts
    if [ -f Extras/Chicago95_Panel_Preferences.tar.bz2 ]; then
      cp Extras/Chicago95_Panel_Preferences.tar.bz2 $out/share/xfce4-panel-profiles/layouts/
    fi

    # XFCE terminal theme
    mkdir -p $out/share/xfce4/terminal/colorschemes
    if [ -f Extras/Chicago95.theme ]; then
      cp Extras/Chicago95.theme $out/share/xfce4/terminal/colorschemes/
    fi

    # Backgrounds
    mkdir -p $out/share/backgrounds/chicago95
    if [ -d Extras/Backgrounds ]; then
      cp -r Extras/Backgrounds/* $out/share/backgrounds/chicago95/
    fi

    # Remove broken symlinks before fixup
    find $out/share/icons -xtype l -delete 2>/dev/null || true

    runHook postInstall
  '';

  # Disable fixup phase to avoid hanging on broken symlinks
  dontFixup = true;

  meta = with lib; {
    description = "Windows 95 theme for XFCE/Xubuntu with Plymouth boot splash";
    homepage = "https://github.com/grassmunk/Chicago95";
    license = with licenses; [ gpl3Plus mit ];
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
