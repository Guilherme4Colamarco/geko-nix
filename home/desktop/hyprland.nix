{ config, lib, pkgs, inputs, ... }:
let
  honey = config.programs.honeyShell.package.override { settings = config.programs.honeyShell.settings; };
  ctl = "${honey}/bin/honeyctl";
  quote = builtins.toJSON;
  media = { XF86AudioRaiseVolume="volume-up"; XF86AudioLowerVolume="volume-down"; XF86AudioMute="mute"; XF86AudioMicMute="mic-mute"; XF86AudioPlay="play-pause"; XF86AudioPause="play-pause"; XF86AudioNext="next"; XF86AudioPrev="previous"; XF86MonBrightnessUp="brightness-up"; XF86MonBrightnessDown="brightness-down"; };
in {
  imports = [ ./honey.nix ];
  programs.honeyShell.enable = true;
  programs.honeyShell.settings.compositor = "hyprland";
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";
    systemd.enable = false; # honeyctl session owns import and lifetime, once per compositor.
    extraConfig = ''
      hl.config({
        input = { kb_layout = "br", repeat_rate = 25, repeat_delay = 400, accel_profile = "flat", sensitivity = 0, touchpad = { natural_scroll = true } },
        general = { layout = "dwindle", gaps_in = 6, gaps_out = 12, border_size = 2,
          col = { active_border = "rgba(ffdb85ff)", inactive_border = "rgba(594225ff)" } },
        decoration = { rounding = 12, blur = { enabled = true, size = 4, passes = 2 } },
        dwindle = { preserve_split = true },
        -- font_family vale para a barra de erro, hyprctl notify e groupbar.
        misc = { disable_hyprland_logo = true, disable_splash_rendering = true, font_family = "Nunito" },
      })
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
      hl.monitor({ output = "DP-1", mode = "1920x1080@165.003", position = "0x0", scale = 1.25 })
      hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "default" })
      hl.env("XCURSOR_THEME", "Adwaita")
      hl.env("XCURSOR_SIZE", "24")
      local function execbind(keys, command) hl.bind(keys, hl.dsp.exec_cmd(command)) end
      execbind("SUPER + RETURN", ${quote "${pkgs.kitty}/bin/kitty"})
      execbind("SUPER + E", ${quote "${pkgs.nautilus}/bin/nautilus"})
      execbind("SUPER + SPACE", ${quote "${ctl} toggle launcher"})
      execbind("SUPER + D", ${quote "${ctl} toggle launcher"})
      execbind("SUPER + V", ${quote "${ctl} toggle clipboard"})
      execbind("SUPER + COMMA", ${quote "${ctl} toggle settings"})
      execbind("SUPER + L", ${quote "${ctl} lock"})
      execbind("SUPER + SHIFT + E", ${quote "${ctl} toggle power"})
      execbind("SUPER + SHIFT + W", ${quote "${ctl} toggle wallpapers"})
      execbind("SUPER + SHIFT + N", ${quote "${ctl} toggle notifications"})
      execbind("PRINT", ${quote "${ctl} screenshot region"})
      execbind("SHIFT + PRINT", ${quote "${ctl} screenshot screen"})
      hl.bind("SUPER + Q", hl.dsp.window.close())
      hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
      for _,d in ipairs({"left", "right", "up", "down"}) do
        hl.bind("SUPER + " .. string.upper(d), hl.dsp.focus({ direction = d }))
        hl.bind("SUPER + SHIFT + " .. string.upper(d), hl.dsp.window.move({ direction = d }))
      end
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
      hl.bind("SUPER + MINUS", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
      hl.bind("SUPER + PLUS", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
      for i=1,9 do
        hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
        hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
      end
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (key: action: ''
        hl.bind(${quote key}, hl.dsp.exec_cmd(${quote "${ctl} media ${action}"}), { locked = true, repeating = ${if lib.elem action [ "volume-up" "volume-down" "brightness-up" "brightness-down" ] then "true" else "false"} })
      '') media)}
      hl.on("hyprland.start", function() hl.exec_cmd(${quote "${ctl} session"}) end)
    '';
  };
}
