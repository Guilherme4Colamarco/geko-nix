{ pkgs, inputs, ... }: {
  imports = [ ./honey-common.nix ];
  programs.pleamar-wm = {
    enable = true;
    withMarea = false;
    package = import ../../pkgs/pleamar-wm.nix { upstream = inputs.pleamar-wm.packages.${pkgs.stdenv.hostPlatform.system}.pleamar-wm; };
  };
  services.displayManager.defaultSession = "pleamar-wm";
  # A sessão exporta XDG_CURRENT_DESKTOP=pleamar. Sem este mapa o portal não
  # escolhe implementação e o diálogo de arquivo não abre.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
  xdg.portal.config.pleamar = {
    default = [ "gnome" "gtk" ];
    "org.freedesktop.impl.portal.Access" = [ "gtk" ];
    "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };
  home-manager.users.geko.imports = [ ../../home/desktop/pleamar.nix ];
}
