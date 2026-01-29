{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    gnome-boxes
  ];

  users.groups.libvirtd.members = [ "artur9010" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
