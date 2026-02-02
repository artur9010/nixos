{ lib, pkgs, ... }:

{
  # Steam
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
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
