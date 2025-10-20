{ lib, pkgs, ... }:

{
  # Steam
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    prismlauncher

    # lossless scaling - https://github.com/PancakeTAS/lsfg-vk
    lsfg-vk
    lsfg-vk-ui
  ];
}
