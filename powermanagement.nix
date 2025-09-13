{
  lib,
  pkgs,
  config,
  ...
}:

{
  # Ryzenadj
  environment.systemPackages = with pkgs; [
    ryzenadj
  ];

  # Use a fork of ryzen_smu that supports newer CPUs, ryzenadj requires it.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage /etc/nixos/pkgs/ryzen_smu { })
  ];

  powerManagement.powertop.enable = true;
  services.thermald.enable = true;
  # https://search.nixos.org/options?channel=25.05&query=tuned
  services.tuned = {
    enable = true;
    profiles = {
      framework-powersave = {
        main = {
          include = "laptop-battery-powersave";
        };
        video = {
          "radeon_powersave" = "dpm-balanced"; #wkurwia jak zmienia sie kolorystyka
        };
      };
    };
    ppdSettings = {
      profiles = {
        balanced = "desktop";
        performance = "throughput-performance";
        power-saver = "framework-powersave";
      };
    };
  };
  services.power-profiles-daemon.enable = false; # conflicts with tuned
  services.tlp.enable = false; # conflicts with tuned
}
