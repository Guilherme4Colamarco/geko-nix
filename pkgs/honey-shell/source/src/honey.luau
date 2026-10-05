-- Geometry and springs stay in .plm. This file only publishes facts and models.
local generation = 0
local actions = {}
local apps = {}
local trayItems = {}
local menus = {}
local trayMenuKey = nil
local trayMenuNodes = {}
local trayMenuStack = {}
local trayMenuPage = 0
local pendingTrayMenu = false
local pendingTrayContext = nil
local request
local liveStarted = false
local lastConfig = nil
local fixtureIcon = ""
local modes = {"apps", "files", "commands", "settings", "emoji", "clipboard"}
local names = {"Aplicativos", "Arquivos", "Comandos", "Configurações", "Emoji", "Clipboard"}
local closing = false
local closeToken = 0
local nativeBacklight = false
local ddcBacklight = false
local ddcBusy = false
local ddcPending = nil
local ddcScheduled = false

local function helper(operation, payload, done)
    run("python3", {"services/bridge.py", operation, json.encode(payload or {})}, function(out, code)
        local ok, result = pcall(json.decode, out)
        if code ~= 0 or not ok then
            text.status = "Helper indisponível: " .. tostring(out):sub(1, 100)
            if done then done({ok = false, message = text.status}) end
            return
        end
        if done then done(result) end
    end)
end

