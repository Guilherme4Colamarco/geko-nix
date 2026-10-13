# iris (Harman1307/iris, MIT): gera a paleta a partir do wallpaper. O Vitreus chama
# `iris --json-only --dark 1 --glass <imagem>` para o tema "a partir do wallpaper".
# No Arch é o pacote AUR iris-colors; não existe no nixpkgs.
# Versão e hash andam juntos. Hash: nix store prefetch-file --unpack <url do tarball>.
{ lib, python3Packages, fetchFromGitHub }:
python3Packages.buildPythonApplication rec {
  pname = "iris-colors";
  version = "0.1.1";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "Harman1307";
    repo = "iris";
    rev = "v${version}";
    hash = "sha256-E2WyBBpdSwDICSsUZItEcfiuL6ccFEF1IVZkTJj1+gI=";
  };
  build-system = [ python3Packages.hatchling ];
  dependencies = [ python3Packages.pillow python3Packages.numpy ];
  pythonImportsCheck = [ "iris" ];
  meta = {
    description = "Semantic color scheme generator (palette from a wallpaper)";
    homepage = "https://github.com/Harman1307/iris";
    license = lib.licenses.mit;
    mainProgram = "iris";
  };
}
