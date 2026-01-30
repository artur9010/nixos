{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.displayManager = {
    ly = {
      enable = true;
      x11Support = false;
      settings = {
        battery_id = "BAT1"; # upower -e
        animation = "doom";
        doom_fire_height = "4";
        box_title = "─  Łelkom to rama.praca  ─";
        bigclock = "en";
        min_refresh_delta = "41"; # keep it at ~24FPS, default delta is 5ms
        edge_margin = "2"; # well, framework screen is curved.
        hide_version_string = "true";
      };
    };
  };

  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
  };

  # labwc
  programs.labwc.enable = true;
  environment.etc."xdg/labwc".source = "/home/artur9010/nixos/systems/ramapraca/etc/xdg/labwc";

  environment.systemPackages = with pkgs; [
    vlc
    brave
    anydesk
    thunderbird
    telegram-desktop
    mumble

    # labwc
    waybar
    wlr-randr
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # keep bluetooth powered off by default
  };

  # Remove unneeded shortcuts
  # https://discourse.nixos.org/t/manage-printers-in-applications-list-while-cups-disabled/55909/2
  environment.extraSetup = ''
    rm -f $out/share/applications/cups.desktop
    rm -f $out/share/applications/nixos-manual.desktop
  '';

  # Remove unneded kde apps
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.kmenuedit
    kdePackages.khelpcenter
  ];

  # Fix for Electron apps scaling on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";

  # Workaround for touchpad not working sometimes after sleep, idk why. Module reload helps...
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
