# Home Manager: módulo programs.honeyShell (shell Honey), serviços de usuário,
# cursor e swaylock. Usado pelos perfis pleamar, niri e hyprland.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.programs.honeyShell;
  runtime = inputs.pleamar-wm.inputs.pleamar.packages.${pkgs.stdenv.hostPlatform.system}.pleamar;
  honey = cfg.package.override { settings = cfg.settings; };
  service = description: command: {
    Unit = { Description = description; PartOf = [ "honey-session.target" ]; After = [ "graphical-session.target" ]; };
    Service = { ExecStart = command; Restart = "on-failure"; RestartSec = 2; KillMode = "control-group"; UMask = "0077"; };
    Install.WantedBy = [ "honey-session.target" ];
  };
in {
  options.programs.honeyShell = {
    enable = lib.mkEnableOption "Honey desktop shell";
    package = lib.mkOption { type = lib.types.package; default = pkgs.callPackage ../pkgs/honey-shell { pleamar = runtime; settings = cfg.settings; }; description = "Honey package supporting the settings override."; };
    settings = lib.mkOption { type = lib.types.attrsOf lib.types.anything; default = {}; description = "Declarative Honey settings, merged with the Honey preset."; };
  };
  config = lib.mkIf cfg.enable {
    programs.honeyShell.settings = {
      mode = lib.mkDefault "live";
      layout.reserve = lib.mkDefault 80;
      files.roots = lib.mkDefault [ "~/Documentos" "~/Downloads" "~/Imagens" ];
      clipboard.history = lib.mkDefault "history.json";
      power.lock_command = lib.mkDefault [ "honeyctl" "lock" ];
    };
    home.packages = [ honey pkgs.kitty pkgs.nautilus pkgs.playerctl ];
    home.pointerCursor = { package = pkgs.adwaita-icon-theme; name = "Adwaita"; size = 35; gtk.enable = true; };
    # A aparência GTK comum fica em home/gtk.nix.
    # Hoje settings.ini é um arquivo solto e somente leitura; force evita que um backup
    # *.before-geko-nix antigo bloqueie a ativação do home-manager.
    xdg.configFile."gtk-3.0/settings.ini".force = true;
    xdg.configFile."gtk-4.0/settings.ini".force = true;
    xdg.configFile."pleamar/shells/honey".source = "${honey}/share/honey";
    xdg.configFile."swaylock/config".text = ''
      color=24201b
      indicator-radius=70
      indicator-thickness=8
      inside-color=372b20
      ring-color=b97912
      key-hl-color=ffdb85
      text-color=fff0ca
      font=Nunito
      inside-wrong-color=6b251e
      ring-wrong-color=ffad28
      show-failed-attempts
    '';
    # Notifications are drawn by the Honey shell itself (pleamar is the
    # org.freedesktop.Notifications server); mako is no longer started.
    systemd.user.targets.honey-session.Unit = {
      Description = "Honey desktop session";
      BindsTo = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    systemd.user.services = {
      honey-reserve = lib.recursiveUpdate (service "Honey top reserve" "${runtime}/bin/pleamar --scene ${honey}/share/honey/src/reserve.plm --no-hud --stall 0") {
        Service.Environment = [ "PLEAMAR_NO_LENS=1" ];
      };
      honey-shell = lib.recursiveUpdate (service "Honey shell" "${honey}/bin/honey-shell") {
        Unit.After = [ "graphical-session.target" "honey-reserve.service" ];
      };
      honey-wallpaper = service "Honey wallpaper" "${honey}/bin/honeyctl wallpaper-run";
      honey-polkit = service "Honey policy authentication" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      # No inactivity timeout. Only ensure a lock before an externally requested sleep.
      honey-sleep-lock = service "Lock before sleep, without idle timers" "${pkgs.swayidle}/bin/swayidle -w before-sleep '${honey}/bin/honeyctl lock'";
    };
  };
}
