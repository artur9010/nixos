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
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.ny-nerd
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro-nerd
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-mono-nerd
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-compact-nerd
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "SFCompactRounded Nerd Font"
        ];
        serif = [
          "NewYork Nerd Font"
        ];
        monospace = [
          "SFMono Nerd Font"
        ];
      };
      useEmbeddedBitmaps = true;
    };
  };

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          font-name = "SFCompactRounded Nerd Font 11";
          monospace-font-name = "SFMono Nerd Font 11";
          document-font-name = "NewYork Nerd Font 11";
        };
      };
    }
  ];
}
