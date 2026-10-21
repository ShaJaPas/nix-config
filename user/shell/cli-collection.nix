{ pkgs, lib, ... }:
{
  # Collection of useful CLI apps
  home.packages = with pkgs; [
    # Command Line
    fastfetch
    psmisc # killall, fuser, pstree
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
    nettools # ifconfig, netstat, arp, route
    (lib.lowPrio inetutils) # telnet, traceroute, whois
    pciutils
    unzip
    xxd
    dpkg
    gh

    # rust
    cargo
    rustfmt
    dioxus-cli
    cargo-expand
    cargo-flamegraph
    cargo-llvm-cov
    cargo-c
    cargo-udeps
    cargo-msrv
    cargo-sort
    cargo-watch
    cargo-deny
    cargo-edit
    rust-bindgen
    appimage-run
    opencode
  ];

  programs.micro = {
    enable = true;
    settings = {
      clipboard = "terminal";
      colorscheme = "darcula";
    };
  };
}
