{ config, lib, pkgs, ... }: {
  options.geko.desktop = {
    terminal = lib.mkOption { type = lib.types.package; default = pkgs.kitty; description = "Terminal da sessão."; };
    fileManager = lib.mkOption { type = lib.types.package; default = pkgs.nautilus; description = "Gerenciador de arquivos."; };
    clipboard.enable = lib.mkOption { type = lib.types.bool; default = true; description = "Histórico de clipboard para Serpantinum."; };
  };
  config.environment.systemPackages = [ config.geko.desktop.terminal config.geko.desktop.fileManager ];
}
