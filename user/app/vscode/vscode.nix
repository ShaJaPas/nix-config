{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    package = pkgs.vscode.fhsWithPackages (
      ps: with ps; [
        rustup
        zlib
        zig
        cargo-zigbuild
        openssl.dev
        pkg-config
        protobuf
        llvmPackages.libclang.dev
        clang
        glibc.static
      ]
    );
    userSettings = {
      "files.autoSave" = "off";
      "workbench.iconTheme" = "icons";
      "editor.fontLigatures" = false;
      "editor.fontFamily" = "JetBrains Mono";
      "terminal.integrated.fontFamily" = "monospace";
      "window.zoomLevel" = 1;
    };
    extensions = with pkgs.vscode-extensions; [
      twxs.cmake
      rust-lang.rust-analyzer
      adpyke.codesnap
      tamasfe.even-better-toml
      ms-azuretools.vscode-docker
      golang.go
      tal7aouy.icons
      bbenoist.nix
      zxh404.vscode-proto3
      ms-python.python
      fill-labs.dependi
    ];
  };
}
