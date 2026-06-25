{
  description = "platki sniegu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/2ad12e8aa42ebcbec5282e74775699047f4b013a"; # przywrocic nixos-unstable
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release"; # nick wzbudza zaufanie
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      nix-flatpak,
      nix-cachyos-kernel,
      ...
    }@inputs:
    let
      inherit (self) outputs;
    in
    {
      # sudo nixos-rebuild switch --flake .#ramapraca
      nixosConfigurations = {
        ramapraca = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            { nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ]; }

            nixos-hardware.nixosModules.framework-13-7040-amd
            nix-flatpak.nixosModules.nix-flatpak
            ./systems/ramapraca/configuration.nix
          ];
        };
      };
    };
}
