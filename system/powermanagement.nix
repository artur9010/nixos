{
  lib,
  pkgs,
  config,
  ...
}:

# Useful links:
# radeon_powersave - https://documentation.suse.com/sles/15-SP7/html/SLES-all/cha-tuning-tuned.html
# https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/performance_tuning_guide/chap-red_hat_enterprise_linux-performance_tuning_guide-tuned

{
  # Ryzenadj
  environment.systemPackages = with pkgs; [
    ryzenadj
    powertop
    fw-ectool
    lm_sensors
  ];

  # Use a fork of ryzen_smu that supports newer CPUs, ryzenadj requires it.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ./../pkgs/ryzen_smu { })
  ];

  # powerManagement.powertop.enable = true;

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
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.ryzenadj} -a 30000 -b 30000 -c 30000";
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
