{
  lib,
  pkgs,
  config,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    ryzenadj
    powertop
    fw-ectool
    lm_sensors
  ];

  # Use a fork of ryzen_smu that supports newer CPUs, ryzenadj requires it.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ./../../pkgs/ryzen_smu { })
  ];

  # Ananicy
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # scx scheduler disabled - it's performance-focused and hurts battery life
  # ananicy-cpp handles process prioritization instead
  services.scx.enable = false;
}
