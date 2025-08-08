_:

{
  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  hardware.bluetooth.settings = {
    General = {
      ControllerMode = "bredr";
    };
  };
}
