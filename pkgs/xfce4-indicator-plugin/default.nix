{
  stdenv,
  lib,
  fetchFromGitLab,
  gettext,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook3,
  glib,
  gtk3,
  xfce4-panel,
  libxfce4ui,
  libxfce4util,
  xfconf,
  libayatana-indicator,
}:

# Not in nixpkgs (checked pkgs.xfce.* and a full nixpkgs search) - Chicago95's
# bundled panel layout (hosts/ideapad3-g) declares this plugin, but nixpkgs
# has no derivation for it. Every dependency below (including
# libayatana-indicator, which already propagates ayatana-ido) is otherwise
# already packaged, so building from upstream's own release tarball is
# straightforward.
stdenv.mkDerivation (finalAttrs: {
  pname = "xfce4-indicator-plugin";
  version = "2.5.0";

  src = fetchFromGitLab {
    domain = "gitlab.xfce.org";
    owner = "panel-plugins";
    repo = "xfce4-indicator-plugin";
    tag = "xfce4-indicator-plugin-${finalAttrs.version}";
    hash = "sha256-U/VINbl1MpblBMc0IdlM+5B6490rTqp0TnPLqQp1H1M=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    gettext
    meson
    ninja
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    gtk3
    xfce4-panel
    libxfce4ui
    libxfce4util
    xfconf
    libayatana-indicator
  ];

  meta = {
    description = "Xfce panel plugin to show messages using indicator-applet";
    homepage = "https://gitlab.xfce.org/panel-plugins/xfce4-indicator-plugin";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
