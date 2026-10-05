{ config, lib, pkgs, inputs, ... }:
let
  honey = config.programs.honeyShell.package.override { settings = config.programs.honeyShell.settings; };
  ctl = "${honey}/bin/honeyctl";
  niri = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.niri;
  outputPolicy = pkgs.writeText "honey-niri-outputs.py" ''
    import json, subprocess, time
    niri = "${niri}/bin/niri"
    seen = set()
    while True:
        try:
            outputs = json.loads(subprocess.check_output([niri,"msg","-j","outputs"],timeout=3))
        except (subprocess.SubprocessError, OSError, ValueError):
            # IPC briefly disappears during logout or compositor restart.
            time.sleep(1)
            continue
        present = set(outputs)
        seen.intersection_update(present)
        for name, output in outputs.items():
            logical = output.get("logical")
            if name == "DP-1" or not logical: continue
            if name not in seen:
                subprocess.run([niri,"msg","output",name,"mode","auto"],check=True,timeout=3)
                seen.add(name)
            if logical["scale"] != 1:
                subprocess.run([niri,"msg","output",name,"scale","1"],check=True,timeout=3)
        time.sleep(5)
  '';
  spawn = keys: args: "${keys} { spawn " + lib.concatMapStringsSep " " builtins.toJSON args + "; }";
  media = { XF86AudioRaiseVolume="volume-up"; XF86AudioLowerVolume="volume-down"; XF86AudioMute="mute"; XF86AudioMicMute="mic-mute"; XF86AudioPlay="play-pause"; XF86AudioPause="play-pause"; XF86AudioNext="next"; XF86AudioPrev="previous"; XF86MonBrightnessUp="brightness-up"; XF86MonBrightnessDown="brightness-down"; };
