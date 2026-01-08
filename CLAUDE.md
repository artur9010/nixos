# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#ramapraca --show-trace

# Test build without applying (dry run)
nixos-rebuild dry-build --flake .#ramapraca --show-trace

# Build only (creates result symlink)
nixos-rebuild build --flake .#ramapraca --show-trace

# Format nix files
nix-shell -p nixfmt --run "nixfmt file.nix"

# Update flake inputs
nix flake update
```

## Architecture

NixOS flake configuration for a Framework 13 7040 AMD laptop. Single host configuration named `ramapraca`.

### Flake Inputs
- `nixpkgs` (nixos-unstable)
- `nixos-hardware` (framework-13-7040-amd module)
- `apple-fonts` (SF Pro, SF Mono, NY fonts)
- `nix-flatpak` (declarative flatpak with bindfs for font sharing)

### Module Structure
- `configuration.nix` - main entry point, imports all modules from `system/`
- `system/*.nix` - feature modules (desktop, shell, gaming, powermanagement, etc.)
- `system/apps/*.nix` - application-specific modules with custom packaging
- `pkgs/` - custom packages (kernel modules, patched packages)

### Custom Package Patterns

**Kernel modules** (see `pkgs/ryzen_smu/`):
```nix
config.boot.kernelPackages.callPackage ./pkgs/module-name { }
```

**Python applications with GTK** (see `system/apps/yafi.nix`):
- Use `buildPythonApplication` with `pyproject = true`
- Include `gobject-introspection` and `wrapGAppsHook4` in nativeBuildInputs
- Add desktop files via `makeDesktopItem` and `copyDesktopItems`

**Sandboxed CLI wrappers** (see `system/ai.nix`):
- Use `writeShellScriptBin` with `systemd-run` for isolated execution
- Pattern restricts filesystem access while allowing specific paths

### Power Management
Uses `tuned` daemon with custom Framework-specific profiles (framework-powersave, framework-balanced, framework-performance) instead of power-profiles-daemon or tlp. Profiles are mapped to power-profiles-daemon interface via `ppdSettings`. Custom scripts go in `/etc/tuned/profiles/`.

### Conventions
- If a tool is not available, use `nix-shell -p <package>` to get it
- Comments may be in Polish
- User account: `artur9010`
