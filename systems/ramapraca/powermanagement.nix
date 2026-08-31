{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    powertop
    fw-ectool
    lm_sensors
    ryzenadj
    ryzen-monitor-ng
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
