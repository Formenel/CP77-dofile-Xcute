-- dofile Xcute
-- Listet alle *.lua in scripts/ (neben dieser Datei) und fuehrt sie per Klick aus.
--
-- CET sperrt dofile/dir/io auf den eigenen Mod-Ordner (LuaSandbox.cpp).
-- Deshalb liegen die Skripte hier im Mod, nicht in cyber_engine_tweaks/scripts.

local ORDNER = "scripts"
local SETTINGS = "settings.lua"   -- wird zur Laufzeit angelegt

local skripte = {}   -- Dateinamen, sortiert
local status = ""    -- Ergebnis des letzten Laufs
local sichtbar = false
local cfg = { debug = true }

--- Einstellungen aus settings.lua lesen (fehlt die Datei: Standardwerte).
local function cfgLaden()
	local ok, t = pcall(dofile, SETTINGS)
	if ok and type(t) == "table" and type(t.debug) == "boolean" then
		cfg.debug = t.debug
	end
end

--- Einstellungen nach settings.lua schreiben.
local function cfgSpeichern()
	local f = io.open(SETTINGS, "w")
	if not f then return end
	f:write("return { debug = " .. tostring(cfg.debug) .. " }\n")
	f:close()
end

--- Ordner neu einlesen.
local function scan()
	skripte = {}
	for _, e in ipairs(dir(ORDNER) or {}) do
		if e.type == "file" and e.name:match("%.lua$") then
			table.insert(skripte, e.name)
		end
	end
	table.sort(skripte, function(a, b) return a:lower() < b:lower() end)
end

--- Ein Skript ausfuehren. Fehler werden immer gemeldet, "ok" nur mit Debug.
--- @param name string Dateiname in scripts/
local function run(name)
	local ok, err = pcall(dofile, ORDNER .. "/" .. name)
	if ok then
		status = name .. ": ok"
		if cfg.debug then print("[dofile Xcute] " .. status) end
	else
		status = name .. ": FEHLER " .. tostring(err)
		print("[dofile Xcute] " .. status)
	end
end

registerForEvent("onInit", function() cfgLaden(); scan() end)
registerForEvent("onOverlayOpen", function() sichtbar = true; scan() end)
registerForEvent("onOverlayClose", function() sichtbar = false end)

registerForEvent("onDraw", function()
	if not sichtbar then return end
	if ImGui.Begin("dofile Xcute") then
		if ImGui.Button("Neu einlesen") then scan() end
		ImGui.SameLine()
		ImGui.Text(#skripte .. " Skript(e)")
		ImGui.SameLine()
		local neu, geklickt = ImGui.Checkbox("Debug-Ausgabe", cfg.debug)
		if geklickt then
			cfg.debug = neu
			cfgSpeichern()
		end
		ImGui.Separator()
		if #skripte == 0 then
			ImGui.TextWrapped("Keine *.lua in mods/dofile_xcute/" .. ORDNER .. "/")
		end
		for _, name in ipairs(skripte) do
			if ImGui.Button((name:gsub("%.lua$", ""))) then run(name) end
		end
		if status ~= "" and (cfg.debug or status:find(": FEHLER ", 1, true)) then
			ImGui.Separator()
			ImGui.TextWrapped(status)
		end
	end
	ImGui.End()
end)
