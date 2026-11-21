-- dofile Xcute
-- Listet alle *.lua in scripts/ (neben dieser Datei) und fuehrt sie per Klick aus.
--
-- CET sperrt dofile/dir/io auf den eigenen Mod-Ordner (LuaSandbox.cpp).
-- Deshalb liegen die Skripte hier im Mod, nicht in cyber_engine_tweaks/scripts.

local ORDNER = "scripts"

local skripte = {}   -- Dateinamen, sortiert
local status = ""    -- Ergebnis des letzten Laufs
local sichtbar = false

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

--- Ein Skript ausfuehren. Fehler landen im Fenster und in der CET-Konsole.
--- @param name string Dateiname in scripts/
local function run(name)
	local ok, err = pcall(dofile, ORDNER .. "/" .. name)
	if ok then
		status = name .. ": ok"
	else
		status = name .. ": FEHLER " .. tostring(err)
	end
	print("[dofile Xcute] " .. status)
end

registerForEvent("onInit", scan)
registerForEvent("onOverlayOpen", function() sichtbar = true; scan() end)
registerForEvent("onOverlayClose", function() sichtbar = false end)

registerForEvent("onDraw", function()
	if not sichtbar then return end
	if ImGui.Begin("dofile Xcute") then
		if ImGui.Button("Neu einlesen") then scan() end
		ImGui.SameLine()
		ImGui.Text(#skripte .. " Skript(e)")
		ImGui.Separator()
		if #skripte == 0 then
			ImGui.TextWrapped("Keine *.lua in mods/dofile_xcute/" .. ORDNER .. "/")
		end
		for _, name in ipairs(skripte) do
			if ImGui.Button((name:gsub("%.lua$", ""))) then run(name) end
		end
		if status ~= "" then
			ImGui.Separator()
			ImGui.TextWrapped(status)
		end
	end
	ImGui.End()
end)
