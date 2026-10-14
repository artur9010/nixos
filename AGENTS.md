# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## IMPORTANT: THIS IS NOT A NIXOS YOU KNOW

User is running rolling-release NixOS from the `nixos-unstable` nixpkgs branch.
Do not rely on your memory of nixpkgs/NixOS options — read the actual sources in `/nix/store`.
To find the nixpkgs source pinned by this flake:

```bash
nix eval --raw --impure --expr '(builtins.getFlake "path:'$PWD'").inputs.nixpkgs.outPath'
```

## Commands

```bash
# Apply configuration (user runs this, agents usually only build)
nixos-rebuild switch --flake .#ramapraca --show-trace --elevate sudo

# Evaluate only (fast, catches assertion/eval errors)
nixos-rebuild dry-build --flake .#ramapraca --show-trace

# Build only (creates `result` symlink)
nixos-rebuild build --flake .#ramapraca --show-trace

# Build a custom package from pkgs/
nix build .#karton

# Format nix files
nix-shell -p nixfmt --run "nixfmt file.nix"

# Update flake inputs
nix flake update
```

Flakes only see files tracked by git — **always `git add` new and modified files before building**.

## Architecture

NixOS flake configuration for a Framework 13 7040 AMD laptop. Single host: `ramapraca`.

### Flake Inputs
- `nixpkgs` (nixos-unstable)
- `nixos-hardware` (`framework-13-7040-amd` module)
- `nix-flatpak` (declarative flatpak)

### Layout
- `flake.nix` – inputs, `packages` output (custom packages), `nixosConfigurations.ramapraca`
- `systems/ramapraca/configuration.nix` – host entry point, imports the feature modules
- `systems/ramapraca/*.nix` – feature modules (desktop, shell, gaming, dev, vpn, flatpak, powermanagement, locale, …)
- `systems/ramapraca/kernel/` – custom trimmed kernel (see below)
- `pkgs/<name>/default.nix` – custom packages, exposed via `flake.nix` `packages` and built with `pkgs.callPackage`
- `extras/` – non-Nix dotfiles/configs (labwc, xfconf, userscripts)
- `scripts/` – helper shell scripts

### Kernel
- `kernel/default.nix` builds `linux_latest` via `linuxManualConfig`: NixOS's generated config is trimmed with `make localmodconfig` against `kernel/modules.lsmod`, and `amdgpu-mst-toggle.patch` is applied.
- The kernel is compiled locally (not in cache.nixos.org), so kernel bumps cost a build.
- If a device/feature doesn't work, the module is probably missing: add its name (underscores, lsmod format) to `modules.lsmod` and rebuild.
- `localmodconfig` matches module *file* names, not aliases (e.g. `blowfish` → `blowfish_generic`). If the initrd build fails with `modprobe: FATAL: Module X not found`, add the real file name(s) from `/run/current-system/kernel-modules`.
- Kernel params / module blacklist stay in `configuration.nix`.

### Power Management
`ananicy-cpp` (CachyOS rules) for process prioritization; `scx` is intentionally disabled. Tools: `fw-ectool`, `ryzenadj`, `powertop`.

### Binary cache
A private S3 substituter (`s3.motyka.pro`) is configured in `configuration.nix` next to cache.nixos.org.

## Conventions
- If a tool is not available, use `nix-shell -p <package>`
- Comments are written in English
- If the user sends a git repository URL for new software, clone it to `/tmp` (or the agent's scratchpad) to inspect it
- User account: `artur9010`
- **Always remove** the `result` symlink after work is complete

## Important Notes
- **DO NOT PUSH** to the repository unless explicitly told to by the user
- Documentation is available locally:
  - NixOS manual: `/run/current-system/sw/share/doc/nixos/index.html`
  - Nix manual: `/run/current-system/sw/share/doc/nix/manual/index.html`
  - Nixpkgs manual: `/run/current-system/sw/share/doc/nixpkgs/index.html`
- **ASK QUESTIONS** when unsure about requirements, preferences, or implementation choices
