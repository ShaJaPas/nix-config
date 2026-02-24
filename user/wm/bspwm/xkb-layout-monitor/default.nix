{
  lib,
  stdenv,
  pkg-config,
  libx11,
}:

stdenv.mkDerivation rec {
  pname = "xkb-layout-monitor";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libx11
  ];

  buildPhase = ''
    runHook preBuild

    $CC $CFLAGS -Wall -Wextra -O2 -std=c99 \
      -o xkb-layout-monitor xkb_layout_monitor.c \
      $(pkg-config --cflags --libs x11)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 xkb-layout-monitor $out/bin/xkb-layout-monitor

    runHook postInstall
  '';

  meta = {
    description = "Fast XKB keyboard layout monitor for EWW";
    homepage = "https://github.com/shajapas/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
