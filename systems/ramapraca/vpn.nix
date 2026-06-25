{ lib, pkgs, ... }:

{
  # VPN
  services.tailscale = {
    enable = true;
  };

  services.mullvad-vpn = {
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    mullvad-vpn
  ];
}
