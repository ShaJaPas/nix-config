{ config, pkgs, ... }:
let
  wallpaperImg = pkgs.fetchurl {
    url = "https://i.ytimg.com/vi/R1nvDRgQTYQ/maxresdefault.jpg";
    hash = "sha256-qxhrwpN0azC/BBxiQ9qQHgctEBzVb5LUy5JmQoZRN3U=";
  };
in
{
  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Tela-ubuntu-dark";
      package = pkgs.tela-icon-theme;
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

  # home.sessionVariables.GTK_THEME = "Tokyonight-Dark";

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        show-battery-percentage = true;
      };
      "org/gnome/settings-daemon/plugins/power" = {
        idle-dim = false;
        power-button-action = "interactive";
        power-saver-profile-on-low-battery = true;
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };
      "org/gnome/desktop/background" = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file://${wallpaperImg}";
        picture-uri-dark = "file://${wallpaperImg}";
      };
      "org/gnome/desktop/peripherals/mouse" = {
        natural-scroll = false;
        speed = -0.35;
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        click-method = "default";
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":minimize,maximize,close";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false; # enables user extensions
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "com.mitchellh.ghostty.desktop"
          "code.desktop"
          "yandex-browser.desktop"
          "yandex-music.desktop"
        ];
        enabled-extensions = [
          pkgs.gnomeExtensions.appindicator.extensionUuid
          pkgs.gnomeExtensions.bluetooth-quick-connect.extensionUuid
          pkgs.gnomeExtensions.blur-my-shell.extensionUuid
          pkgs.gnomeExtensions.dash-to-dock.extensionUuid
          pkgs.gnomeExtensions.media-controls.extensionUuid
          pkgs.gnomeExtensions.privacy-settings-menu.extensionUuid
          pkgs.gnomeExtensions.status-area-horizontal-spacing.extensionUuid
          pkgs.gnomeExtensions.user-themes.extensionUuid
          pkgs.gnomeExtensions.vitals.extensionUuid
        ];
      };

      # Configure individual extensions
      "org/gnome/shell/extensions/appindicator" = {
        tray-pos = "right";
      };
      "org/gnome/shell/extensions/bluetooth-quick-connect" = {
        show-battery-value-on = false;
      };
      "org/gnome/shell/extensions/blur-my-shell/appfoler" = {
        brightness = 0.6;
        sigma = 30;
      };
      "org/gnome/shell/extensions/blur-my-shell/window-list" = {
        brightness = 0.6;
        sigma = 30;
      };
      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = true;
        brightness = 0.6;
        pipeline = "pipeline_default";
        sigma = 30;
        static-blur = true;
        style-dash-to-dock = 0;
      };
      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        blur = true;
        brightness = 0.6;
        override-background = true;
        pipeline = "pipeline_default";
        sigma = 30;
        static-blur = true;
        unblur-in-overview = true;
      };
      "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab" = {
        pipeline = "pipeline_default";
      };
      "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
        pipeline = "pipeline_default";
      };
      "org/gnome/shell/extensions/blur-my-shell/overview" = {
        pipeline = "pipeline_default";
      };
      "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
        pipeline = "pipeline_default";
      };
      "org/gnome/shell/extensions/blur-my-shell" = {
        settings-version = 2;
      };
      "org/gnome/shell/extensions/dash-to-dock" = {
        always-center-icons = false;
        apply-custom-theme = true;
        background-opacity = 0.8;
        custom-background-color = false;
        custom-theme-shrink = false;
        dash-max-icon-size = 50;
        dock-fixed = true;
        dock-position = "LEFT";
        extend-height = true;
        height-fraction = 0.9;
        hide-tooltip = false;
        icon-size-fixed = true;
        intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
        preview-size-scale = 0.0;
        show-favorites = true;
        show-mounts = false;
      };
      "org/gnome/shell/extensions/mediacontrols" = {
        colored-player-icon = true;
        extension-index = 0;
        extension-position = "Right";
        fixed-label-width = false;
        hide-media-notification = false;
        label-width = 200;
        show-control-icons = false;
        show-control-icons-seek-backward = true;
        show-label = true;
        show-player-icon = true;
      };

      "org/gnome/shell/extensions/vitals" = {
        alphabetize = true;
        fixed-widths = true;
        hide-icons = false;
        hide-zeros = false;
        hot-sensors = [
          "_processor_usage_"
          "__network-rx_max__"
          "_memory_usage_"
        ];
        memory-measurement = 1;
        position-in-panel = 2;
        show-battery = false;
        show-fan = false;
        show-processor = true;
        show-storage = false;
        show-temperature = true;
        update-time = 3;
        use-higher-precision = false;
      };
      "org/gnome/shell/extensions/status-area-horizontal-spacing" = {
        hpadding = 3;
      };
      "org/gnome/shell/extensions/user-theme" = {
        name = "Tokyonight-Dark";
      };
    };
  };
}
