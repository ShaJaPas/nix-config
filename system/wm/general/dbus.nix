{ pkgs, ... }:

{
  services.dbus = {
    enable = true;
    implementation = "broker";
  };
}
