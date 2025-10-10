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
    powertop
    fw-ectool
    lm_sensors
  ];

  # Use a fork of ryzen_smu that supports newer CPUs, ryzenadj requires it.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ./pkgs/ryzen_smu { })
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
          # wkurwia jak zmienia sie kolorystyka
          "radeon_powersave" = "dpm-balanced";
          "panel_power_savings" = "0";
        };
      };
      framework-balanced = {
        main = {
          include = "desktop";
        };
        video = {
          "radeon_powersave" = "dpm-balanced"; # zamiast "dpm-balance,auto"
        };
      };
      framework-performance = {
        main = {
          include = "throughput-performance";
        };
        script = {
          "script" = "\${i:PROFILE_DIR}/fanduty.sh";
        };
      };
    };
    ppdSettings = {
      battery = {
        balanced = "framework-balanced";
      };
      profiles = {
        balanced = "framework-balanced";
        performance = "framework-performance";
        power-saver = "framework-powersave";
      };
    };
  };
  services.power-profiles-daemon.enable = false; # conflicts with tuned
  services.tlp.enable = false; # conflicts with tuned

  # Custom tuned scripts, full fan and 30W of powerlimit on cpu for performance. 15W and auto for rest.
  environment.etc = {
    "tuned/profiles/framework-performance/fanduty.sh" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        case "$1" in
          start)
            ${lib.getExe pkgs.fw-ectool} fanduty 100
            ${lib.getExe pkgs.ryzenadj} -c 30000 -b 30000
          ;;
          stop)
            ${lib.getExe pkgs.fw-ectool} autofanctrl
            ${lib.getExe pkgs.ryzenadj} -c 15000 -b 15000
          ;;
        esac
      '';

      mode = "0755";
    };
  };

  # Ananicy
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
