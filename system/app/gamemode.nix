{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ gamemode mangohud ];
  programs.gamemode.enable = true;
}