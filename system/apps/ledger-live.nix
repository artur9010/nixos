# https://github.com/makindotcc/flake/blob/dc0a56de4a0fbe724015a28c5fb36ec5620a9dc1/system/fonts.nix
{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  # Ledger Live app
  hardware.ledger.enable = true; # udev rules for ledger devices
  environment.systemPackages = [
    pkgs.ledger-live-desktop
  ];
}
