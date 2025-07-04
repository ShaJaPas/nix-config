{ userSettings, pkgs, ... }:
{
  imports = [
    ./rofi/rofi.nix
  ];

  gtk = {
    enable = true;
    font = {
      name = "Cantarell";
      package = pkgs.cantarell-fonts;
      size = 11;
    };
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Tela-ubuntu-dark";
      package = pkgs.tela-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  home.packages = with pkgs; [
    sysstat
    pamixer
    xkblayout-state
    xdotool
    wmctrl
    pulseaudio
    feh
    sxhkd
    eww
    nautilus
    xsecurelock
  ];

  # Copy eww config to ~/.config/eww
  xdg.configFile."eww" = {
    source = ./eww;
    recursive = true;
  };

  xsession.windowManager.bspwm.enable = true;
  xsession.windowManager.bspwm.extraConfig = ''
    bspc config border_width 2
    bspc config window_gap 2
    bspc config split_ratio 0.52
    bspc config borderless_monocle true
    bspc config gapless_monocle true
    bspc config focus_follows_pointer true

    bspc config right_padding 0
    bspc config bottom_padding 0

    # Name desktops
    bspc monitor -d 1 2 3 4 5 6 7 8 9

    #xrandr --output eDP --off --output HDMI-A-0 --primary --auto &

    # Set wallpaper
    ${pkgs.feh}/bin/feh --bg-scale '${
      pkgs.fetchurl {
        url = "https://i.ytimg.com/vi/R1nvDRgQTYQ/maxresdefault.jpg";
        hash = "sha256-qxhrwpN0azC/BBxiQ9qQHgctEBzVb5LUy5JmQoZRN3U=";
      }
    }' &

    # Launch eww bar
    eww open bar &
  '';

  services.sxhkd = {
    enable = true;
    keybindings = {
      # Terminal
      "super + q" = "${userSettings.term}";

      # App launcher
      "super + r" = "rofi -show drun";

      # Close window
      "super + c" = "bspc node -c";

      # Focus nodes
      "super + {h,j,k,l}" = "bspc node -f {west,south,north,east}";

      # Move nodes
      "super + shift + {h,j,k,l}" = "bspc node -s {west,south,north,east}";

      # Switch desktops
      "super + 1" = "bspc desktop -f 1";
      "super + 2" = "bspc desktop -f 2";
      "super + 3" = "bspc desktop -f 3";
      "super + 4" = "bspc desktop -f 4";
      "super + 5" = "bspc desktop -f 5";
      "super + 6" = "bspc desktop -f 6";
      "super + 7" = "bspc desktop -f 7";
      "super + 8" = "bspc desktop -f 8";
      "super + 9" = "bspc desktop -f 9";

      # Move window to desktop
      "super + shift + 1" = "bspc node -d 1";
      "super + shift + 2" = "bspc node -d 2";
      "super + shift + 3" = "bspc node -d 3";
      "super + shift + 4" = "bspc node -d 4";
      "super + shift + 5" = "bspc node -d 5";
      "super + shift + 6" = "bspc node -d 6";
      "super + shift + 7" = "bspc node -d 7";
      "super + shift + 8" = "bspc node -d 8";
      "super + shift + 9" = "bspc node -d 9";

      "super + s" = "bspc node focused -t floating";
      "super + t" = "bspc node focused -t tiled";
      "super + f" = "bspc node focused -t fullscreen";

      # Resize windows with arrow keys
      "super + Left" = "bspc node -z left -50 0 || bspc node -z right -50 0";
      "super + Right" = "bspc node -z right 50 0 || bspc node -z left 50 0";
      "super + Up" = "bspc node -z top 0 -50 || bspc node -z bottom 0 -50";
      "super + Down" = "bspc node -z bottom 0 50 || bspc node -z top 0 50";

      # Reload bspwm
      "super + shift + r" = "bspc wm -r";

      # Reload sxhkd
      "super + Escape" = "pkill -USR1 -x sxhkd";

      # Logout from bspwm
      "super + shift + q" = "bspc quit";
    };
  };

  # Picom (compositor) configuration for animations, shadows, and rounded corners
  services.picom = {
    package = pkgs.picom-pijulius;
    enable = true;
    backend = "glx";
    vSync = true;
    settings = {
      # Shadows
      shadow = true;
      shadow-radius = 12;
      shadow-offset-x = -12;
      shadow-offset-y = -12;
      shadow-opacity = 0.6;

      # Rounded corners
      corner-radius = 10;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];

      # Blur
      blur-method = "dual_kawase";
      blur-strength = 8;
      blur-background = true;
      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "_GTK_FRAME_EXTENTS@"
      ];

      # Animations
      animations = true;
      animation-stiffness = 150;
      animation-dampening = 20;
      animation-mass = 1;
      animation-window-mass = 1;
      animation-for-open-window = "zoom";
      animation-for-unmap-window = "zoom";
      animation-for-prev-tag = "fly-in";
      animation-for-next-tag = "fly-out";
    };
  };
}
