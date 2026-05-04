{ pkgs, ... }:
{
  # https://voidcruiser.nl/rambles/i2p-on-nixos/
  containers.i2pd = {
    autoStart = true;
    config =
      { ... }:
      {
        services.i2pd = {
          enable = true;
          address = "127.0.0.1";
          nat = true;
          proto = {
            http.enable = true; # 7070
            socksProxy.enable = true; # 4447
            httpProxy.enable = true; # 4444
            sam.enable = true; # torrent, 7656
          };
        };

        users.users.xd = {
          isSystemUser = true;
          description = "XD torrent client user";
          createHome = true;
          home = "/var/lib/xd";
          group = "xd";
        };
        users.groups.xd = { };

        systemd.services.xd = {
          after = [ "network.target" ];
          serviceConfig = {
            Type = "notify";
            User = "xd";
            ExecStart = "${pkgs.xd}/bin/XD";
          };
        };

        networking.firewall.allowedTCPPorts = [
          7070
          4447
          4444
          7656
          1776 # xd webui
        ];
      };
  };
}
