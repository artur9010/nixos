{
  description = "platki sniegu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
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
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          karton = pkgs.callPackage ./pkgs/karton { };
          ankerctl = pkgs.callPackage ./pkgs/ankerctl { };
        }
      );

      # sudo nixos-rebuild switch --flake .#ramapraca
      nixosConfigurations = {
        ramapraca = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            nix-flatpak.nixosModules.nix-flatpak
            ./systems/ramapraca/configuration.nix
          ];
        };
      };
    };
}
