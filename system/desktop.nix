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
    anydesk
    zed-editor
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

  # Workaround for touchpad not working sometimes after sleep, idk why. Module reload helps...
  environment.etc."systemd/system-sleep/reset-touchpad".source =
    pkgs.writeShellScript "reset-touchpad" ''
      case "$1" in
        pre)
          # Try the common culprits; harmless if not loaded
          ${pkgs.kmod}/bin/modprobe -r i2c_hid_acpi i2c_hid hid_multitouch 2>/dev/null || true
          ;;
        post)
          ${pkgs.kmod}/bin/modprobe i2c_hid_acpi 2>/dev/null || ${pkgs.kmod}/bin/modprobe i2c_hid 2>/dev/null || true
          ${pkgs.kmod}/bin/modprobe hid_multitouch 2>/dev/null || true
          ;;
      esac
    '';
  environment.etc."systemd/system-sleep/reset-touchpad".mode = "0755";
}
