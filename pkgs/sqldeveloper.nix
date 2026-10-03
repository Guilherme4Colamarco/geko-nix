{ lib, stdenvNoCC, fetchurl, unzip, jdk17, buildFHSEnv, makeDesktopItem, symlinkJoin }:
let
  version = "24.3.1.347.1826";
  app = stdenvNoCC.mkDerivation {
    pname = "sqldeveloper-files";
    inherit version;
    src = fetchurl {
      url = "https://download.oracle.com/otn_software/java/sqldeveloper/sqldeveloper-${version}-no-jre.zip";
      hash = "sha256-M5DvWJcvHyVQd8SeZrFxuGZHc7sW43Vwp8oWrMWvuMs=";
    };
    nativeBuildInputs = [ unzip ];
    sourceRoot = "sqldeveloper";
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/sqldeveloper
      cp -r . $out/lib/sqldeveloper/
      echo 'SetJavaHome ${jdk17.home}' >> $out/lib/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf
      # Quote forwarded arguments in Oracle's top-level launcher.
      cat > $out/lib/sqldeveloper/sqldeveloper.sh <<'SCRIPT'
      #!/bin/bash
      cd "$(dirname "$0")/sqldeveloper/bin"
      exec bash sqldeveloper "$@"
      SCRIPT
      chmod +x $out/lib/sqldeveloper/sqldeveloper.sh
      runHook postInstall
    '';
  };
  env = buildFHSEnv {
    name = "sqldeveloper";
    targetPkgs = pkgs: with pkgs; [
      jdk17 bash coreutils which fontconfig freetype zlib gtk3 glib
      libGL libsecret xorg.libX11 xorg.libXext xorg.libXi xorg.libXrender xorg.libXtst
    ];
    runScript = "${app}/lib/sqldeveloper/sqldeveloper.sh";
  };
  desktop = makeDesktopItem {
    name = "sqldeveloper";
    desktopName = "Oracle SQL Developer";
    genericName = "SQL database client";
    exec = "sqldeveloper";
    terminal = false;
    categories = [ "Development" "Database" ];
  };
in symlinkJoin {
  name = "sqldeveloper-${version}";
  paths = [ env desktop ];
  passthru = { inherit app; runtime = jdk17; };
  meta = {
    description = "Oracle SQL Developer with an isolated JDK 17 runtime";
    homepage = "https://www.oracle.com/database/sqldeveloper/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sqldeveloper";
  };
}
