{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.displayManager = {
    # sddm has some weird issues with launching plasma session, it crashes after a minute of wait, idk why, gdm works fine anyway
    gdm = {
      enable = true;
      banner = "rama.praca najlepszy kąkuter";
    };
  };

  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
  };

  services.gnome = {
    gnome-keyring.enable = true; 
  };

  environment.systemPackages = with pkgs; [
    # apps
    vlc
    brave
    antigravity
    anydesk
  ];

  # Remove unneeded shortcuts
  # https://discourse.nixos.org/t/manage-printers-in-applications-list-while-cups-disabled/55909/2
  environment.extraSetup = ''
    rm -f $out/share/applications/cups.desktop
    rm -f $out/share/applications/nixos-manual.desktop
  '';

  # Fix for Electron apps scaling on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
}
