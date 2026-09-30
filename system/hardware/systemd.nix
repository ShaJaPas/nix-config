_:

{
  systemd = {
    coredump = {
      enable = true;
      settings.Coredump = {
        Storage = "none";
        ProcessSizeMax = "2G";
      };
    };
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
    };
  };
  services.journald = {
    extraConfig = ''
      SystemMaxUse=50M
      SystemMaxFiles=5'';
    rateLimitBurst = 500;
    rateLimitInterval = "30s";
  };
}
