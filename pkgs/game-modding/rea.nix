{ lib, buildNpmPackage, nodejs_24, makeWrapper, autoPatchelfHook, stdenv }:
buildNpmPackage {
  pname = "rea-agents";
  version = "4.1.0";
  src = ./rea;
  nodejs = nodejs_24;
  npmDepsHash = "sha256-bz4oCvBBThCo35mfA22aXjrm/TAYLFTWn7IV0T4ipRg=";
  dontNpmBuild = true;
  npmInstallFlags = [ "--ignore-scripts" ];
  npmRebuildFlags = [ "--ignore-scripts" ];
  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/rea" "$out/bin"
    cp -r node_modules "$out/lib/rea/"
    # O artefato Windows não pertence ao pacote Linux.
    rm -rf "$out/lib/rea/node_modules/rea-agents/native/windows"
    makeWrapper ${lib.getExe nodejs_24} "$out/bin/rea" \
      --add-flags "$out/lib/rea/node_modules/rea-agents/scripts/rea.mjs"
    ln -s rea "$out/bin/rea-agents"
    runHook postInstall
  '';
  meta = {
    description = "Reverse Engineer Anything: CLI e servidor MCP";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux;
  };
}
