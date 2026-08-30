{
  pkgs,
  ...
}:

{
  # KDE base
  # services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
  };

  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.discover # its fuckin useless on nixos?
    kdePackages.khelpcenter
    kdePackages.elisa
    kdePackages.kate
    kdePackages.qrca # why i would even need a qr scanner on fkin laptop?
    kdePackages.baloo-widgets # no baloo indexing -> no use for this
  ];

  # Kill baloo file indexing system-wide. It wastes a lot of CPU and memory
  # and I don't need it. kde-baloo.service has an ExecCondition
  # checking "baloofilerc:Basic Settings:Indexing-Enabled", so the daemon never starts.
  # baloo/milou itself is a hardcoded requiredPackage of the plasma6 module and cannot
  # be excluded. https://github.com/NixOS/nixpkgs/issues/63489
  environment.etc."xdg/baloofilerc".text = ''
    [Basic Settings]
    Indexing-Enabled=false
  '';
  environment.extraSetup = ''
    rm -f $out/share/applications/nixos-manual.desktop
    # can't exclude those two, so i dropped them from menu
    rm -f $out/share/applications/org.kde.kmenuedit.destkop
    rm -f $out/share/applications/org.kde.plasma.emojier.desktop
  '';

  # Fonts
  fonts.enableDefaultPackages = true;

  environment.systemPackages = with pkgs; [
    brave # TODO: move to flatpak
    anydesk # TODO: migrate mom to ruskdesk
    thunderbird
    telegram-desktop
    mumble # TODO: should be fine to migrate to flatpak?
    ledger-live-desktop
  ];

  services.flatpak.packages = [
    "com.cherry_ai.CherryStudio"
  ];

  hardware.bluetooth.enable = true;
  hardware.logitech.wireless.enable = true; # logitech udev rules
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
