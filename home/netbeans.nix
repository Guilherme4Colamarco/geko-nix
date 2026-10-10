# NetBeans em XWayland (Hyprland) abre com janela em branco; desligar o XRender do Java2D corrige.
# O tema Dark Nimbus renderiza cinza com isso, então forçamos o FlatLaf Dark.
{ lib, osConfig, ... }:
let
  cfg = osConfig.software.development;
in
{
  config = lib.mkIf (cfg.enable && builtins.elem "netbeans" cfg.apps) {
    home.file.".netbeans/31/etc/netbeans.conf".text = ''
      netbeans_default_options="$netbeans_default_options -J-Dsun.java2d.xrender=false --laf com.formdev.flatlaf.FlatDarkLaf"
    '';
  };
}
