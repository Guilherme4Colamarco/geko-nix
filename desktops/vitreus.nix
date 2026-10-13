# Perfil Vitreus (alvo `vitreus`): Hyprland + shell Vitreus (pleamar). Base comum em _vitreus.nix.
# Parte 1 = sistema (NixOS); parte 2 = usuário (Home Manager: hyprland.lua e atalhos).
#
# O hyprland.lua é gerado aqui e carrega, no fim, o hypr_vitreus.lua do upstream (SUPER+Space
# launcher, SUPER+SHIFT+Space Settings, SUPER+L lock, SUPER+B wallpapers, SUPER+D Desk,
# SUPER+TAB overview, brilho) e os vitreus_*.lua que o Settings grava em ~/.config/hypr.
{ config, lib, pkgs, desktopPkgs, inputs, ... }: let
  cfg = config.geko.desktop;
  quote = builtins.toJSON;
  pleamar = "${inputs.pleamar-vitreus.packages.${pkgs.stdenv.hostPlatform.system}.pleamar}/bin/pleamar";
  say = scene: line: "${pleamar} --say ${scene} ${lib.escapeShellArg line}";
in {
  imports = [ ./_vitreus.nix ];
  programs.hyprland = {
    enable = true;
    package = desktopPkgs.hyprland;
    portalPackage = desktopPkgs.xdg-desktop-portal-hyprland;
  };
  services.displayManager.defaultSession = "hyprland";
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.hyprland.default = [ "hyprland" "gtk" ];

  # ---------- Parte 2: usuário (Home Manager) ----------
  home-manager.users.${config.geko.usuario.nome} = { config, ... }:
  let
    vitreusSrc = "${config.xdg.configHome}/pleamar/shells/vitreus";
  in {
    # Modo Noturno: no Hyprland o install.sh não segue sem o hyprsunset.
    home.packages = [ pkgs.hyprsunset ];

    systemd.user.targets.hyprland-session = {
      Unit = { Description = "Sessão Hyprland (Vitreus)"; BindsTo = [ "graphical-session.target" ]; Wants = [ "graphical-session-pre.target" ]; After = [ "graphical-session-pre.target" ]; };
    };

    # A cópia gravável que a ativação faz (_vitreus.nix), para o require achar o arquivo atual.
    xdg.configFile."hypr/hypr_vitreus.lua".source = config.lib.file.mkOutOfStoreSymlink "${vitreusSrc}/hypr_vitreus.lua";

    xdg.configFile."hypr/hyprland.lua".text = ''
      -- Gerado por desktops/vitreus.nix. O que o Settings do Vitreus muda vai para os vitreus_*.lua.
      hl.config({
        input = { kb_layout = "br", repeat_rate = 25, repeat_delay = 400, accel_profile = "flat", sensitivity = 0, touchpad = { natural_scroll = true } },
        general = { layout = "dwindle", gaps_in = 6, gaps_out = 12, border_size = 2 },
        decoration = { rounding = 14, blur = { enabled = true, size = 4, passes = 2 } },
        dwindle = { preserve_split = true },
        misc = { disable_hyprland_logo = true, disable_splash_rendering = true, font_family = "Space Grotesk" },
      })
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
      hl.monitor({ output = "DP-1", mode = "1920x1080@165.003", position = "0x0", scale = 1.25 })
      hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "default" })
      hl.env("XCURSOR_THEME", ${quote cfg.cursor.name})
      hl.env("XCURSOR_SIZE", ${quote (toString cfg.cursor.size)})
      hl.env("HYPRCURSOR_THEME", ${quote cfg.cursor.name})
      hl.env("HYPRCURSOR_SIZE", ${quote (toString cfg.cursor.size)})

      local function execbind(keys, command, opts) hl.bind(keys, hl.dsp.exec_cmd(command), opts) end
      execbind("SUPER + RETURN", ${quote (lib.getExe cfg.terminal)})
      execbind("SUPER + E", ${quote (lib.getExe cfg.fileManager)})
      -- Capture do Vitreus (o mesmo que o keys.conf do upstream dá no pleamar-wm).
      execbind("PRINT", ${quote (say "vitreus" "emit shot 0")})
      execbind("SHIFT + PRINT", ${quote (say "vitreus" "emit shot 1")})
      execbind("SUPER + C", ${quote (say "vitreus" "emit shot 0")})
      execbind("SUPER + SHIFT + C", ${quote (say "vitreus" "emit rec_toggle")})
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
      -- Volume e mídia direto no wpctl/playerctl: o Vitreus mostra o volume sozinho. O brilho é do hypr_vitreus.lua.
      execbind("XF86AudioRaiseVolume", "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+", { locked = true, repeating = true })
      execbind("XF86AudioLowerVolume", "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { locked = true, repeating = true })
      execbind("XF86AudioMute", "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
      execbind("XF86AudioMicMute", "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
      execbind("XF86AudioPlay", "${pkgs.playerctl}/bin/playerctl play-pause", { locked = true })
      execbind("XF86AudioPause", "${pkgs.playerctl}/bin/playerctl play-pause", { locked = true })
      execbind("XF86AudioNext", "${pkgs.playerctl}/bin/playerctl next", { locked = true })
      execbind("XF86AudioPrev", "${pkgs.playerctl}/bin/playerctl previous", { locked = true })

      -- Ambiente para portais e serviços de usuário (como no Serpantinum).
      hl.on("hyprland.start", function()
        hl.exec_cmd("${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
        hl.exec_cmd("${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; ${pkgs.systemd}/bin/systemctl --user stop hyprland-session.target; ${pkgs.systemd}/bin/systemctl --user start hyprland-session.target")
      end)

      -- Vitreus: atalhos e o hyprland.start dele (pleamar --autostart, hypridle, awww-daemon, cliphist).
      require("hypr_vitreus")
      pcall(require, "vitreus_monitors")      -- Settings > Display
      pcall(require, "vitreus_hypr")          -- Settings > Hyprland
      pcall(require, "vitreus_colors")        -- bordas pelas cores do wallpaper (iris) e o espaço da barra lateral
    '';
  };
}
