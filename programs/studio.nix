{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.software.studio;
  selected = lib.unique cfg.apps;
  catalog = {
    krita = [ pkgs.krita ];
    inkscape = [ pkgs.inkscape ];
    kdenlive = [ pkgs.kdePackages.kdenlive ];
    audacity = [ pkgs.audacity ];
    blender = [ pkgs.blender ];
    gimp = [ pkgs.gimp ];
    darktable = [ pkgs.darktable ];
    shotcut = [ pkgs.shotcut ];
    ardour = [ pkgs.ardour ];
    obs-studio = [ ];
  };
in
{
  options.software.studio = import ./category.nix { inherit lib; } {
    name = "studio";
    inherit catalog;
    defaults = [
      "krita"
      "inkscape"
      "kdenlive"
      "obs-studio"
      "audacity"
      "blender"
    ];
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${config.geko.usuario.nome} = {
      home.packages = lib.unique (
        lib.concatMap (name: catalog.${name}) selected
        ++ cfg.extraPackages
        ++ lib.optional (lib.any (n: builtins.elem n selected) [
          "kdenlive"
          "obs-studio"
          "audacity"
          "blender"
          "shotcut"
          "ardour"
        ]) pkgs.ffmpeg
      );
      programs.obs-studio = lib.mkIf (builtins.elem "obs-studio" selected) {
        enable = true;
        plugins = [ pkgs.obs-studio-plugins.obs-pipewire-audio-capture ];
      };
    };
  };
}
