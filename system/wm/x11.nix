{ pkgs, ... }:

{
  imports = [
    ./pipewire.nix
    ./dbus.nix
    ./gnome-keyring.nix
    ./fonts.nix
  ];

  services.touchegg.enable = true;
  services.libinput = {
    touchpad = {
      horizontalScrolling = true;
      disableWhileTyping = true;
    };
  };
  # Configure X11
  services.xserver = {
    videoDrivers = [ "amdgpu" ];

    enable = true;
    xkb = {
      variant = "";
      options = "grp:alt_shift_toggle";
      layout = "us,ru";
    };
    excludePackages = [ pkgs.xterm ];
  };
}
