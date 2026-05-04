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

  # Lock charging to 80%
  systemd.services.fw-ectool-charge-limit = {
    description = "Set FW ECTOOL charge limit to 80%";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.fw-ectool} fwchargelimit 80";
    };
  };

  # Override that stupid 15W power limit.
  systemd.services.ryzenadj-on-boot = {
    description = "Override TDP limit";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    # Values based on https://github.com/AlxHnr/amd-ryzen-ignore-stapm
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.ryzenadj} --stapm-limit 43000 --fast-limit 53000 --slow-limit 43000";
    };
  };

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
