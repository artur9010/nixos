{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  eufymake-slicer = pkgs.stdenv.mkDerivation rec {
    pname = "eufymake-slicer";
    version = "1.5.25";

    src = pkgs.fetchFromGitHub {
      owner = "eufymake";
      repo = "eufyMake-PrusaSlicer-Release";
      rev = "b34659667ecdf3cedd484d3082f2a5a31849945d"; # v1.5.25 tag
      hash = "sha256-ioNRjZBTD6uWB9RDxjRAprSxfmngaZobAUQ3egS084o=";
    };

    sourceRoot = "source/AnkerStudio";

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      wrapGAppsHook3
      wxGTK32
    ];

    buildInputs = with pkgs; [
      binutils
      boost186
      cereal
      cgal_5
      curl
      dbus
      eigen
      expat
      glew
      glib
      glib-networking
      gmp
      gtk3
      hicolor-icon-theme
      ilmbase
      libpng
      mpfr
      (nanosvg.overrideAttrs (old: {
        pname = "nanosvg-fltk";
        version = "unstable-2022-12-22";
        src = pkgs.fetchFromGitHub {
          owner = "fltk";
          repo = "nanosvg";
          rev = "abcd277ea45e9098bed752cf9c6875b533c0892f";
          hash = "sha256-WNdAYu66ggpSYJ8Kt57yEA4mSTv+Rvzj9Rm1q765HpY=";
        };
      }))
      nlopt
      opencascade-occt_7_6_1
      openvdb
      qhull
      onetbb
      wxGTK32
      xorg.libX11
      libbgcode
      heatshrink
      catch2_3
      webkitgtk_4_1
      z3
      nlohmann_json
    ] ++ lib.optionals (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.systemd) [
      systemd
    ];

    strictDeps = true;

    separateDebugInfo = true;

    # The build system uses custom logic for finding the nlopt library
    NLOPT = pkgs.nlopt;

    # eufymake-slicer uses dlopen on `libudev.so` at runtime
    NIX_LDFLAGS = lib.optionalString (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.systemd) "-ludev";

    prePatch = ''
      # Since version 2.5.0 of nlopt we need to link to libnlopt
      sed -i 's|nlopt_cxx|nlopt|g' cmake/modules/FindNLopt.cmake

      # prusa-slicer expects the OCCTWrapper shared library in the same folder as
      # the executable when loading STEP files. We force the loader to find it in
      # the usual locations (i.e. LD_LIBRARY_PATH) instead.
      if [ -f "src/libslic3r/Format/STEP.cpp" ]; then
        substituteInPlace src/libslic3r/Format/STEP.cpp \
          --replace-fail 'libpath /= "OCCTWrapper.so";' 'libpath = "OCCTWrapper.so";'
      fi

      # https://github.com/prusa3d/PrusaSlicer/issues/9581
      if [ -f "cmake/modules/FindEXPAT.cmake" ]; then
        rm cmake/modules/FindEXPAT.cmake
      fi

      # Fix resources folder location
      substituteInPlace src/CLI/Setup.cpp \
        --replace-fail "#ifdef __APPLE__" "#if 0" || true

      # Relax OpenCASCADE version requirement to work with nixpkgs version
      substituteInPlace src/occt_wrapper/CMakeLists.txt \
        --replace-fail "find_package(OpenCASCADE 7.6.2 REQUIRED)" "find_package(OpenCASCADE 7.6.1 REQUIRED)"

      # Fix case-sensitivity issue in CMakeLists.txt
      substituteInPlace src/libslic3r/CMakeLists.txt \
        --replace-fail "Calib.hpp" "calib.hpp" \
        --replace-fail "Calib.cpp" "calib.cpp"

      # Enable OPEN_SOURCE mode to disable proprietary AnkerNet dependency
      substituteInPlace CMakeLists.txt \
        --replace-fail "set(OPEN_SOURCE OFF)" "set(OPEN_SOURCE ON)"

      # Fix git merge conflict markers in version.inc - keep HEAD version (1.5.25)
      sed -i '/^<<<<<<< HEAD$/,/^=======$/!b; /^<<<<<<< HEAD$/d; /^=======$/d' version.inc
      sed -i '/^>>>>>>> 84b4984 (feat: 1\.5\.21 open source)$/,/^$/d' version.inc

      # Fix git merge conflict markers in GcodeInfo.cpp - keep HEAD version
      sed -i '/^<<<<<<< HEAD$/d' src/slic3r/Utils/GcodeInfo.cpp
      sed -i '/^=======$/,/^>>>>>>> 84b4984 (feat: 1\.5\.21 open source)$/d' src/slic3r/Utils/GcodeInfo.cpp

      # Fix git merge conflict markers in AnkerDevice.hpp - keep HEAD version
      sed -i '/^<<<<<<< HEAD$/d' src/slic3r/GUI/AnkerDevice.hpp
      sed -i '/^=======$/,/^>>>>>>> 84b4984 (feat: 1\.5\.21 open source)$/d' src/slic3r/GUI/AnkerDevice.hpp

      # Fix CGAL const correctness issues in MeshBoolean.cpp
      sed -i 's/for (auto &vi : vertices)/for (const auto \&vi : vertices)/' src/libslic3r/MeshBoolean.cpp
      sed -i 's/for (auto &face : faces)/for (const auto \&face : faces)/' src/libslic3r/MeshBoolean.cpp
    '';

    cmakeFlags = [
      "-DSLIC3R_STATIC=0"
      "-DSLIC3R_FHS=1"
      "-DSLIC3R_GTK=3"
      "-DCMAKE_CXX_FLAGS=-DBOOST_LOG_DYN_LINK"
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
      "-DOPEN_SOURCE=ON"
    ];

    meta = with lib; {
      description = "eufyMake Studio - A PrusaSlicer fork with remote printing control";
      homepage = "https://github.com/eufymake/eufyMake-PrusaSlicer-Release";
      license = licenses.agpl3Only;
      maintainers = [ ];
      platforms = platforms.linux;
      mainProgram = "eufymake-slicer";
    };
  };
in
{
  # eufyMake Studio package
  environment.systemPackages = [
    eufymake-slicer
  ];
}
