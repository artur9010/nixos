{
  lib,
  stdenv,
  fetchzip,
  cmake,
  extra-cmake-modules,
  ninja,
  kwin,
  plasma-workspace,
  plasma5support,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "aerothemeplasma";
  version = "unstable-2025-12-07";

  src = fetchzip {
    url = "https://gitgud.io/wackyideas/aerothemeplasma/-/archive/97506fd35e3d186442e13b8d9021bd9b41c26c22/aerothemeplasma-97506fd35e3d186442e13b8d9021bd9b41c26c22.tar.gz";
    sha256 = "sha256-bXsMJCkrvVHJ6wl3PZkJLpNHqQJaUNmb+skX/+Axedc=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    ninja
  ];

  buildInputs = [
    kwin
    plasma-workspace
    plasma5support
    kdePackages.kwindowsystem
    kdePackages.kconfig
    kdePackages.kconfigwidgets
    kdePackages.kcoreaddons
    kdePackages.kguiaddons
    kdePackages.ki18n
    kdePackages.kio
    kdePackages.kpackage
    kdePackages.ksvg
    kdePackages.kglobalaccel
    kdePackages.knotifications
    kdePackages.kirigami
    kdePackages.kiconthemes
    kdePackages.kcmutils
    kdePackages.kcrash
    kdePackages.kdecoration
    kdePackages.plasma-activities
    kdePackages.qtbase
    kdePackages.qtwayland
    kdePackages.qtmultimedia
    kdePackages.qt5compat
    kdePackages.qtsvg
  ];

  # Run all install scripts
  postPatch = ''
    patchShebangs compile.sh install_plasmoids.sh install_kwin_components.sh install_plasma_components.sh install_misc_components.sh
  '';

  buildPhase = ''
    runHook preBuild
    
    bash compile.sh --ninja
    bash install_plasmoids.sh --ninja
    bash install_kwin_components.sh
    bash install_plasma_components.sh
    bash install_misc_components.sh
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    # The install scripts install to ~/.local/share by default
    # We need to redirect this to $out
    mkdir -p $out
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows 7 theme for KDE Plasma 6";
    homepage = "https://gitgud.io/wackyideas/aerothemeplasma";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
