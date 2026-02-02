# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

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

# IMPORTANT: When adding new files, always add them to git before building:
git add <new-files>
git add <modified-configs>
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

### Power Management
Currently uses `ananicy-cpp` for process prioritization and custom scripts for fan control/charging limits.
- `ryzen_smu` kernel module is used for Ryzen adjustment support.
- Charge limit is set to 80% via `fw-ectool`.
- `tuned` configuration is present but currently disabled (commented out).

### Conventions
- If a tool is not available, use `nix-shell -p <package>` to get it
- Comments may be in Polish
- User account: `artur9010`
- **Always remove** the `result` directory after work is complete

### Available Tools
- **duckduckgo-mcp_search** - Search the internet for information, documentation, solutions

## Important Notes

- **DO NOT PUSH** to the repository unless explicitly told to by the user
- Always add new files and modified configurations to git before running nixos-rebuild
- **ALWAYS CHECK THE NIXOS MANUAL** available at `/run/current-system/sw/share/doc/nixos/index.html` for configuration options and documentation
- **ALWAYS CHECK THE NIX MANUAL** available at `/run/current-system/sw/share/doc/nix/manual/index.html` for Nix package manager documentation
- **ALWAYS CHECK THE NIXPKGS MANUAL** available at `/run/current-system/sw/share/doc/nixpkgs/index.html` for package documentation
- **MAKE USE OF nixos-mcp tools** to query NixOS packages, options, channels, and documentation directly
- **ASK AS MANY QUESTIONS AS POSSIBLE** when unsure or needing clarification on requirements, preferences, or implementation choices
