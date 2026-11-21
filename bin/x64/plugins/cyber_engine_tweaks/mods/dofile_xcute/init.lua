-- dofile Xcute
-- Lists every *.lua in scripts/ (next to this file) and runs it on click.
--
-- CET restricts dofile/dir/io to the mod's own folder (LuaSandbox.cpp),
-- so user scripts live inside this mod, not in cyber_engine_tweaks/scripts.

local SCRIPTS  = "scripts"
local LANGDIR  = "lang"
local SETTINGS = "settings.lua"   -- created at runtime

-- Built-in English: used when a language file is missing, broken or incomplete.
local EN = {
	_name    = "English",
	rescan   = "Rescan",
	count    = "%d script(s)",
	debug    = "Debug output",
	language = "Language",
	none     = "No *.lua in mods/dofile_xcute/%s/",
	ok       = "%s: ok",
	error    = "%s: ERROR %s",
}

local cfg = { debug = true, lang = "en" }
local L = EN              -- active strings
local langs = {}          -- { { id = "de", name = "Deutsch" }, ... }

local scripts = {}        -- file names, sorted
local status = ""         -- result of the last run
local statusIsError = false
local visible = false

local check = true        -- on first show: make sure the window fits its content
local width = 0           -- widest item in the current frame (window-relative)

--- Read a JSON file from the mod folder.
--- @param path string
--- @return table|nil
local function readJson(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	local ok, t = pcall(json.decode, s)
	if ok and type(t) == "table" then return t end
	return nil
end

--- Activate a language; missing keys fall back to English.
--- @param id string file name without .json
local function setLang(id)
	local t = (id ~= "en") and readJson(LANGDIR .. "/" .. id .. ".json") or nil
	L = setmetatable(t or {}, { __index = EN })
	cfg.lang = t and id or "en"
end

--- Collect available languages from lang/*.json (English always included).
local function scanLangs()
	langs = { { id = "en", name = EN._name } }
	for _, e in ipairs(dir(LANGDIR) or {}) do
		local id = e.type == "file" and e.name:match("^(.+)%.json$")
		if id and id ~= "en" then
			local t = readJson(LANGDIR .. "/" .. e.name)
			if t then
				table.insert(langs, { id = id, name = type(t._name) == "string" and t._name or id })
			end
		end
	end
	table.sort(langs, function(a, b) return a.name:lower() < b.name:lower() end)
end

--- Load settings.lua (missing file: defaults).
local function loadSettings()
	local ok, t = pcall(dofile, SETTINGS)
	if ok and type(t) == "table" then
		if type(t.debug) == "boolean" then cfg.debug = t.debug end
		if type(t.lang) == "string" then cfg.lang = t.lang end
	end
end

--- Write settings.lua.
local function saveSettings()
	local f = io.open(SETTINGS, "w")
	if not f then return end
	f:write(string.format("return { debug = %s, lang = %q }\n", tostring(cfg.debug), cfg.lang))
	f:close()
end

--- Re-read the scripts folder.
local function scan()
	scripts = {}
	for _, e in ipairs(dir(SCRIPTS) or {}) do
		if e.type == "file" and e.name:match("%.lua$") then
			table.insert(scripts, e.name)
		end
	end
	table.sort(scripts, function(a, b) return a:lower() < b:lower() end)
end

--- Run one script. Errors are always reported, "ok" only with debug output on.
--- @param name string file name in scripts/
local function run(name)
	local ok, err = pcall(dofile, SCRIPTS .. "/" .. name)
	statusIsError = not ok
	if ok then
		status = string.format(L.ok, name)
		if cfg.debug then print("[dofile Xcute] " .. status) end
	else
		status = string.format(L.error, name, tostring(err))
		print("[dofile Xcute] " .. status)
	end
end

--- Remember the right edge of the last item (only while checking).
local function track()
	if not check then return end
	local x = ImGui.GetItemRectMax()
	local wx = ImGui.GetWindowPos()
	if x - wx > width then width = x - wx end
end

--- End of frame: grow the window if it is smaller than its content.
--- Larger windows are left alone.
local function minSize()
	if not check then return end
	check = false
	local pad = ImGui.GetCursorStartPos()      -- left inner padding
	local needW = width + pad
	local needH = ImGui.GetCursorPosY() + pad  -- content + bottom padding
	local w, h = ImGui.GetWindowSize()
	if w < needW or h < needH then
		ImGui.SetWindowSize(math.max(w, needW), math.max(h, needH))
	end
end

registerForEvent("onInit", function()
	loadSettings()
	setLang(cfg.lang)
	scanLangs()
	scan()
end)
registerForEvent("onOverlayOpen", function() visible = true; scan() end)
registerForEvent("onOverlayClose", function() visible = false end)

registerForEvent("onDraw", function()
	if not visible then return end
	-- fixed title: ImGui identifies the window by it (position/size survive language changes)
	if ImGui.Begin("dofile Xcute") then
		width = 0
		if ImGui.Button(L.rescan .. "##rescan") then scan(); scanLangs() end
		track()
		ImGui.SameLine()
		ImGui.Text(string.format(L.count, #scripts))
		ImGui.SameLine()
		local v, clicked = ImGui.Checkbox(L.debug .. "##debug", cfg.debug)
		if clicked then
			cfg.debug = v
			saveSettings()
		end
		track()

		ImGui.SetNextItemWidth(150)
		if ImGui.BeginCombo(L.language .. "##lang", L._name) then
			for _, lg in ipairs(langs) do
				if ImGui.Selectable(lg.name, lg.id == cfg.lang) then
					setLang(lg.id)
					saveSettings()
					check = true   -- labels changed: re-check minimum size
				end
			end
			ImGui.EndCombo()
		end
		track()

		ImGui.Separator()
		if #scripts == 0 then
			ImGui.TextWrapped(string.format(L.none, SCRIPTS))
		end
		for _, name in ipairs(scripts) do
			if ImGui.Button((name:gsub("%.lua$", ""))) then run(name) end
			track()
		end
		if status ~= "" and (cfg.debug or statusIsError) then
			ImGui.Separator()
			ImGui.TextWrapped(status)
		end
		minSize()
	end
	ImGui.End()
end)
