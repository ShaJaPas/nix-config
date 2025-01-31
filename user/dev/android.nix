{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Android
    # TODO: add ndk
    android-tools
    android-udev-rules
  ];
}
