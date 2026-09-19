{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  python3Packages,
}:

let
  # ankerctl is a from-source Python script (no PyPI release, no setup.py entry
  # point), so it is run directly with a Python that has all its deps on the
  # search path. The commit-specific codeload tarball 404s upstream, so we pin
  # via fetchGit instead of fetchFromGitHub.
  src = builtins.fetchGit {
    url = "https://github.com/Django1982/ankermake-m5-protocol";
    rev = "51ef4d94669979a12cea71dbc74e928f348b88b3";
  };

  # tinyec (pure-Python ECC, used only for login ECDH) is not in nixpkgs.
  # It is tiny and proper cryptography, so vendor the real library rather than
  # reimplement it. Structure: a single `tinyec/` package directory.
  tinyec-src = fetchFromGitHub {
    owner = "alexmgr";
    repo = "tinyec";
    rev = "9a72bde3b77d2311f7a44dede573122f8b826687";
    hash = "sha256-U/Z3A5Bet1M9T8qtz0qBpwiaR5NVIODGJuZxEXEkexQ=";
  };

  pythonEnv = python3.withPackages (ps: [
    ps.paho-mqtt
    ps.pycryptodomex
    ps.rich
    ps.requests
    ps.click
    ps.platformdirs
    ps.crcmod
    ps.tqdm
    ps.flask
    ps.flask-sock
    ps.user-agents
    ps.werkzeug
  ]);
in

stdenv.mkDerivation {
  pname = "ankerctl";
  version = "1.11.0";

  inherit src;

  dontBuild = true;

  installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/lib/ankerctl
        cp -rT $src $out/lib/ankerctl
        cp -rT ${tinyec-src}/tinyec $out/lib/ankerctl/tinyec
        cat > $out/bin/ankerctl <<WRAPPER
    #!${stdenv.shell} -e
    if [ -n "\$PYTHONPATH" ]; then
      export PYTHONPATH="$out/lib/ankerctl:\$PYTHONPATH"
    else
      export PYTHONPATH="$out/lib/ankerctl"
    fi
    exec ${pythonEnv}/bin/python "$out/lib/ankerctl/ankerctl.py" "\$@"
    WRAPPER
        chmod +x $out/bin/ankerctl
        runHook postInstall
  '';

  meta = {
    description = "CLI and web UI for AnkerMake/eufyMake M5 3D printers (reverse engineered)";
    homepage = "https://github.com/Django1982/ankermake-m5-protocol";
    license = with lib.licenses; [ gpl3Plus ];
    platforms = lib.platforms.linux;
    mainProgram = "ankerctl";
  };
}
