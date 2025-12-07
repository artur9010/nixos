{
  # eufyMake Studio - A PrusaSlicer fork with remote printing control
  environment.systemPackages = [
    (pkgs.callPackage ./eufymake-slicer-package.nix {})
  ];
}
