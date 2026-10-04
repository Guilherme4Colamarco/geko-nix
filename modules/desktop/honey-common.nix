{ pkgs, ... }:
let
  # Fredoka só existe dentro do google-fonts; o override copia apenas
  # Fredoka[wdth,wght].ttf (build local, hydraPlatforms = [ ]).
  fredoka = pkgs.google-fonts.override { fonts = [ "Fredoka" ]; };
in {
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  security.pam.services.swaylock = {};
  hardware.i2c.enable = true;
  users.users.geko.extraGroups = [ "i2c" ];
  environment.systemPackages = [ pkgs.ddcutil pkgs.adwaita-icon-theme ];

  # Par tipográfico dos perfis Honey: Nunito no texto de UI, Fredoka nos títulos.
  # Use pkgs.nunito, não "Nunito" no google-fonts: aquele também instala um
  # Nunito-Regular.ttf de teste e duas faces 400 deixam o matching ambíguo.
  fonts.packages = [ pkgs.nunito fredoka ];
  # gtk.font do home-manager grava org.gnome.desktop.interface no dconf; sem o serviço
  # a ativação do home-manager inteira falha (visto na VM do perfil pleamar).
  programs.dconf.enable = true;
  # sans-serif do sistema (GTK, Qt, niri, swaylock). Monospace e serif
  # continuam nos defaults do NixOS (DejaVu), então terminais não mudam.
  fonts.fontconfig.defaultFonts.sansSerif = [ "Nunito" "DejaVu Sans" ];
}
