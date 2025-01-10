{ pkgs, ... }:
{
  # Collection of useful CLI apps
  home.packages = with pkgs; [
    # Command Line
    neofetch
    killall
    tokei
    eza
    bat
    fd
    wrk
    
    # rust
    cargo-expand
    cargo-binstall
    cargo-flamegraph
    cargo-llvm-cov
    cargo-msrv
    cargo-sort
    cargo-watch
    dioxus-cli
  ];
}