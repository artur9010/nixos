{
  lib,
  pkgs,
  config,
  ...
}:

# AMD Framework 13 7040 Power Management
# References:
# - https://community.frame.work/t/guide-fw13-ryzen-power-management/42988
# - https://wiki.archlinux.org/title/Framework_Laptop_13_(AMD_Ryzen_7040_Series)
# - https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/common/amd.nix

{
  # Power management tools
  environment.systemPackages = with pkgs; [
    powertop
    fw-ectool
    lm_sensors
  ];

  # Power-profiles-daemon - recommended by AMD and Framework for Ryzen 7040
  # PPD 0.20+ supports AMDGPU panel power savings automatically
  services.power-profiles-daemon.enable = true;

  # Disable conflicting power managers
  services.tlp.enable = false;
  services.tuned.enable = false;
  # thermald is Intel-only, does nothing on AMD
  services.thermald.enable = false;

  # Powertop auto-tune for misc power savings
  powerManagement.powertop.enable = true;

  # Kernel parameters for power efficiency
  boot.kernelParams = [
    # Fix for AMDGPU display hangs (recommended by Framework/nixos-hardware)
    "amdgpu.dcdebugmask=0x10"
    # RTC CMOS workaround for hibernate (kernel < 6.8)
    "rtc_cmos.use_acpi_alarm=1"
  ];

  # Ananicy for process prioritization (works with kernel scheduler, doesn't replace it)
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # Lock charging to 80% for battery longevity
  systemd.services.fw-ectool-charge-limit = {
    description = "Set FW ECTOOL charge limit to 80%";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.fw-ectool} fwchargelimit 80";
    };
  };

  # Suspend-then-hibernate: suspend first, hibernate after 2 hours
  # This saves more battery during long sleep periods
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=2h
  '';
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
  };

  # Audio power saving
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1
  '';

  # udev rules for power management
  services.udev.extraRules = ''
    # Enable runtime PM for all PCI devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    # USB autosuspend
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"
  '';
}
