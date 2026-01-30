{
  pkgs,
  lib,
  ...
}:

let
  jd-gui = pkgs.stdenv.mkDerivation rec {
    pname = "jd-gui";
    version = "1.6.6";

    src = pkgs.fetchurl {
      url = "https://github.com/java-decompiler/jd-gui/releases/download/v${version}/jd-gui-${version}.jar";
      hash = "sha256-02zwb9l8j0fmf0rhmlmrw08jmyybxzv6i7qkhir8lhq6igx3x79c";
    };

    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.copyDesktopItems
    ];

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "jd-gui";
        desktopName = "JD-GUI";
        comment = "Java Decompiler";
        exec = "jd-gui";
        icon = "jd-gui";
        categories = [
          "Development"
          "Debugger"
        ];
        keywords = [
          "java"
          "decompiler"
          "debugger"
        ];
        startupNotify = true;
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/java $out/bin

      cp $src $out/share/java/jd-gui.jar

      makeWrapper ${pkgs.openjdk}/bin/java $out/bin/jd-gui \
        --add-flags "-jar $out/share/java/jd-gui.jar"

      mkdir -p $out/share/icons/hicolor/256x256/apps
      ${pkgs.imagemagick}/bin/convert -size 256x256 xc:white $out/share/icons/hicolor/256x256/apps/jd-gui.png

      runHook postInstall
    '';

    meta = {
      description = "A standalone graphical utility that displays Java source codes of .class files";
      homepage = "https://github.com/java-decompiler/jd-gui";
      license = lib.licenses.gpl3Plus;
      mainProgram = "jd-gui";
    };
  };
in
{
  environment.systemPackages = [ jd-gui ];
}
