{ pkgs, ... }:

{
  systemd.services = {
    set-power-profile-performance = {
      description = "Set CPU governor to performance";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "set-performance" ''
          echo "performance" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        ''}";
      };
    };

    set-power-profile-balanced = {
      description = "Set CPU governor to schedutil/ondemand";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "set-balanced" ''
          if grep -q 'schedutil' /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors; then
            GOVERNOR="schedutil"
          else
            GOVERNOR="ondemand"
          fi
          echo $GOVERNOR | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        ''}";
      };
    };

    set-power-profile-powersave = {
      description = "Set CPU governor to powersave";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "set-powersave" ''
          echo "powersave" | ${pkgs.coreutils}/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        ''}";
      };
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.systemd1.manage-units") {
          var unit = action.lookup("unit");
          if ((unit === "set-power-profile-performance.service" ||
               unit === "set-power-profile-balanced.service" ||
               unit === "set-power-profile-powersave.service") &&
              subject.local &&
              subject.active) {
              return polkit.Result.YES;
          }
      }
    });
  '';
}
