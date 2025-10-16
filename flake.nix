{
  description = "platki sniegu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      nix-flatpak,
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
            nixos-hardware.nixosModules.framework-13-7040-amd
            nix-flatpak.nixosModules.nix-flatpak
            ./configuration.nix
          ];
        };
      };
    };
}
