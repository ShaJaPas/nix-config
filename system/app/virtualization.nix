{ config, pkgs, ... }:

{
  services.spice-vdagentd.enable = true;
  services.spice-autorandr.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];
  virtualisation.libvirtd = {
    /*
      allowedBridges = [
        "nm-bridge"
        "virbr0"
      ];
    */
    enable = true;
    qemu = {
      runAsRoot = false;
      vhostUserPackages = with pkgs; [
        virtiofsd
      ];
    };
  };
}
