{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  boot.plymouth = {
    enable = true;
    theme = "breeze"; # setting to "breeze" autoincludes theme package:
    # A NixOS branded variant of the breeze theme when config.boot.plymouth.theme == "breeze", otherwise [ ].
  };

  # TODO: try plasma-login-manager after release
  services.displayManager = {
    ly = {
      enable = true;
      x11Support = false;
      settings = {
        battery_id = "BAT1"; # upower -e
        animation = "doom";
        doom_fire_height = "4";
        box_title = "─[  Łelkom to rama.praca  ]─";
        bigclock = "en";
        min_refresh_delta = "41"; # keep it at ~24FPS, default delta is 5ms
        edge_margin = "2"; # well, framework screen is curved.
        hide_version_string = "true";

	# todo: nie dziala 
        #auto_login_session = "plasma";
        #auto_login_user = "artur9010";
      };
    };
  };

  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vlc
    brave
    anydesk
    thunderbird
    telegram-desktop
    mumble
    ledger-live-desktop
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # keep bluetooth powered off by default
  };

  hardware.logitech.wireless = {
    enable = true; # logitech udev rules
    enableGraphical = true; # solaar app
  };

  hardware.ledger.enable = true; # udev rules for ledger devices
  fonts.enableDefaultPackages = true;

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
