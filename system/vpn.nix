{ lib, pkgs, ... }:

{
  # VPN
  services.tailscale = {
    enable = true;
  };
}
