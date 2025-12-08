# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS flake configuration for a Framework 13 laptop (AMD Ryzen 7040U series). The configuration uses a modular structure with separate files for different system aspects.

## Build and Deploy Commands

### System Rebuild
```bash
# Apply configuration changes (current hostname: ramapraca)
sudo nixos-rebuild switch --flake .#ramapraca --show-trace

# Test configuration without setting it as default
sudo nixos-rebuild test --flake .#ramapraca --show-trace

# Build configuration without activating it
sudo nixos-rebuild build --flake .#ramapraca --show-trace

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

### Flake Management
```bash
# Update all flake inputs to latest versions
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Show flake metadata
nix flake show

# Check flake for errors
nix flake check
```

### Format Nix Files
```bash
# Format all .nix files using nixfmt-rfc-style (installed in systemPackages)
nixfmt **/*.nix
```

### Building Custom Packages
```bash
# Build a custom package from pkgs/ directory
nix-build '<nixpkgs>' -A package-name

# Build with the flake
nix build .#package-name
```

## Debugging Nix Builds - IMPORTANT Token Usage Guidelines

**CRITICAL**: Nix build logs can be extremely verbose and consume excessive tokens. Follow these guidelines strictly:

### Reading Build Logs
1. **NEVER read full build logs directly** - Use `nix log` command with filtering
2. **Extract only relevant errors** - Use grep/tail to show only the critical parts
3. **Use head/tail limits** - Show only first/last 50-100 lines of errors

### Recommended Commands for Build Debugging
```bash
# Get ONLY the error summary (last 50 lines)
nix-build '<nixpkgs>' -A package-name 2>&1 | tail -n 50

# Get build log from nix store and show only errors
nix log /nix/store/...-package-name | grep -A 5 -i "error:"

# For compiler errors, show only the error lines
nix-build '<nixpkgs>' -A package-name 2>&1 | grep -E "(error:|failed:|undefined reference)"

# Save log to file instead of reading all into context
nix-build '<nixpkgs>' -A package-name 2>&1 > /tmp/build.log
# Then read only specific sections
grep -A 10 "error:" /tmp/build.log | head -n 100
```

### When Debugging Custom Package Builds
1. **Start with targeted searches**: Look for specific error patterns, not full logs
2. **Incremental approach**: Fix one error type at a time, don't try to read everything
3. **Use background builds**: Run `nix-build` in background, then grep the output file for errors
4. **Focus on first error**: Often subsequent errors are cascading - fix the first one first
5. **Check build phases separately**: If possible, test individual phases (prePatch, configurePhase, buildPhase)

### Example Debugging Workflow
```bash
# 1. Attempt build and capture output to file (run in background if needed)
nix-build '<nixpkgs>' -A eufymake-slicer 2>&1 | tee /tmp/eufy-build.log

# 2. Extract only compilation errors (not warnings)
grep "error:" /tmp/eufy-build.log | head -n 50

# 3. Get context for first error
grep -B 3 -A 3 "first-error-pattern" /tmp/eufy-build.log | head -n 20

# 4. After fixing, re-run and check if that specific error is gone
nix-build '<nixpkgs>' -A eufymake-slicer 2>&1 | grep "first-error-pattern"
```

### What NOT to Do
- ❌ Don't read entire build logs with `nix log` without filtering
- ❌ Don't paste massive compiler output into context
- ❌ Don't read 1000+ line error outputs
- ❌ Don't iterate on all errors at once

### What TO Do
- ✅ Filter logs to show only actual errors (not warnings)
- ✅ Limit output to first 50-100 relevant lines
- ✅ Focus on one category of errors at a time
- ✅ Use temporary files to store full logs, then grep for specific patterns
- ✅ When asking Claude Code about build errors, provide only the specific error message and immediate context (3-5 lines)

## Architecture

### Flake Structure
The flake (`flake.nix`) defines:
- **Inputs**: nixpkgs (unstable), nixos-hardware (Framework 13 AMD 7040), apple-fonts, nix-flatpak
- **Outputs**: Single nixosConfiguration named "ramapraca"
- Hardware module: `nixos-hardware.nixosModules.framework-13-7040-amd`

### Configuration Entry Point
`configuration.nix` is the main entry point that:
- Imports all system modules from `system/` directory
- Configures bootloader (systemd-boot with EFI)
- Uses latest kernel: `boot.kernelPackages = pkgs.linuxPackages_latest`
- Sets hostname: `networking.hostName = "ramapraca"`
- Enables flakes and nix-command
- Configures LUKS encryption for root partition
- Defines user "artur9010" with groups: networkmanager, wheel, docker, dialout

### System Modules (`system/`)
The configuration is split into focused modules:
- **desktop.nix**: GDM display manager, KDE Plasma 6, Wayland optimizations for Electron apps, custom packages including eufymake-slicer
- **powermanagement.nix**: Battery and thermal optimization for Framework laptop
- **gaming.nix**: Steam, game compatibility layers, gaming tools
- **virtualization.nix**: QEMU/KVM and container support (Docker enabled in main config)
- **vpn.nix**: VPN client configuration
- **flatpak.nix**: Declarative Flatpak management via nix-flatpak
- **shell.nix**: Shell environment configuration
- **locale.nix**: Locale and internationalization settings
- **apple-fonts.nix**: Apple San Francisco fonts integration
- **apps/**: Application-specific modules (e.g., ledger-live.nix)

### Custom Packages (`pkgs/`)
Custom package definitions that aren't in nixpkgs:
- **eufymake-slicer-package.nix**: PrusaSlicer fork for eufyMake 3D printers (currently has upstream build issues - see `system/apps/eufymake-slicer-README.md`)
- **ryzen_smu/**: AMD Ryzen SMU (System Management Unit) utilities

## Key Configuration Details

### Networking
- NetworkManager enabled for WiFi/Ethernet management
- iwd (Intel Wireless Daemon) enabled instead of wpa_supplicant
- Hostname: "ramapraca"

### Audio
- PipeWire with ALSA, PulseAudio compatibility
- Bluetooth handsfree profile auto-switch disabled (config in `configuration.nix`)

### Kernel Modules
- Latest kernel from nixpkgs
- Blacklisted module: `hid_lg_g15` (causes brightness control issues with certain speakers)

### Display Manager Notes
- Using GDM (SDDM has session crash issues mentioned in desktop.nix)
- Plasma 6 desktop environment
- Wayland session with Electron/Chromium apps optimized via OZONE flags

### Desktop Cleanup
The configuration removes unwanted .desktop shortcuts:
- cups.desktop (printer management)
- nixos-manual.desktop

## Known Issues and TODOs

### EufyMake Studio Package
The eufymake-slicer package in `pkgs/eufymake-slicer-package.nix` has extensive compilation fixes applied but still cannot build due to upstream source code issues. See `system/apps/eufymake-slicer-README.md` for:
- Current status and blocking issues
- Missing configuration members in upstream code
- Extensive prePatch fixes already applied (merge conflicts, const correctness, DLL_EXPORT definitions, boost filesystem deprecations, duplicate declarations)
- Alternative solutions

### Outstanding TODOs (from README)
- Replace Floorp Flatpak with Floorp Nix package
- Add EufyMake Studio configuration (currently commented out in configuration.nix line 23)

## User Configuration
Main user: artur9010
- Groups: networkmanager, wheel, docker, dialout
- User packages include: kubectl, helm, awscli, sops, vscode, thunderbird, telegram, mumble, lmstudio, IntelliJ IDEA Ultimate, DataGrip, maven

## System State Version
Currently: 25.05
