# Serviços de sessão que todo desktop usa (energia, chaveiro e polkit).
# Importado por serpantinum.nix e _comum-honey.nix, para não repetir.
{ pkgs, ... }: {
  # Necessário para as preferências GTK declaradas pelo Home Manager.
  programs.dconf.enable = true;
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  environment.systemPackages = [ pkgs.gnome-keyring ];
}
