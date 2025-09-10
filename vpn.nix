{ lib, pkgs, ... }:

{
  # VPN
  # Obejscie na gazomierzu zajebane z https://github.com/ncaq/dotfiles/blob/e628194155fdba694c9b76242a718024e973b857/nixos/host/seminar/vpn.nix
  services.tailscale = {
    enable = true;
    # [tailscale: Build failure with portlist tests on NixOS 25.05 - "seek /proc/net/tcp: illegal seek" · Issue #438765 · NixOS/nixpkgs](https://github.com/nixos/nixpkgs/issues/438765)
    package = pkgs.tailscale.overrideAttrs (old: {
      checkFlags = builtins.map (
        flag:
        if lib.hasPrefix "-skip=" flag then
          flag + "|^TestGetList$|^TestIgnoreLocallyBoundPorts$|^TestPoller$"
        else
          flag
      ) old.checkFlags;
    });
  };
}