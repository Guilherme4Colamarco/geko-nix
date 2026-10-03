{ config, lib, pkgs, inputs, ... }:
let
  honey = config.programs.honeyShell.package.override { settings = config.programs.honeyShell.settings; };
  ctl = "${honey}/bin/honeyctl";
  common = [
    "bind Super+Return launch ${pkgs.kitty}/bin/kitty"
    "bind Super+E launch ${pkgs.nautilus}/bin/nautilus"
    "bind Super+space launch ${ctl} toggle launcher"
    "bind Super+d launch ${ctl} toggle launcher"
    "bind Super+v launch ${ctl} toggle clipboard"
    "bind Super+comma launch ${ctl} toggle settings"
    "bind Super+l launch ${ctl} lock"
    "bind Super+Shift+e launch ${ctl} toggle power"
    "bind Print launch ${ctl} screenshot region"
    "bind Shift+Print launch ${ctl} screenshot screen"
    "bind Super+q close" "bind Super+f fullscreen" "bind Super+Shift+f toggle_float"
    "bind Super+Ctrl+f toggle_free" "bind Super+Tab overview"
    "bind Super+m minimize" "bind Super+Shift+m restore_last"
    "bind Super+Left focus_previous" "bind Super+Right focus_next"
    "bind Super+Up focus_previous" "bind Super+Down focus_next"
    "bind Super+Shift+Left move_left" "bind Super+Shift+Right move_right"
    "bind Super+Shift+Up move_up" "bind Super+Shift+Down move_down"
    "bind Super+minus narrower" "bind Super+plus wider"
    "bind Super+Ctrl+Up workspace_previous" "bind Super+Ctrl+Down workspace_next"
    "gesture swipe4_left focus_previous" "gesture swipe4_right focus_next"
  ];
  media = { XF86AudioRaiseVolume="volume-up"; XF86AudioLowerVolume="volume-down"; XF86AudioMute="mute"; XF86AudioMicMute="mic-mute"; XF86AudioPlay="play-pause"; XF86AudioPause="play-pause"; XF86AudioNext="next"; XF86AudioPrev="previous"; XF86MonBrightnessUp="brightness-up"; XF86MonBrightnessDown="brightness-down"; };
  scene = pkgs.runCommand "honey-wm-scene" { nativeBuildInputs = [ inputs.pleamar-wm.inputs.pleamar.packages.${pkgs.stdenv.hostPlatform.system}.pleamar ]; } ''
    mkdir -p $out
    cp ${inputs.pleamar-wm}/examples/session.plm $out/session.plm
    cp -r ${inputs.pleamar-wm}/examples/shaders $out/shaders
    substituteInPlace $out/session.plm \
      --replace-fail '#f5f7f5' '#fff0ca' --replace-fail '#9ed6bd' '#ffdb85' \
      --replace-fail '#ef7a66' '#ffad28' --replace-fail '#e8c26a' '#b97912' \
      --replace-fail '#151616' '#24201b'
    # Remove upstream notifications to the optional Marea shell, keeping WM layout rules.
    sed -i "/launch.*--say marea/d" $out/session.plm
    pleamar --check $out/session.plm
  '';
in {
  imports = [ ./honey.nix ];
  programs.honeyShell.enable = true;
  programs.honeyShell.settings.compositor = "pleamar-wm";
  xdg.configFile = {
    "pleamar/keys.conf".text = lib.concatStringsSep "\n" (common
      ++ lib.mapAttrsToList (key: action: "bind ${key} ${lib.optionalString (lib.elem action [ "volume-up" "volume-down" "brightness-up" "brightness-down" ]) "repeat "}locked launch ${ctl} media ${action}") media
      ++ lib.concatMap (i: [ "bind Super+${toString i} workspace ${toString i}" "bind Super+Shift+${toString i} move_to_workspace ${toString i}" ]) (lib.range 1 9)) + "\n";
    "pleamar/session.conf".text = ''
      monitor "" preferred scale 1
      monitor DP-1 1920x1080@165 at 0,0 scale 1.25
      keyboard layout br repeat 25 delay 400
      pointer accel flat speed 0
      touchpad natural on tap on dwt on
      window app=pavucontrol float size 820x560
      window title="Picture in Picture" float
    '';
    "pleamar/autostart".text = "${ctl} session\n";
    "pleamar/wm".source = scene;
  };
}
