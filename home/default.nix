# Common Home Manager identity, Fish and GTK settings.
{ osConfig, ... }: let cursor = osConfig.geko.desktop.cursor; in {
  imports = [ ./fish.nix ./gtk.nix ];
  home.username = osConfig.geko.usuario.nome;
  home.homeDirectory = "/home/${osConfig.geko.usuario.nome}";
  home.stateVersion = "26.05";
  xdg.enable = true;
  # Cursor único para todos os perfis (opção geko.desktop.cursor, em modules/desktop/options.nix).
  home.pointerCursor = {
    inherit (cursor) package name size;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
