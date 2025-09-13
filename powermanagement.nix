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

  # Custom tuned scripts
  environment.etc = {
    "tuned/profiles/framework-performance/fanduty.sh" = {
      text = ''
        #!/run/current-system/sw/bin/bash
        case "$1" in
          start)
            /run/current-system/sw/bin/ectool fanduty 100
          ;;
          stop)
            /run/current-system/sw/bin/ectool autofanctrl
          ;;
        esac
      '';

      mode = "0755";
    };
  };
}
