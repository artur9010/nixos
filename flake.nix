{
  description = "platki sniegu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
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
            ./configuration.nix
          ];
        };
      };
    };
}
