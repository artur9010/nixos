{ lib, pkgs, ... }:

{
  # Steam
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.steam.gamescopeSession.enable = true;
  hardware.steam-hardware.enable = true; # steam controller udev rules

  # Gamemode
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        desiredgov = "performance";
        defaultgov = "balanced";
      };

      custom = {
        start = "${pkgs.fw-ectool}/bin/ectool fanduty 100";
        end = "${pkgs.fw-ectool}/bin/ectool autofanctrl";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # stuff
    mangohud

    # launchers
    heroic
    prismlauncher
    luanti

    # moddin stuff
    limo

    # lossless scaling - https://github.com/PancakeTAS/lsfg-vk
    lsfg-vk
    lsfg-vk-ui
  ];
}
