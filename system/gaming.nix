{ lib, pkgs, ... }:

{
  # Steam
  programs.steam.enable = true;
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    prismlauncher

    # moddin stuff
    nexusmods-app
    limo

    # lossless scaling - https://github.com/PancakeTAS/lsfg-vk
    lsfg-vk
    lsfg-vk-ui
  ];
}
