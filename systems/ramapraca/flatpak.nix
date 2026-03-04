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

      # other
      "com.usebottles.bottles"
      "org.remmina.Remmina"
      "org.gimp.GIMP"
    ];
  };
}
