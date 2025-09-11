{ lib, pkgs, ... }:

{
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = [
    pkgs.kdePackages.elisa
    pkgs.kdePackages.kate
  ];
}