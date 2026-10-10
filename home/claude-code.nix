# Home Manager: instala as skills do Claude Code (ECC e pstack) em ~/.claude/skills.
{
  inputs,
  lib,
  osConfig,
  ...
}:
let
  eccSkills = lib.filterAttrs (_: kind: kind == "directory") (
    builtins.readDir "${inputs.ecc}/skills"
  );
in
{
  # Skills de usuario: disponiveis no Claude Code em qualquer projeto.
  # Cada skill e gerenciada separadamente para preservar as demais em ~/.claude/skills.
  home.file =
    lib.mkIf
      (
        osConfig.software.development.enable
        && builtins.elem "claude-code" osConfig.software.development.apps
      )
      (
        (lib.mapAttrs' (name: _: {
          name = ".claude/skills/${name}";
          value.source = "${inputs.ecc}/skills/${name}";
        }) eccSkills)
        // {
          ".claude/skills/arena".source = "${inputs.pstack}/skills/arena";
          ".claude/skills/pstack-pi".source = "${inputs.pstack}/skills/pstack-pi";
        }
      );
}
