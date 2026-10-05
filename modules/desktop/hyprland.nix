{ config, pkgs, desktopPkgs, ... }: {
  imports = [ ./honey-common.nix ];
  programs.hyprland = {
    enable = true;
    package = desktopPkgs.hyprland;
    portalPackage = desktopPkgs.xdg-desktop-portal-hyprland;
  };
  services.displayManager.defaultSession = "hyprland";
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];
  home-manager.users.${config.geko.usuario.nome}.imports = [ ../../home/desktop/hyprland.nix ];
}
