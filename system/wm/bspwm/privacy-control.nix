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
          echo "Blocking camera"
          touch /tmp/camera_blocked
          chmod 000 /dev/video0
        ''}";
      };
    };
    unblock-camera = {
      description = "Unblock camera access";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "unblock-camera" ''
          echo "Unblocking camera"
          rm -f /tmp/camera_blocked
          chmod 660 /dev/video0
        ''}";
      };
    };
    restore-camera-state = {
      description = "Restore camera state on login";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "restore-camera-state" ''
          if [ -f "/tmp/camera_blocked" ]; then
            echo "Restoring camera block"
            chmod 000 /dev/video0
          fi
        ''}";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.systemd1.manage-units") {
          var unit = action.lookup("unit");
          if ((unit === "block-camera.service" || 
               unit === "unblock-camera.service" ||
               unit === "restore-camera-state.service") &&
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
