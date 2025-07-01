{ pkgs, ... }:

{
  # Import x11 config
  imports = [ ./x11.nix ];

  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = with pkgs; [
    baobab # disk usage analyzer
    cheese # photo booth
    epiphany # web browser
    simple-scan # document scanner
    totem # video player
    yelp # help viewer
    geary # email client
    seahorse # password manager

    # these should be self explanatory
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-photos
    gnome-weather
    gnome-disk-utility
    pkgs.gnome-connections
    gnome-tour
    gnome-terminal
  ];

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    bluetooth-quick-connect
    blur-my-shell
    dash-to-dock
    media-controls
    privacy-settings-menu
    status-area-horizontal-spacing
    user-themes
    vitals
  ];
}
