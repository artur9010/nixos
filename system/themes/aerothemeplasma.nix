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

  postPatch = ''
    patchShebangs compile.sh
    
    # Patch install scripts to use our output directory
    for script in kwin/decoration/install.sh kwin/effects_cpp/*/install.sh plasma/aerothemeplasma-kcmloader/install.sh; do
      if [ -f "$script" ]; then
        patchShebangs "$script"
      fi
    done
  '';

  buildPhase = ''
    runHook preBuild
    
    export HOME=$TMPDIR
    
    # Build the decoration
    cd kwin/decoration
    mkdir -p build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=$out -G Ninja ..
    ninja
    cd ../../..
    
    # Build the KCM loader
    cd plasma/aerothemeplasma-kcmloader
    mkdir -p build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=$out -G Ninja ..
    ninja
    cd ../../..
    
    # Build KWin effects
    for effect in kwin/effects_cpp/*; do
      if [ -d "$effect" ]; then
        cd "$effect"
        mkdir -p build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=$out -G Ninja ..
        ninja
        cd ../../../..
      fi
    done
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share
    
    # Install compiled components
    cd kwin/decoration/build
    ninja install
    cd ../../..
    
    cd plasma/aerothemeplasma-kcmloader/build
    ninja install
    cd ../../..
    
    for effect in kwin/effects_cpp/*; do
      if [ -d "$effect/build" ]; then
        cd "$effect/build"
        ninja install
        cd ../../../..
      fi
    done
    
    # Copy KWin components
    mkdir -p $out/share/kwin
    cp -r kwin/effects $out/share/kwin/ || true
    cp -r kwin/scripts $out/share/kwin/ || true
    cp -r kwin/tabbox $out/share/kwin/ || true
    cp -r kwin/outline $out/share/kwin/ || true
    cp -r kwin/smod $out/share/ || true
    
    # Copy Plasma components
    mkdir -p $out/share/plasma
    cp -r plasma/plasmoids/* $out/share/plasma/plasmoids/ || true
    cp -r plasma/desktoptheme $out/share/plasma/ || true
    cp -r plasma/look-and-feel $out/share/plasma/ || true
    
    # Copy color schemes, window decorations, icons, etc
    cp -r misc/color-schemes $out/share/ || true
    cp -r misc/aurorae $out/share/ || true
    cp -r misc/icons $out/share/ || true
    
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
