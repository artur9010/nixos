# https://github.com/makindotcc/flake/blob/dc0a56de4a0fbe724015a28c5fb36ec5620a9dc1/system/fonts.nix
{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  fonts = {
    enableDefaultPackages = true;
    packages = [
      inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
      inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "SFRounded Nerd Font"
        ];
        serif = [
          "SFRounded Nerd Font"
        ];
        monospace = [ "SFMono Nerd Font" ];
      };
      useEmbeddedBitmaps = true;
    };
  };
}
