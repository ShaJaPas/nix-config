{ ... }:

{
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';
  services.journald.extraConfig = ''
    SystemMaxUse=50M
    SystemMaxFiles=5'';
  services.journald.rateLimitBurst = 500;
  services.journald.rateLimitInterval = "30s";
}
