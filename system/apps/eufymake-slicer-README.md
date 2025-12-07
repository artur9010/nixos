# eufyMake PrusaSlicer Package

## Status

⚠️ **NOT BUILDABLE** - This package definition is correctly structured but cannot build due to upstream source code issues.

## What's Been Done

1. ✅ Created Nix package definition based on PrusaSlicer package from nixpkgs
2. ✅ Added necessary dependencies (boost, cgal, opencascade-occt, wxGTK32, etc.)
3. ✅ Added package to `configuration.nix`
4. ✅ Fixed OpenCASCADE version requirement (7.6.2 → 7.6.1)
5. ✅ Fixed case-sensitivity issues in CMakeLists.txt (Calib.hpp → calib.hpp)
6. ✅ Enabled OPEN_SOURCE mode to disable proprietary AnkerNet dependency (disables wireless/remote printing features)
7. ✅ Resolved git merge conflict markers in ClipperUtils.hpp  
8. ✅ Fixed CGAL const correctness issues in MeshBoolean.cpp

## Blocking Issues (Upstream)

The eufyMake-PrusaSlicer-Release repository has significant code quality issues that prevent compilation:

### 1. Missing Configuration Members

Multiple source files reference configuration members that don't exist:

- `PrintConfig`:
  - `wipe_tower_x`
  - `wipe_tower_y`
  - `wipe_tower_rotation_angle`
  - `extruder_offset`
  - `max_print_height`

- `FullPrintConfig`:
  - `nozzle_diameter`
  - `bed_shape`
  - `print_flow_ratio`

- `Model` class:
  - `curr_plate_index`

### 2. Incomplete Features

The calibration feature (`calib.cpp`/`calib.hpp`) references these missing members extensively, suggesting it was never completed or tested against this codebase.

### 3. Compiler Errors

Files failing to compile:
- `src/libslic3r/BuildVolume.cpp`
- `src/libslic3r/GCode.cpp`
- `src/libslic3r/calib.cpp`
- `src/libslic3r/Brim.cpp`
- `src/libslic3r/ClipperUtils.cpp`

## What Would Be Needed

To make this buildable, one would need to either:

### Option 1: Use a Different Commit/Branch
The current HEAD may be broken. Check if there's a stable release tag or branch that compiles.

### Option 2: Fix the Source Code
This would require:
1. Finding where these configuration members are supposed to be defined
2. Adding the missing members to the appropriate config classes
3. Possibly disabling incomplete features like calibration
4. Testing compilation end-to-end

### Option 3: Use PrusaSlicer Instead
Since eufyMake Studio is based on PrusaSlicer, using the standard PrusaSlicer package from nixpkgs might be a better option:

```nix
environment.systemPackages = with pkgs; [
  prusa-slicer
];
```

## Repository Structure

- `eufymake-slicer.nix` - Complete package definition and NixOS module (follows PrusaSlicer structure)
- Imported in:
  - `configuration.nix` (line 23)

## Important Notes

⚠️ **OPEN_SOURCE Mode Impact**: The package is configured with `OPEN_SOURCE=ON`, which disables the proprietary `AnkerNet` networking module. This means:
- ✅ The package can build without proprietary dependencies
- ❌ **Wireless/remote printing features are disabled**
- ❌ Real-time streaming from printer is disabled

The main feature that differentiates eufyMake Studio from standard PrusaSlicer (remote printing control) will not work in this configuration.

## Build Command

To attempt building (will fail with current errors):

```bash
nix-build '<nixpkgs>' -A eufymake-slicer
```

## Recommendation

Given the state of the upstream repository, I recommend:

1. Contact the eufyMake developers about the compilation issues
2. Check if there's a pre-built binary release you could package instead
3. Use standard PrusaSlicer from nixpkgs as an alternative
4. Wait for upstream to fix their source code before attempting to package it

## Links

- Upstream Repository: https://github.com/eufymake/eufyMake-PrusaSlicer-Release
- PrusaSlicer (original): https://github.com/prusa3d/PrusaSlicer
- NixOS PrusaSlicer Package: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/misc/prusa-slicer/default.nix
