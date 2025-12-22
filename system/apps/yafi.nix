{
  pkgs,
  lib,
  ...
}:

let
  cros_ec_python = pkgs.python3Packages.buildPythonPackage rec {
    pname = "cros_ec_python";
    version = "0.3.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "Steve-Tech";
      repo = "CrOS_EC_Python";
      rev = version;
      hash = "sha256-bX4UqWHm6XZflEXXYiPZSlMcYJ9ykfhIiuZuq0LrVqs=";
    };

    build-system = [ pkgs.python3Packages.setuptools ];

    pythonImportsCheck = [ "cros_ec_python" ];

    meta = {
      description = "Python library for interacting with Chrome OS Embedded Controllers";
      homepage = "https://github.com/Steve-Tech/CrOS_EC_Python";
      license = lib.licenses.gpl2Plus;
    };
  };

  yafi = pkgs.python3Packages.buildPythonApplication rec {
    pname = "yafi";
    version = "0.6";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "Steve-Tech";
      repo = "YAFI";
      rev = version;
      hash = "sha256-rLUXhKdKbA9WwUNBonZmHjCPt86wBmeduSSqWt4lliU=";
    };

    build-system = [ pkgs.python3Packages.setuptools ];

    dependencies = [
      cros_ec_python
      pkgs.python3Packages.pygobject3
    ];

    nativeBuildInputs = [
      pkgs.gobject-introspection
      pkgs.wrapGAppsHook4
      pkgs.copyDesktopItems
    ];

    buildInputs = [
      pkgs.gtk4
      pkgs.libadwaita
    ];

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "au.stevetech.yafi";
        desktopName = "YAFI";
        comment = "Yet Another Framework Interface";
        exec = "yafi";
        icon = "au.stevetech.yafi";
        categories = [ "Utility" ];
        keywords = [ "Framework" "EC" "Embedded Controller" ];
        startupNotify = true;
      })
    ];

    postInstall = ''
      install -Dm644 $src/data/icons/hicolor/scalable/apps/au.stevetech.yafi.svg \
        $out/share/icons/hicolor/scalable/apps/au.stevetech.yafi.svg
      install -Dm644 $src/data/icons/hicolor/symbolic/apps/au.stevetech.yafi-symbolic.svg \
        $out/share/icons/hicolor/symbolic/apps/au.stevetech.yafi-symbolic.svg
    '';

    pythonImportsCheck = [ "yafi" ];

    meta = {
      description = "Yet Another GUI for the Framework Laptop Embedded Controller";
      homepage = "https://github.com/Steve-Tech/YAFI";
      license = lib.licenses.gpl2Plus;
      mainProgram = "yafi";
    };
  };
in
{
  environment.systemPackages = [ yafi ];

  # udev rules for cros_ec device access
  services.udev.extraRules = ''
    KERNEL=="cros_ec", TAG+="uaccess"
  '';
}
