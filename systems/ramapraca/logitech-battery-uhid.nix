{
  pkgs,
  ...
}:
{
  # Bridge Logitech battery readings (Bolt/BT/hidpp devices) into the kernel
  # as virtual HID batteries, so UPower and the KDE Power and Battery applet
  # can display them. Needed until the stock kernel's hid-logitech-dj supports
  # the Bolt receiver. Talks HID++ directly over hidraw, no Solaar needed.
  boot.kernelModules = [ "uhid" ];

  systemd.services.logitech-battery-uhid = {
    description = "Bridge Logitech battery readings to virtual HID batteries";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${./logitech-battery-uhid.py} --interval 5";
      Restart = "always";
      RestartSec = "10s";
      ConditionPathExists = [ "/dev/uhid" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };
}
