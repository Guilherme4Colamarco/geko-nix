# Docker: motor, limpeza semanal, grupo docker para o usuário e utilitários.
# Nenhum container sobe sozinho.
{ pkgs, ... }:

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
  users.users.geko.extraGroups = [ "docker" ];

  # Utilitários do Docker
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
    ctop
  ];
}
