# Docker: motor, limpeza semanal, grupo docker para o usuário e utilitários.
# Nenhum container sobe sozinho.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf (config.software.development.enable && config.software.development.docker.enable)
      {
        # --- Motor do Docker ---
        virtualisation.docker = {
          enable = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
            flags = [ "--all" ];
          };
          daemon.settings = {
            "log-driver" = "json-file";
            "log-opts" = {
              "max-size" = "10m";
              "max-file" = "3";
            };
            "live-restore" = true;
          };
        };

        # Usar docker sem sudo (o grupo docker equivale a administrador)
        users.users.${config.geko.usuario.nome}.extraGroups = [ "docker" ];

        # Utilitários do Docker
        home-manager.users.${config.geko.usuario.nome}.home.packages = with pkgs; [
          docker-compose
          lazydocker
          ctop
        ];
      };
}
