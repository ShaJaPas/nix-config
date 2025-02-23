{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # CC
    gcc
    cmake
    gnumake
    ninja
    meson
    autoconf
    automake
    autogen
    libtool
    gnum4
  ];
}
