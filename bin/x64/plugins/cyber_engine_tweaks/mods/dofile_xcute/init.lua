-- dofile Xcute
-- Lists every *.lua in scripts/ (next to this file), runs it on click and
-- offers a small editor for new and existing scripts.
--
-- CET restricts dofile/dir/io/os.rename/os.remove to the mod's own folder
-- (LuaSandbox.cpp), so user scripts live inside this mod and the editor
-- cannot touch anything outside of it.

local SCRIPTS  = "scripts"
local LANGDIR  = "lang"
local SETTINGS = "settings.lua"   -- created at runtime
local MINBUF   = 65536            -- editor buffer; CET truncates text to this size

-- Built-in English: used when a language file is missing, broken or incomplete.
local EN = {
	_name         = "English",
	rescan        = "Rescan",
	new           = "New",
	count         = "%d script(s)",
	debug         = "Debug output",
	language      = "Language",
	none          = "No *.lua in mods/dofile_xcute/%s/",
	ok            = "%s: ok",
	error         = "%s: ERROR %s",
	edit          = "Edit",
	file          = "File name",
	save          = "Save",
	saveRun       = "Save & run",
	paste         = "Paste clipboard",
	delete        = "Delete",
	close         = "Close",
	yes           = "Yes",
	no            = "No",
	confirmDelete = "Delete %s for good?",
	confirmClose  = "Discard unsaved changes?",
	confirmPaste  = "Replace the whole text with the clipboard?",
	unsaved       = "unsaved",
	saved         = "Saved: %s",
	syntax        = "Saved, but syntax error: %s",
	errName       = "Invalid file name (letters, digits, space, - _ . only)",
	errExists     = "%s already exists",
	errWrite      = "Could not write %s",
	errRename     = "Could not rename: %s",
	errDelete     = "Could not delete: %s",
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

-- editor state
local ed = {
	open    = false,
	orig    = nil,   -- file name on disk, nil for a new script
	name    = "",    -- name in the input field (without .lua)
	text    = "",
	dirty   = false,
	msg     = "",
	msgErr  = false,
	confirm = nil,   -- "delete" | "close" | "paste"
}

--- Read a whole file from the mod folder.
--- @param path string
--- @return string|nil
local function readFile(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	return s
end

--- Write a whole file into the mod folder.
--- @param path string
--- @param s string
--- @return boolean
local function writeFile(path, s)
	local f = io.open(path, "w")
	if not f then return false end
	f:write(s)
	f:close()
	return true
end

--- Read a JSON file from the mod folder.
--- @param path string
--- @return table|nil
local function readJson(path)
	local s = readFile(path)
	if not s then return nil end
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
	writeFile(SETTINGS, string.format("return { debug = %s, lang = %q }\n", tostring(cfg.debug), cfg.lang))
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

-- ── editor ───────────────────────────────────────────────────────────────────

--- Open the editor for an existing script, or for a new one (name = nil).
--- @param name string|nil file name in scripts/
local function edOpen(name)
	ed.open, ed.orig, ed.dirty, ed.msg, ed.msgErr, ed.confirm = true, name, false, "", false, nil
	if name then
		ed.name = name:gsub("%.lua$", "")
		ed.text = (readFile(SCRIPTS .. "/" .. name) or ""):gsub("\r\n", "\n")
	else
		ed.name, ed.text = "", ""
	end
end

--- @param s string
--- @param isErr boolean|nil
local function edMsg(s, isErr)
	ed.msg, ed.msgErr = s, isErr and true or false
end

--- Save (and rename, if the name changed). Saves even with syntax errors,
--- so work in progress is never lost; the error is shown instead.
--- @return string|nil file name on success
local function edSave()
	local n = ed.name:match("^%s*(.-)%s*$"):gsub("%.lua$", "")
	if n == "" or not n:match("^[%w%-_%. ]+$") or n:match("^%.") then
		edMsg(L.errName, true)
		return nil
	end
	local file = n .. ".lua"
	local renamed = ed.orig and ed.orig ~= file
	if (not ed.orig or renamed) and file:lower() ~= (ed.orig or ""):lower()
		and readFile(SCRIPTS .. "/" .. file) then
		edMsg(string.format(L.errExists, file), true)
		return nil
	end

	-- write to the current file first, then rename: content is safe either way
	local target = ed.orig or file
	if not writeFile(SCRIPTS .. "/" .. target, ed.text) then
		edMsg(string.format(L.errWrite, target), true)
		return nil
	end
	if renamed then
		local ok, err = os.rename(SCRIPTS .. "/" .. ed.orig, SCRIPTS .. "/" .. file)
		if not ok then
			edMsg(string.format(L.errRename, tostring(err)), true)
			return nil
		end
	end

	ed.orig, ed.name, ed.dirty = file, n, false
	scan()

	local fn, err = loadstring(ed.text, "@" .. file)
	if fn then
		edMsg(string.format(L.saved, file))
	else
		edMsg(string.format(L.syntax, tostring(err)), true)
	end
	return file
end

--- Delete the edited script and close the editor.
local function edDelete()
	if ed.orig then
		local ok, err = os.remove(SCRIPTS .. "/" .. ed.orig)
		if not ok then
			edMsg(string.format(L.errDelete, tostring(err)), true)
			return
		end
		scan()
	end
	ed.open = false
end

--- Draw the editor window.
local function edDraw()
	ImGui.SetNextWindowSize(640, 480, ImGuiCond.FirstUseEver)
	if ImGui.Begin("dofile Xcute - Editor") then
		ImGui.SetNextItemWidth(250)
		local n, changed = ImGui.InputText(L.file .. "##edname", ed.name, 128)
		if changed then ed.name, ed.dirty = n, true end
		ImGui.SameLine()
		ImGui.Text(".lua")

		if ImGui.Button(L.save .. "##edsave") then edSave() end
		ImGui.SameLine()
		if ImGui.Button(L.saveRun .. "##edrun") then
			local file = edSave()
			if file then run(file) end
		end
		ImGui.SameLine()
		if ImGui.Button(L.paste .. "##edpaste") then
			if ed.text == "" then
				ed.text, ed.dirty = ImGui.GetClipboardText() or "", true
			else
				ed.confirm = "paste"
			end
		end
		ImGui.SameLine()
		if ImGui.Button(L.delete .. "##eddel") then ed.confirm = "delete" end
		ImGui.SameLine()
		if ImGui.Button(L.close .. "##edclose") then
			if ed.dirty then ed.confirm = "close" else ed.open = false end
		end

		-- confirmation line
		if ed.confirm then
			local q = ed.confirm == "delete" and string.format(L.confirmDelete, ed.orig or ed.name)
				or ed.confirm == "close" and L.confirmClose
				or L.confirmPaste
			ImGui.Text(q)
			ImGui.SameLine()
			if ImGui.Button(L.yes .. "##edyes") then
				if ed.confirm == "delete" then edDelete()
				elseif ed.confirm == "close" then ed.open = false
				else ed.text, ed.dirty = ImGui.GetClipboardText() or "", true end
				ed.confirm = nil
			end
			ImGui.SameLine()
			if ImGui.Button(L.no .. "##edno") then ed.confirm = nil end
		end

		-- status line
		local line = ed.msg
		if ed.dirty then line = "* " .. L.unsaved .. (line ~= "" and "  |  " .. line or "") end
		if line ~= "" then
			if ed.msgErr then
				ImGui.PushStyleColor(ImGuiCol.Text, 1, 0.4, 0.4, 1)
				ImGui.TextWrapped(line)
				ImGui.PopStyleColor()
			else
				ImGui.TextWrapped(line)
			end
		end

		-- the code itself; buffer always well above the text length
		local buf = math.max(MINBUF, #ed.text * 2)
		local t, edited = ImGui.InputTextMultiline("##edtext", ed.text, buf, -1, -1, ImGuiInputTextFlags.AllowTabInput)
		if edited then ed.text, ed.dirty = t, true end
	end
	ImGui.End()
end

-- ── main window ──────────────────────────────────────────────────────────────

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
		ImGui.SameLine()
		if ImGui.Button(L.new .. "##new") then edOpen(nil) end
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
			if ImGui.Button(IconGlyphs.Pencil .. "##e_" .. name) then edOpen(name) end
			if ImGui.IsItemHovered() then ImGui.SetTooltip(L.edit) end
			ImGui.SameLine()
			if ImGui.Button((name:gsub("%.lua$", "")) .. "##r_" .. name) then run(name) end
			track()
		end
		if status ~= "" and (cfg.debug or statusIsError) then
			ImGui.Separator()
			ImGui.TextWrapped(status)
		end
		minSize()
	end
	ImGui.End()

	if ed.open then edDraw() end
end)
