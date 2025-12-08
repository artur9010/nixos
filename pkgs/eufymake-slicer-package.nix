{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  wrapGAppsHook3,
  wxGTK32,
  binutils,
  boost186,
  cereal,
  cgal_5,
  curl,
  dbus,
  eigen,
  expat,
  glew,
  glib,
  glib-networking,
  gmp,
  gtk3,
  hicolor-icon-theme,
  ilmbase,
  libpng,
  mpfr,
  nanosvg,
  nlopt,
  opencascade-occt_7_6_1,
  openvdb,
  qhull,
  onetbb,
  xorg,
  libbgcode,
  heatshrink,
  catch2_3,
  webkitgtk_4_1,
  z3,
  nlohmann_json,
  systemd,
  ...
}:

stdenv.mkDerivation rec {
    pname = "eufymake-slicer";
    version = "1.5.25";

    src = pkgs.fetchFromGitHub {
      owner = "eufymake";
      repo = "eufyMake-PrusaSlicer-Release";
      rev = "b34659667ecdf3cedd484d3082f2a5a31849945d"; # v1.5.25 tag
      hash = "sha256-ioNRjZBTD6uWB9RDxjRAprSxfmngaZobAUQ3egS084o=";
    };

    sourceRoot = "source/AnkerStudio";

    nativeBuildInputs = [
      cmake
      pkg-config
      wrapGAppsHook3
      wxGTK32
      pkgs.perl
    ];

    buildInputs = [
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
        src = fetchFromGitHub {
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
    ] ++ lib.optionals (lib.meta.availableOn stdenv.hostPlatform systemd) [
      systemd
    ];

    strictDeps = true;

    separateDebugInfo = true;

    # The build system uses custom logic for finding the nlopt library
    NLOPT = nlopt;

    # eufymake-slicer uses dlopen on `libudev.so` at runtime
    NIX_LDFLAGS = lib.optionalString (lib.meta.availableOn stdenv.hostPlatform systemd) "-ludev";

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

      # Relax OpenCASCADE version requirement to work with nixpkgs version
      substituteInPlace src/occt_wrapper/CMakeLists.txt \
        --replace-fail "find_package(OpenCASCADE 7.6.2 REQUIRED)" "find_package(OpenCASCADE 7.6.1 REQUIRED)"

      # Fix case-sensitivity issue in CMakeLists.txt
      substituteInPlace src/libslic3r/CMakeLists.txt \
        --replace-fail "Calib.hpp" "calib.hpp" \
        --replace-fail "Calib.cpp" "calib.cpp"

      # Note: OPEN_SOURCE is already ON in v1.5.25, no need to change it

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

      # Fix comma operator misuse in ExtrusionProcessor.hpp (should be &&)
      sed -i 's/if (move_dist > 2 \* scaled(line_width), distance_data_new.distance > EPSILON)/if (move_dist > 2 * scaled(line_width) \&\& distance_data_new.distance > EPSILON)/' src/libslic3r/GCode/ExtrusionProcessor.hpp

      # Remove deprecated boost/filesystem/string_file.hpp include (not used, removed in newer Boost)
      sed -i '/#include <boost\/filesystem\/string_file.hpp>/d' src/libslic3r/Format/bbs_3mf.cpp

      # Fix boost::filesystem::extension() - use path member method instead
      sed -i 's/boost::filesystem::extension(filePath)/filePath.extension().string()/' src/libslic3r/GCode/GCodeProcessor.cpp

      # Fix DLL_EXPORT for Linux - just remove DLL_EXPORT from all declarations
      # AnkerNet plugin is loaded dynamically anyway, so we don't need export declarations
      sed -i 's/class DLL_EXPORT /class /g' "src/slic3r/GUI/AnkerNetModule/Interface Files/AnkerNetBase.h"
      sed -i 's/struct DLL_EXPORT /struct /g' "src/slic3r/GUI/AnkerNetModule/Interface Files/AnkerNetBase.h"
      sed -i 's/enum DLL_EXPORT /enum /g' "src/slic3r/GUI/AnkerNetModule/Interface Files/AnkerNetBase.h"
      sed -i 's/class DLL_EXPORT /class /g' "src/anker_plungin/Interface Files/AnkerPlugin.hpp"
      sed -i 's/struct DLL_EXPORT /struct /g' "src/anker_plungin/Interface Files/AnkerPlugin.hpp"
      sed -i 's/enum DLL_EXPORT /enum /g' "src/anker_plungin/Interface Files/AnkerPlugin.hpp"
      # Also remove any remaining _declspec references
      sed -i 's/_\?_declspec(dllexport)//g' "src/slic3r/GUI/AnkerNetModule/Interface Files/AnkerNetBase.h"
      sed -i 's/_\?_declspec(dllexport)//g' "src/anker_plungin/Interface Files/AnkerPlugin.hpp"
      sed -i 's/_\?_declspec(dllimport)//g' "src/slic3r/GUI/AnkerNetModule/Interface Files/AnkerNetBase.h"
      sed -i 's/_\?_declspec(dllimport)//g' "src/anker_plungin/Interface Files/AnkerPlugin.hpp"

      # Add forward declarations for missing AnkerNet types
      # These types are defined in the AnkerNet plugin which is loaded at runtime
      sed -i '1i namespace AnkerNet { struct MsgCenterItem {}; struct MsgCenterConfig {}; struct MsgErrCodeInfo {}; }' "src/slic3r/GUI/AnkerNetModule/Interface Files/AnkerNetBase.h"

      # Fix duplicate const in AppConfig.hpp
      sed -i 's/bool get_slice_times(const const std::string&/bool get_slice_times(const std::string\&/' src/libslic3r/AppConfig.hpp
      sed -i 's/bool set_slice_times(const const std::string&/bool set_slice_times(const std::string\&/' src/libslic3r/AppConfig.hpp

      # Fix boost::filesystem::ofstream - use std::ofstream instead
      sed -i 's/boost::filesystem::ofstream/std::ofstream/' src/libslic3r/PrintApply.cpp

      # Fix boost::filesystem::change_extension - use path member function
      sed -i 's/boost::filesystem::change_extension(filename, default_ext)/boost::filesystem::path(filename).replace_extension(default_ext).string()/' src/libslic3r/PrintBase.cpp

      # Fix unterminated string in AnkerGUIConfig.hpp
      sed -i 's/wxT(fonttype""))/wxT(fonttype))/' src/slic3r/GUI/Common/AnkerGUIConfig.hpp

      # Fix case-sensitive wx header
      sed -i 's|wx/Overlay.h|wx/overlay.h|' src/slic3r/GUI/AnkerVideo.hpp
      sed -i 's|wx/Overlay.h|wx/overlay.h|' src/slic3r/GUI/AnkerGcodePreviewToolBar.hpp

      # Fix case-sensitive Common directory include
      sed -i 's|"common/AnkerMsgDialog.hpp"|"Common/AnkerMsgDialog.hpp"|' src/slic3r/GUI/MainFrame.hpp

      # Fix duplicate function declarations in ImGuiWrapper.hpp (lines 317-320 duplicate 304-307)
      sed -i '317,320d' src/slic3r/GUI/ImGuiWrapper.hpp

      # Fix duplicate TextAlignType enum in AnkerHyperlink.hpp (lines 17-21 duplicate 8-12)
      sed -i '17,21d' src/slic3r/GUI/AnkerHyperlink.hpp

      # Fix duplicate AnkerDialogIconTextOkPanel class in AnkerDialog.hpp
      # Delete the second occurrence using brace counting to handle nested structures
      perl -i -ne '
        BEGIN { $$count = 0; $$skip = 0; $$brace_depth = 0; }
        if (/class AnkerDialogIconTextOkPanel/) {
          $$count++;
          if ($$count == 2) { $$skip = 1; $$brace_depth = 0; }
        }
        if ($$skip) {
          $$brace_depth++ while /\{/g;
          $$brace_depth-- while /\}/g;
          if ($$brace_depth <= 0 && /};/) { $$skip = 0; next; }
          next;
        }
        print;
      ' src/slic3r/GUI/Common/AnkerDialog.hpp

      # Fix AnkerMsgDialog missing base class - ensure it inherits from wxDialog
      # If the class declaration is missing wxDialog inheritance, add it
      sed -i 's/^class AnkerMsgDialog$/class AnkerMsgDialog : public wxDialog/' src/slic3r/GUI/Common/AnkerMsgDialog.hpp
      sed -i 's/^class AnkerMsgDialog {$/class AnkerMsgDialog : public wxDialog {/' src/slic3r/GUI/Common/AnkerMsgDialog.hpp

      # Fix duplicate RightSidePanelUpdateReason enum in Plater.hpp
      # Delete the second occurrence of the enum (around line 123)
      perl -i -ne '
        BEGIN { $$count = 0; $$skip = 0; }
        if (/^\s*enum RightSidePanelUpdateReason/) {
          $$count++;
          if ($$count == 2) { $$skip = 1; }
        }
        if ($$skip) {
          if (/^\s*};/) { $$skip = 0; next; }
          next;
        }
        print;
      ' src/slic3r/GUI/Plater.hpp

      # Fix duplicate set_mmu_render_data_from_model_volume function in 3DScene.cpp
      # Delete the second occurrence (lines 315-334 based on error)
      perl -i -ne '
        BEGIN { $$count = 0; $$skip = 0; $$brace_depth = 0; }
        if (/void GLVolume::set_mmu_render_data_from_model_volume/) {
          $$count++;
          if ($$count == 2) { $$skip = 1; $$brace_depth = 0; }
        }
        if ($$skip) {
          $$brace_depth++ while /\{/g;
          $$brace_depth-- while /\}/g;
          if ($$brace_depth == 0 && /\}/) { $$skip = 0; next; }
          next;
        }
        print;
      ' src/slic3r/GUI/3DScene.cpp

      # Fix duplicate functions in GLGizmoMeasure.cpp
      perl -i -ne '
        BEGIN { $$count_set = 0; $$count_update = 0; $$skip = 0; $$brace_depth = 0; }
        if (/void GLGizmoMeasure::set_input_window_state/) {
          $$count_set++;
          if ($$count_set == 2) { $$skip = 1; $$brace_depth = 0; }
        }
        if (/void GLGizmoMeasure::update_input_window/) {
          $$count_update++;
          if ($$count_update == 2) { $$skip = 1; $$brace_depth = 0; }
        }
        if ($$skip) {
          $$brace_depth++ while /\{/g;
          $$brace_depth-- while /\}/g;
          if ($$brace_depth == 0 && /\}/) { $$skip = 0; next; }
          next;
        }
        print;
      ' src/slic3r/GUI/Gizmos/GLGizmoMeasure.cpp
    '';

    cmakeFlags = [
      "-DSLIC3R_STATIC=0"
      "-DSLIC3R_FHS=1"
      "-DSLIC3R_GTK=3"
      "-DCMAKE_CXX_FLAGS=-DBOOST_LOG_DYN_LINK"
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
    ];

    meta = with lib; {
      description = "eufyMake Studio - A PrusaSlicer fork with remote printing control";
      homepage = "https://github.com/eufymake/eufyMake-PrusaSlicer-Release";
      license = licenses.agpl3Only;
      maintainers = [ ];
      platforms = platforms.linux;
      mainProgram = "eufymake-slicer";
    };
  }
