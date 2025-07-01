{ pkgs, ... }:

let
  themeFile = ./theme.rasi;
  wallpaper = ./background.jpg;
  # Read the content of the theme file
  themeContent = builtins.readFile themeFile;
  # Replace "background.jpg" with the actual path to the wallpaper in the Nix store
  finalThemeContent = builtins.replaceStrings [ "background.jpg" ] [ "${wallpaper}" ] themeContent;
in
{
  home.packages = [ pkgs.rofi ];

  # Create the theme file in the correct location
  xdg.configFile."rofi/themes/custom.rasi".text = finalThemeContent;

  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      // You can add other global rofi settings here if needed.
      // The main theme settings are now in the theme file.
    }
    @theme "custom"
  '';
}
