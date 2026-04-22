{
  userSettings,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  wallpaper = pkgs.fetchurl {
    url = "https://i.ytimg.com/vi/R1nvDRgQTYQ/maxresdefault.jpg";
    hash = "sha256-qxhrwpN0azC/BBxiQ9qQHgctEBzVb5LUy5JmQoZRN3U=";
  };
in
{
  imports = [ inputs.dms-plugin-registry.modules.default ];
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableClipboardPaste = true; # Pasting from the clipboard history (wtype)
    settings = builtins.fromJSON (builtins.readFile ./dms-settings.json);
    plugins = {
      dankBatteryAlerts.enable = true;
      dockerManager.enable = true;
      amdGpuMonitorRevive.enable = true;
      powerUsagePlugin.enable = true;
      networkDownloadMonitor = {
        enable = true;
        src = ./plugins/networkDownloadMonitor;
      };
      singBoxManager = {
        enable = true;
        src = ./plugins/singBoxManager;
      };
    };
    quickshell.package = pkgs.quickshell;
  };

  gtk = {
    enable = true;
    font = {
      name = "Cantarell";
      package = pkgs.cantarell-fonts;
      size = 11;
    };
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Tela-ubuntu-dark";
      package = pkgs.tela-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
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

  /*
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
  */

  home.packages = with pkgs; [
    nautilus
    mission-center
    networkmanagerapplet
    gtk3
    pavucontrol
    xwayland-satellite
    amdgpu_top
  ];

  xdg.configFile = {
    "niri/config.kdl".text = ''

      include "dms/outputs.kdl"

      hotkey-overlay {
        skip-at-startup
      }
        input {
            keyboard {
                xkb {
                    layout "us,ru"
                    options "grp:alt_shift_toggle"
                }
            }
            touchpad {
                tap
                dwt
                natural-scroll
            }
        }

        gestures {
            hot-corners {
                off
            }
        }
        layout {
            gaps 2

            border {
                width 2
                active-color "#498a49"
                inactive-color "#8a8d9e"
            }
            
            focus-ring {
                width 0
            }
        }

        animations {
            workspace-switch { spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001; }
            window-open { spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001; }
            window-close { spring damping-ratio=0.8 stiffness=1000 epsilon=0.0001; }
        }

        spawn-at-startup "dms"
        
        spawn-at-startup "bash" "-c" "dms ipc call wallpaper set ${wallpaper}"
        
      window-rule {
            match app-id="steam"
            open-floating true
        }
        window-rule {
        	geometry-corner-radius 10
        	clip-to-geometry true
        }

        binds {
            Mod+Q { spawn "${userSettings.term}"; }
            Mod+B { spawn "gtk-launch" "${userSettings.browser}"; }
            Mod+D { spawn "nautilus"; }
            Mod+E { spawn "${userSettings.editor}"; }
            
            Mod+R { spawn "dms" "ipc" "call" "launcher" "toggle"; }
            
            Mod+L { spawn "dms" "ipc" "call" "lock" "lock"; }

            Print { spawn "dms" "screenshot" "full"; }
            Shift+Print { spawn "dms" "screenshot" "region"; }

            Mod+C { close-window; }
            Mod+S { toggle-window-floating; }
            Mod+F { fullscreen-window; }

            Mod+WheelScrollDown { focus-column-right; }
            Mod+WheelScrollUp   { focus-column-left; }

            Mod+Shift+Left  { move-column-left; }
            Mod+Shift+Right { move-column-right; }

            Mod+Left  { set-column-width "-5%"; }
            Mod+Right { set-column-width "+5%"; }
            Mod+Up    { set-window-height "-5%"; }
            Mod+Down  { set-window-height "+5%"; }

            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }

            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }

            Mod+Shift+Q { quit skip-confirmation=true; }
        }
    '';
  };
}
