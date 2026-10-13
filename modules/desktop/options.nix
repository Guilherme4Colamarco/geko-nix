# Opções geko.desktop.* (terminal, gerenciador de arquivos, histórico de clipboard, cursor)
# que o Serpantinum consome; terminal, gerenciador e cursor também entram no sistema.
# O cursor é definido aqui uma vez e vale para todos os perfis (GTK, Hyprland, niri, Mango, pleamar, COSMIC).
{ config, lib, pkgs, ... }: {
  options.geko.desktop = {
    terminal = lib.mkOption { type = lib.types.package; default = pkgs.kitty; description = "Terminal da sessão."; };
    fileManager = lib.mkOption { type = lib.types.package; default = pkgs.nautilus; description = "Gerenciador de arquivos."; };
    clipboard.enable = lib.mkOption { type = lib.types.bool; default = true; description = "Histórico de clipboard para Serpantinum."; };
    cursor = {
      package = lib.mkOption { type = lib.types.package; default = pkgs.callPackage ../../pkgs/bibata-material-cursor { }; description = "Pacote do tema de cursor."; };
      name = lib.mkOption { type = lib.types.str; default = "Bibata-Material-Peach"; description = "Nome do tema dentro do pacote (pasta em share/icons). Troque junto com o package."; };
      size = lib.mkOption { type = lib.types.int; default = 35; description = "Tamanho do cursor em px."; };
    };
  };
  config = {
    environment.systemPackages = [ config.geko.desktop.terminal config.geko.desktop.fileManager config.geko.desktop.cursor.package ];
    # Lido por qualquer compositor/toolkit (inclui COSMIC e Xwayland) ao iniciar a sessão.
    environment.sessionVariables = {
      XCURSOR_THEME = config.geko.desktop.cursor.name;
      XCURSOR_SIZE = toString config.geko.desktop.cursor.size;
    };
  };
}
