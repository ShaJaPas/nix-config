{ ... }:

{
  # Pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire = {
      "context.properties" = {
        "default.configured.audio.source" =
          "{ \"name\": \"alsa_card.usb-Generalplus_Usb_Audio_Device-00\" }";
      };
    };
  };
}
