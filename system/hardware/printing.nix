{ pkgs, ... }:

{
  # Enable printing
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  # services.avahi.openFirewall = true;
  services.printing.drivers = [ pkgs.hplipWithPlugin ];
}
