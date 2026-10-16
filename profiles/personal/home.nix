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
    stateVersion = "25.11"; # Please read the comment before changing.

    packages = with pkgs; [
      # Core
      fish
      ghostty
      starship
      git

      # Other
      #yandex-music
      steam
      #discord
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
      GAME = "${config.home.homeDirectory}/Media/Games";
      GAME_SAVE = "${config.home.homeDirectory}/Media/Game Saves";
    };
  };

}
