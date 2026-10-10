# Ghidra + servidor GhidraMCP headless (127.0.0.1:8089), iniciado junto com a sessão do usuário.
# O MCP "ghidra" (bridge em pkgs/game-modding) conversa com este servidor.
{ pkgs, ... }:
let
  plugin = pkgs.fetchzip {
    url = "https://github.com/bethington/ghidra-mcp/releases/download/v7.0.0-rc.1/GhidraMCP-7.0.0-rc.1.zip";
    hash = "sha256-FyGUi8kyqWKF/pgKhXznKaSYE3agWxboKz5vcIBtL+c=";
  };
  ghidraHome = "${pkgs.ghidra}/lib/ghidra";
  # O jar do GhidraMCP não embute o Ghidra: os jars dele entram no classpath.
  start = pkgs.writeShellScript "ghidra-mcp-headless" ''
    CP=$(${pkgs.findutils}/bin/find \
      ${ghidraHome}/Ghidra/Framework ${ghidraHome}/Ghidra/Features \
      ${ghidraHome}/Ghidra/Processors ${ghidraHome}/Ghidra/Debug \
      -name '*.jar' | ${pkgs.coreutils}/bin/tr '\n' ':')
    exec ${pkgs.jdk21}/bin/java -Dghidra.install.dir=${ghidraHome} \
      -cp "${plugin}/GhidraMCP/lib/GhidraMCP-7.0.0.jar:$CP" \
      com.xebyte.headless.GhidraMCPHeadlessServer --port 8089
  '';
in
{
  environment.systemPackages = [ pkgs.ghidra ];

  systemd.user.services.ghidra-mcp = {
    description = "Servidor GhidraMCP headless";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${start}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
