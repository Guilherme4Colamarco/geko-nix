# Serviços de sessão que todo desktop usa (energia, chaveiro e polkit).
# Importado por serpantinum.nix e honey-common.nix, para não repetir.
{ ... }: {
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
}
