{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
  users.groups.vboxusers.members = [ "artur9010" ];
}
