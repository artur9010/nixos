{
  lib,
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation rec {
  pname = "aerothemeplasma";
  version = "unstable-2025-12-07";

  src = fetchzip {
    url = "https://gitgud.io/wackyideas/aerothemeplasma/-/archive/97506fd35e3d186442e13b8d9021bd9b41c26c22/aerothemeplasma-97506fd35e3d186442e13b8d9021bd9b41c26c22.tar.gz";
    sha256 = "sha256-aeI5wiW9qXlSm/h5B21sRGCt2Azlit5WE5axeY8Sfew=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share
    
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
    description = "Windows 7 theme for KDE Plasma 6 - Theme assets only (C++ components require manual compilation)";
    longDescription = ''
      AeroThemePlasma is a theme that recreates the look and feel of Windows 7 on KDE Plasma 6.
      
      This package includes the theme assets (plasmoids, desktop themes, color schemes, icons, etc.)
      that don't require compilation. The C++ components (window decorations, KWin effects) need to
      be built separately following the project's installation instructions.
      
      To fully utilize this theme, you may need to:
      1. Manually compile and install the window decoration
      2. Manually compile and install C++ KWin effects
      3. Configure Plasma to use the AeroThemePlasma components
    '';
    homepage = "https://gitgud.io/wackyideas/aerothemeplasma";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
