{ pkgs, ... }:

let
  base = pkgs.linux_latest;

  kernelPatches = [
    {
      # Adds amdgpu.mst kernel module parameter (default: enabled).
      # Upstream hook (preferred_training_settings.mst_enable) exists but is
      # not wired to any parameter on Linux.
      # (hooman input) amd is a $750B company ran by morons who can't fix their broken drivers for 3 years, thanks amd, fuck you.
      name = "amdgpu-mst-toggle";
      patch = ./amdgpu-mst-toggle.patch;
    }
  ];

  # NixOS's generated config for linux_latest, trimmed with `make localmodconfig`
  # to the modules listed in modules.lsmod (hardware + common USB accessories).
  # Builtins (=y) are untouched, only unlisted modules (=m) get disabled.
  # Regenerated automatically on every kernel bump.
  trimmedConfig = pkgs.stdenv.mkDerivation {
    pname = "linux-config-ramapraca";
    inherit (base) version src;

    nativeBuildInputs = with pkgs; [
      perl
      flex
      bison
      bc
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      install -m644 ${base.configfile} .config
      make LSMOD=${./modules.lsmod} localmodconfig < /dev/null
      make olddefconfig
      runHook postBuild
    '';

    installPhase = ''
      cp .config $out
    '';
  };

  kernel = pkgs.linuxManualConfig {
    inherit (base) src version modDirVersion;
    inherit kernelPatches;
    # Builtins are unchanged by localmodconfig, so base features (ia32Emulation etc.) still hold.
    inherit (base) features;
    configfile = trimmedConfig;
    # Needed to parse the config for NixOS's requiredKernelConfig assertions.
    allowImportFromDerivation = true;
  };
in
{
  boot.kernelPackages = pkgs.linuxPackagesFor kernel;
}
