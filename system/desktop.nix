{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  services.displayManager = {
    sddm = {
      enable = false;
      wayland.enable = true;
    };
    gdm = {
      enable = true;
      banner = "rama.praca najlepszy kąkuter";
    };
  };

  services.desktopManager = {
    plasma6 = {
      enable = true;
    };
    gnome = {
      enable = false;
    };
  };

  services.gnome = {
    core-apps.enable = false;
    gnome-keyring.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
    gnome-console
  ];

  environment.systemPackages = with pkgs; [
    # apps
    nautilus
    ptyxis # terminal emulator
    gthumb # image viewer and basic editor
    papers # document viewer
    vlc
    file-roller # archive manager
#    gnome-tweaks
    brave

    # gnome themes
 #   yaru-theme
 #   morewaita-icon-theme

    # gnome extensions
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    gnomeExtensions.user-themes
    gnomeExtensions.bluetooth-battery-meter
    gnomeExtensions.appindicator
    gnomeExtensions.gtk4-desktop-icons-ng-ding
    gnomeExtensions.gsconnect
    gnomeExtensions.arcmenu
    gnomeExtensions.caffeine
    gnomeExtensions.search-light
    gnomeExtensions.tailscale-qs
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

            # theme
            cursor-theme = "Yaru";
            icon-theme = "MoreWaita";
          };

          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
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
            panel-element-positions = ''
              {"BOE-0x00000000":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}],"DEL-F8P92S3":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}
            '';
            trans-panel-opacity = 0.45;
            trans-use-custom-opacity = true;
            trans-use-dynamic-opacity = true;
          };

          "org/gnome/shell/extensions/arcmenu" = {
            hide-overview-on-startup = true;
            multi-monitor = true;
            menu-layout = "Windows";
            apps-show-extra-details = true;
          };

          "org/gnome/shell/extensions/search-light" = {
            shortcut-search = [ "<Control><Alt>space" ];
            popup-at-cursor-monitor = true;
          };

          "org/gnome/tweaks" = {
            show-extensions-notice = false;
          };

          "org/gnome/shell" = {
            favorite-apps = lib.gvariant.mkTuple [ ];
            enabled-extensions = [
              pkgs.gnomeExtensions.blur-my-shell.extensionUuid
              pkgs.gnomeExtensions.dash-to-panel.extensionUuid
              pkgs.gnomeExtensions.user-themes.extensionUuid
              pkgs.gnomeExtensions.bluetooth-battery-meter.extensionUuid
              pkgs.gnomeExtensions.appindicator.extensionUuid
              pkgs.gnomeExtensions.gtk4-desktop-icons-ng-ding.extensionUuid
              pkgs.gnomeExtensions.gsconnect.extensionUuid
              pkgs.gnomeExtensions.arcmenu.extensionUuid
              pkgs.gnomeExtensions.caffeine.extensionUuid
              pkgs.gnomeExtensions.search-light.extensionUuid
              pkgs.gnomeExtensions.tailscale-qs.extensionUuid
            ];
          };
        };
      }
    ];
  };

#  qt = {
#    enable = true;
#    platformTheme = "gnome";
#    style = "adwaita-dark";
#  };

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
