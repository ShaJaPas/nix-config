{ pkgs, pkgs-stable, ... }:

{
  fonts = {
    fontDir.enable = true;

    packages = with pkgs; [
      ubuntu-classic
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "Ubuntu"
          "Noto Sans"
        ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "JetBrains Mono"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
