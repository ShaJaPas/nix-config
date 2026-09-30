{ pkgs, ... }:

{
  services.dbus = {
    enable = true;
    implementation = "broker";
    packages = [ pkgs.dconf ];
  };

  programs.dconf = {
    enable = true;
  };
}
