-- Lua explícito: os campos Hyprlang antigos não são chamadas da API Lua.
hl.config({
  input = { kb_layout = "br" },
  general = { gaps_in = 5, gaps_out = 10, border_size = 2 },
  decoration = { rounding = 12, blur = { enabled = true } },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
hl.monitor({ output = "DP-1", mode = "1920x1080@165.003", position = "auto", scale = 1.0 })
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")

local function execbind(keys, command)
  hl.bind(keys, hl.dsp.exec_cmd(command))
end

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
execbind("SUPER + F11", "hyprctl dispatch fullscreen 0")
execbind("SUPER + SHIFT + E", "hyprctl dispatch exit")
execbind("SUPER + D", "serpantinum msg toggle launcher")
execbind("SUPER + B", "serpantinum msg toggle system")
execbind("SUPER + C", "serpantinum msg toggle clipboard")
execbind("SUPER + W", "serpantinum msg toggle wallpaper")
execbind("SUPER + V", "serpantinum msg toggle volume")
execbind("SUPER + H", "serpantinum msg toggle guide")
execbind("SUPER + L", "serpantinum lock")
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
for i = 1, 10 do
  local key = tostring(i % 10)
  execbind("SUPER + " .. key, "hyprctl dispatch workspace " .. i)
  execbind("SUPER + SHIFT + " .. key, "hyprctl dispatch movetoworkspace " .. i)
end

-- O Home Manager acrescenta os hooks da sessão systemd ao final.
-- O serviço Serpantinum inicia somente por hyprland-session.target.

-- Teclas de mídia e brilho do upstream Serpantinum.
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("serpantinum brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("serpantinum brightness raise"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("serpantinum volume mic-toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("serpantinum volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("serpantinum volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("serpantinum volume raise"), { repeating = true, locked = true })
