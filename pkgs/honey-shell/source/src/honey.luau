-- Geometry and springs stay in .plm. This file only publishes facts and models.
local generation = 0
local actions = {}
local apps = {}
local trayItems = {}
local menus = {}
local liveStarted = false
local lastConfig = nil
local fixtureIcon = ""
local modes = {"apps", "files", "commands", "settings", "emoji", "clipboard"}
local names = {"Aplicativos", "Arquivos", "Comandos", "Configurações", "Emoji", "Clipboard"}
local closing = false
local nativeBacklight = false
local ddcBacklight = false

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
        for _, a in ipairs(apps) do
            if #hits < fact.capacity and (query == "" or string.find(string.lower(a.name), string.lower(query), 1, true)) then
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

local function opened(which)
    closing = false
    fact.previewphase = -1
    fact.panel = which
    fact.target = which
    fact.confirm = 0
    text.commandout = ""
    if which == 3 then
        menus = {}; model.traymenu = {}
        local rows = {}
        for i, t in ipairs(trayItems) do
            if i <= 5 then rows[#rows + 1] = {key=t.key,name=t.title or t.id,icon=t.icon or ""} end
        end
        model.icons = rows; model.traymini = rows
        text.traytitle = #rows > 0 and "Tray" or "Nenhum item no tray"
    end
    if which == 1 then
        after(120, function() if fact.panel == 1 and fact.target == 1 then focus("query") end end)
        search()
    else
        focus()
    end
    log("panel", which)
end

local function request(which)
    which = math.floor(which)
    if which < 0 or which > 5 then return end
    if which == 2 and not fact.controlson or which == 3 and not fact.trayon or which == 4 and not fact.poweron or which == 5 and not fact.cavaon then return end
    if fact.panel == 0 then opened(which); return end
    if which == fact.panel and not closing then which = 0 end
    fact.previewphase = -1
    fact.nextpanel = which
    fact.target = 0
    fact.confirm = 0
    closing = true
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
    elseif code >= 2 and code <= 4 then if not force or fact.panel ~= code then request(code) end
    elseif code == 0 then request(0) end
end)
on("settled", function()
    if not closing then return end
    local next = fact.nextpanel
    fact.nextpanel = 0; fact.panel = 0; closing = false
    text.query = ""; actions = {}; model.hits = {}
    log("closed")
    if next > 0 then opened(next) end
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
local function live_services()
    if liveStarted then return end
    liveStarted = true
    -- Register each native service in its own handler. Initial enumeration can
    -- involve D-Bus/graphics work; combining all six exceeds the runtime budget.
    local delay = 2500
    local function watch(name, callback, unavailable)
        delay += 500
        after(delay, function()
            log("service", name, "register")
            if not sys.watch(name, callback) and unavailable then unavailable() end
            log("service", name, "ready")
        end)
    end
    watch("network", function(n)
        if fact.demo then return end
        wifi = n.online and (n.kind == "wifi" and "Wi-Fi" or "Rede") or "Offline"
        fact.wifion = n.online or false
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
        fact.audioavailable = a.outputs ~= nil and #a.outputs > 0; fact.volume = a.volume or 0; fact.muted = a.muted or false; text.mutelabel = fact.muted and "Silenciado" or "Som ativo"
    end, function() fact.audioavailable = false; text.status = "Áudio indisponível" end)
    watch("brightness", function(b)
        if fact.demo then return end
        nativeBacklight = b.present or false; fact.backlight = nativeBacklight or ddcBacklight; if nativeBacklight then fact.brightness = b.level or 0 end
    end, function() fact.backlight = false end)
    watch("tray", function(list)
        if fact.demo then return end
        trayItems = list; local rows = {}
        for i, t in ipairs(list) do
            if i <= 5 then rows[#rows + 1] = {key=t.key, name=t.title ~= "" and t.title or t.id, icon=t.icon} end
        end
        model.icons = rows; model.traymini = rows
        text.traytitle = #rows > 0 and "Tray" or "Nenhum item no tray"
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
    if not c.modules.cava and fact.panel == 5 or not c.modules.controls and fact.panel == 2 or not c.modules.tray and fact.panel == 3 or not c.modules.power and fact.panel == 4 then request(0) end
    if fact.panel == 1 and fact.mode == 0 then search() end
    lastConfig = c
    log("config", c.mode, packet.error)
end

on("volume_set", function(value)
    local previous = fact.volume
    if not fact.demo and not fact.audioavailable then text.status="Áudio indisponível";return end
    fact.volume = value
    if fact.demo then text.status="[demo] volume simulado"
    else
        local ok, err = pcall(function() sys.call("audio.volume", value) end)
        if not ok then fact.volume=previous end
        text.status=ok and "Volume atualizado" or "Áudio: " .. tostring(err)
    end
    log("volume", value)
end)
on("brightness_set", function(value)
    if not fact.backlight then return end
    fact.brightness = value
    if not fact.demo then
        if nativeBacklight then
            local ok, err=pcall(function() sys.call("brightness.level", value) end)
            text.status=ok and "Brilho atualizado" or "Brilho: " .. tostring(err)
        else helper("action",{kind="brightness",value=value},function(r) text.status=r.message end) end
    end
    log("brightness", value)
end)
on("mute", function()
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

on("tray_action", function(index)
    local t=trayItems[index+1];if not t then return end
    if fact.demo then text.status="[demo] ativar "..t.title else pcall(function() sys.call("tray.activate",t.key) end) end
end)
on("tray_context", function(index)
    local t=trayItems[index+1];if not t then return end
    menus={}
    if fact.demo then menus={{id=1,name="Abrir",enabled=true,key=t.key},{id=2,name="Opção indisponível",enabled=false,key=t.key}}
    else
        local function flatten(items,prefix)
            for _,m in ipairs(items) do
                if not m.separator and #menus<8 then
                    menus[#menus+1]={id=m.id,name=prefix..m.label,enabled=m.enabled,key=t.key}
                    if m.children then flatten(m.children,prefix.."› ") end
                end
            end
        end
        local ok, data=pcall(function() return sys.ask("tray.menu",t.key) end)
        if ok and data then flatten(data,"") end
    end
    model.icons={};model.traymenu=menus;text.traytitle=t.title or t.id
end)
on("tray_click",function(index)
    local m=menus[index+1];if not m or not m.enabled then return end
    if fact.demo then text.status="[demo] menu "..m.name else pcall(function() sys.call("tray.menu_click",m.key,m.id) end) end
end)

spawn("python3", {"services/bridge.py", "stream"}, function(line)
    local ok, packet=pcall(json.decode,line)
    if not ok then log("bridge parse",line);return end
    if packet.type=="config" then apply_config(packet)
    elseif packet.type=="cava" then
        local rows={};local sum=0
        for _,v in ipairs(packet.bars or {}) do rows[#rows+1]={level=v};sum+=v end
        model.bands=rows;fact.energy=sum/12
        text.mediastatus=packet.error ~= nil and packet.error ~= "" and packet.error or (fact.demo and "Cava · áudio simulado" or "Cava · áudio do desktop")
    elseif packet.type=="brightness" then
        ddcBacklight=packet.available or false
        fact.backlight=nativeBacklight or ddcBacklight
        if not nativeBacklight and ddcBacklight then fact.brightness=packet.level end
    elseif packet.type=="clipboard" and fact.panel==1 and fact.mode==5 then search() end
end, function(_,code) text.status="Helper encerrado: "..tostring(code) end)
text.status = "Clique no relógio para abrir o launcher"
