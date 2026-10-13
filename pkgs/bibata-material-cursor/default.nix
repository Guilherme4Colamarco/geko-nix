# Material Bibata Cursor (SakibShahariar, MIT; base: Bibata de ful1e5): Xcursor, SVG e Hyprcursor.
# O release traz as 28 cores; instala só a escolhida (`variant`), para não levar ~90 MB à closure.
# Versão, url e hash andam juntos. Hash: nix store prefetch-file --unpack <url>.
{ lib, stdenvNoCC, fetchzip, variant ? "Peach" }:
stdenvNoCC.mkDerivation rec {
  pname = "bibata-material-cursor-${lib.toLower variant}";
  version = "1.5.0";
  src = fetchzip {
    url = "https://github.com/SakibShahariar/material-bibata-cursor/releases/download/v${version}/bibata-material-dark-v${version}.tar.gz";
    hash = "sha256-qRZIG2wGEo6Qvg9+99QSyLKmCfHGsl3DpblF7/+cH4Y=";
  };
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    test -d "Bibata-Material-${variant}" || { echo "variante inexistente: ${variant}" >&2; exit 1; }
    mkdir -p $out/share/icons
    cp -r "Bibata-Material-${variant}" $out/share/icons/
    runHook postInstall
  '';
  meta = {
    description = "Material Bibata Cursor, variante ${variant} (escura)";
    homepage = "https://github.com/SakibShahariar/material-bibata-cursor";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
