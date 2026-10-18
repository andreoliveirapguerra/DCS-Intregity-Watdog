--[[ ModWatch client reporter  (modreport_hook.lua)

     A small, open GameGUI hook you install voluntarily. When you load into a
     multiplayer mission it tells THAT server which mods you are running, so the
     server's admins can see everyone is playing fair (or that everyone has the
     required mods). That's all it does.

     How it learns your mods, without any guesswork:
       * It reads YOUR OWN  Logs/dcs.log  and collects the "IC fail: <file>"
         lines that DCS itself writes -- DCS's own integrity-check result, which
         already knows every file of yours that differs from a clean install
         (even edited stock files).
       * It also lists the mod folders you added under  Mods/aircraft  and
         Mods/tech.
     Those are turned into short, generic mod names and sent to the server as a
     single hidden chat line.

     What it does NOT do (read the source -- it is short):
       * it reads nothing outside your DCS folders; no documents, no browser,
         no system info, no personal data;
       * it opens no network connection of its own -- it uses DCS's own in-game
         chat channel to the server you chose to join, nothing else;
       * it is not hidden and not anti-cheat: a cheater would simply not install
         it. It is an honesty/compatibility tool for cooperative servers.

     Uninstall: delete this file. That is the whole uninstall.

     MIT licensed. See the repository README. ]]

local modreport = { sent = {} }

local function rlog(fmt, ...)
    local text = select("#", ...) > 0 and string.format(fmt, ...) or fmt
    pcall(function() log.write("modreport", log.INFO, text) end)
end

-- Turn an integrity-check file path into a short, generic mod label.
-- Server-agnostic: it names categories, not specific community mods.
local function labelFor(path)
    local p = path:lower()
    local function aircraft(seg)
        local name = p:match(seg .. "([^/]+)/")
        return name
    end
    if p:find("/shaders/", 1, true) or p:find("bazar/shaders", 1, true) then
        return "shader/graphics mod"
    end
    if p:find("scripts/hooks/", 1, true) then
        return "GameGUI hook"
    end
    if p:find("/liveries/", 1, true) or p:find("liveries/", 1, true) then
        return "custom livery"
    end
    local acMods = aircraft("mods/aircraft/")
    if acMods then
        if p:find("/cockpit/", 1, true) then return "cockpit mod: " .. acMods end
        return "aircraft module edit: " .. acMods
    end
    local acCore = aircraft("coremods/aircraft/")
    if acCore then return "aircraft/loadout edit: " .. acCore end
    if p:find("coremods/", 1, true) then return "coremods edit" end
    if p:find("mods/", 1, true) then return "mod file edit" end
    return "other edit"
end

--- DCS's own integrity-check result from this machine's dcs.log: lowercase paths.
local function readICFailures()
    local files = {}
    pcall(function()
        local fh = io.open(lfs.writedir() .. "Logs/dcs.log", "r")
        if not fh then return end
        for line in fh:lines() do
            local f = line:match("IC fail:%s*(.-)%s*$")
            if f then files[f:lower()] = true end
        end
        fh:close()
    end)
    return files
end

--- Added mod folders under the writedir, as generic names.
local function readAddedMods()
    local names = {}
    local function scan(sub, prefix)
        pcall(function()
            for entry in lfs.dir(lfs.writedir() .. sub) do
                if entry ~= "." and entry ~= ".." then names[prefix .. entry] = true end
            end
        end)
    end
    scan("Mods/aircraft/", "aircraft mod: ")
    scan("Mods/tech/", "tech mod: ")
    return names
end

local function shortId(s)
    local h = 5381
    for i = 1, #s do h = (h * 131 + s:byte(i)) % 2147483648 end
    return string.format("%08x", h)
end

local function buildReportLine()
    local ic = readICFailures()
    local modset, icCount = {}, 0
    for path in pairs(ic) do
        icCount = icCount + 1
        modset[labelFor(path)] = true
    end
    for name in pairs(readAddedMods()) do modset[name] = true end

    local mods = {}
    for name in pairs(modset) do mods[#mods + 1] = name end
    table.sort(mods)

    local joined = table.concat(mods, ", ")
    local hash = shortId(joined .. "|" .. tostring(icCount))
    if #joined > 350 then joined = joined:sub(1, 347) .. "..." end
    return string.format("-mw v1 ic=%d h=%s mods=%s", icCount, hash, joined), hash
end

local function report()
    local isSrv = true
    pcall(function() isSrv = DCS.isServer() end)
    if isSrv then return end   -- a dedicated server is not a player

    local line, hash = buildReportLine()
    if modreport.sent[hash] then return end
    modreport.sent[hash] = true
    pcall(function() net.send_chat(line, true) end)
    rlog("reported mods to the server: %s", line)
end

local callbacks = {}

function callbacks.onMissionLoadEnd()
    modreport._due = true   -- defer one frame so dcs.log has this session's lines
end

function callbacks.onSimulationFrame()
    if modreport._due then
        modreport._due = false
        pcall(report)
    end
end

DCS.setUserCallbacks(callbacks)
rlog("loaded - will report mods to the server on mission load")
