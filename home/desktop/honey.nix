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
    package = lib.mkOption { type = lib.types.package; default = pkgs.callPackage ../../pkgs/honey-shell { pleamar = runtime; settings = cfg.settings; }; description = "Honey package supporting the settings override."; };
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
    home.packages = [ honey pkgs.kitty pkgs.nautilus pkgs.adwaita-icon-theme pkgs.playerctl ];
    home.pointerCursor = { package = pkgs.adwaita-icon-theme; name = "Adwaita"; size = 24; gtk.enable = true; };
    xdg.configFile."pleamar/shells/honey".source = "${honey}/share/honey";
    xdg.configFile."swaylock/config".text = ''
      color=24201b
      indicator-radius=70
      indicator-thickness=8
      inside-color=372b20
      ring-color=b97912
      key-hl-color=ffdb85
      text-color=fff0ca
      inside-wrong-color=6b251e
      ring-wrong-color=ffad28
      show-failed-attempts
    '';
    xdg.configFile."mako/config".text = ''
      background-color=#372b20ee
      text-color=#fff0ca
      border-color=#b97912
      border-size=2
      border-radius=12
      margin=90,16,16
      default-timeout=6000
      max-visible=5
      [mode=locked]
      invisible=1
    '';
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
      honey-wallpaper = service "Honey wallpaper" "${pkgs.swaybg}/bin/swaybg -i ${honey}/share/honey/fixtures/wallpaper.png -m fill";
      honey-notifications = service "Honey notifications (Mako)" "${pkgs.mako}/bin/mako";
      honey-polkit = service "Honey policy authentication" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      # No inactivity timeout. Only ensure a lock before an externally requested sleep.
      honey-sleep-lock = service "Lock before sleep, without idle timers" "${pkgs.swayidle}/bin/swayidle -w before-sleep '${honey}/bin/honeyctl lock'";
    };
  };
}
