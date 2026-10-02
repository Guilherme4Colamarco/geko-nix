{ config, lib, pkgs, desktopPkgs, inputs, ... }: let
  cfg = config.geko.desktop;
  command = value: builtins.toJSON value;
in {
  programs.serpantinum.enable = true;
  programs.hyprland = {
    enable = true;
    package = desktopPkgs.hyprland;
    portalPackage = desktopPkgs.xdg-desktop-portal-hyprland;
  };
  services.displayManager.defaultSession = "hyprland";
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  environment.systemPackages = [ pkgs.adwaita-icon-theme pkgs.playerctl ] ++ lib.optionals cfg.clipboard.enable [ pkgs.wl-clipboard pkgs.cliphist ];
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];
  home-manager.users.geko = {
    imports = [ inputs.serpantinum.homeManagerModules.default ];
    programs.serpantinum = {
      enable = true;
      systemd.target = "hyprland-session.target";
      settings.general.language = "pt";
    };
    systemd.user.targets.hyprland-session = {
      Unit = { Description = "Sessão Hyprland do geko"; BindsTo = [ "graphical-session.target" ]; Wants = [ "graphical-session-pre.target" ]; After = [ "graphical-session-pre.target" ]; };
    };
    xdg.configFile."hypr/hyprland.lua".text = builtins.readFile ../../config/hyprland/serpantinum.lua + ''
      execbind("SUPER + RETURN", ${command (lib.getExe cfg.terminal)})
      execbind("SUPER + E", ${command (lib.getExe cfg.fileManager)})
      hl.on("hyprland.start", function()
        hl.exec_cmd("${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
        hl.exec_cmd("${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; ${pkgs.systemd}/bin/systemctl --user stop hyprland-session.target; ${pkgs.systemd}/bin/systemctl --user start hyprland-session.target")
        ${lib.optionalString cfg.clipboard.enable ''
          hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store")
          hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store")
        ''}
      end)
    '';
  };
}
