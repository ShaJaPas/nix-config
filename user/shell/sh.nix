{ pkgs, ... }:
let
  # My shell aliases
  myAliases = {
    ls = "eza";
    cat = "bat";
    find = "fd";
    neofetch = "fastfetch";
    cd = "z";
    nix-shell = "nix-shell --run fish";
  };
in
{
  programs.fish = {
    enable = true;
    shellAliases = myAliases;
    interactiveShellInit = ''
      set fish_greeting
      zoxide init fish | source
      starship init fish | source
    '';
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = myAliases;
    initExtra = ''
      eval "$(zoxide init bash)"
      eval "$(starship init bash)"
    '';
  };
}
