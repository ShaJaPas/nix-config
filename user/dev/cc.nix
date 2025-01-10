{ pkgs, ... }:

{
  home.packages = with pkgs; [
      # CC
      gcc
      cmake
      gnumake
  ];
}