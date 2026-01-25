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
    maven

    # AI DANGER ZONE
    lmstudio
    opencode
    devcontainer # required for https://github.com/athal7/opencode-devcontainers

    ## lsp: https://opencode.ai/docs/lsp/
    javaPackages.compiler.openjdk25 # requirement for opencode built-in java lsp
    nixd # nix lsp
    nodejs # provides npx

    ## mcps
    playwright-mcp
  ];
}
