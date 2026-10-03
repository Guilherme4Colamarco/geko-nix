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
    output "DP-1" { mode "1920x1080@165"; scale 1.25; position x=0 y=0; }
    layout {
      gaps 12
      preset-column-widths { proportion 0.33333; proportion 0.5; proportion 0.66667; }
      default-column-width { proportion 0.5; }
      focus-ring { width 2; active-color "#ffdb85"; inactive-color "#594225"; }
      border { off; }
      shadow { on; color "#00000044"; softness 24; spread 2; offset x=0 y=6; }
    }
    cursor { xcursor-theme "Adwaita"; xcursor-size 24; }
    hotkey-overlay { skip-at-startup; }
    prefer-no-csd
    screenshot-path "~/Imagens/Capturas/%Y-%m-%d_%H-%M-%S.png"
    spawn-at-startup "${ctl}" "session"
    window-rule { geometry-corner-radius 12; clip-to-geometry true; }
    window-rule {
      opacity 0.92
      background-effect { blur true; }
    }
    window-rule { match app-id="^pavucontrol$"; open-floating true; }
    window-rule { match title="^Picture in Picture$"; open-floating true; }
    binds {
      ${spawn "Mod+Return" [ "${pkgs.kitty}/bin/kitty" ]}
      ${spawn "Mod+E" [ "${pkgs.nautilus}/bin/nautilus" ]}
      ${spawn "Mod+Space" [ ctl "toggle" "launcher" ]}
      ${spawn "Mod+D" [ ctl "toggle" "launcher" ]}
      ${spawn "Mod+V" [ ctl "toggle" "clipboard" ]}
      ${spawn "Mod+Comma" [ ctl "toggle" "settings" ]}
      ${spawn "Mod+L" [ ctl "lock" ]}
      ${spawn "Mod+Shift+E" [ ctl "toggle" "power" ]}
      Print { screenshot; }
      Shift+Print { screenshot-screen; }
      Mod+Q { close-window; }
      Mod+F { fullscreen-window; }
      Mod+Shift+F { toggle-window-floating; }
      Mod+Tab { toggle-overview; }
      Mod+Left { focus-column-left; }
      Mod+Right { focus-column-right; }
      Mod+Up { focus-window-up; }
      Mod+Down { focus-window-down; }
      Mod+Shift+Left { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up { move-window-up; }
      Mod+Shift+Down { move-window-down; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Plus { set-column-width "+10%"; }
      Mod+Ctrl+Up { focus-workspace-up; }
      Mod+Ctrl+Down { focus-workspace-down; }
      ${lib.concatMapStringsSep "\n" (i: ''
        Mod+${toString i} { focus-workspace ${toString i}; }
        Mod+Shift+${toString i} { move-window-to-workspace ${toString i}; }
      '') (lib.range 1 9)}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: action: spawn "${key} allow-when-locked=true" [ ctl "media" action ]) media)}
    }
  '';
}
