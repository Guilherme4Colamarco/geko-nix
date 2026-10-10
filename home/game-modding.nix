# MCPs e skills globais para o Codex, com versões e dependências geridas pelo Nix.
{ pkgs, lib, osConfig, ... }:
let
  tools = pkgs.callPackage ../pkgs/game-modding { };
  skillNames = [
    "mod-any-game" "game-recon" "reverse-engineering" "mashup-mods"
    "asset-pipeline" "fal-assets" "game-automation" "showcase-video"
    "publish-mod" "share-field-notes"
  ];
  enabled = osConfig.software.development.enable
    && builtins.elem "codex" osConfig.software.development.apps;
in
{
  config = lib.mkIf enabled {
    home.packages = [
      tools.universal-modder tools.rea tools.ghidra-mcp tools.ida-mcp
    ];
    home.file = lib.listToAttrs (map (name: {
      name = ".agents/skills/${name}";
      value.source = "${tools.sources.universal-modder}/skills/${name}";
    }) skillNames) // {
      ".agents/skills/reverse-engineer-anything".source =
        "${tools.rea}/lib/rea/node_modules/rea-agents/skills/reverse-engineer-anything";
    };
    programs.codex = {
      enable = true;
      # A categoria development já instala o executável.
      package = null;
      # Preserva os ajustes do app, plugins e os MCPs preexistentes.
      mutableSettings = true;
      settings.mcp_servers = {
        rea = {
          command = lib.getExe tools.rea;
          args = [ "mcp" ];
          startup_timeout_sec = 30;
          tool_timeout_sec = 120;
          enabled = true;
        };
        ghidra = {
          command = lib.getExe tools.ghidra-mcp;
          args = [ "--transport" "stdio" ];
          env.GHIDRA_MCP_URL = "http://127.0.0.1:8089";
          startup_timeout_sec = 30;
          tool_timeout_sec = 120;
          enabled = true;
        };
        ida = {
          command = lib.getExe tools.ida-mcp;
          args = [ "stdio" "--agent=codex" ];
          startup_timeout_sec = 30;
          tool_timeout_sec = 120;
          enabled = true;
        };
        fal = {
          url = "https://mcp.fal.ai/mcp";
          bearer_token_env_var = "FAL_KEY";
          enabled = false;
        };
      };
    };
  };
}
