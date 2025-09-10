{
  lib,
  pkgs,
  config,
  ...
}:

{
  # Ryzenadj
  environment.systemPackages = with pkgs; [
    pkgs.ryzenadj
  ];

  # Use a fork of ryzen_smu that supports newer CPUs, ryzenadj requires it.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage /etc/nixos/pkgs/ryzen_smu { })
  ];
}
