{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  kdePackages,
  libvirt,
  libosinfo,
  glib,
  spice-gtk,
  spice-protocol,
  sysprof,
  libGL,
  qemu,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "karton";
  version = "1.0.0-unstable-2026-08-23";

  src = fetchFromGitHub {
    owner = "KDE";
    repo = "karton";
    rev = "bb41d44325c8fee6ab58efbe76a60fd26e932a1b";
    hash = "sha256-8wW+Bc9I1Zxliv/YDWzWsoC+mOrN0zEQEAvQRtDL3Pc=";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    pkg-config
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = [
    kdePackages.qtbase
    kdePackages.qtdeclarative
    kdePackages.qtmultimedia
    kdePackages.kirigami
    kdePackages.kirigami-addons
    kdePackages.ki18n
    kdePackages.kcoreaddons
    kdePackages.qqc2-desktop-style
    kdePackages.kiconthemes
    libvirt
    libosinfo
    glib
    spice-gtk
    spice-protocol
    sysprof
    libGL
  ];

  # Replace the bare Exec with an absolute path so the entry works
  # even in launchers that do not inherit the system PATH.
  postInstall = ''
    substituteInPlace $out/share/applications/org.kde.karton.desktop \
      --replace-fail "Exec=karton" "Exec=$out/bin/karton"
  '';

  # Karton talks to the session libvirt daemon (qemu:///session) and shells
  # out to qemu-img. The spawned session daemon inherits this environment,
  # so qemu on PATH also lets it find qemu-system-x86_64.
  qtWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ qemu ]}" ];

  meta = {
    description = "Libvirt-based virtual machine manager for KDE";
    mainProgram = "karton";
    homepage = "https://invent.kde.org/sitter/karton";
    license = with lib.licenses; [
      gpl3Plus
      bsd2
      cc0
    ];
    platforms = lib.platforms.linux;
  };
})
