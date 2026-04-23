{ pkgs, ... }:
{
  imports = [
    ../general/wayland.nix
  ];

  programs.niri.enable = true;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    wayland = {
      enable = true;
      # weston (default) не умеет multi-monitor — заменяем на kwin_wayland
      compositorCommand = "${pkgs.kdePackages.kwin}/bin/kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1";
    };
    extraPackages = with pkgs; [
      sddm-astronaut
      kdePackages.layer-shell-qt
    ];
    settings = {
      General.GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
      Theme = {
        CursorTheme = "Adwaita";
        CursorSize = 24;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    adwaita-icon-theme
  ];

  systemd.services.disable-sddm-pipewire = {
    description = "Disable PipeWire services for the sddm user";
    after = [ "user-runtime-dir@sddm.service" ];
    before = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.systemd}/bin/systemctl --user --machine sddm@ stop pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1 || true
      ${pkgs.systemd}/bin/systemctl --user --machine sddm@ disable pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1
      ${pkgs.systemd}/bin/systemctl --user --machine sddm@ mask pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1
    '';
  };

  security.wrappers.sing-box = {
    capabilities = "cap_net_admin+ep";
    source = "${pkgs.sing-box}/bin/sing-box";
    owner = "root";
    group = "root";
  };

  services.upower.enable = true;
}
