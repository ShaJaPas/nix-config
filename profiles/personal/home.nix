{
  config,
  pkgs,
  userSettings,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    inherit (userSettings) username;
    homeDirectory = "/home/" + userSettings.username;
    stateVersion = "24.11"; # Please read the comment before changing.

    packages = with pkgs; [
      # Core
      fish
      wezterm
      starship
      git

      # Other
      yandex-music
      steam
      discord
      lutris
    ];
  };

  programs.home-manager.enable = true;

  imports = [
    ../work/home.nix # Personal is essentially work system
  ];

  xdg.enable = true;
  xdg.userDirs = {
    extraConfig = {
      XDG_GAME_DIR = "${config.home.homeDirectory}/Media/Games";
      XDG_GAME_SAVE_DIR = "${config.home.homeDirectory}/Media/Game Saves";
    };
  };

}
