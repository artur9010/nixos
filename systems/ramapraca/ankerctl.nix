{ pkgs, outputs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Reverse-engineered CLI + web UI for the AnkerMake/eufyMake M5 printer.
    # Web UI on http://127.0.0.1:4470. PPPP LAN uses UDP 32108 (no firewall
    # is enabled in this config, so it works on the local network as-is).
    outputs.packages.${pkgs.system}.ankerctl
    ffmpeg # needed by ankerctl for timelapse capture
  ];

  # Persistent web UI for ankerctl, running as user artur9010.
  # Config/credentials live in ~/.config/ankerctl/default.json.
  systemd.user.services.ankerctl = {
    description = "ankerctl web UI for AnkerMake/eufyMake M5";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${
        outputs.packages.${pkgs.system}.ankerctl
      }/bin/ankerctl webserver run --host 127.0.0.1 --port 4470";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
