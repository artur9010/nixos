{
  pkgs,
  ...
}:
{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
  users.groups.vboxusers.members = [ "artur9010" ];
}
