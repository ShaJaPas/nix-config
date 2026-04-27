{ pkgs, ... }:

{
  services.dbus = {
    enable = true;
    implementation = "dbus";
    packages = [ pkgs.dconf ];
  };

  programs.dconf = {
    enable = true;
  };
}
