{ pkgs, ... }:
{
  # Import x11 config
  imports = [
    ../general/x11.nix
    ./privacy-control.nix
  ];

  services = {
    displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs; [
        sddm-astronaut
      ];
    };
    xserver.windowManager.bspwm.enable = true;
    libinput.touchpad.naturalScrolling = true;
    autorandr = {
      enable = true;
      profiles = {
        laptop = {
          fingerprint.eDP = "00ffffffffffff0009e5000700000000011a0104a522137802c9a0955d599429245054000000010101010101010101010101010101019c3b803671383c403020360058c21000001a000000000000000000000000000000000000000000fe00424f452043510a202020202020000000fe004e5631353646484d2d4e34380a007c";
          config = {
            "eDP" = {
              enable = true;
              primary = true;
              mode = "1920x1080";
              position = "0x0";
            };
            "HDMI-A-0" = {
              enable = false;
            };
          };
        };
        external = {
          fingerprint = {
            "eDP" =
              "00ffffffffffff0009e5000700000000011a0104a522137802c9a0955d599429245054000000010101010101010101010101010101019c3b803671383c403020360058c21000001a000000000000000000000000000000000000000000fe00424f452043510a202020202020000000fe004e5631353646484d2d4e34380a007c";
            "HDMI-A-0" =
              "00ffffffffffff000469d124010101012b17010380342078ea4ca5a7554da226105054230800818081409500a940b300d1c001010101283c80a070b023403020360006442100001a000000fd00323d1e5311000a202020202020000000fc0056533234410a20202020202020000000ff0044414c4d51533130343734320a01bd02031ef14b900504030201111213141f230907078301000065030c0010001a3680a070381e403020350006442100001a662156aa51001e30468f330006442100001e011d007251d01e206e28550006442100001e8c0ad08a20e02d10103e9600064421000018011d8018711c1620582c250006442100009e00000000000000fe";
          };
          config = {
            "eDP" = {
              enable = false;
            };
            "HDMI-A-0" = {
              enable = true;
              primary = true;
              mode = "1920x1200";
              position = "0x0";
            };
          };
        };
      };
    };
    udev.extraRules = ''ACTION=="change", SUBSYSTEM=="drm", RUN+="${pkgs.autorandr}/bin/autorandr -c"'';
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
  ];

  systemd.services.disable-sddm-pipewire = {
    description = "Disable PipeWire services for the sddm user";
    after = [ "user-runtime-dir@sddm.service" ];
    before = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # The user instance should be up now.
      ${pkgs.systemd}/bin/systemctl --user --machine sddm@ stop pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1 || true
      ${pkgs.systemd}/bin/systemctl --user --machine sddm@ disable pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1
      ${pkgs.systemd}/bin/systemctl --user --machine sddm@ mask pipewire.service pipewire.socket wireplumber.service > /dev/null 2>&1
    '';
  };
}
