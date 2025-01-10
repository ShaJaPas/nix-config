{ pkgs, ... }:
{
    programs.vscode = {
        enable = true;
        package = pkgs.vscode.fhsWithPackages (ps: with ps; [
             rustup zlib openssl.dev pkg-config protobuf
        ]);
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
        ];
    };
}