{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.software.office;
  selected = lib.unique cfg.apps;
  catalog = {
    libreoffice = [ pkgs.libreoffice ];
    evince = [ pkgs.evince ];
    thunderbird = [ pkgs.thunderbird ];
    onlyoffice = [ pkgs.onlyoffice-desktopeditors ];
    obsidian = [ pkgs.obsidian ];
    zotero = [ pkgs.zotero ];
  };
in
{
  options.software.office = import ./category.nix { inherit lib; } {
    name = "office";
    inherit catalog;
    defaults = [
      "libreoffice"
      "evince"
      "thunderbird"
    ];
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.geko.usuario.nome} = {
      home.packages = lib.unique (lib.concatMap (name: catalog.${name}) selected ++ cfg.extraPackages);
    };
  };
}
