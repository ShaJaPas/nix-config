{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation {
  pname = "bspwm-workspaces";
  version = "1.0.0";

  src = ./.;

  buildInputs = with pkgs; [
    xorg.libX11
    xorg.libXext
  ];

  nativeBuildInputs = with pkgs; [
    gcc
    pkg-config
  ];

  buildPhase = ''
    gcc -Wall -Wextra -O2 -std=c99 -o bspwm-workspaces workspaces.c -lX11
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bspwm-workspaces $out/bin/
  '';

  meta = with pkgs.lib; {
    description = "Fast bspwm workspace monitor with JSON output";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
