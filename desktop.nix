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

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
}