{
  lib,
  stdenv,
  pkg-config,
  libx11,
  libxext,
}:

stdenv.mkDerivation rec {
  pname = "bspwm-workspaces";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libx11
    libxext
  ];

  buildPhase = ''
    runHook preBuild

    $CC $CFLAGS -Wall -Wextra -O2 -std=c99 \
      -o bspwm-workspaces workspaces.c \
      $(pkg-config --cflags --libs x11)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 bspwm-workspaces $out/bin/bspwm-workspaces

    runHook postInstall
  '';

  meta = {
    description = "Fast bspwm workspace monitor with JSON output";
    homepage = "https://github.com/shajapas/nix-config";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
