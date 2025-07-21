{ pkgs, ... }:

{
  # Enable printing
  services = {
    printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      # openFirewall = true;
    };
  };
}
