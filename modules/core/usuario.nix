# Opção com o nome do usuário principal da máquina (padrão: geko).
# Para trocar de usuário, defina geko.usuario.nome em configuration.nix.
{ lib, ... }: {
  options.geko.usuario.nome = lib.mkOption {
    type = lib.types.str;
    default = "geko";
    description = "Nome do usuário principal (conta, grupos e Home Manager).";
  };
}