local function publish(rows)
    actions = {}
    for i, row in ipairs(rows or {}) do if i <= fact.capacity then actions[#actions + 1] = row end end
    for _, row in ipairs(actions) do row.icon = row.icon or fixtureIcon end
    model.hits = actions
    log("results", generation, #actions)
    fact.sel = 0
    text.status = #actions == 0 and "Nenhum resultado" or tostring(#actions) .. " resultados · " .. (fact.demo and "ações simuladas" or "serviços do desktop")
end

local function search()
    generation += 1
    local token = generation
    local mode = modes[math.floor(fact.mode) + 1] or "apps"
    local query = text.query or ""
    if mode == "commands" then
        actions = {}; model.hits = {}; text.status = "Enter executa somente no modo Comandos"; return
    end
    text.commandout = ""
    if mode == "apps" then
        local hits = {}
        local needle = string.lower(query)
        for _, a in ipairs(apps) do
            if #hits < fact.capacity and (query == "" or string.find(string.lower(a.name), needle, 1, true)) then
                hits[#hits + 1] = {id = a.id or a.exec, name = a.name, detail = "Aplicativo", kind = "app", value = a.exec, icon = (a.icon ~= nil and a.icon ~= "" and a.icon or fixtureIcon), preview = ""}
            end
        end
        publish(hits)
    else
        text.status = "Buscando…"
        helper("search", {mode = mode, query = query, generation = token}, function(result)
            if token ~= generation then return end
            publish(result.rows or {})
        end)
    end
end

local function tray_rows()
    local rows = {}
    for i, t in ipairs(trayItems) do
        if i <= 5 then rows[#rows + 1] = {key=t.key, name=(t.title ~= nil and t.title ~= "" and t.title) or t.id or t.name or "", icon=t.icon or ""} end
    end
    return rows
end

local function show_tray_list()
    menus = {}
    trayMenuKey = nil
    trayMenuNodes = {}
    trayMenuStack = {}
    trayMenuPage = 0
    pendingTrayMenu = false
    model.traymenu = {}
    local rows = tray_rows()
    model.icons = rows
    model.traymini = rows
    text.traytitle = #rows > 0 and "Tray" or "Nenhum item no tray"
end

local function menu_nodes(items)
    local rows = {}
    for _, item in ipairs(items or {}) do
        if not item.separator then rows[#rows + 1] = item end
    end
    return rows
end

local function publish_tray_menu()
    menus = {}
    -- Six entries leave two rows for paging, without losing any application action.
    local first = trayMenuPage * 6 + 1
    if trayMenuPage > 0 then
        menus[#menus + 1] = {id=0, name="‹ Página anterior", enabled=true, key=trayMenuKey, move=-1}
    end
    for i = first, math.min(first + 5, #trayMenuNodes) do
        local m = trayMenuNodes[i]
        local children = menu_nodes(m.children)
        local mark = m.checked == true and "✓ " or (m.checked == false and "○ " or "")
        menus[#menus + 1] = {id=m.id, name=mark .. (m.label or "") .. (#children > 0 and "  ›" or ""), label=m.label or "", enabled=m.enabled ~= false, key=trayMenuKey, children=children}
    end
    if first + 5 < #trayMenuNodes then
        menus[#menus + 1] = {id=0, name="Próxima página ›", enabled=true, key=trayMenuKey, move=1}
    end
    model.icons = {}
    model.traymenu = menus
end

local function native_tray_context(key)
    local ok, err = pcall(function() sys.call("tray.context", key) end)
    text.status = ok and "Menu aberto pelo aplicativo" or "Menu indisponível: " .. tostring(err)
end

local function show_tray_menu(index)
    local t = trayItems[math.floor(index) + 1]
    if not t then return end
    local data
    if fact.demo then
        data = {{id=1, label="Abrir", enabled=true}, {id=2, label="Opções", enabled=true, children={{id=3,label="Opção indisponível",enabled=false},{id=4,label="Exemplo",enabled=true}}}}
    elseif t.menu then
        local ok, result = pcall(function() return sys.ask("tray.menu", t.key) end)
        if ok then data = result else log("tray menu", t.key, tostring(result)) end
    end
    local rows = menu_nodes(data)
    if #rows == 0 then
        -- Some SNI applications export ContextMenu instead of a DBusMenu tree.
        -- Ask the application to show it rather than leaving an empty Honey panel.
        if not fact.demo then
            if fact.panel > 0 then
                pendingTrayContext = t.key
                request(0)
            else native_tray_context(t.key) end
        end
        return
    end
    trayMenuKey = t.key
    trayMenuNodes = rows
    trayMenuStack = {}
    trayMenuPage = 0
    text.traytitle = "‹ " .. (t.title or t.id or "Menu")
    publish_tray_menu()
    if fact.panel ~= 3 or fact.target ~= 3 then
        pendingTrayMenu = true
        request(3)
    end
end

-- Notifications: pleamar is the org.freedesktop.Notifications server. Toasts are the
-- newest ones whose time has not run out; the centre is the service's own list
-- (`notifications.keep` stops them expiring), so nothing is lost when a toast goes.
local noteList = {}
local noteSeen = {}
local noteHidden = {}
local noteRead = {}
local toastIds = {}
local histIds = {}

local function note_level(u)
    if u == "critical" or u == 2 then return 2 end
    if u == "low" or u == 0 then return 0 end
    return 1
end

local function note_age(t)
    local d = os.time() - (t or os.time())
    if d < 60 then return "agora" end
    if d < 3600 then return math.floor(d / 60) .. " min" end
    if d < 86400 then return math.floor(d / 3600) .. " h" end
    return math.floor(d / 86400) .. " d"
end

local function note_row(n)
    local label, key = "", ""
    for _, a in ipairs(n.actions or {}) do
        if a.key ~= "default" then label = a.label or ""; key = a.key or ""; break end
    end
    local icon = n.icon
    if icon == nil or icon == "" then icon = fixtureIcon end
    return {id = n.id, app = n.app or "", title = n.title or "", body = n.body or "", icon = icon,
            pic = n.image or "", level = note_level(n.urgency), actlabel = label, actkey = key, hasact = label ~= "", age = note_age(n.time)}
end

local function publish_notes()
    local cfg = lastConfig and lastConfig.notifications or {}
    local limit = math.floor(cfg.max_visible or 3)
    local toasts, hist, unread = {}, {}, 0
    toastIds, histIds = {}, {}
    local quiet = fact.dnd or fact.locked or fact.panel == 7
    for _, n in ipairs(noteList) do
        if not noteRead[n.id] then unread += 1 end
        if #hist < 8 then hist[#hist + 1] = note_row(n); histIds[#hist] = n.id end
        if not noteHidden[n.id] and not quiet and #toasts < limit then toasts[#toasts + 1] = note_row(n); toastIds[#toasts] = n.id end
    end
    model.notes = toasts
    model.notes_hist = hist
    fact.unread = unread
    fact.notecount = #noteList
    text.noteinfo = #noteList == 0 and "Nenhuma notificação" or (#noteList .. (#noteList == 1 and " notificação" or " notificações"))
end

local function mark_notes_read()
    for _, n in ipairs(noteList) do noteRead[n.id] = true end
    publish_notes()
end

local function on_notifications(list)
    if fact.demo then return end
    noteList = list or {}
    local present = {}
    local cfg = lastConfig and lastConfig.notifications or {}
    for _, n in ipairs(noteList) do
        present[n.id] = true
        if not noteSeen[n.id] then
            noteSeen[n.id] = true
            local lv = note_level(n.urgency)
            -- Critical drops stay until someone dismisses them; the others dry up.
            if lv < 2 then
                local secs = lv == 0 and (cfg.low_timeout or 3) or (cfg.timeout or 6)
                local id = n.id
                after(math.floor(secs * 1000), function() noteHidden[id] = true; publish_notes() end)
            end
            if not fact.dnd and not fact.locked then helper("action", {kind = "sound", value = ""}) end
        end
    end
    for id in pairs(noteSeen) do
        if not present[id] then noteSeen[id] = nil; noteHidden[id] = nil; noteRead[id] = nil end
    end
    publish_notes()
end

local function note_target(code)
    code = math.floor(code)
    if code >= 100 then return histIds[code - 99] end
    return toastIds[code + 1]
end

on("note_open", function(code)
    local id = note_target(code)
    if not id or fact.demo then return end
    pcall(function() sys.call("notifications.invoke", id, "default") end)
    pcall(function() sys.call("notifications.dismiss", id) end)
end)
on("note_act", function(code)
    local id = note_target(code)
    if not id or fact.demo then return end
    for _, n in ipairs(noteList) do
        if n.id == id then
            for _, a in ipairs(n.actions or {}) do
                if a.key ~= "default" then
                    pcall(function() sys.call("notifications.invoke", id, a.key) end)
                    pcall(function() sys.call("notifications.dismiss", id) end)
                    return
                end
            end
        end
    end
end)
on("note_close", function(code)
    local id = note_target(code)
    if not id or fact.demo then return end
    pcall(function() sys.call("notifications.dismiss", id) end)
end)
on("note_clear", function()
    if fact.demo then return end
    pcall(function() sys.call("notifications.clear") end)
    pcall(function() sys.call("notifications.clear_history") end)
end)
on("dnd", function(v)
    v = math.floor(v)
    if v == 2 then fact.dnd = not fact.dnd else fact.dnd = v == 1 end
    publish_notes()
end)
on("lock_state", function(v) fact.locked = math.floor(v) == 1; publish_notes() end)

local wallRows = {}
local wallPage = 0

local function load_walls()
    helper("wallpapers", {page = wallPage}, function(r)
        if fact.panel ~= 6 then return end
        wallRows = r.rows or {}
        local rows = {}
        for i, w in ipairs(wallRows) do rows[i] = {thumb = w.path, name = w.name, current = w.current == true} end
        model.walls = rows
        wallPage = r.page or 0
        fact.wallpage = wallPage; fact.wallpages = r.pages or 1
        text.wallinfo = r.error or ((r.total or 0) .. " imagens · página " .. (wallPage + 1) .. "/" .. (r.pages or 1))
    end)
end

local function opened(which)
    closing = false
    fact.previewphase = -1
    fact.panel = which
    fact.target = which
    fact.confirm = 0
    text.commandout = ""
    if which == 6 then fact.wallpick = -1; load_walls() end
    if which == 7 then mark_notes_read() end
    if which == 3 then
        if pendingTrayMenu then pendingTrayMenu = false; publish_tray_menu() else show_tray_list() end
    end
    if which == 1 then
        after(120, function() if fact.panel == 1 and fact.target == 1 then focus("query") end end)
        search()
    else
        focus()
    end
    log("panel", which)
end

request = function(which)
    which = math.floor(which)
    if which < 0 or which > 7 then pendingTrayMenu = false; return end
    if which == 2 and not fact.controlson or which == 3 and not fact.trayon or which == 4 and not fact.poweron or which == 5 or which == 6 and not fact.wallon or which == 7 and not fact.noteon then pendingTrayMenu = false; return end
    if fact.panel == 0 then opened(which); return end
    if which == fact.panel and not closing then which = 0 end
    fact.previewphase = -1
    fact.nextpanel = which
    fact.target = 0
    fact.confirm = 0
    closing = true
    closeToken += 1
    local token = closeToken
    -- The spring may already rest at zero, so no `change` ever fires `settled`.
    after(1500, function() if closing and closeToken == token then emit("settled") end end)
    generation += 1 -- invalidate callbacks from a closing launcher
    focus()
end

on("request", request)
on("control", function(code)
    code = math.floor(code)
    local force = code >= 100
    if force then code -= 100 end
    if code >= 10 and code <= 15 then
        local mode = code - 10
        if fact.panel == 1 and fact.mode == mode and not closing then if not force then request(0) end;return end
        fact.mode=mode;text.modename=names[mode+1];text.query=""
        if fact.panel == 1 and not closing then search();focus("query")
        else request(1) end
    elseif code >= 2 and code <= 7 then if not force or fact.panel ~= code then request(code) end
    elseif code == 0 then request(0) end
end)
on("settled", function()
    if not closing then return end
    local next = fact.nextpanel
    fact.nextpanel = 0; fact.panel = 0; closing = false
    text.query = ""; actions = {}; model.hits = {}
    log("closed")
    if next > 0 then
        pendingTrayContext = nil
        opened(next)
    elseif pendingTrayContext then
        local key = pendingTrayContext
        pendingTrayContext = nil
        -- Let the renderer release its overlay and exclusive keyboard first.
        after(50, function() if fact.panel == 0 and not closing then native_tray_context(key) end end)
    end
end)
on("choosemode", function(which)
    local m = math.floor(which)
    if m < 0 or m > 5 then return end
    fact.mode = m; text.modename = names[m + 1]; text.query = ""; search(); focus("query")
    log("mode", modes[m+1])
end)
on("text:query", search)
on("resized", function() if fact.panel == 1 then search() end end)

local function activate(index)
    if fact.panel ~= 1 or closing then return end
    if fact.mode == 2 then
        generation += 1; local token = generation
        text.commandout = "Executando…"
        helper("action", {kind = "command", value = text.query}, function(r)
            if token ~= generation or fact.mode ~= 2 then return end
            text.commandout = tostring(r.message or ""):sub(1, 700)
            text.status = r.ok and "Comando concluído" or "Erro no comando"
            log("command", r.ok, r.code)
        end)
        return
    end
    local row = actions[index + 1]
    if not row then return end
    if row.kind == "app" then
        if fact.demo then
            text.status = "[demo] abrir " .. row.name
        else
            local ok, err = pcall(function() sys.call("apps.launch", row.value) end)
            text.status = ok and "Abrindo " .. row.name or tostring(err)
        end
        log("app", row.name, fact.demo)
        request(0)
    else
        helper("action", {kind = row.kind, value = row.value}, function(r)
            text.status = r.message or "Concluído"
            log("action", row.kind, r.ok)
            if row.kind == "setting" and r.config then
                lastConfig = r.config
                if row.value == "motion.reduced" then fact.reduced = r.config.motion.reduced end
                search()
            end
        end)
    end
end
on("activate", activate)
on("submit:query", function(value)
    if value ~= nil then text.query = value end
    activate(fact.sel)
end)

local wifi = "Rede —"
local bluetooth = "BT —"
-- A volume change that did not come from Honey itself (media keys, wpctl,
-- another app) swells the volume drop for a moment.
local ownVolume, osdToken, audioSeen = 0, 0, false
local function own_volume()
    ownVolume += 1
    local token = ownVolume
    after(500, function() if ownVolume == token then ownVolume = 0 end end)
end
local function show_volume()
    osdToken += 1
    local token = osdToken
    fact.volosd = 1
    after(1500, function() if osdToken == token then fact.volosd = 0 end end)
end
local function audio_changed(volume, muted)
    local changed = math.abs(volume - fact.volume) > 0.004 or muted ~= fact.muted
    fact.volume = volume; fact.muted = muted; text.mutelabel = muted and "Silenciado" or "Som ativo"
    if audioSeen and changed and ownVolume == 0 and fact.panel ~= 2 then show_volume() end
    audioSeen = true
end
local function live_services()
    if liveStarted then return end
    liveStarted = true
    -- Register each native service in its own handler. Initial enumeration can
    -- involve D-Bus/graphics work; combining all six exceeds the runtime budget.
    local delay = 2500
    local function watch(name, callback, unavailable, at)
        if not at then delay += 500 end
        after(at or delay, function()
            log("service", name, "register")
            if not sys.watch(name, callback) and unavailable then unavailable() end
            log("service", name, "ready")
        end)
    end
    -- Notifications first and early: a message sent right after login must not be lost.
    watch("notifications", on_notifications, function() text.status = "Notificações indisponíveis" end, 400)
    after(900, function() pcall(function() sys.call("notifications.keep", true) end) end)
    watch("network", function(n)
        if fact.demo then return end
        wifi = n.online and (n.kind == "wifi" and "Wi-Fi" or "Rede") or "Offline"
        fact.wifion = n.wifi == true
        text.traybar = wifi .. " · " .. bluetooth
    end)
    watch("bluetooth", function(b)
        if fact.demo then return end
        fact.bton = b.present and b.powered or false
        bluetooth = not b.present and "BT —" or b.powered and "BT ligado" or "BT desligado"
        text.traybar = wifi .. " · " .. bluetooth
    end)
    watch("apps", function(list) if fact.demo then return end; apps = list; if fact.panel == 1 and fact.mode == 0 then search() end end)
    watch("audio", function(a)
        if fact.demo then return end
        fact.audioavailable = a.outputs ~= nil and #a.outputs > 0; audio_changed(a.volume or 0, a.muted or false)
    end, function() fact.audioavailable = false; text.status = "Áudio indisponível" end)
    watch("brightness", function(b)
        if fact.demo then return end
        nativeBacklight = b.present or false; fact.backlight = nativeBacklight or ddcBacklight; if nativeBacklight then fact.brightness = b.level or 0 end
    end, function() fact.backlight = false end)
    watch("tray", function(list)
        if fact.demo then return end
        trayItems = list
        local rows = tray_rows()
        model.traymini = rows
        if trayMenuKey then
            local present = false
            for _, item in ipairs(list) do if item.key == trayMenuKey then present = true; break end end
            if not present then show_tray_list() end
        else
            model.icons = rows
            text.traytitle = #rows > 0 and "Tray" or "Nenhum item no tray"
        end
    end, function() text.traytitle = "Tray indisponível" end)
end

local function apply_config(packet)
    local c = packet.config
    fixtureIcon = packet.fixture_icon or fixtureIcon
    if not c then return end
    local wasDemo = fact.demo
    fact.demo = c.mode ~= "live"
    fact.reduced = c.motion.reduced
    fact.cavaon = c.modules.cava; fact.controlson = c.modules.controls
    fact.clockon = c.modules.clock; fact.trayon = c.modules.tray; fact.poweron = c.modules.power
    fact.wallon = c.modules.wallpaper ~= false
    fact.noteon = c.modules.notifications ~= false
    if not lastConfig then fact.dnd = c.notifications ~= nil and c.notifications.dnd == true end
    text.configerror = packet.error ~= "" and "Configuração inválida; mantendo a anterior: " .. tostring(packet.error) or ""
    text.backend = fact.demo and "DEMO · workspace isolado" or (packet.capabilities.compositor .. " · LIVE")
    if fact.demo then
        fact.audioavailable = true; fact.backlight = true; text.traybar = "Tray · Wi-Fi · BT"
        apps = {{name="Firefox",exec="firefox",id="firefox"},{name="Terminal",exec="kitty",id="terminal"},{name="Arquivos",exec="xdg-open .",id="files"},{name="Editor",exec="editor",id="editor"}}
        trayItems = {{key="wifi",title="Wi-Fi · demonstração"},{key="bt",title="Bluetooth · demonstração"},{key="sync",title="Sincronização · demonstração"}}
        model.icons = {{key="wifi",name="Wi-Fi · demonstração"},{key="bt",name="Bluetooth · demonstração"},{key="sync",name="Sincronização · demonstração"}}
        text.traytitle = "Tray · demo"
    else
        if wasDemo then apps={}; model.icons={}; model.traymini={}; fact.audioavailable=false; fact.backlight=false end
        live_services()
    end
    if fact.panel == 5 or not c.modules.controls and fact.panel == 2 or not c.modules.tray and fact.panel == 3 or not c.modules.power and fact.panel == 4 or c.modules.wallpaper == false and fact.panel == 6 or c.modules.notifications == false and fact.panel == 7 then request(0) end
    if fact.panel == 1 and fact.mode == 0 then search() end
    lastConfig = c
    log("config", c.mode, packet.error)
end

on("volume_set", function(value)
    value = math.clamp(value, 0, 1)
    local previous = fact.volume
    if not fact.demo and not fact.audioavailable then text.status="Áudio indisponível";return end
    fact.volume = value
    own_volume()
    if fact.demo then text.status="[demo] volume simulado"
    else
        local ok, err = pcall(function() sys.call("audio.volume", value) end)
        if not ok then fact.volume=previous end
        text.status=ok and "Volume atualizado" or "Áudio: " .. tostring(err)
    end
    log("volume", value)
end)
local function flush_ddc()
    ddcScheduled = false
    if ddcBusy or ddcPending == nil then return end
    if fact.demo or not fact.backlight or nativeBacklight then ddcPending = nil; return end
    local value = ddcPending
    ddcPending = nil
    ddcBusy = true
    helper("action", {kind="brightness",value=value}, function(r)
        ddcBusy = false
        if ddcPending ~= nil then flush_ddc()
        else text.status = r.message or "Brilho atualizado" end
    end)
end
on("brightness_set", function(value)
    value = math.clamp(value, 0, 1)
    if not fact.backlight then return end
    fact.brightness = value
    if not fact.demo then
        if nativeBacklight then
            local ok, err=pcall(function() sys.call("brightness.level", value) end)
            text.status=ok and "Brilho atualizado" or "Brilho: " .. tostring(err)
        else
            ddcPending = value
            if not ddcBusy and not ddcScheduled then
                ddcScheduled = true
                after(80, flush_ddc)
            end
        end
    end
    log("brightness", value)
end)
on("mute", function()
    own_volume()
    if fact.demo then fact.muted = not fact.muted; text.mutelabel = fact.muted and "Silenciado" or "Som ativo" else
        if not fact.audioavailable then text.status="Áudio indisponível";return end
        local ok, err=pcall(function() sys.call("audio.mute") end)
        if not ok then text.status="Áudio: " .. tostring(err) end
    end
end)
on("power_action", function(index)
    local actions = {"lock", "suspend", "logout", "reboot", "shutdown"}
    local action = actions[index + 1]
    if not action then return end
    if index >= 3 and fact.confirm ~= index + 1 then
        fact.confirm = index + 1; text.status = "Clique novamente para confirmar " .. action; return
    end
    helper("action", {kind="power",value=action,confirmed=index>=3}, function(r)
        text.status=r.message;fact.confirm=0;log("power",action,r.ok,fact.demo)
    end)
end)

on("tray_wifi", function()
    if fact.demo then
        fact.wifion = not fact.wifion
        text.status = fact.wifion and "[demo] Wi-Fi ligado" or "[demo] Wi-Fi desligado"
        return
    end
    local nextOn = not fact.wifion
    local ok, err = pcall(function() sys.call("network.wifi", nextOn) end)
    if ok then fact.wifion = nextOn; text.status = nextOn and "Wi-Fi ligado" or "Wi-Fi desligado"
    else text.status = "Wi-Fi: " .. tostring(err) end
end)
on("tray_bt", function()
    if fact.demo then
        fact.bton = not fact.bton
        text.status = fact.bton and "[demo] Bluetooth ligado" or "[demo] Bluetooth desligado"
        return
    end
    local nextOn = not fact.bton
    local ok, err = pcall(function() sys.call("bluetooth.power", nextOn) end)
    if ok then fact.bton = nextOn; text.status = nextOn and "Bluetooth ligado" or "Bluetooth desligado"
    else text.status = "Bluetooth: " .. tostring(err) end
end)
on("tray_back", function()
    local previous = table.remove(trayMenuStack)
    if previous then
        trayMenuNodes = previous.nodes
        trayMenuPage = previous.page
        text.traytitle = previous.title
        publish_tray_menu()
    else show_tray_list() end
end)
on("tray_action", function(index)
    local t = trayItems[math.floor(index) + 1]
    if not t then return end
    if fact.demo then text.status = "[demo] ativar " .. (t.title or t.name or "")
    else
        local ok, err = pcall(function() sys.call("tray.activate", t.key) end)
        if not ok then text.status = "Bandeja: " .. tostring(err) end
    end
end)
on("tray_secondary", function(index)
    local t = trayItems[math.floor(index) + 1]
    if not t then return end
    if fact.demo then text.status = "[demo] ação secundária " .. (t.title or t.name or "")
    else
        local ok, err = pcall(function() sys.call("tray.secondary", t.key) end)
        if not ok then text.status = "Bandeja: " .. tostring(err) end
    end
end)
on("tray_context", function(index) show_tray_menu(index) end)
on("tray_click", function(index)
    local m = menus[math.floor(index) + 1]
    if not m or not m.enabled then return end
    if m.move then
        trayMenuPage += m.move
        publish_tray_menu()
        return
    end
    if #m.children > 0 then
        trayMenuStack[#trayMenuStack + 1] = {nodes=trayMenuNodes, page=trayMenuPage, title=text.traytitle}
        trayMenuNodes = m.children
        trayMenuPage = 0
        text.traytitle = "‹ " .. (m.label or m.name)
        publish_tray_menu()
        return
    end
    if fact.demo then text.status = "[demo] menu " .. m.name
    else
        local ok, err = pcall(function() sys.call("tray.menu_click", m.key, m.id) end)
        if not ok then text.status = "Menu: " .. tostring(err); return end
    end
    show_tray_list()
end)

on("wall_pick", function(index)
    local i = math.floor(index)
    local w = wallRows[i + 1]
    if not w or fact.wallpick >= 0 then return end
    fact.wallpick = i
    helper("action", {kind = "wallpaper", value = w.path}, function(r)
        text.status = r.message or ""
        if not r.ok then fact.wallpick = -1; return end
        local rows = {}
        for k, row in ipairs(wallRows) do row.current = row.path == w.path; rows[k] = {thumb = row.path, name = row.name, current = row.current} end
        model.walls = rows
        -- Let the chosen hexagon finish melting before the panel closes.
        after(900, function() if fact.panel == 6 and not closing then request(0) end end)
    end)
end)
on("wall_page", function(delta)
    local pages = math.max(1, fact.wallpages)
    wallPage = math.max(0, math.min(pages - 1, wallPage + math.floor(delta)))
    load_walls()
end)

local beat = 0
spawn("python3", {"services/bridge.py", "stream"}, function(line)
    local ok, packet=pcall(json.decode,line)
    if not ok then log("bridge parse",line);return end
    if packet.type=="config" then apply_config(packet)
    elseif packet.type=="cava" then
        local rows={};local sum=0
        for _,v in ipairs(packet.bars or {}) do rows[#rows+1]={level=v};sum+=v end
        model.bands=rows;fact.energy=sum/math.max(#rows,1)
        -- Bass (first three bands) hits fast and falls slowly, so the body marks the beat.
        local bars=packet.bars or {}
        beat=math.max(((bars[1] or 0)+(bars[2] or 0)+(bars[3] or 0))/3, beat*0.8)
        fact.beat=if beat < 0.01 then 0 else beat
        text.mediastatus=packet.error ~= nil and packet.error ~= "" and packet.error or (fact.demo and "Cava · áudio simulado" or "Cava · áudio do desktop")
    elseif packet.type=="brightness" then
        ddcBacklight=packet.available or false
        fact.backlight=nativeBacklight or ddcBacklight
        if not nativeBacklight and ddcBacklight and not ddcBusy and ddcPending == nil then fact.brightness=packet.level end
    elseif packet.type=="clipboard" and fact.panel==1 and fact.mode==5 then search() end
end, function(_,code) text.status="Helper encerrado: "..tostring(code) end)
text.status = "Clique no relógio para abrir o launcher"
