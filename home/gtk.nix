# Aparência GTK comum a todos os perfis, gerenciada pelo Home Manager.
# Para trocar o tema, ajuste package e name juntos; colorScheme define claro/escuro.
{ pkgs, ... }: {
  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    iconTheme = {
      package = pkgs.whitesur-icon-theme;
      name = "WhiteSur";
    };
    font = { package = pkgs.nunito; name = "Nunito"; size = 11; };
    # O cursor vem de home.pointerCursor (home/default.nix).
    # Apps GTK 4/libadwaita usam a preferência de cor, sem importar CSS de GTK 3.
    gtk4.theme = null;
  };
}
