{ pkgs, ... }:
{
  imports = [
    ../general/wayland.nix
  ];

  programs.niri.enable = true;

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
  };

  systemd.services.disable-greeter-pipewire = {
    description = "Disable PipeWire services for the greeter user";
    after =[ "user-runtime-dir@greeter.service" ];
    before =[ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.systemd}/bin/systemctl --user --machine greeter@ stop pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1 || true
      ${pkgs.systemd}/bin/systemctl --user --machine greeter@ disable pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1
      ${pkgs.systemd}/bin/systemctl --user --machine greeter@ mask pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1
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