in {
  imports = [ ./honey.nix ];
  programs.honeyShell.enable = true;
  programs.honeyShell.settings.compositor = "niri";
  # The pinned Pleamar capture client allocates ARGB even when Niri requests
  # XRGB, which disconnects the Wayland client. Use the documented fallback.
  systemd.user.services.honey-shell.Service.Environment = [ "PLEAMAR_NO_LENS=1" ];
  # Niri has no catch-all output rule. Enforce the declarative default on
  # discovered outputs, including hotplug, without writing configuration files.
  systemd.user.services.honey-niri-outputs = {
    Unit = { Description = "Honey Niri output defaults"; PartOf = [ "honey-session.target" ]; After = [ "graphical-session.target" ]; };
    Service = { ExecStart = "${pkgs.python3}/bin/python3 ${outputPolicy}"; Restart = "on-failure"; RestartSec = 2; };
    Install.WantedBy = [ "honey-session.target" ];
  };
  xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard { xkb { layout "br"; }; repeat-delay 400; repeat-rate 25; }
      touchpad { tap; natural-scroll; dwt; }
      mouse { accel-profile "flat"; accel-speed 0.0; }
    }
    // 165 sozinho não casa com o modo do AOC (165.003) e o Niri fica no preferido de 60 Hz.
    output "DP-1" { mode "1920x1080@165.003"; scale 1.25; position x=0 y=0; }
    layout {
      gaps 12
      preset-column-widths { proportion 0.33333; proportion 0.5; proportion 0.66667; }
      default-column-width { proportion 0.5; }
      focus-ring { width 2; active-color "#ffdb85"; inactive-color "#594225"; }
      border { off; }
      shadow { on; color "#00000044"; softness 24; spread 2; offset x=0 y=6; }
    }
    cursor { xcursor-theme "Adwaita"; xcursor-size 35; }
    // O niri não tem opção de fonte: overlay de atalhos, UI de captura e avisos usam
    // pango "sans 14px", que segue fonts.fontconfig.defaultFonts (honey-common.nix).
    hotkey-overlay { skip-at-startup; }
    prefer-no-csd
    screenshot-path "~/Imagens/Capturas/%Y-%m-%d_%H-%M-%S.png"
    spawn-at-startup "${ctl}" "session"
    window-rule { geometry-corner-radius 12; clip-to-geometry true; }
    window-rule {
      opacity 0.92
      background-effect {
        blur true
      }
    }
    window-rule { match app-id="^pavucontrol$"; open-floating true; }
    window-rule { match title="^Picture in Picture$"; open-floating true; }
    binds {
      ${spawn "Mod+Return" [ "${pkgs.kitty}/bin/kitty" ]}
      ${spawn "Mod+T" [ "${pkgs.kitty}/bin/kitty" ]}
      ${spawn "Mod+E" [ "${pkgs.nautilus}/bin/nautilus" ]}
      ${spawn "Mod+Space" [ ctl "toggle" "launcher" ]}
      ${spawn "Mod+D" [ ctl "toggle" "launcher" ]}
      ${spawn "Mod+V" [ ctl "toggle" "clipboard" ]}
      ${spawn "Mod+Comma" [ ctl "toggle" "settings" ]}
      ${spawn "Mod+Alt+L" [ ctl "lock" ]}
      ${spawn "Mod+Shift+E" [ ctl "toggle" "power" ]}
      ${spawn "Mod+W" [ ctl "toggle" "wallpapers" ]}
      ${spawn "Mod+Shift+W" [ ctl "toggle" "wallpapers" ]}
      ${spawn "Mod+Shift+N" [ ctl "toggle" "notifications" ]}
      Print { screenshot; }
      Shift+Print { screenshot-screen; }
      Ctrl+Print { screenshot-screen; }
      Alt+Print { screenshot-window; }
      Mod+Shift+Slash { show-hotkey-overlay; }
      Mod+Q repeat=false { close-window; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
      Mod+Alt+V { toggle-window-floating; }
      Mod+Shift+V { switch-focus-between-floating-and-tiling; }
      Mod+O repeat=false { toggle-overview; }
      Mod+Tab { toggle-overview; }
      Mod+Left { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up { focus-window-up; }
      Mod+Down { focus-window-down; }
      Mod+H { focus-column-left; }
      Mod+J { focus-window-down; }
      Mod+K { focus-window-up; }
      Mod+L { focus-column-right; }
      Mod+Ctrl+Left { move-column-left; }
      Mod+Ctrl+Right { move-column-right; }
      Mod+Ctrl+Up { move-window-up; }
      Mod+Ctrl+Down { move-window-down; }
      Mod+Ctrl+H { move-column-left; }
      Mod+Ctrl+J { move-window-down; }
      Mod+Ctrl+K { move-window-up; }
      Mod+Ctrl+L { move-column-right; }
      // Alternativas antigas; as setas com Shift do padrão focariam monitores.
      Mod+Shift+Left { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up { move-window-up; }
      Mod+Shift+Down { move-window-down; }
      Mod+Home { focus-column-first; }
      Mod+End { focus-column-last; }
      Mod+Ctrl+Home { move-column-to-first; }
      Mod+Ctrl+End { move-column-to-last; }
      Mod+Shift+H { focus-monitor-left; }
      Mod+Shift+J { focus-monitor-down; }
      Mod+Shift+K { focus-monitor-up; }
      Mod+Shift+L { focus-monitor-right; }
      Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
      Mod+Shift+Ctrl+Down { move-column-to-monitor-down; }
      Mod+Shift+Ctrl+Up { move-column-to-monitor-up; }
      Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
      Mod+Page_Down { focus-workspace-down; }
      Mod+Page_Up { focus-workspace-up; }
      Mod+U { focus-workspace-down; }
      Mod+I { focus-workspace-up; }
      Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
      Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
      Mod+Ctrl+U { move-column-to-workspace-down; }
      Mod+Ctrl+I { move-column-to-workspace-up; }
      Mod+Shift+Page_Down { move-workspace-down; }
      Mod+Shift+Page_Up { move-workspace-up; }
      Mod+Shift+U { move-workspace-down; }
      Mod+Shift+I { move-workspace-up; }
      Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
      Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
      Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
      Mod+WheelScrollRight { focus-column-right; }
      Mod+WheelScrollLeft { focus-column-left; }
      Mod+Ctrl+WheelScrollRight { move-column-right; }
      Mod+Ctrl+WheelScrollLeft { move-column-left; }
      Mod+Shift+WheelScrollDown { focus-column-right; }
      Mod+Shift+WheelScrollUp { focus-column-left; }
      Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
      Mod+Ctrl+Shift+WheelScrollUp { move-column-left; }
      Mod+BracketLeft { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }
      Mod+Alt+Comma { consume-window-into-column; }
      Mod+Period { expel-window-from-column; }
      Mod+R { switch-preset-column-width; }
      Mod+Shift+R { switch-preset-column-width-back; }
      Mod+Ctrl+Shift+R { switch-preset-window-height; }
      Mod+Ctrl+R { reset-window-height; }
      Mod+M { maximize-window-to-edges; }
      Mod+Ctrl+F { expand-column-to-available-width; }
      Mod+C { center-column; }
      Mod+Ctrl+C { center-visible-columns; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Plus { set-column-width "+10%"; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }
      Mod+Ctrl+W { toggle-column-tabbed-display; }
      Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
      Ctrl+Alt+Delete { quit; }
      Mod+Shift+P { power-off-monitors; }
      ${lib.concatMapStringsSep "\n" (i: ''
        Mod+${toString i} { focus-workspace ${toString i}; }
        Mod+Shift+${toString i} { move-window-to-workspace ${toString i}; }
        Mod+Ctrl+${toString i} { move-column-to-workspace ${toString i}; }
      '') (lib.range 1 9)}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: action: spawn "${key} allow-when-locked=true" [ ctl "media" action ]) media)}
    }
  '';
}
