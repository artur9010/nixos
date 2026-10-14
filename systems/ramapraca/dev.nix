{ pkgs, outputs, ... }:

let

in
{
  environment.systemPackages = with pkgs; [

    # CODIN
    zed-editor

    # java
    maven
    javaPackages.compiler.openjdk25

    # python
    python3
    uv
    poetry

    # nodejs
    nodejs

    # terraform
    terraform
    terraform-ls

    # AI DANGER ZONE
    lmstudio
    opencode
    claude-code

    ## lsp: https://opencode.ai/docs/lsp/
    nixd
    terraform-lsp
    pyright # python

    # radicle
    radicle-node

    ## mcps
    playwright-mcp
    mcp-nixos

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
    "com.google.AndroidStudio"
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "radicle-node-1.10.3"
  ];
}
