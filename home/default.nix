# Common Home Manager identity, Fish and GTK settings.
{ osConfig, ... }: {
  imports = [ ./fish.nix ./gtk.nix ];
  home.username = osConfig.geko.usuario.nome;
  home.homeDirectory = "/home/${osConfig.geko.usuario.nome}";
  home.stateVersion = "26.05";
  xdg.enable = true;
}
