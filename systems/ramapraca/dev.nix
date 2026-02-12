{ config, pkgs, ... }:

let

in
{
  environment.systemPackages = with pkgs; [

    # CODIN
    vscode
    zed-editor
    jetbrains.idea
    jetbrains.datagrip

    # java
    maven
    javaPackages.compiler.openjdk25

    # python
    python3
    uv
    pyright # https://opencode.ai/docs/lsp/

    # nodejs
    nodejs

    # terraform
    terraform
    terraform-ls

    # AI DANGER ZONE
    lmstudio
    opencode
    devcontainer # required for https://github.com/athal7/opencode-devcontainers

    ## lsp: https://opencode.ai/docs/lsp/
    nixd # nix lsp

    ## mcps
    playwright-mcp

    ## OTHER
    podman-compose # for `docker compose` compat
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
