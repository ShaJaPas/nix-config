{ pkgs, userSettings, ... }:

{
  imports = [ ./pipewire.nix
              ./dbus.nix
              ./gnome-keyring.nix
              ./fonts.nix
            ];

  services.touchegg.enable = true;
  # Configure X11
  services.xserver = {
    enable = true;
    layout = "us,ru";
    xkbVariant = "";
    xkbOptions = "grp:alt_shift_toggle";
    excludePackages = [ pkgs.xterm ];
    displayManager.gdm = {
      enable = true;
      autoLogin = {
          enable = true;
          user = "${userSettings.username}";
      };
    };
    desktopManager.gnome.enable = true;
    
    libinput = {
      touchpad = {
        horizontalScrolling = true;
        disableWhileTyping = true;
      };
    };
  };
}