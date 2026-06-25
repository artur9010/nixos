{ config, pkgs, ... }:

let

in
{
  environment.systemPackages = with pkgs; [

    # CODIN
    vscode

    # java
    maven
    javaPackages.compiler.openjdk25

    # python
    python3
    uv
    pyright # https://opencode.ai/docs/lsp/
    poetry

    # nodejs
    nodejs

    # terraform
    terraform
    terraform-ls

    # AI DANGER ZONE
    lmstudio
    opencode

    ## lsp: https://opencode.ai/docs/lsp/
    nixd # nix lsp

    # radicle
    radicle-node
    radicle-desktop

    ## mcps
    playwright-mcp

    ## OTHER
    podman-compose # for `docker compose` compat
    ghidra-bin

    ## smieciowe telefonu
    pmbootstrap
    heimdall
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  services.flatpak.packages = [
    "com.jetbrains.IntelliJ-IDEA-Ultimate"
    "com.jetbrains.DataGrip"
    "com.google.AndroidStudio"
  ];
}
