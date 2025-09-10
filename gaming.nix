{ lib, pkgs, ... }:

{
  # Steam
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    pkgs.prismlauncher
  ];
}
