---
name: check-for-updates
description: Check for updates
compatibility: opencode
---

# What I need to do?

## 1. Check for updates for self-packaged software

Go through `.nix` files located in `systems/ramapraca/apps` and check for available updates to self-packaged software.
After you're done, verify that system can be built, use command `nixos-rebuild dry-build --flake .#ramapraca --show-trace`.
If there is any error on above command, try to fix it and try rebuild again.

Always check READMEs and CHANGELOGs for possible breaking changes and if found inform user before proceeding.

## 2. Flake update

Run `nix flake update`