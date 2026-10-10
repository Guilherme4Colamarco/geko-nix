# Base dos perfis Honey (pleamar, niri, hyprland): fontes Nunito/Fredoka, PAM do swaylock,
# dconf e ícones. Importada por cada perfil em desktops/.
{ pkgs, ... }:
let
  # Fredoka só existe dentro do google-fonts; o override copia apenas
  # Fredoka[wdth,wght].ttf (build local, hydraPlatforms = [ ]).
  fredoka = pkgs.google-fonts.override { fonts = [ "Fredoka" ]; };
in {
  imports = [ ./_comum.nix ];
  security.pam.services.swaylock = {};
  environment.systemPackages = [ pkgs.adwaita-icon-theme ];

  # Par tipográfico dos perfis Honey: Nunito no texto de UI, Fredoka nos títulos.
  # Use pkgs.nunito, não "Nunito" no google-fonts: aquele também instala um
  # Nunito-Regular.ttf de teste e duas faces 400 deixam o matching ambíguo.
  fonts.packages = [ pkgs.nunito fredoka ];
  # sans-serif do sistema (GTK, Qt, niri, swaylock). Monospace e serif
  # continuam nos defaults do NixOS (DejaVu), então terminais não mudam.
  fonts.fontconfig.defaultFonts.sansSerif = [ "Nunito" "DejaVu Sans" ];
}
