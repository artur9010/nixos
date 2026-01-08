{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  # https://github.com/gmodena/nix-flatpak
  services.flatpak = {
    enable = true;

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };

    packages = [
      "one.ablaze.floorp" # web browser
      "org.onlyoffice.desktopeditors"
      "io.github.kolunmi.Bazaar"

      # gaming
      "io.github.streetpea.Chiaki4deck" # grajdworzec zdalny kubus play
    ];
  };

  # https://wiki.nixos.org/wiki/Fonts#Solution_3:_Configure_bindfs_for_fonts/cursors/icons_support
  # Expose fonts and cursors on /usr/share/{fonts,icons}, so flatpak can discover and use them.
  system.fsPackages = [ pkgs.bindfs ];

  fileSystems =
    let
      mkRoSymBind = path: {
        device = path;
        fsType = "fuse.bindfs";
        options = [
          "ro"
          "resolve-symlinks"
          "x-gvfs-hide"
        ];
      };
      aggregated = pkgs.buildEnv {
        name = "system-fonts-and-icons";
        paths =
          config.fonts.packages
          ++ (with pkgs; [
            # Add your cursor themes and icon packages here
            # bibata-cursors
            # gnome.gnome-themes-extra
            # etc.
          ]);
        pathsToLink = [
          "/share/fonts"
          "/share/icons"
        ];
      };
    in
    {
      "/usr/share/fonts" = mkRoSymBind "${aggregated}/share/fonts";
      "/usr/share/icons" = mkRoSymBind "${aggregated}/share/icons";
    };
}
