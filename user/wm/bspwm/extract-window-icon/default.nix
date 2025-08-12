{
  stdenv,
  glib,
  cairo,
  pkg-config,
  xorg,
}:

stdenv.mkDerivation {
  pname = "extract-window-icon";
  version = "0.1";

  src = ./.;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    glib
    cairo
    xorg.xcbutilwm
    xorg.xcbutil
    xorg.libxcb
  ];

  buildPhase = ''
    gcc $CFLAGS extract-window-icon.c -o extract-window-icon \
    $(pkg-config --cflags --libs glib-2.0 xcb xcb-atom xcb-icccm xcb-ewmh xcb-util cairo cairo-png cairo-xcb)
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -m755 extract-window-icon $out/bin
  '';
}
