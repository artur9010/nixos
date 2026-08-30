{
  pkgs,
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
      "org.mozilla.firefox"
      "org.onlyoffice.desktopeditors"
      "io.github.kolunmi.Bazaar"

      # gaming
      "io.github.streetpea.Chiaki4deck" # grajdworzec zdalny kubus play

      # other
      "com.usebottles.bottles"
      "org.kde.krita"
      "im.riot.Riot" # element
      "com.prusa3d.PrusaSlicer"
      "org.videolan.VLC"
      "md.obsidian.Obsidian"
      "io.github.zingytomato.netpeek"
      "org.grayjay.Grayjay"

    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.flatpak-kcm # settings integration
  ];
}
