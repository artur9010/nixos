{ config, pkgs, ... }:

let

in {
  environment.systemPackages = [
    pkgs.opencode
    pkgs.devcontainer # required for https://github.com/athal7/opencode-devcontainers
    
    # lsp: https://opencode.ai/docs/lsp/
    pkgs.javaPackages.compiler.openjdk25 # requirement for opencode built-in java lsp
    pkgs.nixd # nix lsp
    pkgs.nodejs # provides npx

    # mcps
    pkgs.playwright-mcp
  ];
}