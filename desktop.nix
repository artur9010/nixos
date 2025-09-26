{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.displayManager = {
    gdm = {
      enable = true;
    };
  };

  services.desktopManager = {
    gnome = {
      enable = true;
    };
  };

  services.gnome = {
    core-apps.enable = false;
    gnome-keyring.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

  environment.systemPackages = with pkgs; [
    # apps
    gnome-console
    gnome-tweaks
    nautilus
    # gnome extensions
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    gnomeExtensions.user-themes
    gnomeExtensions.bluetooth-battery-meter
    gnomeExtensions.appindicator
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/mutter" = {
          # https://wiki.nixos.org/wiki/GNOME#Experimental_settings
          experimental-features = [
            "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
            "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays

            #"xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
            # ^ causes to render minecraft at twice the resolution, related: https://gitlab.gnome.org/GNOME/mutter/-/issues/3704
          ];
        };

        "org/gnome/shell" = {
          enabled-extensions = [
            pkgs.gnomeExtensions.blur-my-shell.extensionUuid
            pkgs.gnomeExtensions.dash-to-panel.extensionUuid
            pkgs.gnomeExtensions.user-themes.extensionUuid
            pkgs.gnomeExtensions.bluetooth-battery-meter.extensionUuid
            pkgs.gnomeExtensions.appindicator.extensionUuid
          ];
        };

        # Dash to panel ext.
        # Dump current settings using: `dconf dump /org/gnome/shell/extensions/dash-to-panel/`
        # You can give result of that command to some LLM to rewrite it in Nix format, make sure to put everything as strings
        "org/gnome/shell/extensions/dash-to-panel" = {
          animate-appicon-hover-animation-extent = "{'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}";
          appicon-margin = "2";
          appicon-style = "NORMAL";
          context-menu-entries = "[{\"title\":\"Terminal\",\"cmd\":\"gnome-terminal\"},{\"title\":\"System monitor\",\"cmd\":\"gnome-system-monitor\"},{\"title\":\"Files\",\"cmd\":\"nautilus\"},{\"title\":\"Extensions\",\"cmd\":\"gnome-extensions-app\"}]";
          dot-position = "BOTTOM";
          dot-style-focused = "DOTS";
          dot-style-unfocused = "DOTS";
          extension-version = "70";
          global-border-radius = "0";
          group-apps = "false";
          hotkeys-overlay-combo = "TEMPORARILY";
          intellihide = "false";
          panel-anchors = "{\"DEL-F8P92S3\":\"MIDDLE\",\"BOE-0x00000000\":\"MIDDLE\"}";
          panel-element-positions = "{\"DEL-F8P92S3\":[{\"element\":\"showAppsButton\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"activitiesButton\",\"visible\":false,\"position\":\"stackedTL\"},{\"element\":\"leftBox\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"taskbar\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"centerBox\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"rightBox\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"dateMenu\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"systemMenu\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"desktopButton\",\"visible\":true,\"position\":\"stackedBR\"}],\"BOE-0x00000000\":[{\"element\":\"showAppsButton\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"activitiesButton\",\"visible\":false,\"position\":\"stackedTL\"},{\"element\":\"leftBox\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"taskbar\",\"visible\":true,\"position\":\"stackedTL\"},{\"element\":\"centerBox\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"rightBox\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"dateMenu\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"systemMenu\",\"visible\":true,\"position\":\"stackedBR\"},{\"element\":\"desktopButton\",\"visible\":true,\"position\":\"stackedBR\"}]}";
          panel-lengths = "{\"DEL-F8P92S3\":100,\"BOE-0x00000000\":100}";
          panel-positions = "{\"DEL-F8P92S3\":\"BOTTOM\",\"BOE-0x00000000\":\"BOTTOM\"}";
          panel-sizes = "{\"DEL-F8P92S3\":48,\"BOE-0x00000000\":48}";
          prefs-opened = "false";
          secondarymenu-contains-showdetails = "false";
          show-apps-icon-file = "";
          show-apps-icon-side-padding = "8";
          stockgs-force-hotcorner = "false";
          stockgs-keep-dash = "false";
          stockgs-keep-top-panel = "false";
          trans-use-border = "false";
          trans-use-custom-bg = "false";
          trans-use-custom-gradient = "true";
          trans-use-custom-opacity = "false";
          window-preview-title-position = "TOP";
        };

      };
    }
  ];

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # Fix for Electron apps scaling on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";

  services.flatpak.enable = true;
}
