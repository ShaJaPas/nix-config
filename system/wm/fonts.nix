{ pkgs-stable, ... }:

{
  # Fonts are nice to have
  fonts.packages = with pkgs-stable; [
    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

}
