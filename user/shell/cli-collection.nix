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
    nh
    expect
    (curl.override {
      # Enable c-ares support
      c-aresSupport = true;
    })
    socat
    busybox

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
    cargo-deny
    cargo-edit
    rust-bindgen
    qwen-code
  ];

  programs.micro = {
    enable = true;
    settings = {
      clipboard = "terminal";
      colorscheme = "darcula";
    };
  };
}
