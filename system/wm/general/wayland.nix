{ pkgs, ... }:

{
  imports = [
    ./pipewire.nix
    ./dbus.nix
    ./gnome-keyring.nix
    ./fonts.nix
  ];

  services = {
    xserver = {
      videoDrivers = [ "amdgpu" ];
    };
  };
  programs.xwayland.enable = true;
}
