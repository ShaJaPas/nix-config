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
}
