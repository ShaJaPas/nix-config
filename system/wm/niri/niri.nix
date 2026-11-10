{
  pkgs,
  personalSettings,
  ...
}:
let
  # The greeter mirrors the interactive user's DMS settings.
  greeterConfigHome = "/home/${personalSettings.username}";
in
{
  imports = [
    ../general/wayland.nix
  ];

  programs.niri.enable = true;

  services.greetd.enable = true;

  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = greeterConfigHome;
  };

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
  ];

  security.wrappers.sing-box = {
    capabilities = "cap_net_admin,cap_net_raw+eip";
    source = "${pkgs.sing-box}/bin/sing-box";
    owner = "root";
    group = "root";
  };

  services.upower.enable = true;
}
