{
  config,
  lib,
  userSettings,
  pkgs,
  inputs,
  ...
}:
let
  wallpaper = "${config.home.homeDirectory}/Pictures/Wallpapers/wallpaper.jpg";
  dms = lib.getExe config.programs.dank-material-shell.package;
  jq = lib.getExe pkgs.jq;
in
{
  imports = [ inputs.dms-plugin-registry.homeModules.default ];
  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  services.kanshi = {
    enable = true;

    settings = [
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            scale = 1.0;
            status = "enable";
          }
        ];
      }
      {
        profile.name = "home_office";
        profile.outputs = [
          {
            criteria = "HDMI-A-1";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
    ];
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
    managePluginSettings = true;
    plugins = {
      dankBatteryAlerts.enable = true;
      dockerManager = {
        enable = true;
        settings = {
          groupByCompose = false;
          terminalApp = userSettings.term;
        };
      };
      amdGpuMonitorRevive = {
        enable = true;
        settings = {
          popoutStyle = "dms";
          minimumWidth = false;
        };
      };
      powerUsagePlugin = {
        enable = true;
        settings.selectedPopout = "battery";
      };
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
    gtk4.theme = config.gtk.theme;

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  home.packages = with pkgs; [
    nautilus
    mission-center
    networkmanagerapplet
    gtk3
    pavucontrol
    xwayland-satellite
    amdgpu_top
  ];

  home.file."Pictures/Wallpapers/wallpaper.jpg".source = ../wallpaper.jpg;

  home.activation.dmsWallpaper = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    session="${config.xdg.stateHome}/DankMaterialShell/session.json"
    current=$(${jq} -r '.wallpaperPath // empty' "$session" 2>/dev/null || true)
    if [[ ! -v DRY_RUN && ( -z "$current" || ! -e "$current" || "$current" == /nix/store/* ) ]]; then
      if [[ $(${dms} ipc call wallpaper set "${wallpaper}" 2>&1) != SUCCESS* ]]; then
        mkdir -p "$(dirname "$session")"
        [[ -s "$session" ]] || echo '{}' > "$session"
        ${jq} --arg p "${wallpaper}" '.wallpaperPath = $p' "$session" > "$session.tmp"
        mv "$session.tmp" "$session"
      fi
    fi
  '';

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
            mouse {
                accel-profile "flat"
                accel-speed 0.2
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
