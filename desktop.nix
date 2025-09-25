{ lib, pkgs, inputs, ... }:

{
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager = {
    defaultSession = "plasma";
    gdm = {
      enable = true;
    };
  };

  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
    gnome = {
      enable = true;
    };
  };

  services.gnome = {
    core-apps.enable = false;
    gnome-keyring.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnome-console
    gnome-tweaks
    nautilus
  ];

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  environment.plasma6.excludePackages = [
    pkgs.kdePackages.elisa
    pkgs.kdePackages.kate
    pkgs.kdePackages.discover
  ];

  # Fix for Electron apps scaling on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";

  services.flatpak.enable = true;
}
