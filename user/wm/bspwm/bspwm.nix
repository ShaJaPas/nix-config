{
  userSettings,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./rofi/rofi.nix
    ./dunst.nix
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

  sops.age.keyFile = "/home/${userSettings.username}/.config/sops/age/keys.txt";
  sops.secrets =
    let
      secretsDir = ./sing-box-profiles;
    in
    lib.mapAttrs' (
      fileName: _:
      lib.nameValuePair "sing-box-${lib.removeSuffix ".json" fileName}" {
        sopsFile = "${secretsDir}/${fileName}";
        path = "/home/${userSettings.username}/.config/sing-box/${fileName}";
        key = "";
        format = "json";
      }
    ) (builtins.readDir secretsDir);

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
    mission-center
    xsecurelock
    brightnessctl
    ddcutil
    networkmanagerapplet
    gtk3
    escrotum
    libinput-gestures
    pavucontrol
    blueberry
    polkit_gnome
  ];

  # Copy eww config to ~/.config/eww
  xdg.configFile."eww" = {
    source = ./eww;
    recursive = true;
  };

  xsession.windowManager.bspwm.enable = true;
  xsession.windowManager.bspwm.extraConfig = ''
    systemctl start restore-camera-state
    ${pkgs.autorandr}/bin/autorandr -c
    echo UPDATESTARTUPTTY | gpg-connect-agent

    nm-applet &

    ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &

    libinput-gestures -c $HOME/.config/libinput-gestures.conf &

    bspc config border_width 2
    bspc config window_gap 2
    bspc config split_ratio 0.52
    bspc config borderless_monocle true
    bspc config gapless_monocle true
    bspc config single_monocle true
    bspc config focus_follows_pointer true

    bspc config focused_border_color "#498a49"
    bspc config active_border_color  "#2c692c"
    bspc config normal_border_color  "#8a8d9e"

    bspc config merge_overlapping_monitors true

    bspc rule -a steam state=floating sticky=on
    bspc rule -a Eww layer=below

    # Name desktops
    bspc monitor -d 1 2 3 4 5 6 7 8 9

    # Set wallpaper
    ${pkgs.feh}/bin/feh --bg-scale '${
      pkgs.fetchurl {
        url = "https://i.ytimg.com/vi/R1nvDRgQTYQ/maxresdefault.jpg";
        hash = "sha256-qxhrwpN0azC/BBxiQ9qQHgctEBzVb5LUy5JmQoZRN3U=";
      }
    }' &

    # Launch eww bar
    eww daemon
    eww close-all
    eww active-windows | grep -q 'bar: bar' || eww open bar

    eww update brightness_level=$(bash $HOME/.config/eww/scripts/brightness get) &
    eww update current_uptime=$(awk '{print int($1)}' /proc/uptime) &
    eww update dnd_active=$(bash $HOME/.config/eww/scripts/dnd.sh get) &

    # Script to hide bar on fullscreen
    bspc subscribe node_state desktop_focus | while read -r event _ _ _ state _; do
      if [ "$event" = "desktop_focus" ] || [ "$state" = "fullscreen" ]; then
        if bspc query -N -d focused -n .fullscreen > /dev/null; then
          eww close-all
        else
          eww active-windows | grep -q 'bar: bar' || eww open bar
        fi
      fi
    done &
  '';

  services.sxhkd = {
    enable = true;
    keybindings = {
      # Terminal
      "super + q" = "${userSettings.term}";
      # Browser
      "super + b" = "gtk-launch ${userSettings.browser}";
      # File-manager
      "super + d" = "nautilus";
      # File-manager
      "super + e" = "${userSettings.editor}";

      # App launcher
      "super + r" = "rofi -show drun";

      # Screenshots
      "Print" =
        "sh -c 'mkdir -p $HOME/Media/Pictures/Screenshots && escrotum $HOME/Media/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png'";
      "shift + Print" =
        "sh -c 'mkdir -p $HOME/Media/Pictures/Screenshots && escrotum -s $HOME/Media/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png'";

      # Close window
      "super + c" = "bspc node -c";

      # Move nodes
      "super + shift + {Right,Left}" = "bspc node @/ -C {forward,backward}";

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
      "super + shift + 1" = "bspc node -d 1 --follow";
      "super + shift + 2" = "bspc node -d 2 --follow";
      "super + shift + 3" = "bspc node -d 3 --follow";
      "super + shift + 4" = "bspc node -d 4 --follow";
      "super + shift + 5" = "bspc node -d 5 --follow";
      "super + shift + 6" = "bspc node -d 6 --follow";
      "super + shift + 7" = "bspc node -d 7 --follow";
      "super + shift + 8" = "bspc node -d 8 --follow";
      "super + shift + 9" = "bspc node -d 9 --follow";

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
      "super + shift + q" = "bspc quit; pkill -x sxhkd";
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
      shadow = false;
      #shadow-radius = 12;
      #shadow-offset-x = -12;
      #shadow-offset-y = -12;
      #shadow-opacity = 0.6;

      # Rounded corners
      corner-radius = 10;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
      ];

      # Blur
      #blur-method = "dual_kawase";
      #blur-strength = 8;
      #blur-background = true;
      #blur-background-exclude = [
      #  "window_type = 'dock'"
      #  "window_type = 'desktop'"
      #  "_GTK_FRAME_EXTENTS@"
      #];

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

  xdg.configFile."libinput-gestures.conf".text = ''
    gesture swipe right 3 bspc desktop -f prev.local
    gesture swipe left 3 bspc desktop -f next.local
  '';
}
