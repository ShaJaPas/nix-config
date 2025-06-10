{
  config,
  pkgs,
  ...
}:

{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-websocket
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };
  home.packages = [ pkgs.obs-cli ];
  /*
    systemd.user.services.obs-autostart = {
      Unit = {
        Description = "Autostart OBS minimized to tray";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.obs-studio}/bin/obs --minimize-to-tray";
        Restart = "no";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  */
}
