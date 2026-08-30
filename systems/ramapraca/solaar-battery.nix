{
  pkgs,
  ...
}:
{
  # Bridge Solaar battery readings (Bolt/BT Logitech devices) into the kernel
  # as virtual HID batteries, so UPower and the KDE Power and Battery applet
  # can display them. Needed until the stock kernel's hid-logitech-dj supports
  # the Bolt receiver.
  boot.kernelModules = [ "uhid" ];

  programs.solaar.enable = true; # used by python script

  systemd.services.solaar-battery-uhid = {
    description = "Bridge Solaar battery readings to virtual HID batteries";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${./solaar-battery-uhid.py} --interval 5 --solaar-bin ${pkgs.solaar}/bin/solaar";
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
