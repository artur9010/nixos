{ config, pkgs, ... }:

let
  copilotSandboxed = pkgs.writeShellScriptBin "copilot" ''
    # ProtectHome=read-only, przy yes nie odpala sie nic jak workdir jest wewnatrz /home
    # .cache/nix potrzebne do dzialania nix-shell wewnatrz sandboxa
    exec systemd-run --user --pty \
      --unit=copilot-sandboxed-$RANDOM \
      --working-directory="$PWD" \
      --setenv=PATH="$PATH" \
      -p ProtectHome=read-only \
      -p PrivateTmp=yes \
      -p ProtectSystem=strict \
      -p NoNewPrivileges=yes \
      -p RestrictSUIDSGID=yes \
      -p PrivateDevices=yes \
      -p ReadWritePaths="$PWD" \
      -p ReadWritePaths="$HOME/.copilot" \
      -p ReadWritePaths="$HOME/.cache/nix" \
      ${pkgs.github-copilot-cli}/bin/copilot "$@"
  '';

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
      -p ReadWritePaths="$HOME/.cache/nix" \
      -p ReadWritePaths="$HOME/.cache/claude-cli-nodejs" \
      ${pkgs.claude-code}/bin/claude "$@"
  '';
in {
  environment.systemPackages = [
    copilotSandboxed
    #
    claudeSandboxed
    pkgs.claude-monitor
  ];
}