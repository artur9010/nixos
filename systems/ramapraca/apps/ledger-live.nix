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
