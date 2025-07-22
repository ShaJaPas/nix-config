{
  pkgs,
  ...
}:

{
  systemd.services = {
    block-camera = {
      description = "Block camera access";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "block-camera" ''
          chmod 000 /dev/video0
        ''}";
        RemainAfterExit = "no";
      };
    };

    unblock-camera = {
      description = "Unblock camera access";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "unblock-camera" ''
          chmod 660 /dev/video0
        ''}";
        RemainAfterExit = "no";
      };
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.systemd1.manage-units") {
          var unit = action.lookup("unit");
          if ((unit === "block-camera.service" || 
               unit === "unblock-camera.service") &&
              subject.local && 
              subject.active) {
              return polkit.Result.YES;
          }
      }
    });
  '';

  services.udev.extraRules = ''
    KERNEL=="video[0-9]*", GROUP="video", MODE="0660", TAG+="systemd"
  '';
}
