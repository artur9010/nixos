{ config, pkgs, ... }:

let
  claudeSandboxed = pkgs.writeShellScriptBin "claude" ''
    # ProtectHome=read-only, przy yes nie odpala sie nic jak workdir jest wewnatrz /home
    # .cache/nix potrzebne do dzialania nix-shell wewnatrz sandboxa
    exec systemd-run --user --pty \
      --unit=claude-sandboxed-$RANDOM \
      --working-directory="$PWD" \
      --setenv=PATH="$PATH" \
      -p ProtectHome=read-only \
      -p PrivateTmp=yes \
      -p ProtectSystem=strict \
      -p NoNewPrivileges=yes \
      -p RestrictSUIDSGID=yes \
      -p PrivateDevices=yes \
      -p ReadWritePaths="$PWD" \
      -p ReadWritePaths="$HOME/.claude" \
      -p ReadWritePaths="$HOME/.claude.json" \
      -p ReadWritePaths="$HOME/.cache" \
      -p ReadWritePaths="$HOME/.m2" \
      -p ReadWritePaths="$HOME/.npm" \
      -p ReadWritePaths="$HOME/.config/claude-code" \
      ${pkgs.claude-code}/bin/claude "$@"
  '';
in {
  environment.systemPackages = [
    claudeSandboxed
    pkgs.claude-monitor
    # lsp: https://opencode.ai/docs/lsp/
    pkgs.opencode
    pkgs.javaPackages.compiler.openjdk25 # requirement for opencode built-in java lsp
    pkgs.nixd # nix lsp

  ];
}