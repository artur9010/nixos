{
  description = "platki sniegu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    winboat.url = "github:TibixDev/winboat/?ref=a01038e0828913b8aaac4bf4d67777a2999a50e1"; # 0.8.7 with correct sha256, commit https://github.com/TibixDev/winboat/commit/a01038e0828913b8aaac4bf4d67777a2999a50e1
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      nix-flatpak,
      winboat,
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
