{ pkgs, ... }:
{
  # Collection of useful CLI apps
  home.packages = with pkgs; [
    # Command Line
    fastfetch
    killall
    tokei
    eza
    bat
    fd
    zoxide
    jq
    go-wrk
    fzf
    micro
    patchelf
    lsof
    bind
    nix-search-cli

    # rust
    cargo
    rustfmt
    dioxus-cli
    cargo-expand
    cargo-flamegraph
    cargo-llvm-cov
    cargo-msrv
    cargo-sort
    cargo-watch
    rust-bindgen
  ];

  programs.micro = {
    enable = true;
    settings = {
      clipboard = "terminal";
      colorscheme = "darcula";
    };
  };
}
