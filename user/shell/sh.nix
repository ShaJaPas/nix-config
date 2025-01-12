{ pkgs, ... }:
let
  # My shell aliases
  myAliases = {
    ls = "eza";
    cat = "bat";
    find = "fd";
    neofetch = "fastfetch";
  };
in
{
  programs.fish = {
    enable = true;
    shellAliases = myAliases;
    interactiveShellInit = ''
        set fish_greeting
        starship init fish | source
    '';
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = myAliases;
  };
}