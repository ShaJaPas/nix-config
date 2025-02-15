{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    package = pkgs.vscode.fhsWithPackages (
      ps: with ps; [
        rustup
        zlib
        openssl.dev
        pkg-config
        pkgsStatic.openssl
        protobuf
        glibc.static
        drill
        grpcurl
        llvmPackages.libclang.dev
        llvmPackages.libclang.lib
        llvmPackages.clang
        alsa-lib.dev
        fftwFloat.dev
      ]
    );
    userSettings = {
      "files.autoSave" = "off";
      "workbench.iconTheme" = "icons";
      "editor.fontLigatures" = false;
      "editor.fontFamily" = "JetBrains Mono";
      "terminal.integrated.fontFamily" = "monospace";
      "window.zoomLevel" = 1;
      "terminal.integrated.defaultProfile.linux" = "fish";
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
