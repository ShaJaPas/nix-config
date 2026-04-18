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
  security.wrappers.sing-box = {
    capabilities = "cap_net_admin+ep";
    source = "${pkgs.sing-box}/bin/sing-box";
    owner = "root";
    group = "root";
  };
}
