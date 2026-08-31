{
  pkgs,
  outputs,
  ...
}:
{
  # virtualisation.virtualbox.host = {
  #   enable = true;
  #   enableExtensionPack = true;
  # };
  users.groups.vboxusers.members = [ "artur9010" ];

  # Karton - KDE virtual machine manager (talks to qemu:///session)
  virtualisation.libvirtd.enable = true;
  environment.systemPackages = [
    outputs.packages.${pkgs.system}.karton
  ];
}
