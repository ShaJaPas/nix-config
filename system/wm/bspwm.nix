{ pkgs, ... }:
{
  # Import x11 config
  imports = [ ./x11.nix ];

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = with pkgs; [
      sddm-astronaut
    ];
  };
  services.xserver.windowManager.bspwm.enable = true;
  environment.systemPackages = with pkgs; [
    sddm-astronaut
  ];

  services.libinput.touchpad.naturalScrolling = true;
}
