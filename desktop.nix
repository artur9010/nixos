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
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.gsconnect
    gnomeExtensions.arcmenu
  ];

  programs.dconf = {
    enable = true;

    profiles.user.databases = [
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

            # Poki co arcmenu to nadpisuje i wywoluje swoje menu wiec super
            # overlay-key = ""; # disable fcking activities shortcut
          };

          "org/gnome/desktop/interface" = {
            enable-hot-corners = false;
            font-hinting = "full";
            color-scheme = "prefer-dark";
            accent-color = "teal";
            show-battery-percentage = true;
          };

          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
          };

          "org/gnome/desktop/background" = {
            picture-uri = "file:///home/artur9010/nixos/assets/wins25.jpg";
            picture-uri-dark = "file:///home/artur9010/nixos/assets/wins25.jpg";
          };

          "org/gnome/desktop/screensaver" = {
            restart-enabled = true;
          };

          "org/gnome/settings-daemon/plugins/power" = {
            ambient-enabled = false;
          };

          "org/gnome/shell/extensions/Bluetooth-Battery-Meter" = {
            enable-battery-level-icon = true;
            enable-battery-percentage-icon = true;
          };

          "org/gnome/shell/extensions/dash-to-panel" = {
            extension-version = lib.gvariant.mkInt32 68;
            group-apps = false;
            group-apps-underline-unfocused = false;
            appicon-margin = lib.gvariant.mkInt32 2;
            animate-appicon-hover = true;
          };

          "org/gnome/shell/extensions/arcmenu" = {
            hide-overview-on-startup = true;
            multi-monitor = true;
            menu-layout = "Windows";
            apps-show-extra-details = true;
          };

          "org/gnome/shell" = {
            favorite-apps = "[]";
            enabled-extensions = [
              pkgs.gnomeExtensions.blur-my-shell.extensionUuid
              pkgs.gnomeExtensions.dash-to-panel.extensionUuid
              pkgs.gnomeExtensions.user-themes.extensionUuid
              pkgs.gnomeExtensions.bluetooth-battery-meter.extensionUuid
              pkgs.gnomeExtensions.appindicator.extensionUuid
              pkgs.gnomeExtensions.gtk4-desktop-icons-ng-ding.extensionUuid
              pkgs.gnomeExtensions.gsconnect.extensionUuid
              pkgs.gnomeExtensions.arcmenu.extensionUuid
            ];
          };
        };
      }
    ];
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # Fix for Electron apps scaling on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
}
