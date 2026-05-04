{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # KDE base
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
  };
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.kmenuedit # it's still there ._.
    kdePackages.khelpcenter
    kdePackages.elisa
    kdePackages.kate
    kdePackages.qrca # why i would even need a qr scanner on fkin laptop?
  ];
  environment.extraSetup = ''
    rm -f $out/share/applications/nixos-manual.desktop
  '';

  # Fonts
  fonts.enableDefaultPackages = true;

  environment.systemPackages = with pkgs; [
    brave # TODO: move to flatpak
    anydesk
    thunderbird
    telegram-desktop
    mumble # TODO: should be fine to migrate to flatpak?
    ledger-live-desktop
  ];

  services.flatpak.packages = [
    "com.cherry_ai.CherryStudio"
  ];

  hardware.bluetooth = {
    enable = true;
  };

  hardware.logitech.wireless = {
    enable = true; # logitech udev rules
    enableGraphical = true; # solaar app
  };

  hardware.ledger.enable = true; # udev rules for ledger devices

  # Fix for Electron apps scaling on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";

  # Workaround for touchpad not working sometimes after sleep, idk why. Module reload helps...
  # TODO: verify is still required
  environment.etc."systemd/system-sleep/reset-touchpad".source =
    pkgs.writeShellScript "reset-touchpad" ''
      case "$1" in
        pre)
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
