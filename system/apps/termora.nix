{
  pkgs,
  lib,
  ...
}:
let
  termora = pkgs.stdenv.mkDerivation rec {
    pname = "termora";
    version = "unstable-2025-01-25";

    src = pkgs.fetchFromGitHub {
      owner = "TermoraDev";
      repo = "termora";
      rev = "refs/heads/2.x";
      hash = "sha256-zlWkzlxUsknf/E0XcAo0Ic3NNdM/4mJgsGt180GMkHY=";
    };

    nativeBuildInputs = with pkgs; [
      gradle
      jdk21
      copyDesktopItems
      makeWrapper
    ];

    buildInputs = with pkgs; [
      jre
    ];

    GRADLE_USER_HOME = ".gradle";

    buildPhase = ''
      ${pkgs.gradle}/bin/gradle --no-daemon clean build -x test
    '';

    installPhase = ''
      mkdir -p $out/share/{applications,icons/hicolor/256x256/apps} $out/bin

      # Find the built jar
      cp build/libs/termora-*.jar $out/share/termora.jar

      # Create wrapper script
      makeWrapper ${pkgs.jre}/bin/java $out/bin/termora \
        --add-flags "-jar $out/share/termora.jar"

      # Install icon
      cp src/main/resources/icons/termora_256x256.png $out/share/icons/hicolor/256x256/apps/termora.png

      # Create desktop entry
      cat > $out/share/applications/termora.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=Termora
      Comment=Terminal emulator and SSH client
      Exec=$out/bin/termora
      Icon=termora
      Categories=Development;System;TerminalEmulator;
      StartupNotify=true
      EOF
    '';

    meta = {
      description = "Terminal emulator and SSH client for Windows, macOS and Linux";
      homepage = "https://github.com/TermoraDev/termora";
      license = lib.licenses.agpl3Plus;
      mainProgram = "termora";
    };
  };
in
{
  environment.systemPackages = [ termora ];
}
