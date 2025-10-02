# NixOS config

Flake for nix config for my Framework 13 7040u-series.

Rebuild system:
```
sudo nixos-rebuild switch --flake .#ramapraca --show-trace
```

## TODOs

- replace floorp flatpak with floorp nix package, https://noogle.dev/f/pkgs/wrapFirefox ?
- eufymake studio