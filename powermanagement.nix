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
    ppdSettings = {
      profiles = {
        balanced = "desktop";
        performance = "throughput-performance";
        power-saver = "laptop-battery-powersave";
      };
    };
  };
  services.power-profiles-daemon.enable = false; # conflicts with tuned
  services.tlp.enable = false; # conflicts with tuned

  # TODO: change powerlimits (ryzenadj -c 30000 -b 30000) based on power source (AC/ battery), idk, 5W on battery?
  # TODO: change fan curve as 30W is quite a lot for a laptop
}
