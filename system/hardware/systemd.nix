_:

{
  services.logind.settings.Login = {
    KillUserProcesses = true;
    UserStopDelaySec = 0;
  };
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
    settings.Journal = {
      SystemMaxUse = "50M";
      SystemMaxFiles = 5;
      rateLimitBurst = 500;
      RateLimitIntervalSec = 30;
    };
  };
}
