{ pkgs, ... }:

{
  # Enable printing
  services = {
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      # openFirewall = true;
    };
  };
}
