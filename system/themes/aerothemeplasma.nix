{
  lib,
  stdenv,
  fetchzip,
  cmake,
  extra-cmake-modules,
  ninja,
  kdePackages,
}:

stdenv.mkDerivation rec {
  pname = "aerothemeplasma";
  version = "unstable-2025-12-07";

  src = fetchzip {
    url = "https://gitgud.io/wackyideas/aerothemeplasma/-/archive/97506fd35e3d186442e13b8d9021bd9b41c26c22/aerothemeplasma-97506fd35e3d186442e13b8d9021bd9b41c26c22.tar.gz";
    sha256 = "sha256-aeI5wiW9qXlSm/h5B21sRGCt2Azlit5WE5axeY8Sfew=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    ninja
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = with kdePackages; [
    # Qt6 packages
    qtbase
    qtdeclarative
    qtsvg
    qt5compat
    qtwayland
    qtmultimedia
    
    # KDE Frameworks 6
    kconfig
    kcoreaddons
    kcolorscheme
    kguiaddons
    ki18n
    kiconthemes
    kwindowsystem
    kcmutils
    kcrash
    kdecoration
    kglobalaccel
    kio
    knotifications
    kpackage
    ksvg
    kirigami
    frameworkintegration
    kwidgetsaddons
    kxmlgui
    kservice
    kjobwidgets
    kdbusaddons
    kitemviews
    kbookmarks
    solid
    kcompletion
    kcodecs
    
    # Plasma 6 packages
    kwin
    plasma-workspace
    plasma5support
    plasma-activities
    libplasma
  ];

  # Don't use the automatic CMake configure phase since there's no top-level CMakeLists.txt
  dontUseCmakeConfigure = true;
  
  postPatch = ''
    # Patch kwin/decoration/CMakeLists.txt to replace multi-component find_package(KF6 ...)
    # with individual find_package(KF6Component ...) calls
    # Use sed for more robust pattern matching
    sed -i '/find_package(KF6.*REQUIRED COMPONENTS$/,/WindowSystem)$/{
      s|find_package(KF6.*REQUIRED COMPONENTS$|find_package(KF6CoreAddons ''${KF6_MIN_VERSION} REQUIRED)\n    find_package(KF6ColorScheme ''${KF6_MIN_VERSION} REQUIRED)\n    find_package(KF6Config ''${KF6_MIN_VERSION} REQUIRED)\n    find_package(KF6GuiAddons ''${KF6_MIN_VERSION} REQUIRED)\n    find_package(KF6I18n ''${KF6_MIN_VERSION} REQUIRED)\n    find_package(KF6IconThemes ''${KF6_MIN_VERSION} REQUIRED)\n    find_package(KF6WindowSystem ''${KF6_MIN_VERSION} REQUIRED)\n    # Replaced multi-component find_package(KF6)|
      /^[[:space:]]*CoreAddons$/d
      /^[[:space:]]*ColorScheme$/d
      /^[[:space:]]*Config$/d
      /^[[:space:]]*GuiAddons$/d
      /^[[:space:]]*I18n$/d
      /^[[:space:]]*IconThemes$/d
      /^[[:space:]]*WindowSystem)$/d
    }' kwin/decoration/CMakeLists.txt
    
    echo "Patched kwin/decoration/CMakeLists.txt"
  '';

  buildPhase = ''
    runHook preBuild
    
    export HOME=$TMPDIR
    
    # Build window decoration (SMOD)
    echo "Building window decoration..."
    (
      cd kwin/decoration
      mkdir -p build
      cd build
      cmake -DCMAKE_INSTALL_PREFIX=$out \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_TESTING=OFF \
            -DQT_MAJOR_VERSION=6 \
            -G Ninja \
            ..
      ninja
    ) && echo "Window decoration built successfully" || echo "Warning: Window decoration build failed"
    
    # Build C++ KWin effects
    for effect in kwin/effects_cpp/*; do
      if [ -d "$effect" ] && [ -f "$effect/CMakeLists.txt" ]; then
        echo "Building KWin effect: $(basename $effect)..."
        (
          cd "$effect"
          mkdir -p build
          cd build
          cmake -DCMAKE_INSTALL_PREFIX=$out \
                -DCMAKE_BUILD_TYPE=Release \
                -DBUILD_TESTING=OFF \
                -G Ninja \
                ..
          ninja
        ) && echo "Effect $(basename $effect) built successfully" || echo "Warning: Effect $(basename $effect) build failed"
      fi
    done
    
    # Build C++ plasmoids
    for plasmoid in plasma/plasmoids/src/*_src; do
      if [ -d "$plasmoid" ] && [ -f "$plasmoid/CMakeLists.txt" ]; then
        echo "Building plasmoid: $(basename $plasmoid)..."
        (
          cd "$plasmoid"
          mkdir -p build
          cd build
          cmake -DCMAKE_INSTALL_PREFIX=$out \
                -DCMAKE_BUILD_TYPE=Release \
                -DBUILD_TESTING=OFF \
                -G Ninja \
                ..
          ninja
        ) && echo "Plasmoid $(basename $plasmoid) built successfully" || echo "Warning: Plasmoid $(basename $plasmoid) build failed"
      fi
    done
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share
    
    # Install compiled C++ components
    echo "Installing compiled components..."
    
    # Install window decoration
    if [ -d kwin/decoration/build ]; then
      (cd kwin/decoration/build && ninja install) && echo "Window decoration installed" || echo "Warning: Window decoration install failed"
    fi
    
    # Install C++ KWin effects
    for effect in kwin/effects_cpp/*; do
      if [ -d "$effect/build" ]; then
        (cd "$effect/build" && ninja install) && echo "Effect $(basename $effect) installed" || echo "Warning: Effect $(basename $effect) install failed"
      fi
    done
    
    # Install C++ plasmoids
    for plasmoid in plasma/plasmoids/src/*_src; do
      if [ -d "$plasmoid/build" ]; then
        (cd "$plasmoid/build" && ninja install) && echo "Plasmoid $(basename $plasmoid) installed" || echo "Warning: Plasmoid $(basename $plasmoid) install failed"
      fi
    done
    
    # Copy KWin components (JS effects, scripts, tabbox, etc.)
    mkdir -p $out/share/kwin
    [ -d kwin/effects ] && cp -r kwin/effects $out/share/kwin/ || true
    [ -d kwin/scripts ] && cp -r kwin/scripts $out/share/kwin/ || true
    [ -d kwin/tabbox ] && cp -r kwin/tabbox $out/share/kwin/ || true
    [ -d kwin/outline ] && cp -r kwin/outline $out/share/kwin/ || true
    [ -d kwin/smod ] && cp -r kwin/smod $out/share/ || true
    
    # Copy Plasma components (plasmoids without C++ code)
    mkdir -p $out/share/plasma/plasmoids
    for plasmoid in plasma/plasmoids/*; do
      # Skip src directory and directories ending with _src (these have C++ code)
      if [ -d "$plasmoid" ] && [[ ! "$plasmoid" =~ _src$ ]] && [[ "$(basename "$plasmoid")" != "src" ]]; then
        cp -r "$plasmoid" $out/share/plasma/plasmoids/
      fi
    done
    
    # Copy desktop theme and look-and-feel
    [ -d plasma/desktoptheme ] && cp -r plasma/desktoptheme $out/share/plasma/ || true
    [ -d plasma/look-and-feel ] && cp -r plasma/look-and-feel $out/share/plasma/ || true
    
    # Copy SDDM theme if present
    [ -d plasma/sddm ] && mkdir -p $out/share/sddm/themes && cp -r plasma/sddm/* $out/share/sddm/themes/ || true
    
    # Copy color schemes
    [ -d misc/color-schemes ] && cp -r misc/color-schemes $out/share/ || true
    
    # Copy Aurorae window decorations
    [ -d misc/aurorae ] && cp -r misc/aurorae $out/share/ || true
    
    # Copy icons
    [ -d misc/icons ] && cp -r misc/icons $out/share/ || true
    
    # Copy Kvantum themes
    [ -d misc/kvantum ] && mkdir -p $out/share/Kvantum && cp -r misc/kvantum/* $out/share/Kvantum/ || true
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Windows 7 theme for KDE Plasma 6 with compiled C++ components";
    longDescription = ''
      AeroThemePlasma is a comprehensive theme that recreates the look and feel of Windows 7 on KDE Plasma 6.
      
      This package includes:
      - Compiled window decorations (SMOD decoration)
      - C++ KWin effects (aeroglassblur, aeroglide, smodglow, etc.)
      - C++ Plasma plasmoids (seventasks, systemtray, sevenstart, etc.)
      - JavaScript-based KWin effects (fadingpopupsaero, loginaero, dimscreenaero, etc.)
      - QML-based Plasma plasmoids
      - Desktop themes and look-and-feel packages
      - SDDM login themes
      - Color schemes
      - Aurorae window decorations
      - Icons (Windows 7 Aero cursor theme)
      - Kvantum Qt themes
      
      After installation, configure Plasma to use the AeroThemePlasma components through System Settings:
      - Appearance > Window Decorations (select SMOD)
      - Appearance > Global Theme
      - Appearance > Colors
      - Window Management > KWin Scripts
      - Workspace > Startup and Shutdown > Login Screen (SDDM)
    '';
    homepage = "https://gitgud.io/wackyideas/aerothemeplasma";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
