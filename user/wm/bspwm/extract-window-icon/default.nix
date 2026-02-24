{
  lib,
  stdenv,
  pkg-config,
  glib,
  cairo,
  libxcb-wm,
  libxcb-util,
  libxcb,
}:

stdenv.mkDerivation rec {
  pname = "extract-window-icon";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    glib
    cairo
    libxcb-wm
    libxcb-util
    libxcb
  ];

  buildPhase = ''
    runHook preBuild

    $CC $CFLAGS extract-window-icon.c -o extract-x11-icon -std=c99 \
      $(pkg-config --cflags --libs glib-2.0 xcb xcb-atom xcb-icccm xcb-ewmh xcb-util cairo cairo-png cairo-xcb)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 extract-x11-icon $out/bin/extract-x11-icon
    install -Dm755 ./extract-window-icon $out/bin/extract-window-icon

    runHook postInstall
  '';

  meta = {
    description = "Extract window icons from X11 applications";
    homepage = "https://github.com/shajapas/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
