local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    return
end

local core = addon._core or {}
local defaults = core.defaults or {}
local addonName = core.addonName or "SimpleUnitFrames"
local ICON_PATH = core.ICON_PATH or "Interface\\Icons\\INV_Misc_QuestionMark"
local CopyTableDeep = core.CopyTableDeep
local MergeDefaults = core.MergeDefaults
local UNIT_TYPE_ORDER = core.UNIT_TYPE_ORDER or { "player", "target", "tot", "focus", "pet", "party", "raid", "boss" }
local DEFAULT_UNIT_CASTBAR = core.DEFAULT_UNIT_CASTBAR or {}
local DEFAULT_UNIT_LAYOUT = core.DEFAULT_UNIT_LAYOUT or {}
local DEFAULT_UNIT_MAIN_BARS_BACKGROUND = core.DEFAULT_UNIT_MAIN_BARS_BACKGROUND or {}
local DEFAULT_HEAL_PREDICTION = core.DEFAULT_HEAL_PREDICTION or {}
local function SafeText(value, fallback)
    if value == nil then
        return fallback
    end
    local ok, text = pcall(tostring, value)
    if not ok or text == nil then
        return fallback
    end
    return text
end
local function TrimString(value)
    if type(value) ~= "string" then
        return ""
    end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

if type(CopyTableDeep) ~= "function" then
    CopyTableDeep = function(source)
        local copy = {}
        for key, value in pairs(source or {}) do
            copy[key] = (type(value) == "table") and CopyTableDeep(value) or value
        end
        return copy
    end
end

if type(MergeDefaults) ~= "function" then
    MergeDefaults = function(target, defaultsTable)
        if type(target) ~= "table" or type(defaultsTable) ~= "table" then
            return
        end
        for key, value in pairs(defaultsTable) do
            if target[key] == nil then
                target[key] = type(value) == "table" and CopyTableDeep(value) or value
            elseif type(value) == "table" and type(target[key]) == "table" then
                MergeDefaults(target[key], value)
            end
        end
    end
end

function addon:ShowOptions()
	local UI_STYLE = (self.GetOptionsUIStyle and self:GetOptionsUIStyle()) or {
		windowBg = { 0.03, 0.04, 0.05, 0.96 },
		windowBorder = { 0.34, 0.29, 0.15, 0.90 },
		panelBg = { 0.05, 0.06, 0.07, 0.92 },
		panelBorder = { 0.23, 0.21, 0.15, 0.92 },
		accent = { 0.96, 0.82, 0.24 },
		accentSoft = { 0.72, 0.64, 0.32 },
		textMuted = { 0.72, 0.74, 0.78 },
		searchBg = { 0.08, 0.09, 0.11, 0.95 },
		searchBorder = { 0.34, 0.30, 0.18, 0.96 },
		navDefault = { 0.08, 0.08, 0.08, 0.88 },
		navDefaultBorder = { 0.18, 0.18, 0.18, 0.95 },
		navHover = { 0.12, 0.13, 0.16, 0.92 },
		navHoverBorder = { 0.34, 0.31, 0.22, 0.95 },
		navSelected = { 0.12, 0.36, 0.58, 0.95 },
		navSelectedBorder = { 0.28, 0.60, 0.88, 0.95 },
		navSearch = { 0.10, 0.14, 0.10, 0.92 },
		navSearchBorder = { 0.20, 0.30, 0.20, 0.92 },
	}
	local function ClampOptionsHeight(frame)
		if not frame then
			return
		end
		local maxHeightCap = math.max(500, math.floor(UIParent:GetHeight() * 0.65))
		local minHeight = 500
		local height = frame:GetHeight()
		local clampedHeight = math.max(minHeight, math.min(height, maxHeightCap))
		if clampedHeight ~= height then
			frame:SetHeight(clampedHeight)
		end
		if frame.SetResizeBounds then
			frame:SetResizeBounds(940, minHeight, UIParent:GetWidth() - 40, maxHeightCap)
		else
			if frame.SetMinResize then
				frame:SetMinResize(940, minHeight)
			end
			if frame.SetMaxResize then
				frame:SetMaxResize(UIParent:GetWidth() - 40, maxHeightCap)
			end
		end
	end

	if self.optionsFrame then
		ClampOptionsHeight(self.optionsFrame)
		self:PrepareWindowForDisplay(self.optionsFrame)
		self.optionsFrame:Show()
		self:PlayWindowOpenAnimation(self.optionsFrame)
		if self.optionsFrame.BuildTab then
			self.optionsFrame:BuildTab(self.optionsFrame.currentTab or "global")
		end
		return
	end

	local frame = CreateFrame("Frame", "SUFOptionsWindow", UIParent, "BasicFrameTemplateWithInset")
	local maxHeightCap = math.max(500, math.floor(UIParent:GetHeight() * 0.65))
	local initialHeight = math.min(620, maxHeightCap)
	frame:SetSize(1240, initialHeight)
	frame:SetPoint("CENTER")
	self:EnableMovableFrame(frame, true, "options_window", { "CENTER", "UIParent", "CENTER", 0, 0 })
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(940, 560, UIParent:GetWidth() - 40, maxHeightCap)
	else
		if frame.SetMinResize then
			frame:SetMinResize(940, 560)
		end
		if frame.SetMaxResize then
			frame:SetMaxResize(UIParent:GetWidth() - 40, maxHeightCap)
		end
	end
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame.TitleText:SetText("SimpleUnitFrames Options")
	frame.TitleText:SetFontObject("GameFontNormalLarge")
	frame.TitleText:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
	self:ApplySUFBackdropColors(frame, UI_STYLE.windowBg, UI_STYLE.windowBorder, true)

	local close = frame.CloseButton
	if not close then
		close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	end
	close:SetScript("OnClick", function()
		self:SetTestMode(false)
		frame:Hide()
	end)

	local okResize, resize = pcall(CreateFrame, "Button", nil, frame, "UIPanelResizeButtonTemplate")
	if not okResize or not resize then
		resize = CreateFrame("Button", nil, frame)
		resize:SetSize(16, 16)
		resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	end
	resize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
	resize:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then
			frame:StartSizing("BOTTOMRIGHT")
		end
	end)
	resize:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" then
			frame:StopMovingOrSizing()
		end
	end)

	local tabsHost = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	tabsHost:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
	tabsHost:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 14)
	tabsHost:SetWidth(240)
	self:ApplySUFBackdropColors(tabsHost, UI_STYLE.panelBg, UI_STYLE.panelBorder, true)
	tabsHost:Show()

	local iconSize = 96
	local icon = tabsHost:CreateTexture(nil, "ARTWORK")
	icon:SetSize(iconSize, iconSize)
	icon:SetPoint("TOP", tabsHost, "TOP", 0, -14)
	icon:SetTexture(ICON_PATH)
	icon:SetTexCoord(0, 1, 0, 1)
	icon:SetVertexColor(1, 1, 1, 1)

	local contentHost = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	contentHost:SetPoint("TOPLEFT", tabsHost, "TOPRIGHT", 8, 0)
	contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 14)
	self:ApplySUFBackdropColors(contentHost, UI_STYLE.panelBg, UI_STYLE.panelBorder, true)
	contentHost:Show()

	local searchLabel = contentHost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	searchLabel:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 12, -10)
	searchLabel:SetText("Search")
	searchLabel:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])

	local searchBox = CreateFrame("EditBox", nil, contentHost, "InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetSize(280, 22)
	searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
	self:ApplySUFBackdropColors(searchBox, UI_STYLE.searchBg, UI_STYLE.searchBorder, true)
	searchBox:SetScript("OnEscapePressed", function(box)
		box:ClearFocus()
	end)
	local searchHint = contentHost:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	searchHint:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
	searchHint:SetText("Alt+Up/Down: navigate  Enter: open")
	searchHint:SetShown(self.db.profile.optionsUI and self.db.profile.optionsUI.searchKeyboardHints ~= false)

	local searchDivider = contentHost:CreateTexture(nil, "BORDER")
	searchDivider:SetColorTexture(UI_STYLE.accentSoft[1], UI_STYLE.accentSoft[2], UI_STYLE.accentSoft[3], 0.45)
	searchDivider:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 10, -32)
	searchDivider:SetPoint("TOPRIGHT", contentHost, "TOPRIGHT", -10, -32)
	searchDivider:SetHeight(1)

	local scroll = CreateFrame("ScrollFrame", nil, contentHost, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 8, -34)
	scroll:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -28, 8)
	scroll:Show()
	
	-- Style content scrollbar with theme colors
	if scroll.ScrollBar then
		local scrollBar = scroll.ScrollBar
		if scrollBar.ThumbTexture then
			scrollBar.ThumbTexture:SetVertexColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3], 0.8)
		end
		-- ScrollUpButton/ScrollDownButton don't support SetBackdropColor, skip styling
	end
	
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(920, 200)
	scroll:SetScrollChild(content)
	content:Show()

	local tabs = {
		{ key = "global", label = "Global" },
		{ key = "performance", label = "PerformanceLib" },
		{ key = "importexport", label = "Import / Export" },
		{ key = "tags", label = "Tags" },
		{ key = "player", label = "Player" },
		{ key = "target", label = "Target" },
		{ key = "tot", label = "TargetOfTarget" },
		{ key = "focus", label = "Focus" },
		{ key = "pet", label = "Pet" },
		{ key = "party", label = "Party" },
		{ key = "raid", label = "Raid" },
		{ key = "boss", label = "Boss" },
		{ key = "credits", label = "Credits" },
	}
	local sidebarGroups = {
		{
			key = "grp_general",
			label = "General",
			items = { "global", "performance", "importexport", "tags", "credits" },
		},
		{
			key = "grp_units",
			label = "Units",
			items = { "player", "target", "tot", "focus", "pet", "party", "raid", "boss" },
		},
	}
	local tabIndexByKey = {}
	for i = 1, #tabs do
		tabIndexByKey[tabs[i].key] = tabs[i]
	end
	local unitTabLookup = {}
	for i = 1, #UNIT_TYPE_ORDER do
		unitTabLookup[UNIT_TYPE_ORDER[i]] = true
	end
	local UNIT_SECTION_NAV = (self.GetOptionsUnitSectionNav and self:GetOptionsUnitSectionNav()) or {}
	local OPTIONS_SEARCH_SCHEMA_VERSION = 2
	local TAB_SEARCH_HINTS = {
		global = "global media statusbar font visibility indicators castbar plugins fader party minimap",
		performance = "performance perflib profiler analyze profile coalescing eventbus dirty pools preset dashboard",
		importexport = "import export wizard profile copy paste validate preview apply",
		tags = "tags ouf name level health power format token",
		player = "player general bars castbar auras plugins advanced portrait heal prediction",
		target = "target general bars castbar auras plugins advanced portrait heal prediction",
		tot = "targetoftarget tot general bars castbar auras plugins advanced portrait heal prediction",
		focus = "focus general bars castbar auras plugins advanced portrait heal prediction",
		pet = "pet general bars castbar auras plugins advanced portrait heal prediction",
		party = "party general bars castbar auras plugins advanced fader aurawatch raiddebuffs",
		raid = "raid general bars castbar auras plugins advanced fader aurawatch raiddebuffs",
		boss = "boss general bars castbar auras plugins advanced portrait heal prediction",
		credits = "credits libraries thanks authors uuf performancelib ace3",
	}
	local OPTIONS_SEARCH_TREE = {
		global = {
			{ label = "Global", aliases = { "settings", "defaults" }, children = {
				{ label = "Media", aliases = { "texture", "font", "statusbar" } },
				{ label = "Castbar", aliases = { "cast", "safe zone", "spark", "shield" } },
				{ label = "Performance", aliases = { "perflib", "preset", "coalescing", "eventbus" } },
				{ label = "Debug", aliases = { "sufdebug", "console", "export logs" } },
			}},
		},
		importexport = {
			{ label = "Import / Export", aliases = { "profile", "paste", "copy", "validate", "preview" } },
		},
		performance = {
			{ label = "PerformanceLib", aliases = { "preset", "profile start", "profile stop", "analyze", "dashboard" } },
		},
		tags = {
			{ label = "Tags", aliases = { "ouf tags", "health tags", "power tags", "cast tags" } },
		},
		player = {
			{ label = "General", aliases = { "name", "level", "portrait", "size" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs" } },
			{ label = "Advanced", aliases = { "layout", "anchor", "offset", "profile copy" } },
		},
		target = {
			{ label = "General", aliases = { "name", "level", "portrait", "size" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs" } },
			{ label = "Advanced", aliases = { "layout", "anchor", "offset", "profile copy" } },
		},
		tot = {
			{ label = "General", aliases = { "name", "level", "portrait", "size" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs", "none" } },
			{ label = "Advanced", aliases = { "layout", "anchor", "offset", "profile copy" } },
		},
		focus = {
			{ label = "General", aliases = { "name", "level", "portrait", "size" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs", "none" } },
			{ label = "Advanced", aliases = { "layout", "anchor", "offset", "profile copy" } },
		},
		pet = {
			{ label = "General", aliases = { "name", "level", "portrait", "size" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs", "none" } },
			{ label = "Advanced", aliases = { "layout", "anchor", "offset", "profile copy" } },
		},
		party = {
			{ label = "General", aliases = { "show player", "spacing", "layout" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency", "not shown" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing", "heal prediction" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs" } },
			{ label = "Advanced", aliases = { "visibility", "vehicle", "pet battle" } },
		},
		raid = {
			{ label = "General", aliases = { "group", "layout", "spacing" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency", "not shown" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing", "heal prediction" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs" } },
			{ label = "Advanced", aliases = { "visibility", "vehicle", "pet battle" } },
		},
		boss = {
			{ label = "General", aliases = { "name", "level", "portrait", "size" } },
			{ label = "Bars", aliases = { "health", "power", "absorb", "incoming heals" } },
			{ label = "Castbar", aliases = { "spell", "time", "interrupt", "latency" } },
			{ label = "Auras", aliases = { "buffs", "debuffs", "icons", "spacing" } },
			{ label = "Plugins", aliases = { "fader", "aurawatch", "raiddebuffs", "none" } },
			{ label = "Advanced", aliases = { "layout", "anchor", "offset", "profile copy" } },
		},
		credits = {
			{ label = "Credits", aliases = { "authors", "libraries", "uuf", "ace3", "oUF", "performancelib" } },
		},
	}
	local function TokenizeSearch(searchText)
		local out = {}
		local normalized = string.lower(TrimString(SafeText(searchText, "")))
		if normalized == "" then
			return out
		end
		for token in normalized:gmatch("[^%s]+") do
			if token ~= "" then
				out[#out + 1] = token
			end
		end
		return out
	end
	local function BuildOptionsSearchFingerprint()
		local pieces = { tostring(OPTIONS_SEARCH_SCHEMA_VERSION), tostring(#tabs) }
		for i = 1, #tabs do
			local t = tabs[i]
			pieces[#pieces + 1] = tostring(t.key) .. ":" .. tostring(t.label) .. ":" .. tostring(TAB_SEARCH_HINTS[t.key] or "")
		end
		local function AddTreeNode(node)
			if type(node) ~= "table" then
				return
			end
			pieces[#pieces + 1] = tostring(node.label or "")
			local aliases = node.aliases or node.values
			if type(aliases) == "table" then
				for i = 1, #aliases do
					pieces[#pieces + 1] = tostring(aliases[i])
				end
			end
			local children = node.children
			if type(children) == "table" then
				for i = 1, #children do
					AddTreeNode(children[i])
				end
			end
		end
		for _, nodes in pairs(OPTIONS_SEARCH_TREE) do
			if type(nodes) == "table" then
				for i = 1, #nodes do
					AddTreeNode(nodes[i])
				end
			end
		end
		return table.concat(pieces, "|")
	end
	local function AddOptionsSearchEntry(cache, tabKey, tabLabel, label, keywords, section)
		local text = TrimString(SafeText(label, ""))
		local words = TrimString(SafeText(keywords, ""))
		if text == "" and words == "" then
			return
		end
		local dedupe = string.lower(tostring(tabKey) .. "|" .. text .. "|" .. words .. "|" .. tostring(section or "control"))
		if cache.seen[dedupe] then
			return
		end
		cache.seen[dedupe] = true
		cache.entriesByTab[tabKey] = cache.entriesByTab[tabKey] or {}
		local entry = {
			tabKey = tabKey,
			tabLabel = tabLabel,
			label = text ~= "" and text or tabLabel,
			keywords = words,
			section = section or "control",
			haystack = string.lower(table.concat({ tabLabel, text, words }, " ")),
			tabLower = string.lower(tostring(tabLabel or "")),
			labelLower = string.lower(tostring(text ~= "" and text or tabLabel)),
			keywordsLower = string.lower(tostring(words)),
		}
		cache.entries[#cache.entries + 1] = entry
		cache.entriesByTab[tabKey][#cache.entriesByTab[tabKey] + 1] = entry
	end
	local function IndexOptionsSearchNodes(cache, tabKey, tabLabel, nodes, trail)
		if type(nodes) ~= "table" then
			return
		end
		local baseTrail = trail or tabLabel or tostring(tabKey)
		for i = 1, #nodes do
			local node = nodes[i]
			if type(node) == "table" then
				local label = TrimString(SafeText(node.label, ""))
				local aliases = {}
				local aliasList = node.aliases or node.values
				if type(aliasList) == "table" then
					for j = 1, #aliasList do
						aliases[#aliases + 1] = tostring(aliasList[j])
					end
				end
				local keywords = table.concat(aliases, " ")
				local path = baseTrail
				if label ~= "" then
					path = baseTrail .. " " .. label
				end
				AddOptionsSearchEntry(cache, tabKey, tabLabel, label, table.concat({ keywords, path }, " "), "schema")
				if type(node.children) == "table" then
					IndexOptionsSearchNodes(cache, tabKey, tabLabel, node.children, path)
				end
			end
		end
	end
	local function EnsureOptionsSearchIndex()
		local fingerprint = BuildOptionsSearchFingerprint()
		local cache = frame.optionsSearchIndex
		if cache and cache.fingerprint == fingerprint and cache.schemaVersion == OPTIONS_SEARCH_SCHEMA_VERSION then
			return cache
		end
		cache = {
			schemaVersion = OPTIONS_SEARCH_SCHEMA_VERSION,
			fingerprint = fingerprint,
			entries = {},
			entriesByTab = {},
			seen = {},
			tabLabels = {},
		}
		for i = 1, #tabs do
			local t = tabs[i]
			cache.tabLabels[t.key] = t.label or t.key
			cache.entriesByTab[t.key] = cache.entriesByTab[t.key] or {}
			local label = tostring(t.label or t.key)
			local keywords = tostring(TAB_SEARCH_HINTS[t.key] or "")
			AddOptionsSearchEntry(cache, t.key, label, label, keywords, "tab")
			IndexOptionsSearchNodes(cache, t.key, label, OPTIONS_SEARCH_TREE[t.key], label)
		end
		frame.optionsSearchIndex = cache
		return cache
	end
	local function RegisterOptionsSearchEntry(tabKey, label, keywords, section)
		if not tabKey then
			return
		end
		local cache = EnsureOptionsSearchIndex()
		local tabLabel = cache.tabLabels[tabKey] or tostring(tabKey)
		AddOptionsSearchEntry(cache, tabKey, tabLabel, label, keywords, section or "control")
	end
	local function ScoreSearchEntry(entry, normalizedSearch, tokens)
		if not entry or not entry.haystack then
			return 0
		end
		if #tokens == 0 then
			return 0
		end
		local score = 0
		for i = 1, #tokens do
			local token = tokens[i]
			local tokenScore = 0
			local startPos = 1
			local tokenMatched = false
			while true do
				local s, e = entry.haystack:find(token, startPos, true)
				if not s then
					break
				end
				tokenMatched = true
				tokenScore = tokenScore + ((s <= #(entry.tabLabel or "")) and 3 or 1)
				startPos = e + 1
			end
			if not tokenMatched then
				return 0
			end
			if entry.labelLower == token then
				tokenScore = tokenScore + 10
			elseif entry.labelLower:find(token, 1, true) == 1 then
				tokenScore = tokenScore + 6
			elseif entry.keywordsLower:find(token, 1, true) == 1 then
				tokenScore = tokenScore + 3
			elseif entry.tabLower:find(token, 1, true) == 1 then
				tokenScore = tokenScore + 4
			end
			score = score + tokenScore
		end
		if string.lower(entry.label or "") == normalizedSearch then
			score = score + 6
		end
		return score
	end
	local function QueryOptionsSearch(searchText)
		local normalized = string.lower(TrimString(SafeText(searchText, "")))
		if normalized == "" then
			return {}
		end
		local cache = EnsureOptionsSearchIndex()
		local tokens = TokenizeSearch(normalized)
		local grouped = {}
		for i = 1, #cache.entries do
			local entry = cache.entries[i]
			local score = ScoreSearchEntry(entry, normalized, tokens)
			if score > 0 then
				local group = grouped[entry.tabKey]
				if not group then
					group = {
						tabKey = entry.tabKey,
						tabLabel = entry.tabLabel,
						score = 0,
						hits = {},
					}
					grouped[entry.tabKey] = group
				end
				group.score = math.max(group.score, score)
				group.hits[#group.hits + 1] = { label = entry.label, section = entry.section, score = score }
			end
		end
		local out = {}
		for _, group in pairs(grouped) do
			table.sort(group.hits, function(a, b)
				if a.score == b.score then
					return tostring(a.label) < tostring(b.label)
				end
				return a.score > b.score
			end)
			out[#out + 1] = group
		end
		table.sort(out, function(a, b)
			if a.score == b.score then
				return tostring(a.tabLabel) < tostring(b.tabLabel)
			end
			return a.score > b.score
		end)
		return out
	end
	local function DoesTabMatchSearch(tabKey, searchText)
		local normalized = string.lower(TrimString(SafeText(searchText, "")))
		if normalized == "" then
			return true
		end
		local groups = QueryOptionsSearch(normalized)
		for i = 1, #groups do
			if groups[i].tabKey == tabKey then
				return true
			end
		end
		return false
	end

	local tabButtons = {}
	local function StopPerformanceSnapshotTicker()
		if frame and frame.performanceSnapshotTicker then
			frame.performanceSnapshotTicker:Cancel()
			frame.performanceSnapshotTicker = nil
		end
		if frame then
			frame.performanceSnapshotText = nil
			frame.performanceSnapshotPage = nil
			frame.performanceBuildSnapshotText = nil
		end
	end
	local function ClearContent()
		for _, child in ipairs({ content:GetChildren() }) do
			child:Hide()
			child:SetParent(nil)
		end
	end

	local function NewBuilder(page, tabKey)
		local builder = {
			addon = self,
			page = page,
			y = -16,
			width = math.max(760, contentHost:GetWidth() - 52),
			colGap = 24,
			col = 1,
			rowHeight = 0,
			search = "",
			searchLower = "",
		}
		builder.colWidth = math.max(280, math.floor((builder.width - builder.colGap) / 2))

		function builder:SetSearch(searchText)
			self.search = TrimString(SafeText(searchText, ""))
			self.searchLower = string.lower(self.search or "")
		end

		function builder:HasSearch()
			return self.searchLower ~= ""
		end

		function builder:Matches(label, keywords)
			if not self:HasSearch() then
				return true
			end
			local haystack = tostring(label or "")
			if keywords then
				haystack = haystack .. " " .. tostring(keywords)
			end
			haystack = string.lower(haystack)
			return haystack:find(self.searchLower, 1, true) ~= nil
		end

		function builder:BeginNewLine()
			if self.col == 2 then
				self.col = 1
				self.y = self.y - self.rowHeight
				self.rowHeight = 0
			end
		end

		function builder:Reserve(height, span)
			if span then
				self:BeginNewLine()
				local x, y = 12, self.y
				self.y = self.y - height
				return x, y, self.width
			end

			local x = 12 + ((self.col - 1) * (self.colWidth + self.colGap))
			local y = self.y
			self.rowHeight = math.max(self.rowHeight, height)
			if self.col == 1 then
				self.col = 2
			else
				self.col = 1
				self.y = self.y - self.rowHeight
				self.rowHeight = 0
			end
			return x, y, self.colWidth
		end

		function builder:Label(text, large)
			RegisterOptionsSearchEntry(tabKey, text, "label section group heading", "label")
			if not self:Matches(text, "label section group heading") then
				return
			end
			self:BeginNewLine()
			if not large and self.y < -24 then
				local divider = self.page:CreateTexture(nil, "BORDER")
				divider:SetColorTexture(UI_STYLE.accentSoft[1], UI_STYLE.accentSoft[2], UI_STYLE.accentSoft[3], 0.25)
				divider:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y + 6)
				divider:SetSize(self.width, 1)
			end
			local fs = self.page:CreateFontString(nil, "OVERLAY", large and "GameFontNormalLarge" or "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			fs:SetText(text)
			if self:HasSearch() then
				fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			elseif large then
				fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			else
				fs:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
			end
			self.y = self.y - (large and 26 or 18)
		end

		function builder:Edit(label, getter, setter, disabled)
			RegisterOptionsSearchEntry(tabKey, label, "edit text input tag", "edit")
			if not self:Matches(label, "edit text input tag") then
				return
			end
			local x, y, width = self:Reserve(56, false)
			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			fs:SetText(label)
			if self:HasSearch() then
				fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			else
				fs:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
			end
			local eb = CreateFrame("EditBox", nil, self.page, "InputBoxTemplate")
			eb:SetAutoFocus(false)
			eb:SetSize(width, 22)
			eb:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y - 20)
			eb:SetText(tostring(getter() or ""))
			eb:SetEnabled(not disabled)
			eb:SetScript("OnEnterPressed", function(w)
				if disabled then
					w:ClearFocus()
					return
				end
				setter(w:GetText())
				w:ClearFocus()
			end)
			eb:SetScript("OnEscapePressed", function(w)
				w:ClearFocus()
			end)
		end

		function builder:Slider(label, minv, maxv, step, getter, setter, disabled)
			RegisterOptionsSearchEntry(tabKey, label, "slider value size width height opacity alpha spacing gap offset", "slider")
			if not self:Matches(label, "slider value size width height opacity alpha spacing gap offset") then
				return
			end
			addon._optSliderId = (addon._optSliderId or 0) + 1
			local name = "SUF_OptSlider_" .. tabKey .. "_" .. addon._optSliderId
			local x, y, width = self:Reserve(48, false)
			local s = CreateFrame("Slider", name, self.page, "OptionsSliderTemplate")
			s:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			s:SetWidth(width)
			s:SetMinMaxValues(minv, maxv)
			s:SetValueStep(step)
			s:SetObeyStepOnDrag(true)
			s:SetValue(type(getter()) == "number" and getter() or minv)
			local text = _G[name .. "Text"]
			local low = _G[name .. "Low"]
			local high = _G[name .. "High"]
			if text then
				text:SetText(label)
				if self:HasSearch() then
					text:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
				else
					text:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
				end
			end
			if low then low:SetText(tostring(minv)) end
			if high then high:SetText(tostring(maxv)) end
			if disabled then
				if s.EnableMouse then
					s:EnableMouse(false)
				end
				if s.SetEnabled then
					s:SetEnabled(false)
				end
			end
			s:SetScript("OnValueChanged", function(_, v)
				if disabled then
					return
				end
				setter(v)
			end)
		end

		function builder:Check(label, getter, setter, disabled)
			RegisterOptionsSearchEntry(tabKey, label, "checkbox toggle enable disable show hide", "check")
			if not self:Matches(label, "checkbox toggle enable disable show hide") then
				return
			end
			local x, y = self:Reserve(28, false)
			local c = CreateFrame("CheckButton", nil, self.page, "UICheckButtonTemplate")
			c:SetPoint("TOPLEFT", self.page, "TOPLEFT", x - 2, y)
			if c.Text then
				c.Text:SetText(label)
				if self:HasSearch() then
					c.Text:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
				else
					c.Text:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
				end
			end
			c:SetChecked(getter() and true or false)
			c:SetEnabled(not disabled)
			c:SetScript("OnClick", function(w)
				setter(w:GetChecked() and true or false)
			end)
		end

		function builder:Button(label, onClick, span, disabled)
			RegisterOptionsSearchEntry(tabKey, label, "button apply validate copy reset import export add remove clear", "button")
			if not self:Matches(label, "button apply validate copy reset import export add remove clear") then
				return nil
			end
			local height = 36
			local x, y, width = self:Reserve(height, span == true)
			local b = CreateFrame("Button", nil, self.page, "UIPanelButtonTemplate")
			b:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y - 2)
			b:SetSize(span and math.max(160, width) or math.max(120, width), 24)
			b:SetText(label or "Button")
			b:SetNormalFontObject("GameFontHighlight")
			b:SetHighlightFontObject("GameFontNormal")
			b:SetEnabled(not disabled)
			b:SetScript("OnClick", function()
				if disabled then
					return
				end
				if type(onClick) == "function" then
					onClick()
				end
			end)
			return b
		end

		function builder:Dropdown(label, options, getter, setter, disabled)
			RegisterOptionsSearchEntry(tabKey, label, "dropdown select profile preset mode texture font anchor", "dropdown")
			if not self:Matches(label, "dropdown select profile preset mode texture font anchor") then
				return
			end
			local x, y, width = self:Reserve(58, false)
			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			fs:SetText(label)
			if self:HasSearch() then
				fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			else
				fs:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
			end

			local button = CreateFrame("Button", nil, self.page, "BackdropTemplate")
			button:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y - 20)
			button:SetSize(math.max(180, width), 22)
			button:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = 1,
			})
			addon:ApplySUFBackdropColors(button, UI_STYLE.searchBg, UI_STYLE.searchBorder, false)

			local valueText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			valueText:SetPoint("LEFT", button, "LEFT", 8, 0)
			valueText:SetPoint("RIGHT", button, "RIGHT", -22, 0)
			valueText:SetJustifyH("LEFT")
			button.__sufValueText = valueText

			local arrow = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			arrow:SetPoint("RIGHT", button, "RIGHT", -8, 0)
			arrow:SetText("|cFFB7BDC7▼|r")
			button.__sufOpenState = arrow

			local function RefreshText()
				local current = getter and getter() or nil
				local selectedText = current ~= nil and tostring(current) or "-"
				for i = 1, #(options or {}) do
					local item = options[i]
					if item.value == current then
						selectedText = tostring(item.text or item.value or "-")
						break
					end
				end
				valueText:SetText(selectedText)
			end
			RefreshText()
			if disabled and button.EnableMouse then
				button:EnableMouse(false)
			end

			button:SetScript("OnClick", function(widget)
				if disabled then
					return
				end
				if addon._simpleDropdown and addon._simpleDropdown:IsShown() and addon._simpleDropdown.ownerButton == widget then
					addon._simpleDropdown:Hide()
					return
				end
				arrow:SetText("|cFFFFD15C▲|r")
				addon:ShowSimpleDropdown(widget, options, getter, function(v)
					if setter then
						setter(v)
					end
					RefreshText()
				end, math.max(180, width))
			end)
		end

		function builder:Color(label, getter, setter, disabled)
			RegisterOptionsSearchEntry(tabKey, label, "color picker red green blue", "color")
			if not self:Matches(label, "color picker red green blue") then
				return
			end
			local x, y, width = self:Reserve(38, false)
			local button = CreateFrame("Button", nil, self.page, "UIPanelButtonTemplate")
			button:SetSize(40, 20)
			button:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y - 2)
			button:SetText("")
			button:SetEnabled(not disabled)

			local swatch = button:CreateTexture(nil, "ARTWORK")
			swatch:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
			swatch:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
			swatch:SetColorTexture(1, 1, 1, 1)

			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("LEFT", button, "RIGHT", 8, 0)
			fs:SetWidth(math.max(120, width - 52))
			fs:SetJustifyH("LEFT")
			fs:SetText(label)
			if self:HasSearch() then
				fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			else
				fs:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
			end

			local function RefreshSwatch()
				local c = getter and getter() or nil
				local r = c and c[1] or 1
				local g = c and c[2] or 1
				local b = c and c[3] or 1
				swatch:SetColorTexture(r, g, b, 1)
			end

			local function OpenColorPicker()
				if disabled then
					return
				end
				local c = getter and getter() or { 1, 1, 1 }
				local r = c[1] or 1
				local g = c[2] or 1
				local b = c[3] or 1

				if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
					local previous = { r = r, g = g, b = b }
					local info = {
						r = r,
						g = g,
						b = b,
						hasOpacity = false,
						swatchFunc = function()
							local nr, ng, nb = ColorPickerFrame:GetColorRGB()
							setter(nr, ng, nb)
							RefreshSwatch()
						end,
						cancelFunc = function()
							setter(previous.r, previous.g, previous.b)
							RefreshSwatch()
						end,
					}
					ColorPickerFrame:SetupColorPickerAndShow(info)
				elseif ColorPickerFrame then
					ColorPickerFrame.previousValues = { r, g, b }
					ColorPickerFrame.hasOpacity = false
					ColorPickerFrame:SetColorRGB(r, g, b)
					ColorPickerFrame.func = function()
						local nr, ng, nb = ColorPickerFrame:GetColorRGB()
						setter(nr, ng, nb)
						RefreshSwatch()
					end
					ColorPickerFrame.cancelFunc = function(previousValues)
						local pv = previousValues or ColorPickerFrame.previousValues
						if pv then
							setter(pv[1] or pv.r or r, pv[2] or pv.g or g, pv[3] or pv.b or b)
							RefreshSwatch()
						end
					end
					ColorPickerFrame:Show()
				end
			end

			button:SetScript("OnClick", OpenColorPicker)
			if disabled then
				swatch:SetAlpha(0.35)
			end
			RefreshSwatch()
		end

		function builder:Paragraph(text, small)
			RegisterOptionsSearchEntry(tabKey, text, "info help description", "paragraph")
			if self:HasSearch() and not self:Matches(text, "info help description") then
				return
			end
			self:BeginNewLine()
			local fs = self.page:CreateFontString(nil, "OVERLAY", small and "GameFontHighlightSmall" or "GameFontHighlight")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			fs:SetWidth(self.width)
			fs:SetJustifyH("LEFT")
			fs:SetJustifyV("TOP")
			fs:SetText(text or "")
			fs:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
			local height = math.max(16, math.floor((fs:GetStringHeight() or 0) + 0.5))
			self.y = self.y - (height + 8)
		end

		function builder:Section(title, key, defaultOpen)
			RegisterOptionsSearchEntry(tabKey, title, "section group collapse", "section")
			self:BeginNewLine()
			self.addon.db.profile.optionsUI = self.addon.db.profile.optionsUI or { sectionState = {} }
			self.addon.db.profile.optionsUI.sectionState = self.addon.db.profile.optionsUI.sectionState or {}
			frame.optionsSectionState = self.addon.db.profile.optionsUI.sectionState
			local stateKey = tostring(tabKey) .. "::" .. tostring(key or title)
			if frame.optionsSectionState[stateKey] == nil then
				frame.optionsSectionState[stateKey] = defaultOpen ~= false
			end
			local expanded = frame.optionsSectionState[stateKey]
			if self:HasSearch() then
				expanded = true
			end

			local x, y, width = self:Reserve(30, true)
			local toggle = CreateFrame("Button", nil, self.page, "BackdropTemplate")
			toggle:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			toggle:SetSize(math.max(160, width), 22)
			toggle:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = 1,
			})
			addon:ApplySUFBackdropColors(toggle, UI_STYLE.navDefault, UI_STYLE.navDefaultBorder, false)
			local txt = toggle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			txt:SetPoint("LEFT", toggle, "LEFT", 8, 0)
			txt:SetJustifyH("LEFT")
			txt:SetText((expanded and "[-] " or "[+] ") .. tostring(title or "Section"))
			txt:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			toggle:SetScript("OnEnter", function(self)
				addon:ApplySUFBackdropColors(self, UI_STYLE.navHover, UI_STYLE.navHoverBorder, false)
			end)
			toggle:SetScript("OnLeave", function(self)
				addon:ApplySUFBackdropColors(self, UI_STYLE.navDefault, UI_STYLE.navDefaultBorder, false)
			end)
			toggle:SetScript("OnClick", function()
				if self:HasSearch() then
					return
				end
				frame.optionsSectionState[stateKey] = not frame.optionsSectionState[stateKey]
				frame:BuildTab(tabKey)
			end)
			return expanded
		end

		function builder:GetHeight()
			local tail = self.y - ((self.col == 2) and self.rowHeight or 0)
			return math.abs(tail) + 24
		end

		return builder
	end

	function frame.BuildTab(_, tabKey, unitSubTabOverride)
		frame.currentTab = tabKey
		self.db.profile.optionsUI = self.db.profile.optionsUI or {}
		self.db.profile.optionsUI.unitSubTabs = self.db.profile.optionsUI.unitSubTabs or {}
		if unitSubTabOverride and unitTabLookup[tabKey] then
			self.db.profile.optionsUI.unitSubTabs[tabKey] = tostring(unitSubTabOverride)
		end
		StopPerformanceSnapshotTicker()
		local searchText = frame.searchText or ""
		if searchHint then
			searchHint:SetShown(self.db.profile.optionsUI and self.db.profile.optionsUI.searchKeyboardHints ~= false)
		end
		for key, button in pairs(tabButtons) do
			local matchSearch = DoesTabMatchSearch(key, searchText)
			button:SetAlpha(matchSearch and 1 or ((searchText ~= "" and 0.35) or 1))
			if button.__sufSetSelected then
				button:__sufSetSelected(key == tabKey, matchSearch)
			else
				button:SetEnabled(key ~= tabKey)
			end
		end
		if frame.sectionNavButtons then
			local selectedUnitSubTab = self.db.profile.optionsUI.unitSubTabs[tabKey] or "all"
			for compoundKey, button in pairs(frame.sectionNavButtons) do
				local unitKey, sectionKey = strsplit("::", compoundKey)
				local selected = (unitKey == tabKey) and (selectedUnitSubTab == sectionKey)
				local matchSearch = searchText == "" or DoesTabMatchSearch(unitKey, searchText)
				button:SetAlpha(matchSearch and 1 or 0.35)
				if button.__sufSetSelected then
					button:__sufSetSelected(selected, matchSearch)
				end
			end
		end
		self.isBuildingOptions = true
		ClearContent()

		local page = CreateFrame("Frame", nil, content)
		page:SetPoint("TOPLEFT", content, "TOPLEFT")
		page:SetWidth(math.max(760, contentHost:GetWidth() - 44))
		local ui = NewBuilder(page, tabKey)
		ui:SetSearch(searchText)
		local function BuildLSMOptions(kind)
			local values = LSM and LSM:List(kind) or {}
			local out = {}
			for _, value in ipairs(values) do
				out[#out + 1] = { value = value, text = value }
			end
			table.sort(out, function(a, b)
				return a.text < b.text
			end)
			return out
		end
		local statusbarOptions = BuildLSMOptions("statusbar")
		local fontOptions = BuildLSMOptions("font")
		local function GetUnitLabel(unitKey)
			local labels = addon._core and addon._core.UNIT_LABELS
			return (labels and labels[unitKey]) or tostring(unitKey)
		end
		local function CollectOUFTags()
			local ouf = self.oUF or GetOuf()
			if not (ouf and ouf.Tags and ouf.Tags.Methods) then
				return {}
			end
			local tagsList = {}
			for tagName in pairs(ouf.Tags.Methods) do
				if type(tagName) == "string" then
					tagsList[#tagsList + 1] = tagName
				end
			end
			table.sort(tagsList)
			return tagsList
		end
		local function CategorizeTag(tagName)
			local t = string.lower(tagName or "")
			if t:find("health", 1, true) or t:find("hp", 1, true) or t:find("absorb", 1, true) then
				return "Health"
			elseif t:find("power", 1, true) or t:find("pp", 1, true) or t:find("mana", 1, true) or t:find("energy", 1, true) or t:find("rage", 1, true) or t:find("rune", 1, true) then
				return "Power"
			elseif t:find("cast", 1, true) or t:find("channel", 1, true) then
				return "Cast"
			elseif t:find("aura", 1, true) or t:find("buff", 1, true) or t:find("debuff", 1, true) then
				return "Auras"
			elseif t:find("threat", 1, true) or t:find("combat", 1, true) or t:find("status", 1, true) or t:find("dead", 1, true) or t:find("offline", 1, true) then
				return "Status"
			elseif t:find("name", 1, true) or t:find("level", 1, true) or t:find("class", 1, true) or t:find("race", 1, true) then
				return "Identity"
			end
			return "Other"
		end
		local TAG_PRESETS = {
			{
				value = "COMPACT",
				text = "Compact",
				tags = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			},
			{
				value = "HEALER",
				text = "Healer",
				tags = { name = "[raidcolor][name]", level = "[difficulty][level]", health = "[perhp]% | [suf:incoming:abbr]", power = "[curpp]" },
			},
			{
				value = "TANK",
				text = "Tank",
				tags = { name = "[raidcolor][name]", level = "[difficulty][level]", health = "[curhp]/[maxhp]", power = "[curpp] | [suf:ehp:abbr]" },
			},
			{
				value = "DPS",
				text = "DPS",
				tags = { name = "[raidcolor][name]", level = "[level]", health = "[curhp] ([perhp]%)", power = "[curpp]" },
			},
			{
				value = "ABSORB_FOCUS",
				text = "Absorb Focus",
				tags = { name = "[raidcolor][name]", level = "[level]", health = "[curhp] +[suf:absorbs:abbr]", power = "[curpp]" },
			},
			{
				value = "MINIMAL",
				text = "Minimal",
				tags = { name = "[name]", level = "", health = "[perhp]%", power = "" },
			},
		}
		local function GetTagPresetByValue(value)
			for i = 1, #TAG_PRESETS do
				if TAG_PRESETS[i].value == value then
					return TAG_PRESETS[i]
				end
			end
			return TAG_PRESETS[1]
		end
		local function ApplyUnitTagPreset(unitKey, presetValue)
			if not (self.db and self.db.profile and self.db.profile.tags and self.db.profile.tags[unitKey]) then
				return
			end
			local preset = GetTagPresetByValue(presetValue)
			if not preset or not preset.tags then
				return
			end
			local tags = self.db.profile.tags[unitKey]
			tags.name = preset.tags.name or ""
			tags.level = preset.tags.level or ""
			tags.health = preset.tags.health or ""
			tags.power = preset.tags.power or ""
			self:ScheduleUpdateAll()
		end
		local MODULE_KEYS = self:GetModuleCopyResetKeys()
		local function ResolveOptionValue(value)
			if type(value) == "function" then
				return value()
			end
			return value
		end
		local function IsOptionDisabled(option)
			if not option then
				return false
			end
			return ResolveOptionValue(option.disabled) and true or false
		end
		local function IsOptionHidden(option)
			if not option then
				return false
			end
			return ResolveOptionValue(option.hidden) and true or false
		end
		local function RenderOptionSpec(uiBuilder, option)
			if IsOptionHidden(option) then
				return
			end
			local isDisabled = IsOptionDisabled(option)
			local kind = tostring(option.type or "")
			if kind == "label" then
				uiBuilder:Label(option.text or "", option.large == true)
			elseif kind == "paragraph" then
				uiBuilder:Paragraph(option.text or "", option.small ~= false)
			elseif kind == "check" then
				uiBuilder:Check(option.label or "", option.get, option.set, isDisabled)
			elseif kind == "slider" then
				uiBuilder:Slider(option.label or "", option.min or 0, option.max or 1, option.step or 1, option.get, option.set, isDisabled)
			elseif kind == "dropdown" then
				uiBuilder:Dropdown(option.label or "", ResolveOptionValue(option.options) or {}, option.get, option.set, isDisabled)
			elseif kind == "edit" then
				uiBuilder:Edit(option.label or "", option.get, option.set, isDisabled)
			elseif kind == "color" then
				uiBuilder:Color(option.label or "", option.get, option.set, isDisabled)
			elseif kind == "button" then
				uiBuilder:Button(option.label or "", option.onClick, option.span == true, isDisabled)
			elseif kind == "dropdown_or_edit" then
				local opts = ResolveOptionValue(option.options) or {}
				if #opts > 0 then
					uiBuilder:Dropdown(option.label or "", opts, option.get, option.set, isDisabled)
				else
					uiBuilder:Edit(option.fallbackLabel or option.label or "", option.get, option.set, isDisabled)
				end
			end
		end
		local function RenderOptionSpecs(uiBuilder, list)
			for i = 1, #(list or {}) do
				RenderOptionSpec(uiBuilder, list[i])
			end
		end
		local AURAWATCH_PRESETS = {
			{ key = "HEALER_CORE", label = "Healer Core", spells = { 17, 774, 139, 1022, 6940, 33206 } },
			{ key = "RAID_DEFENSIVES", label = "Raid Defensives", spells = { 1022, 6940, 33206, 47788, 97462, 98008 } },
			{ key = "MYTHIC_PLUS", label = "M+ Utility", spells = { 1022, 6940, 33206, 98008, 77764, 204018 } },
		}
		local function RenderAuraWatchSpellListEditor(auraWatchCfg, commitFn)
			auraWatchCfg.customSpellList = SafeText(auraWatchCfg.customSpellList, "")
			local parsedAura = self:ParseAuraWatchSpellTokens(auraWatchCfg.customSpellList)
			local auraEntries = {}
			for i = 1, #(parsedAura.adds or {}) do
				auraEntries[#auraEntries + 1] = { id = parsedAura.adds[i], remove = false }
			end
			for i = 1, #(parsedAura.removes or {}) do
				auraEntries[#auraEntries + 1] = { id = parsedAura.removes[i], remove = true }
			end
			for i = 1, #(parsedAura.addFilters or {}) do
				auraEntries[#auraEntries + 1] = { id = "@" .. tostring(parsedAura.addFilters[i]), remove = false, filterToken = true }
			end
			for i = 1, #(parsedAura.removeFilters or {}) do
				auraEntries[#auraEntries + 1] = { id = "-@" .. tostring(parsedAura.removeFilters[i]), remove = false, filterToken = true }
			end

			local function DedupEntries()
				local out = {}
				local seen = {}
				for i = #auraEntries, 1, -1 do
					local entry = auraEntries[i]
					local key = (entry.remove and "-" or "+") .. tostring(entry.id)
					if not seen[key] then
						out[#out + 1] = entry
						seen[key] = true
					end
				end
				auraEntries = {}
				for i = #out, 1, -1 do
					auraEntries[#auraEntries + 1] = out[i]
				end
			end
			local function BuildAuraWatchCustomString()
				local tokens = {}
				for i = 1, #auraEntries do
					local entry = auraEntries[i]
					if type(entry.id) == "string" then
						tokens[#tokens + 1] = entry.id
					else
						tokens[#tokens + 1] = (entry.remove and "-" or "") .. tostring(entry.id)
					end
				end
				return table.concat(tokens, " ")
			end
			local function SaveAuraWatchList()
				DedupEntries()
				auraWatchCfg.customSpellList = BuildAuraWatchCustomString()
				if commitFn then
					commitFn()
				end
			end

			DedupEntries()
			ui:Label("AuraWatch Spell List", false)
			local ax, ay, awidth = ui:Reserve(370, true)
			local addBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			addBox:SetAutoFocus(false)
			addBox:SetSize(140, 22)
			addBox:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay)
			addBox:SetText("")
			addBox:SetScript("OnEscapePressed", function(w)
				w:ClearFocus()
			end)
			local addHint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			addHint:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 24)
			addHint:SetText("Spell ID or @FilterSet (e.g. @ImportantCC)")
			local addBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
			addBtn:SetSize(80, 22)
			addBtn:SetText("Add")
			addBtn:SetScript("OnClick", function()
				local token = TrimString(SafeText(addBox:GetText(), ""))
				if token == "" then
					self:Print(addonName .. ": Enter a spell ID or @FilterSet.")
					return
				end
				if token:sub(1, 1) == "@" then
					local setName = token:sub(2)
					if not self:GetImportedAuraFilterSet(setName) then
						self:Print(addonName .. ": Unknown filter set " .. tostring(token) .. ".")
						return
					end
					auraEntries[#auraEntries + 1] = { id = "@" .. string.upper(setName):gsub("%s+", ""), remove = false, filterToken = true }
					SaveAuraWatchList()
					return
				end
				local spellID = tonumber(token)
				if not spellID or spellID <= 0 then
					self:Print(addonName .. ": Enter a valid spell ID.")
					return
				end
				if not self:GetSpellNameForValidation(spellID) then
					self:Print(addonName .. ": Unknown spell ID " .. tostring(spellID) .. ".")
					return
				end
				auraEntries[#auraEntries + 1] = { id = spellID, remove = false }
				SaveAuraWatchList()
			end)
			local addRemoveBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			addRemoveBtn:SetPoint("LEFT", addBtn, "RIGHT", 6, 0)
			addRemoveBtn:SetSize(120, 22)
			addRemoveBtn:SetText("Add Remove Rule")
			addRemoveBtn:SetScript("OnClick", function()
				local token = TrimString(SafeText(addBox:GetText(), ""))
				if token == "" then
					self:Print(addonName .. ": Enter a spell ID or @FilterSet.")
					return
				end
				if token:sub(1, 1) == "@" then
					local setName = token:sub(2)
					if not self:GetImportedAuraFilterSet(setName) then
						self:Print(addonName .. ": Unknown filter set " .. tostring(token) .. ".")
						return
					end
					auraEntries[#auraEntries + 1] = { id = "-@" .. string.upper(setName):gsub("%s+", ""), remove = false, filterToken = true }
					SaveAuraWatchList()
					return
				end
				local spellID = tonumber(token)
				if not spellID or spellID <= 0 then
					self:Print(addonName .. ": Enter a valid spell ID.")
					return
				end
				if not self:GetSpellNameForValidation(spellID) then
					self:Print(addonName .. ": Unknown spell ID " .. tostring(spellID) .. ".")
					return
				end
				auraEntries[#auraEntries + 1] = { id = spellID, remove = true }
				SaveAuraWatchList()
			end)
			local clearBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			clearBtn:SetSize(100, 22)
			clearBtn:SetText("Clear List")
			clearBtn:SetScript("OnClick", function()
				auraEntries = {}
				SaveAuraWatchList()
			end)

			local layoutGrid = {
				x = ax,
				width = awidth,
				colGap = 8,
				rowGap = 4,
				cursorY = ay,
				rowTop = ay,
				colWidth = math.max(120, math.floor((awidth - 8) / 2)),
			}
			function layoutGrid:BeginRow(height)
				self.rowTop = self.cursorY
				self.cursorY = self.cursorY - height - self.rowGap
				return self.rowTop
			end
			function layoutGrid:Cell(col, span)
				local startCol = math.max(1, math.min(2, tonumber(col) or 1))
				local cols = math.max(1, math.min(2, tonumber(span) or 1))
				local x = self.x + ((startCol - 1) * (self.colWidth + self.colGap))
				local width = (cols == 2 and startCol == 1) and self.width or ((cols == 2) and (self.colWidth + self.colGap + self.colWidth) or self.colWidth)
				return x, self.rowTop, width
			end
			function layoutGrid:Anchor(control, col, span, height, widthOverride)
				local x, y, width = self:Cell(col, span)
				control:ClearAllPoints()
				control:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
				control:SetSize(widthOverride or width, height)
				return control
			end
			function layoutGrid:Label(fontString, col, span)
				local x, y = self:Cell(col, span)
				fontString:ClearAllPoints()
				fontString:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
				return fontString
			end
			function layoutGrid:Buttons(buttonDefs, height)
				local h = tonumber(height) or 20
				local col = 1
				local buttons = {}
				for i = 1, #(buttonDefs or {}) do
					if col == 1 then
						self:BeginRow(h)
					end
					local def = buttonDefs[i]
					local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
					self:Anchor(button, col, 1, h)
					button:SetText(tostring(def.label or ""))
					if def.onClick then
						button:SetScript("OnClick", def.onClick)
					end
					buttons[#buttons + 1] = button
					col = (col == 1) and 2 or 1
				end
				return buttons
			end

			layoutGrid:BeginRow(22)
			layoutGrid:Anchor(addBox, 1, 1, 22, layoutGrid.colWidth)
			layoutGrid:Anchor(addBtn, 2, 1, 22, layoutGrid.colWidth)

			layoutGrid:BeginRow(22)
			layoutGrid:Anchor(addRemoveBtn, 1, 1, 22, layoutGrid.colWidth)
			layoutGrid:Anchor(clearBtn, 2, 1, 22, layoutGrid.colWidth)

			layoutGrid:BeginRow(16)
			layoutGrid:Label(addHint, 1, 2)

			local sortAscBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			layoutGrid:BeginRow(20)
			layoutGrid:Anchor(sortAscBtn, 1, 1, 20, layoutGrid.colWidth)
			sortAscBtn:SetText("Sort Asc")
			sortAscBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return (a.remove and 1 or 0) < (b.remove and 1 or 0)
					end
					local aId, bId = tonumber(a.id), tonumber(b.id)
					if aId and bId then
						return aId < bId
					end
					return tostring(a.id or "") < tostring(b.id or "")
				end)
				SaveAuraWatchList()
			end)
			local sortDescBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			layoutGrid:Anchor(sortDescBtn, 2, 1, 20, layoutGrid.colWidth)
			sortDescBtn:SetText("Sort Desc")
			sortDescBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return (a.remove and 1 or 0) < (b.remove and 1 or 0)
					end
					local aId, bId = tonumber(a.id), tonumber(b.id)
					if aId and bId then
						return aId > bId
					end
					return tostring(a.id or "") > tostring(b.id or "")
				end)
				SaveAuraWatchList()
			end)

			local presetButtonDefs = {}
			for i = 1, #AURAWATCH_PRESETS do
				local preset = AURAWATCH_PRESETS[i]
				presetButtonDefs[#presetButtonDefs + 1] = {
					label = preset.label,
					onClick = function()
						for s = 1, #preset.spells do
							auraEntries[#auraEntries + 1] = { id = preset.spells[s], remove = false }
						end
						SaveAuraWatchList()
					end,
				}
			end
			layoutGrid:Buttons(presetButtonDefs, 20)

			local importSets = {
				{ key = "IMPORTANTCC", label = "Add @ImportantCC" },
				{ key = "CLASSDEBUFFS", label = "Add @ClassDebuffs" },
				{ key = "-IMPORTANTCC", label = "Remove @ImportantCC" },
				{ key = "-CLASSDEBUFFS", label = "Remove @ClassDebuffs" },
			}
			local importButtonDefs = {}
			for i = 1, #importSets do
				local setInfo = importSets[i]
				importButtonDefs[#importButtonDefs + 1] = {
					label = setInfo.label,
					onClick = function()
						local token = setInfo.key
						if token:sub(1, 1) == "-" then
							token = "-@" .. token:sub(2)
						else
							token = "@" .. token
						end
						auraEntries[#auraEntries + 1] = { id = token, remove = false, filterToken = true }
						SaveAuraWatchList()
					end,
				}
			end
			layoutGrid:Buttons(importButtonDefs, 20)

			local function MoveAuraEntry(fromIndex, toIndex)
				fromIndex = tonumber(fromIndex)
				toIndex = tonumber(toIndex)
				if not fromIndex or not toIndex then
					return false
				end
				if fromIndex < 1 or toIndex < 1 or fromIndex > #auraEntries or toIndex > #auraEntries then
					return false
				end
				if fromIndex == toIndex then
					return true
				end
				local moving = table.remove(auraEntries, fromIndex)
				table.insert(auraEntries, toIndex, moving)
				return true
			end

			local regularCount = 0
			local specialCount = 0
			for i = 1, #auraEntries do
				if auraEntries[i].remove or auraEntries[i].filterToken then
					specialCount = specialCount + 1
				else
					regularCount = regularCount + 1
				end
			end

			layoutGrid:BeginRow(16)
			local grouping = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			layoutGrid:Label(grouping, 1, 2)
			grouping:SetText(("Priority Groups: Regular (+)=%d, Special Remove (-)=%d"):format(regularCount, specialCount))

			layoutGrid:BeginRow(20)
			local dragLeft = CreateFrame("Frame", nil, page)
			layoutGrid:Anchor(dragLeft, 1, 1, 20, layoutGrid.colWidth)
			local dragFrom = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			dragFrom:SetAutoFocus(false)
			dragFrom:SetSize(46, 20)
			dragFrom:ClearAllPoints()
			dragFrom:SetPoint("TOPLEFT", dragLeft, "TOPLEFT", 0, 0)
			dragFrom:SetScript("OnEscapePressed", function(w) w:ClearFocus() end)
			local dragArrow = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
			dragArrow:ClearAllPoints()
			dragArrow:SetPoint("LEFT", dragFrom, "RIGHT", 4, 0)
			dragArrow:SetText("->")
			local dragTo = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			dragTo:SetAutoFocus(false)
			dragTo:SetSize(46, 20)
			dragTo:SetPoint("LEFT", dragArrow, "RIGHT", 4, 0)
			dragTo:SetScript("OnEscapePressed", function(w) w:ClearFocus() end)
			local dragBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			dragBtn:SetPoint("LEFT", dragTo, "RIGHT", 6, 0)
			dragBtn:SetSize(math.max(72, layoutGrid.colWidth - 108), 20)
			dragBtn:SetText("Drag Move")
			dragBtn:SetScript("OnClick", function()
				if MoveAuraEntry(dragFrom:GetText(), dragTo:GetText()) then
					SaveAuraWatchList()
				else
					self:Print(addonName .. ": Invalid drag move indexes.")
				end
			end)

			local regularFirstBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			layoutGrid:Anchor(regularFirstBtn, 2, 1, 20, math.floor((layoutGrid.colWidth - 6) / 2))
			regularFirstBtn:SetText("Regular First")
			regularFirstBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return not a.remove
					end
					local aId, bId = tonumber(a.id), tonumber(b.id)
					if aId and bId then
						return aId < bId
					end
					return tostring(a.id or "") < tostring(b.id or "")
				end)
				SaveAuraWatchList()
			end)
			local specialFirstBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			specialFirstBtn:SetPoint("LEFT", regularFirstBtn, "RIGHT", 6, 0)
			specialFirstBtn:SetSize(math.floor((layoutGrid.colWidth - 6) / 2), 20)
			specialFirstBtn:SetText("Special First")
			specialFirstBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return a.remove
					end
					local aId, bId = tonumber(a.id), tonumber(b.id)
					if aId and bId then
						return aId < bId
					end
					return tostring(a.id or "") < tostring(b.id or "")
				end)
				SaveAuraWatchList()
			end)

			local listTitleY = layoutGrid.cursorY - 2
			local entriesStartY = listTitleY - 22

			local listTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			listTitle:SetPoint("TOPLEFT", page, "TOPLEFT", ax, listTitleY)
			listTitle:SetText("Configured Entries (priority order)")
			local entries = auraEntries
			local maxRows = math.min(10, #entries)
			for row = 1, maxRows do
				local rowIndex = row
				local entry = entries[row]
				local rowY = entriesStartY - ((row - 1) * 22)
				local spellName = self:GetSpellNameForValidation(entry.id) or "Unknown Spell"
				local entryToken = (entry.remove and "- " or "+ ") .. tostring(entry.id)
				if type(entry.id) == "string" then
					spellName = "Imported Filter Set"
					entryToken = tostring(entry.id)
				end
				local rowText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				rowText:SetPoint("TOPLEFT", page, "TOPLEFT", ax, rowY)
				rowText:SetWidth(awidth - 164)
				rowText:SetJustifyH("LEFT")
				rowText:SetText(("[%d] %s  %s"):format(rowIndex, entryToken, tostring(spellName)))
				if entry.remove or entry.filterToken then
					rowText:SetTextColor(1.00, 0.56, 0.60)
				else
					rowText:SetTextColor(0.56, 1.00, 0.66)
				end
				local upBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
				upBtn:SetPoint("TOPRIGHT", page, "TOPLEFT", ax + awidth - 130, rowY + 2)
				upBtn:SetSize(28, 20)
				upBtn:SetText("^")
				upBtn:SetEnabled(rowIndex > 1)
				upBtn:SetScript("OnClick", function()
					MoveAuraEntry(rowIndex, rowIndex - 1)
					SaveAuraWatchList()
				end)
				local downBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
				downBtn:SetPoint("LEFT", upBtn, "RIGHT", 2, 0)
				downBtn:SetSize(28, 20)
				downBtn:SetText("v")
				downBtn:SetEnabled(rowIndex < #entries)
				downBtn:SetScript("OnClick", function()
					MoveAuraEntry(rowIndex, rowIndex + 1)
					SaveAuraWatchList()
				end)
				local removeBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
				removeBtn:SetPoint("LEFT", downBtn, "RIGHT", 2, 0)
				removeBtn:SetSize(64, 20)
				removeBtn:SetText("Remove")
				removeBtn:SetScript("OnClick", function()
					table.remove(auraEntries, rowIndex)
					SaveAuraWatchList()
				end)
			end
			if #entries > maxRows then
				local extra = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
				extra:SetPoint("TOPLEFT", page, "TOPLEFT", ax, entriesStartY - (maxRows * 22))
				extra:SetText(("...and %d more entries"):format(#entries - maxRows))
			end
			local report = self:ValidateAuraWatchSpellList(auraWatchCfg.customSpellList or "")
			local hasWarn = (#(report.invalidIDs or {}) > 0 or #(report.invalidTokens or {}) > 0)
			local summary = ("Validation: add=%d remove=%d addSets=%d removeSets=%d invalidIDs=%d invalidTokens=%d"):format(
				#(report.validAdds or {}),
				#(report.validRemoves or {}),
				#(report.validAddFilters or {}),
				#(report.validRemoveFilters or {}),
				#(report.invalidIDs or {}),
				#(report.invalidTokens or {})
			)
			local summaryText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			summaryText:SetPoint("TOPLEFT", page, "TOPLEFT", ax, entriesStartY - (maxRows * 22) - 8)
			summaryText:SetWidth(awidth)
			summaryText:SetJustifyH("LEFT")
			summaryText:SetText(summary)
			if hasWarn then
				summaryText:SetTextColor(1.00, 0.56, 0.60)
			else
				summaryText:SetTextColor(0.56, 1.00, 0.66)
			end
		end
		if searchText ~= "" then
			ui:Label("Search Results", false)
			local grouped = QueryOptionsSearch(searchText)
			frame.searchResultGroups = grouped
			if #grouped == 0 then
				ui:Paragraph(("No tab matches found for '%s'."):format(searchText), true)
			else
				local rx, ry = 12, ui.y
				local show = math.min(8, #grouped)
				local showCounts = self.db.profile.optionsUI and self.db.profile.optionsUI.searchShowCounts ~= false
				for i = 1, show do
					local item = grouped[i]
					local hit1 = item.hits and item.hits[1] and item.hits[1].label or ""
					local hit2 = item.hits and item.hits[2] and item.hits[2].label or ""
					local details = hit1
					if hit2 ~= "" and hit2 ~= hit1 then
						details = details .. ", " .. hit2
					end
					local btn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
					btn:SetSize(184, 22)
					btn:SetPoint("TOPLEFT", page, "TOPLEFT", rx + (((i - 1) % 3) * 190), ry - (math.floor((i - 1) / 3) * 26))
					local labelText = item.tabLabel
					if showCounts then
						labelText = ("%s (%d/%d)"):format(item.tabLabel, item.score, #(item.hits or {}))
					end
					btn:SetText(labelText)
					btn:SetScript("OnClick", function()
						frame:BuildTab(item.tabKey)
					end)
					if details ~= "" then
						btn:SetScript("OnEnter", function(widget)
							if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
								GameTooltip:SetOwner(widget, "ANCHOR_TOPLEFT")
								GameTooltip:AddLine(item.tabLabel, 1, 1, 1)
								GameTooltip:AddLine(details, 0.7, 0.85, 1, true)
								GameTooltip:Show()
							end
						end)
						btn:SetScript("OnLeave", function()
							if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
								GameTooltip:Hide()
							end
						end)
					end
				end
				ui.y = ry - (math.max(1, math.ceil(show / 3)) * 26) - 8
			end
		else
			frame.searchResultGroups = nil
		end
		if searchText ~= "" and not DoesTabMatchSearch(tabKey, searchText) then
			ui:Label("Search Navigation", false)
			ui:Paragraph(("'%s' appears to belong to another tab. Jump to a matching tab:"):format(searchText), true)
			local jumpX, jumpY = 12, ui.y
			local shown = 0
			local groups = QueryOptionsSearch(searchText)
			for i = 1, #groups do
				local candidate = groups[i]
				local jump = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
				jump:SetSize(156, 22)
				jump:SetPoint("TOPLEFT", page, "TOPLEFT", jumpX + ((shown % 4) * 162), jumpY - (math.floor(shown / 4) * 26))
				jump:SetText(candidate.tabLabel)
				jump:SetScript("OnClick", function()
					frame:BuildTab(candidate.tabKey)
				end)
				shown = shown + 1
				if shown >= 8 then
					break
				end
			end
			ui.y = jumpY - (math.max(1, math.ceil(shown / 4)) * 26) - 8
		end

		if tabKey == "global" then
			local castbarCfg = self.db.profile.castbar
			local enhancementCfg = self:GetEnhancementSettings()
			local pluginCfg = self:GetPluginSettings()
			local backgroundCfg = self:GetMainBarsBackgroundSettings()
			local absorbTagOptions = {
				{ value = "[suf:absorbs:abbr]", text = "Abbreviated ([suf:absorbs:abbr])" },
				{ value = "[suf:absorbs]", text = "Raw ([suf:absorbs])" },
				{ value = "[suf:ehp:abbr]", text = "Effective HP ([suf:ehp:abbr])" },
				{ value = "[suf:ehp]", text = "Effective HP Raw ([suf:ehp])" },
				{ value = "[suf:incoming:abbr]", text = "Incoming Heals ([suf:incoming:abbr])" },
				{ value = "[suf:incoming]", text = "Incoming Heals Raw ([suf:incoming])" },
				{ value = "[suf:healabsorbs:abbr]", text = "Heal Absorbs ([suf:healabsorbs:abbr])" },
				{ value = "[suf:healabsorbs]", text = "Heal Absorbs Raw ([suf:healabsorbs])" },
				{ value = "", text = "Hidden" },
			}
			RenderOptionSpecs(ui, {
				{ type = "label", text = "Global Options", large = true },
				{ type = "dropdown_or_edit", label = "Statusbar Texture", fallbackLabel = "Statusbar Texture Name", options = function() return statusbarOptions end, get = function() return self.db.profile.media.statusbar end, set = function(v) self.db.profile.media.statusbar = v; self:ScheduleUpdateAll() end },
				{ type = "dropdown_or_edit", label = "Font", fallbackLabel = "Font Name", options = function() return fontOptions end, get = function() return self.db.profile.media.font end, set = function(v) self.db.profile.media.font = v; self:ScheduleUpdateAll() end },
				{ type = "label", text = "Main Bars Background" },
				{ type = "check", label = "Enable Main Bars Background", get = function() return backgroundCfg.enabled ~= false end, set = function(v) backgroundCfg.enabled = v and true or false; self:ScheduleUpdateAll() end },
				{ type = "dropdown_or_edit", label = "Main Bars Background Texture", options = function() return statusbarOptions end, get = function() return backgroundCfg.texture end, set = function(v) backgroundCfg.texture = v; self:ScheduleUpdateAll() end },
				{ type = "color", label = "Main Bars Background Color", get = function() return backgroundCfg.color end, set = function(r, g, b) backgroundCfg.color[1], backgroundCfg.color[2], backgroundCfg.color[3] = r, g, b; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Main Bars Background Opacity", min = 0, max = 1, step = 0.05, get = function() return backgroundCfg.alpha end, set = function(v) backgroundCfg.alpha = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Power Bar Height", min = 4, max = 20, step = 1, get = function() return self.db.profile.powerHeight end, set = function(v) self.db.profile.powerHeight = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Class Power Height", min = 4, max = 20, step = 1, get = function() return self.db.profile.classPowerHeight end, set = function(v) self.db.profile.classPowerHeight = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Class Power Spacing", min = 0, max = 10, step = 1, get = function() return self.db.profile.classPowerSpacing end, set = function(v) self.db.profile.classPowerSpacing = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Castbar Height", min = 8, max = 30, step = 1, get = function() return self.db.profile.castbarHeight end, set = function(v) self.db.profile.castbarHeight = v; self:ScheduleUpdateAll() end },
				{ type = "label", text = "Castbar Enhancements" },
				{ type = "dropdown", label = "Castbar Color Profile", options = { { value = "UUF", text = "UUF" }, { value = "Blizzard", text = "Blizzard" }, { value = "HighContrast", text = "High Contrast" } }, get = function() return castbarCfg.colorProfile end, set = function(v) castbarCfg.colorProfile = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Icon", get = function() return castbarCfg.iconEnabled ~= false end, set = function(v) castbarCfg.iconEnabled = v; self:ScheduleUpdateAll() end },
				{ type = "dropdown", label = "Castbar Icon Position", options = { { value = "LEFT", text = "Left" }, { value = "RIGHT", text = "Right" } }, get = function() return castbarCfg.iconPosition end, set = function(v) castbarCfg.iconPosition = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Castbar Icon Size", min = 12, max = 40, step = 1, get = function() return castbarCfg.iconSize end, set = function(v) castbarCfg.iconSize = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Castbar Icon Gap", min = 0, max = 12, step = 1, get = function() return castbarCfg.iconGap end, set = function(v) castbarCfg.iconGap = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Shield", get = function() return castbarCfg.showShield ~= false end, set = function(v) castbarCfg.showShield = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Latency Safe Zone", get = function() return castbarCfg.showSafeZone ~= false end, set = function(v) castbarCfg.showSafeZone = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Safe Zone Opacity", min = 0.05, max = 1, step = 0.05, get = function() return castbarCfg.safeZoneAlpha end, set = function(v) castbarCfg.safeZoneAlpha = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Spark", get = function() return castbarCfg.showSpark ~= false end, set = function(v) castbarCfg.showSpark = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Direction Indicator", get = function() return castbarCfg.showDirectionIndicator == true end, set = function(v) castbarCfg.showDirectionIndicator = v and true or false; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Channel Ticks", get = function() return castbarCfg.showChannelTicks == true end, set = function(v) castbarCfg.showChannelTicks = v and true or false; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Channel Tick Width", min = 1, max = 6, step = 1, get = function() return tonumber(castbarCfg.channelTickWidth) or 2 end, set = function(v) castbarCfg.channelTickWidth = v; self:ScheduleUpdateAll() end, disabled = function() return castbarCfg.showChannelTicks ~= true end },
				{ type = "check", label = "Castbar Empower Pips", get = function() return castbarCfg.showEmpowerPips ~= false end, set = function(v) castbarCfg.showEmpowerPips = v and true or false; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Castbar Latency Text", get = function() return castbarCfg.showLatencyText == true end, set = function(v) castbarCfg.showLatencyText = v and true or false; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Latency Warn (ms)", min = 40, max = 400, step = 5, get = function() return tonumber(castbarCfg.latencyWarnMs) or 120 end, set = function(v) castbarCfg.latencyWarnMs = v; if (tonumber(castbarCfg.latencyHighMs) or 220) < v then castbarCfg.latencyHighMs = v end; self:ScheduleUpdateAll() end, disabled = function() return castbarCfg.showLatencyText ~= true end },
				{ type = "slider", label = "Latency High (ms)", min = 60, max = 600, step = 5, get = function() return tonumber(castbarCfg.latencyHighMs) or 220 end, set = function(v) castbarCfg.latencyHighMs = math.max(v, tonumber(castbarCfg.latencyWarnMs) or 120); self:ScheduleUpdateAll() end, disabled = function() return castbarCfg.showLatencyText ~= true end },
				{ type = "slider", label = "Spell Name Max Chars", min = 6, max = 40, step = 1, get = function() return castbarCfg.spellMaxChars end, set = function(v) castbarCfg.spellMaxChars = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Cast Time Decimals", min = 0, max = 2, step = 1, get = function() return castbarCfg.timeDecimals end, set = function(v) castbarCfg.timeDecimals = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Show Cast Delay", get = function() return castbarCfg.showDelay ~= false end, set = function(v) castbarCfg.showDelay = v; self:ScheduleUpdateAll() end },
				{ type = "label", text = "Library Enhancements" },
				{ type = "check", label = "Sticky Window Drag (LibSimpleSticky)", get = function() return enhancementCfg.stickyWindows ~= false end, set = function(v) enhancementCfg.stickyWindows = v and true or false end, disabled = function() return not LibSimpleSticky end },
				{ type = "slider", label = "Sticky Snap Range", min = 4, max = 36, step = 1, get = function() return enhancementCfg.stickyRange or 15 end, set = function(v) enhancementCfg.stickyRange = v end },
				{ type = "check", label = "Pixel Snap Windows", get = function() return enhancementCfg.pixelSnapWindows ~= false end, set = function(v) enhancementCfg.pixelSnapWindows = v and true or false end },
				{ type = "check", label = "Transliterate Names (LibTranslit)", get = function() return enhancementCfg.translitNames == true end, set = function(v) enhancementCfg.translitNames = v and true or false; self:ScheduleUpdateAll() end, disabled = function() return not LibTranslit end },
				{ type = "edit", label = "Translit Marker Prefix", get = function() return enhancementCfg.translitMarker or "" end, set = function(v) enhancementCfg.translitMarker = SafeText(v, ""); self:ScheduleUpdateAll() end },
				{ type = "check", label = "Non-Interruptible Castbar Glow (LibCustomGlow)", get = function() return enhancementCfg.castbarNonInterruptibleGlow ~= false end, set = function(v) enhancementCfg.castbarNonInterruptibleGlow = v and true or false; self:ScheduleUpdateAll() end, disabled = function() return not LibCustomGlow end },
				{ type = "check", label = "Window Open Animation (LibAnim)", get = function() return enhancementCfg.uiOpenAnimation ~= false end, set = function(v) enhancementCfg.uiOpenAnimation = v and true or false end, disabled = function() return not (UIParent and UIParent.CreateAnimationGroup) end },
				{ type = "slider", label = "Window Animation Duration", min = 0.05, max = 0.60, step = 0.01, get = function() return tonumber(enhancementCfg.uiOpenAnimationDuration) or 0.18 end, set = function(v) enhancementCfg.uiOpenAnimationDuration = v end },
				{ type = "slider", label = "Window Animation Offset Y", min = -40, max = 40, step = 1, get = function() return tonumber(enhancementCfg.uiOpenAnimationOffsetY) or 12 end, set = function(v) enhancementCfg.uiOpenAnimationOffsetY = v end },
				{ type = "label", text = "DataText Panel" },
				{ type = "check", label = "Enable DataText Panel", get = function() return self.db.profile.datatext.enabled ~= false end, set = function(v) self.db.profile.datatext.enabled = v and true or false; self:InitializeDataSystems() end },
				{ type = "slider", label = "DataText Refresh Rate (sec)", min = 0.2, max = 5.0, step = 0.1, get = function() return tonumber(self.db.profile.datatext.refreshRate) or 1.0 end, set = function(v) self.db.profile.datatext.refreshRate = v; self:InitializeDataSystems() end },
				{ type = "dropdown", label = "DataText Position Mode", options = {
					{ value = "ANCHOR", text = "Top/Bottom Anchor" },
					{ value = "EDIT_MODE", text = "Edit Mode Position" },
				}, get = function() return tostring(self.db.profile.datatext.positionMode or "ANCHOR") end, set = function(v) self.db.profile.datatext.positionMode = v; self:UpdateDataTextPanel() end },
				{ type = "slider", label = "DataText Panel Width", min = 280, max = 900, step = 10, get = function() return tonumber(self.db.profile.datatext.panel.width) or 520 end, set = function(v) self.db.profile.datatext.panel.width = v; self:UpdateDataTextPanel() end },
				{ type = "slider", label = "DataText Panel Height", min = 16, max = 40, step = 1, get = function() return tonumber(self.db.profile.datatext.panel.height) or 20 end, set = function(v) self.db.profile.datatext.panel.height = v; self:UpdateDataTextPanel() end },
				{ type = "dropdown", label = "DataText Panel Anchor", options = { { value = "TOP", text = "Top" }, { value = "BOTTOM", text = "Bottom" } }, get = function() return tostring(self.db.profile.datatext.panel.anchor or "TOP") end, set = function(v) self.db.profile.datatext.panel.anchor = v; self:UpdateDataTextPanel() end },
				{ type = "check", label = "DataText Mouseover Fade", get = function() return self.db.profile.datatext.panel.mouseover == true end, set = function(v) self.db.profile.datatext.panel.mouseover = v and true or false; self:UpdateDataTextPanel() end },
				{ type = "dropdown", label = "DataText Left Slot", options = function() return self:GetAvailableDataTextSources() end, get = function() return self.db.profile.datatext.slots.left or "FPS" end, set = function(v) self.db.profile.datatext.slots.left = v; self:UpdateDataTextPanel() end },
				{ type = "dropdown", label = "DataText Center Slot", options = function() return self:GetAvailableDataTextSources() end, get = function() return self.db.profile.datatext.slots.center or "Time" end, set = function(v) self.db.profile.datatext.slots.center = v; self:UpdateDataTextPanel() end },
				{ type = "dropdown", label = "DataText Right Slot", options = function() return self:GetAvailableDataTextSources() end, get = function() return self.db.profile.datatext.slots.right or "Memory" end, set = function(v) self.db.profile.datatext.slots.right = v; self:UpdateDataTextPanel() end },
				{ type = "label", text = "Data Bars" },
				{ type = "check", label = "Enable Data Bars", get = function() return self.db.profile.databars.enabled ~= false end, set = function(v) self.db.profile.databars.enabled = v and true or false; self:UpdateDataBars() end },
				{ type = "dropdown", label = "Data Bar Position Mode", options = {
					{ value = "ANCHOR", text = "Top/Bottom Anchor" },
					{ value = "EDIT_MODE", text = "Edit Mode Position" },
				}, get = function() return tostring(self.db.profile.databars.positionMode or "ANCHOR") end, set = function(v) self.db.profile.databars.positionMode = v; self:UpdateDataBars() end },
				{ type = "check", label = "Show XP Bar", get = function() return self.db.profile.databars.showXP ~= false end, set = function(v) self.db.profile.databars.showXP = v and true or false; self:UpdateDataBars() end },
				{ type = "check", label = "Show Reputation Bar", get = function() return self.db.profile.databars.showReputation ~= false end, set = function(v) self.db.profile.databars.showReputation = v and true or false; self:UpdateDataBars() end },
				{ type = "check", label = "Show Pet XP Bar", get = function() return self.db.profile.databars.showPetXP ~= false end, set = function(v) self.db.profile.databars.showPetXP = v and true or false; self:UpdateDataBars() end },
				{ type = "check", label = "Show Rested XP Overlay", get = function() return self.db.profile.databars.showRestedOverlay ~= false end, set = function(v) self.db.profile.databars.showRestedOverlay = v and true or false; self:UpdateDataBars() end, disabled = function() return self.db.profile.databars.showXP == false end },
				{ type = "check", label = "Show Quest XP Overlay", get = function() return self.db.profile.databars.showQuestXPOverlay ~= false end, set = function(v) self.db.profile.databars.showQuestXPOverlay = v and true or false; self:UpdateDataBars() end, disabled = function() return self.db.profile.databars.showXP == false end },
				{ type = "check", label = "Show Data Bar Text", get = function() return self.db.profile.databars.showText ~= false end, set = function(v) self.db.profile.databars.showText = v and true or false; self:UpdateDataBars() end },
				{ type = "label", text = "XP Bar Fade" },
				{ type = "check", label = "Enable XP Bar Fade", get = function() return self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.enabled = v and true or false
					self:UpdateDataBars()
				end },
				{ type = "check", label = "Show on Hover", get = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.showOnHover == false) end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.showOnHover = v and true or false
					self:UpdateDataBars()
				end, disabled = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true) end },
				{ type = "check", label = "Show in Combat", get = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.showInCombat == false) end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.showInCombat = v and true or false
					self:UpdateDataBars()
				end, disabled = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true) end },
				{ type = "slider", label = "Fade In Duration", min = 0.05, max = 1.0, step = 0.05, get = function() return tonumber(self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.fadeInDuration) or 0.2 end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.fadeInDuration = v
					self:UpdateDataBars()
				end, disabled = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true) end },
				{ type = "slider", label = "Fade Out Duration", min = 0.05, max = 1.2, step = 0.05, get = function() return tonumber(self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.fadeOutDuration) or 0.3 end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.fadeOutDuration = v
					self:UpdateDataBars()
				end, disabled = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true) end },
				{ type = "slider", label = "Fade Out Alpha", min = 0.0, max = 1.0, step = 0.05, get = function() return tonumber(self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.fadeOutAlpha) or 0 end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.fadeOutAlpha = v
					self:UpdateDataBars()
				end, disabled = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true) end },
				{ type = "slider", label = "Fade Out Delay", min = 0.0, max = 2.0, step = 0.05, get = function() return tonumber(self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.fadeOutDelay) or 0.5 end, set = function(v)
					if not self.db.profile.databars.xpFade then
						self.db.profile.databars.xpFade = {}
					end
					self.db.profile.databars.xpFade.fadeOutDelay = v
					self:UpdateDataBars()
				end, disabled = function() return not (self.db.profile.databars.xpFade and self.db.profile.databars.xpFade.enabled == true) end },
				{ type = "slider", label = "Data Bar Width", min = 280, max = 900, step = 10, get = function() return tonumber(self.db.profile.databars.width) or 520 end, set = function(v) self.db.profile.databars.width = v; self:UpdateDataBars() end },
				{ type = "slider", label = "Data Bar Height", min = 8, max = 24, step = 1, get = function() return tonumber(self.db.profile.databars.height) or 10 end, set = function(v) self.db.profile.databars.height = v; self:UpdateDataBars() end },
				{ type = "dropdown", label = "Data Bar Anchor", options = { { value = "TOP", text = "Top" }, { value = "BOTTOM", text = "Bottom" } }, get = function() return tostring(self.db.profile.databars.anchor or "TOP") end, set = function(v) self.db.profile.databars.anchor = v; self:UpdateDataBars() end },
				{ type = "label", text = "Search UX" },
				{ type = "check", label = "Search Result Counts", get = function() return self.db.profile.optionsUI.searchShowCounts ~= false end, set = function(v) self.db.profile.optionsUI.searchShowCounts = v and true or false; frame:BuildTab("global") end },
				{ type = "check", label = "Search Keyboard Hints", get = function() return self.db.profile.optionsUI.searchKeyboardHints ~= false end, set = function(v) self.db.profile.optionsUI.searchKeyboardHints = v and true or false; frame:BuildTab("global") end },
				{ type = "label", text = "oUF Plugin Integrations" },
				{ type = "check", label = "Raid Debuffs (Party/Raid)", get = function() return pluginCfg.raidDebuffs.enabled ~= false end, set = function(v) pluginCfg.raidDebuffs.enabled = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Raid Debuff Glow", get = function() return pluginCfg.raidDebuffs.glow ~= false end, set = function(v) pluginCfg.raidDebuffs.glow = v and true or false; self:SchedulePluginUpdate() end, disabled = function() return not LibCustomGlow end },
				{ type = "dropdown", label = "Raid Debuff Glow Mode", options = { { value = "ALL", text = "All Debuffs" }, { value = "DISPELLABLE", text = "Dispellable Only" }, { value = "PRIORITY", text = "Boss/Priority Only" } }, get = function() return pluginCfg.raidDebuffs.glowMode or "ALL" end, set = function(v) pluginCfg.raidDebuffs.glowMode = v; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Raid Debuff Icon Size", min = 12, max = 36, step = 1, get = function() return tonumber(pluginCfg.raidDebuffs.size) or 18 end, set = function(v) pluginCfg.raidDebuffs.size = v; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Aura Watch (Party/Raid)", get = function() return pluginCfg.auraWatch.enabled ~= false end, set = function(v) pluginCfg.auraWatch.enabled = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Aura Watch Icon Size", min = 8, max = 22, step = 1, get = function() return tonumber(pluginCfg.auraWatch.size) or 10 end, set = function(v) pluginCfg.auraWatch.size = v; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Aura Watch Buff Slots", min = 0, max = 8, step = 1, get = function() return tonumber(pluginCfg.auraWatch.numBuffs) or 3 end, set = function(v) pluginCfg.auraWatch.numBuffs = v; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Aura Watch Debuff Slots", min = 0, max = 8, step = 1, get = function() return tonumber(pluginCfg.auraWatch.numDebuffs) or 3 end, set = function(v) pluginCfg.auraWatch.numDebuffs = v; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Aura Watch Debuff Overlay", get = function() return pluginCfg.auraWatch.showDebuffType ~= false end, set = function(v) pluginCfg.auraWatch.showDebuffType = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Frame Fader", get = function() return pluginCfg.fader.enabled == true end, set = function(v) pluginCfg.fader.enabled = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Fader Min Alpha", min = 0.05, max = 1, step = 0.05, get = function() return tonumber(pluginCfg.fader.minAlpha) or 0.45 end, set = function(v) pluginCfg.fader.minAlpha = v; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Fader Max Alpha", min = 0.05, max = 1, step = 0.05, get = function() return tonumber(pluginCfg.fader.maxAlpha) or 1 end, set = function(v) pluginCfg.fader.maxAlpha = v; self:SchedulePluginUpdate() end },
				{ type = "slider", label = "Fader Smooth", min = 0, max = 1, step = 0.05, get = function() return tonumber(pluginCfg.fader.smooth) or 0.2 end, set = function(v) pluginCfg.fader.smooth = v; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Fader: Combat", get = function() return pluginCfg.fader.combat ~= false end, set = function(v) pluginCfg.fader.combat = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Fader: Hover", get = function() return pluginCfg.fader.hover ~= false end, set = function(v) pluginCfg.fader.hover = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Fader: Player Target", get = function() return pluginCfg.fader.playerTarget ~= false end, set = function(v) pluginCfg.fader.playerTarget = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Fader: Action Targeting", get = function() return pluginCfg.fader.actionTarget == true end, set = function(v) pluginCfg.fader.actionTarget = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Fader: Unit Target", get = function() return pluginCfg.fader.unitTarget == true end, set = function(v) pluginCfg.fader.unitTarget = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Fader: Casting", get = function() return pluginCfg.fader.casting == true end, set = function(v) pluginCfg.fader.casting = v and true or false; self:SchedulePluginUpdate() end },
				{ type = "check", label = "Hide in Vehicle", get = function() return self.db.profile.visibility.hideVehicle end, set = function(v) self.db.profile.visibility.hideVehicle = v; self:ScheduleApplyVisibility() end },
				{ type = "check", label = "Hide in Pet Battles", get = function() return self.db.profile.visibility.hidePetBattle end, set = function(v) self.db.profile.visibility.hidePetBattle = v; self:ScheduleApplyVisibility() end },
				{ type = "check", label = "Hide with Override Bar", get = function() return self.db.profile.visibility.hideOverride end, set = function(v) self.db.profile.visibility.hideOverride = v; self:ScheduleApplyVisibility() end },
				{ type = "check", label = "Hide with Possess Bar", get = function() return self.db.profile.visibility.hidePossess end, set = function(v) self.db.profile.visibility.hidePossess = v; self:ScheduleApplyVisibility() end },
				{ type = "check", label = "Hide with Extra Bar", get = function() return self.db.profile.visibility.hideExtra end, set = function(v) self.db.profile.visibility.hideExtra = v; self:ScheduleApplyVisibility() end },
				{ type = "label", text = "Blizzard Unit Frames" },
				{ type = "check", label = "Hide Blizzard Player Frame", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.player ~= false end, set = function(v) self.db.profile.blizzardFrames.player = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Pet Frame", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.pet ~= false end, set = function(v) self.db.profile.blizzardFrames.pet = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Target Frame", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.target ~= false end, set = function(v) self.db.profile.blizzardFrames.target = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Target of Target Frame", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.tot ~= false end, set = function(v) self.db.profile.blizzardFrames.tot = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Focus Frame", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.focus ~= false end, set = function(v) self.db.profile.blizzardFrames.focus = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Party Frames", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.party ~= false end, set = function(v) self.db.profile.blizzardFrames.party = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Raid Frames", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.raid ~= false end, set = function(v) self.db.profile.blizzardFrames.raid = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "check", label = "Hide Blizzard Boss Frames", get = function() return self.db.profile.blizzardFrames and self.db.profile.blizzardFrames.boss ~= false end, set = function(v) self.db.profile.blizzardFrames.boss = v and true or false; self:UpdateBlizzardFrames() end },
				{ type = "label", text = "Party Header" },
				{ type = "check", label = "Show Player In Party", get = function() return self.db.profile.party.showPlayerInParty ~= false end, set = function(v) self.db.profile.party.showPlayerInParty = v; self:TrySpawnGroupHeaders(); self:ApplyPartyHeaderSettings() end },
				{ type = "check", label = "Show Player When Solo", get = function() return self.db.profile.party.showPlayerWhenSolo == true end, set = function(v) self.db.profile.party.showPlayerWhenSolo = v; self:TrySpawnGroupHeaders(); self:ApplyPartyHeaderSettings() end },
				{ type = "slider", label = "Party Vertical Spacing", min = 0, max = 40, step = 1, get = function() return self.db.profile.party.spacing end, set = function(v) self.db.profile.party.spacing = v; self:ApplyPartyHeaderSettings() end },
				{ type = "dropdown", label = "Absorb Value Tag", options = absorbTagOptions, get = function() return self.db.profile.absorbValueTag or "[suf:absorbs:abbr]" end, set = function(v) self.db.profile.absorbValueTag = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Test Mode (Show All Frames)", get = function() return self.testMode end, set = function(v) self:SetTestMode(v) end },
				{ type = "check", label = "Enable PerformanceLib Integration", get = function() return self.db.profile.performance and self.db.profile.performance.enabled end, set = function(v) self:SetPerformanceIntegrationEnabled(v) end, disabled = function() return not self.performanceLib end },
			})
			RenderAuraWatchSpellListEditor(pluginCfg.auraWatch, function()
				self:SchedulePluginUpdate()
				frame:BuildTab(tabKey)
			end)
		elseif tabKey == "performance" then
			ui:Label("PerformanceLib", true)
			ui:Paragraph("Tune presets, launch performance tools, and view a current metrics snapshot.", true)

			ui:Check("Enable PerformanceLib Integration", function()
				return self.db.profile.performance and self.db.profile.performance.enabled
			end, function(v)
				self:SetPerformanceIntegrationEnabled(v)
			end, not self.performanceLib)

			ui:Dropdown("Active Preset", {
				{ value = "Low", text = "Low" },
				{ value = "Medium", text = "Medium" },
				{ value = "High", text = "High" },
				{ value = "Ultra", text = "Ultra" },
			}, function()
				return self:GetPerformanceLibPreset()
			end, function(v)
				if self.performanceLib and self.performanceLib.SetPreset then
					self.performanceLib:SetPreset(v)
					self:DebugLog("Performance", "PerformanceLib preset set to " .. tostring(v) .. ".", 2)
					frame:BuildTab("performance")
				end
			end)
			ui:Check("Auto-refresh Snapshot (1s)", function()
				return self.db.profile.performance.optionsAutoRefresh ~= false
			end, function(v)
				self.db.profile.performance.optionsAutoRefresh = v and true or false
				frame:BuildTab("performance")
			end)

			local function AddActionButton(label, onClick)
				local x, y, width = ui:Reserve(34, false)
				local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
				button:SetSize(math.max(120, width - 8), 24)
				button:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
				button:SetText(label)
				button:SetScript("OnClick", onClick)
				return button
			end

			AddActionButton("Open /perflib UI", function()
				if self.performanceLib and self.performanceLib.ToggleDashboard then
					self.performanceLib:ToggleDashboard()
				end
			end)
			AddActionButton("Open SUF Debug", function()
				self:ShowDebugPanel()
			end)
			AddActionButton("Profile Start", function()
				self:StartPerformanceProfileFromUI()
			end)
			AddActionButton("Profile Stop", function()
				self:StopPerformanceProfileFromUI()
			end)
			AddActionButton("Profile Analyze", function()
				self:AnalyzePerformanceProfileFromUI()
			end)
			AddActionButton("Print Status Report", function()
				self:PrintStatusReport()
			end)
			AddActionButton("Refresh Snapshot", function()
				frame:BuildTab("performance")
			end)

			ui:Label("Class Resource Status", false)
			local function BuildClassResourceStatusText()
				local data = self:GetClassResourceAuditData() or {}
				local statusText = "|cffaaaaaaIDLE|r"
				if not data.hasPlayerFrame then
					statusText = "|cffff4444NOT SPAWNED|r"
				elseif data.active and data.classPowerVisible and (tonumber(data.visibleSlots) or 0) > 0 then
					statusText = "|cff00ff00HEALTHY|r"
				elseif data.active and not data.classPowerVisible then
					statusText = "|cffffcc00CONTEXT ACTIVE / BAR HIDDEN|r"
				elseif (not data.active) and data.classPowerVisible then
					statusText = "|cffffcc00CONTEXT INACTIVE / BAR VISIBLE|r"
				end
				local lines = {
					("Status: %s"):format(statusText),
					("Class: %s | SpecID: %s | PowerType: %s"):format(
						tostring(data.classTag or "UNKNOWN"),
						tostring(data.specID or "n/a"),
						tostring(data.powerToken or "n/a")
					),
					("Expected: %s | Active Context: %s"):format(
						tostring(data.expected or "None"),
						tostring(data.active and true or false)
					),
					("Player Frame: %s | Resource Visible: %s | Visible Slots: %s"):format(
						tostring(data.hasPlayerFrame and true or false),
						tostring(data.classPowerVisible and true or false),
						tostring(data.visibleSlots or 0)
					),
				}
				if data.classTag == "DRUID" then
					lines[#lines + 1] = "Druid combo points are only active in Cat Form."
				elseif data.classTag == "DEATHKNIGHT" then
					lines[#lines + 1] = "DK runes use oUF Runes; no dedicated SUF top-row class bar yet."
				end
				return table.concat(lines, "\n")
			end
			ui:Paragraph(BuildClassResourceStatusText(), true)

			ui:Label("Current Snapshot", false)
			local function BuildPerformanceSnapshotText()
				local frameStats = self.performanceLib and self.performanceLib.GetFrameTimeStats and self.performanceLib:GetFrameTimeStats() or {}
				local eventStats = self.performanceLib and self.performanceLib.EventCoalescer and self.performanceLib.EventCoalescer.GetStats and self.performanceLib.EventCoalescer:GetStats() or {}
				local dirtyStats = self.performanceLib and self.performanceLib.DirtyFlagManager and self.performanceLib.DirtyFlagManager.GetStats and self.performanceLib.DirtyFlagManager:GetStats() or {}
				local poolStats = self.performanceLib and self.performanceLib.FramePoolManager and self.performanceLib.FramePoolManager.GetStats and self.performanceLib.FramePoolManager:GetStats() or {}
				local profilerStats = self.performanceLib and self.performanceLib.PerformanceProfiler and self.performanceLib.PerformanceProfiler.GetStats and self.performanceLib.PerformanceProfiler:GetStats() or {}
				local isRecording = profilerStats.isRecording and "Yes" or "No"
				return ("Preset: %s\nFrame: avg %.2fms | p95 %.2f | p99 %.2f\nEventBus: coalesced=%d dispatched=%d queued=%d savings=%.1f%%\nDirty: processed=%d batches=%d queued=%d\nPools: created=%d reused=%d released=%d\nProfiler: recording=%s events=%d"):format(
					self:GetPerformanceLibPreset(),
					tonumber(frameStats.avg or 0) or 0,
					tonumber(frameStats.P95 or 0) or 0,
					tonumber(frameStats.P99 or 0) or 0,
					tonumber(eventStats.totalCoalesced or 0) or 0,
					tonumber(eventStats.totalDispatched or 0) or 0,
					tonumber(eventStats.queuedEvents or 0) or 0,
					tonumber(eventStats.savingsPercent or 0) or 0,
					tonumber(dirtyStats.framesProcessed or 0) or 0,
					tonumber(dirtyStats.batchesRun or 0) or 0,
					tonumber(dirtyStats.currentDirtyCount or 0) or 0,
					tonumber(poolStats.totalCreated or 0) or 0,
					tonumber(poolStats.totalReused or 0) or 0,
					tonumber(poolStats.totalReleased or 0) or 0,
					isRecording,
					tonumber(profilerStats.eventCount or 0) or 0
				)
			end

			ui:BeginNewLine()
			local snapshot = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			snapshot:SetPoint("TOPLEFT", page, "TOPLEFT", 12, ui.y)
			snapshot:SetWidth(ui.width)
			snapshot:SetJustifyH("LEFT")
			snapshot:SetJustifyV("TOP")
			snapshot:SetText(BuildPerformanceSnapshotText())
			local snapshotHeight = math.max(96, math.floor((snapshot:GetStringHeight() or 0) + 0.5))
			ui.y = ui.y - (snapshotHeight + 8)

			frame.performanceSnapshotText = snapshot
			frame.performanceSnapshotPage = page
			frame.performanceBuildSnapshotText = BuildPerformanceSnapshotText

			ui:Label("SUF Status Report", false)
			ui:Paragraph(self:BuildStatusReportText(), true)

			if self.db.profile.performance.optionsAutoRefresh ~= false then
				frame.performanceSnapshotTicker = C_Timer.NewTicker(1.0, function()
					if not frame:IsShown() or frame.currentTab ~= "performance" then
						StopPerformanceSnapshotTicker()
						return
					end
					if frame.performanceSnapshotText and frame.performanceBuildSnapshotText then
						frame.performanceSnapshotText:SetText(frame.performanceBuildSnapshotText())
						local textHeight = frame.performanceSnapshotText:GetStringHeight() or 0
						if frame.performanceSnapshotPage then
							local minHeight = math.max(96, math.floor(textHeight + 8))
							if minHeight > 0 then
								local currentHeight = frame.performanceSnapshotPage:GetHeight() or 0
								if minHeight > currentHeight then
									frame.performanceSnapshotPage:SetHeight(minHeight)
								end
							end
						end
					end
				end)
			end
		elseif tabKey == "importexport" then
			ui:Label("Import / Export", true)
			ui:Paragraph("Wizard flow: paste data, Validate, Preview, then Apply.", true)
			local box = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			box:SetAutoFocus(false)
			box:SetMultiLine(true)
			box:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -36)
			box:SetSize(math.max(420, contentHost:GetWidth() - 72), 220)
			local wizardState = {
				parsed = nil,
				err = nil,
				validation = nil,
				preview = nil,
			}
			frame.importInstallerState = frame.importInstallerState or { step = 1, status = {} }
			local installerState = frame.importInstallerState
			local function MarkInstallerStep(stepIndex, stateText)
				installerState.status[stepIndex] = stateText
				if stateText == "done" and installerState.step <= stepIndex then
					installerState.step = stepIndex + 1
				elseif stateText == "error" then
					installerState.step = stepIndex
				end
			end
			local wizardStatus = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			wizardStatus:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
			wizardStatus:SetWidth(math.max(420, contentHost:GetWidth() - 72))
			wizardStatus:SetJustifyH("LEFT")
			wizardStatus:SetText("Ready.")
			local wizardPreview = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			wizardPreview:SetPoint("TOPLEFT", wizardStatus, "BOTTOMLEFT", 0, -6)
			wizardPreview:SetWidth(math.max(420, contentHost:GetWidth() - 72))
			wizardPreview:SetJustifyH("LEFT")
			wizardPreview:SetJustifyV("TOP")
			wizardPreview:SetText("")
			local function SetWizardStatus(text, warn)
				wizardStatus:SetText(text or "")
				if warn then
					wizardStatus:SetTextColor(1.00, 0.56, 0.60)
				else
					wizardStatus:SetTextColor(0.56, 1.00, 0.66)
				end
			end
			local function RunInstallerStep(stepIndex)
				if stepIndex == 1 then
					local data, err = self:DeserializeProfile(box:GetText() or "")
					if not data then
						wizardState.parsed, wizardState.validation, wizardState.preview = nil, nil, nil
						SetWizardStatus("Validation failed: " .. tostring(err), true)
						MarkInstallerStep(1, "error")
						return false
					end
					local validation, validationErr = self:ValidateImportedProfileData(data)
					if not validation or validation.ok == false then
						SetWizardStatus("Validation failed: " .. tostring(validationErr or "invalid payload"), true)
						MarkInstallerStep(1, "error")
						return false
					end
					wizardState.parsed = data
					wizardState.validation = validation
					wizardState.preview = nil
					wizardPreview:SetText("")
					SetWizardStatus("Validation passed.", false)
					MarkInstallerStep(1, "done")
					return true
				elseif stepIndex == 2 then
					if not wizardState.parsed then
						SetWizardStatus("Preview blocked: run validation first.", true)
						MarkInstallerStep(2, "error")
						return false
					end
					wizardState.preview = self:BuildImportedProfilePreview(wizardState.parsed, wizardState.validation)
					wizardPreview:SetText(wizardState.preview.summary or "")
					SetWizardStatus("Preview ready.", false)
					MarkInstallerStep(2, "done")
					return true
				elseif stepIndex == 3 then
					if not wizardState.parsed then
						SetWizardStatus("Apply blocked: run validation first.", true)
						MarkInstallerStep(3, "error")
						return false
					end
					local ok, applyErr, meta = self:ApplyImportedProfile(wizardState.parsed)
					if not ok then
						SetWizardStatus("Import failed: " .. tostring(applyErr), true)
						if meta and meta.manualFallback and meta.manualText then
							wizardPreview:SetText(meta.manualText)
						end
						MarkInstallerStep(3, "error")
						return false
					end
					if meta and meta.preview and meta.preview.summary then
						wizardPreview:SetText(meta.preview.summary)
					end
					SetWizardStatus("Import applied successfully.", false)
					MarkInstallerStep(3, "done")
					return true
				elseif stepIndex == 4 then
					local summary = "Import complete.\nReload recommended to finalize secure/UI state.\n\nReload UI now?"
					self:PromptReloadAfterImport(summary)
					SetWizardStatus("Reload prompt opened.", false)
					MarkInstallerStep(4, "done")
					return true
				end
				return false
			end
			local exportBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			exportBtn:SetSize(140, 24)
			exportBtn:SetPoint("TOPLEFT", wizardStatus, "BOTTOMLEFT", 0, -8)
			exportBtn:SetText("Export")
			exportBtn:SetScript("OnClick", function()
				local data, err = self:SerializeProfile()
				if data then
					box:SetText(data)
					SetWizardStatus("Exported current profile into the input box.", false)
				else
					self:Print(addonName .. ": " .. err)
					SetWizardStatus(err, true)
				end
			end)
			local validateBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			validateBtn:SetSize(100, 24)
			validateBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
			validateBtn:SetText("Validate")
			validateBtn:SetScript("OnClick", function()
				local data, err = self:DeserializeProfile(box:GetText() or "")
				if data then
					local validation, validationErr = self:ValidateImportedProfileData(data)
					wizardState.parsed = data
					wizardState.err = nil
					wizardState.validation = validation
					wizardState.preview = nil
					wizardPreview:SetText("")
					if validation and validation.ok ~= false then
						SetWizardStatus(("Validation passed. Top-level keys: %d"):format(validation.keyCount or 0), false)
						MarkInstallerStep(1, "done")
					else
						local reason = validationErr or "Validation failed."
						SetWizardStatus("Validation failed: " .. tostring(reason), true)
						wizardState.err = reason
						MarkInstallerStep(1, "error")
					end
				else
					self:Print(addonName .. ": " .. err)
					wizardState.parsed = nil
					wizardState.err = err
					wizardState.validation = nil
					wizardState.preview = nil
					wizardPreview:SetText("")
					SetWizardStatus("Validation failed: " .. tostring(err), true)
					MarkInstallerStep(1, "error")
				end
			end)
			local previewBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			previewBtn:SetSize(100, 24)
			previewBtn:SetPoint("LEFT", validateBtn, "RIGHT", 8, 0)
			previewBtn:SetText("Preview")
			previewBtn:SetScript("OnClick", function()
				local data = wizardState.parsed
				if not data then
					SetWizardStatus("Nothing validated yet. Click Validate first.", true)
					return
				end
				local validation = wizardState.validation or self:ValidateImportedProfileData(data)
				if not validation or validation.ok == false then
					SetWizardStatus("Preview unavailable: validation failed.", true)
					return
				end
				local preview = self:BuildImportedProfilePreview(data, validation)
				wizardState.preview = preview
				wizardPreview:SetText(preview.summary or "")
				SetWizardStatus("Preview generated. Review impact details below.", false)
				MarkInstallerStep(2, "done")
			end)
			local importBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			importBtn:SetSize(100, 24)
			importBtn:SetPoint("LEFT", previewBtn, "RIGHT", 8, 0)
			importBtn:SetText("Apply")
			importBtn:SetScript("OnClick", function()
				local data = wizardState.parsed
				if not data then
					SetWizardStatus("Nothing validated yet. Click Validate first.", true)
					return
				end
				local ok, applyErr, meta = self:ApplyImportedProfile(data)
				if ok then
					local adapterText = meta and meta.adapter and (" via " .. tostring(meta.adapter)) or ""
					SetWizardStatus("Import applied successfully" .. adapterText .. ".", false)
					if meta and meta.preview and meta.preview.summary then
						wizardPreview:SetText(meta.preview.summary)
					end
					if meta and meta.preview and meta.preview.reloadSummary then
						self:PromptReloadAfterImport("Import complete.\n" .. tostring(meta.preview.reloadSummary) .. "\n\nReload UI now?")
					end
					MarkInstallerStep(3, "done")
					frame:BuildTab(tabKey)
				else
					self:Print(addonName .. ": " .. tostring(applyErr))
					if meta and meta.manualFallback and meta.manualText then
						wizardPreview:SetText(meta.manualText)
					end
					MarkInstallerStep(3, "error")
					SetWizardStatus("Import failed: " .. tostring(applyErr), true)
				end
			end)
			local manualBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			manualBtn:SetSize(170, 24)
			manualBtn:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)
			manualBtn:SetText("Manual Fallback Plan")
			manualBtn:SetScript("OnClick", function()
				local data = wizardState.parsed
				if not data then
					SetWizardStatus("Manual fallback needs validated data.", true)
					return
				end
				local text = self:BuildManualImportFallbackText(data, wizardState.validation)
				wizardPreview:SetText(text)
				SetWizardStatus("Manual fallback plan generated.", false)
			end)
			wizardPreview:ClearAllPoints()
			wizardPreview:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -8)
			wizardPreview:SetWidth(math.max(420, contentHost:GetWidth() - 72))

			local controlsBottom = manualBtn:GetBottom() or importBtn:GetBottom() or wizardPreview:GetBottom()
			local pageTop = page:GetTop()
			if controlsBottom and pageTop and pageTop > controlsBottom then
				ui.y = -((pageTop - controlsBottom) + 16)
			else
				ui.y = ui.y - 120
			end
			ui:BeginNewLine()
			ui:Label("Migration Installer", false)
			local steps = {
				{ title = "1. Validate Import Payload" },
				{ title = "2. Preview Impact" },
				{ title = "3. Apply With Rollback Safety" },
				{ title = "4. Reload Confirmation" },
			}
			local doneSteps = 0
			for i = 1, #steps do
				local status = installerState.status[i] or "pending"
				if status == "done" then
					doneSteps = doneSteps + 1
				end
				local marker = (status == "done" and "[OK]") or (status == "error" and "[ERR]") or (installerState.step == i and "[RUN]") or "[PEND]"
				ui:Paragraph(("%s %s"):format(marker, steps[i].title), true)
			end
			local progress = math.floor((doneSteps / #steps) * 100)
			ui:Paragraph(("Progress: %d%% (%d/%d)"):format(progress, doneSteps, #steps), true)
			ui:Button("Run Next Installer Step", function()
				local nextStep = math.max(1, math.min(#steps, installerState.step or 1))
				RunInstallerStep(nextStep)
				frame:BuildTab(tabKey)
			end, true)
			ui:Button("Run All Pending Steps", function()
				local start = math.max(1, math.min(#steps, installerState.step or 1))
				for i = start, #steps do
					if not RunInstallerStep(i) then
						break
					end
				end
				frame:BuildTab(tabKey)
			end, true)
			ui:Button("Reset Installer Steps", function()
				installerState.step = 1
				installerState.status = {}
				SetWizardStatus("Installer steps reset.", false)
				frame:BuildTab(tabKey)
			end, true)
		elseif tabKey == "tags" then
			ui:Label("Tags Reference", true)
			ui:Paragraph("Use these in Name/Level/Health/Power fields. Grouped below by unit + sub type and by oUF tag category.", true)
			ui:Label("Per-Unit Sub Types", false)
			for _, unitKey in ipairs(UNIT_TYPE_ORDER) do
				local unitTags = self.db.profile.tags and self.db.profile.tags[unitKey]
				if unitTags then
					ui:Label(GetUnitLabel(unitKey), false)
					ui:Paragraph("name: " .. tostring(unitTags.name or "") .. "\nlevel: " .. tostring(unitTags.level or "") .. "\nhealth: " .. tostring(unitTags.health or "") .. "\npower: " .. tostring(unitTags.power or ""), true)
				end
			end

			local allTags = CollectOUFTags()
			local categories = {
				"Identity",
				"Health",
				"Power",
				"Cast",
				"Auras",
				"Status",
				"Other",
			}
			local grouped = {}
			for i = 1, #categories do
				grouped[categories[i]] = {}
			end
			for i = 1, #allTags do
				local category = CategorizeTag(allTags[i])
				grouped[category][#grouped[category] + 1] = allTags[i]
			end

			ui:Label("Available oUF Tags", false)
			for i = 1, #categories do
				local category = categories[i]
				local list = grouped[category]
				if list and #list > 0 then
					ui:Label(category, false)
					ui:Paragraph(table.concat(list, ", "), true)
				end
			end
			local usedTags = {}
			for _, unitKey in ipairs(UNIT_TYPE_ORDER) do
				local unitTags = self.db.profile.tags and self.db.profile.tags[unitKey]
				if unitTags then
					local fields = { "name", "level", "health", "power" }
					for fieldIndex = 1, #fields do
						local fieldValue = unitTags[fields[fieldIndex]]
						if type(fieldValue) == "string" then
							for token in string.gmatch(fieldValue, "%[([^%]]+)%]") do
								usedTags[token] = true
							end
						end
					end
				end
			end
			local availableNotUsed = {}
			for i = 1, #allTags do
				local tagName = allTags[i]
				if not usedTags[tagName] and string.sub(tagName, 1, 4) ~= "suf:" then
					availableNotUsed[#availableNotUsed + 1] = tagName
				end
			end
			ui:Label("Available but Not in Current Tag Strings", false)
			if #availableNotUsed > 0 then
				local preview = {}
				local limit = math.min(#availableNotUsed, 60)
				for i = 1, limit do
					preview[#preview + 1] = availableNotUsed[i]
				end
				ui:Paragraph(table.concat(preview, ", "), true)
				if #availableNotUsed > limit then
					ui:Paragraph(string.format("...plus %d more tags.", #availableNotUsed - limit), true)
				end
			else
				ui:Paragraph("All currently available non-SUF tags are already in use by your unit tag strings.", true)
			end

			ui:Label("SUF Custom Tags", false)
			local sufTagDescriptions = {
				["suf:absorbs"] = "Total absorbs (raw)",
				["suf:absorbs:abbr"] = "Total absorbs (abbreviated)",
				["suf:incoming"] = "Incoming heals (raw)",
				["suf:incoming:abbr"] = "Incoming heals (abbreviated)",
				["suf:healabsorbs"] = "Heal absorbs (raw)",
				["suf:healabsorbs:abbr"] = "Heal absorbs (abbreviated)",
				["suf:ehp"] = "Effective health (health + absorbs, raw)",
				["suf:ehp:abbr"] = "Effective health (health + absorbs, abbreviated)",
				["suf:missinghp"] = "Missing health (raw)",
				["suf:missinghp:abbr"] = "Missing health (abbreviated)",
				["suf:missingpp"] = "Missing power (raw)",
				["suf:missingpp:abbr"] = "Missing power (abbreviated)",
				["suf:status"] = "Status text (Dead/Ghost/Offline/AFK/DND)",
				["suf:health:percent-with-absorbs"] = "Health percent including absorbs (status-aware)",
			}
			local sufTags = {}
			for i = 1, #allTags do
				local tagName = allTags[i]
				if string.sub(tagName, 1, 4) == "suf:" then
					sufTags[#sufTags + 1] = tagName
				end
			end
			if #sufTags > 0 then
				local lines = {}
				for i = 1, #sufTags do
					local tagName = sufTags[i]
					lines[#lines + 1] = tagName .. " - " .. (sufTagDescriptions[tagName] or "SUF custom tag")
				end
				ui:Paragraph(table.concat(lines, "\n"), true)
			else
				ui:Paragraph("No SUF custom tags are currently registered.", true)
			end
		elseif tabKey == "credits" then
			ui:Label("Credits", true)
			ui:Paragraph("SimpleUnitFrames (SUF)\nPrimary Author: Grevin", true)
			ui:Paragraph("UnhaltedUnitFrames (UUF)\nReference architecture, performance patterns, and feature inspirations.\nIncludes UUF-inspired ports plus your personal custom changes that are not present in UUF mainline.", true)
			ui:Paragraph("PerformanceLib\nIntegrated optional performance framework for event coalescing, dirty batching, and profiling workflows.", true)
			ui:Paragraph("Libraries Used\nAce3 (AceAddon/AceDB/AceGUI/AceSerializer), oUF, oUF_Plugins, LibSharedMedia-3.0, LibDualSpec-1.0, LibSerialize, LibDeflate, LibDataBroker-1.1, LibDBIcon-1.0, LibAnim, LibCustomGlow-1.0, LibSimpleSticky, LibTranslit-1.0, UTF8, LibDispel-1.0, CallbackHandler-1.0, LibStub, TaintLess.", true)
			ui:Paragraph("Special Thanks\nBlizzard UI Source and WoW addon ecosystem maintainers.", true)
		else
			local unitSettings = self:GetUnitSettings(tabKey)
			local tags = self.db.profile.tags[tabKey]
			local size = self.db.profile.sizes[tabKey]
			local plugins = self:GetPluginSettings()
			local unitPluginProfile = nil
			if self:IsGroupUnitType(tabKey) then
				plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
				MergeDefaults(plugins.units, defaults.profile.plugins.units)
				unitPluginProfile = plugins.units[tabKey] or CopyTableDeep(defaults.profile.plugins.units[tabKey])
				plugins.units[tabKey] = unitPluginProfile
				MergeDefaults(unitPluginProfile, defaults.profile.plugins.units[tabKey])
			end
			unitSettings.fontSizes = unitSettings.fontSizes or CopyTableDeep(self.db.profile.fontSizes)
			unitSettings.portrait = unitSettings.portrait or { mode = "none", size = 32, showClass = false, position = "LEFT" }
			unitSettings.media = unitSettings.media or { statusbar = self.db.profile.media.statusbar }
			unitSettings.castbar = unitSettings.castbar or CopyTableDeep(DEFAULT_UNIT_CASTBAR)
			unitSettings.layout = unitSettings.layout or CopyTableDeep(DEFAULT_UNIT_LAYOUT)
			unitSettings.mainBarsBackground = unitSettings.mainBarsBackground or CopyTableDeep(DEFAULT_UNIT_MAIN_BARS_BACKGROUND)
			unitSettings.healPrediction = unitSettings.healPrediction or CopyTableDeep(DEFAULT_HEAL_PREDICTION)
			ui:Label((tabKey == "tot" and "TargetOfTarget" or tabKey:upper()) .. " Options", true)
			self.db.profile.optionsUI = self.db.profile.optionsUI or {}
			self.db.profile.optionsUI.unitSubTabs = self.db.profile.optionsUI.unitSubTabs or {}
			local UNIT_SUB_TABS = (self.GetOptionsUnitSubTabs and self:GetOptionsUnitSubTabs()) or {}
			local activeUnitSubTab = tostring(self.db.profile.optionsUI.unitSubTabs[tabKey] or "all")
			if ui:HasSearch() then
				activeUnitSubTab = "all"
			end
			ui:Label("Section Tabs", false)
			local tabX, tabY, tabWidth = ui:Reserve(34, true)
			local tabStrip = CreateFrame("Frame", nil, page)
			tabStrip:SetPoint("TOPLEFT", page, "TOPLEFT", tabX, tabY)
			tabStrip:SetSize(tabWidth, 24)
			local spacing = 4
			local tabButtonWidth = math.max(72, math.floor((tabWidth - (spacing * (#UNIT_SUB_TABS - 1))) / #UNIT_SUB_TABS))
			local previousTabButton = nil
			for i = 1, #UNIT_SUB_TABS do
				local subTab = UNIT_SUB_TABS[i]
				local btn = CreateFrame("Button", nil, tabStrip, "BackdropTemplate")
				btn:SetSize(tabButtonWidth, 22)
				if previousTabButton then
					btn:SetPoint("LEFT", previousTabButton, "RIGHT", spacing, 0)
				else
					btn:SetPoint("LEFT", tabStrip, "LEFT", 0, 0)
				end
				btn:SetBackdrop({
					bgFile = "Interface\\Buttons\\WHITE8x8",
					edgeFile = "Interface\\Buttons\\WHITE8x8",
					edgeSize = 1,
				})
				local selected = activeUnitSubTab == subTab.key
				if selected then
					addon:ApplySUFBackdropColors(btn, UI_STYLE.navSelected, { UI_STYLE.navSelectedBorder[1], UI_STYLE.navSelectedBorder[2], UI_STYLE.navSelectedBorder[3], 0.95 }, false)
				else
					addon:ApplySUFBackdropColors(btn, UI_STYLE.navDefault, { UI_STYLE.navDefaultBorder[1], UI_STYLE.navDefaultBorder[2], UI_STYLE.navDefaultBorder[3], 0.95 }, false)
				end
				local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				label:SetPoint("CENTER", btn, "CENTER", 0, 0)
				label:SetText(subTab.label)
				if selected then
					label:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
				else
					label:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
				end
				btn:SetScript("OnClick", function()
					self.db.profile.optionsUI.unitSubTabs[tabKey] = subTab.key
					frame:BuildTab(tabKey)
				end)
				previousTabButton = btn
			end
			local function ShowUnitSection(sectionKey)
				if ui:HasSearch() then
					return true
				end
				return activeUnitSubTab == "all" or activeUnitSubTab == tostring(sectionKey)
			end
			if ShowUnitSection("general") and ui:Section("General", "unit.general", true) then
				ui:Slider("Frame Width", 80, 400, 1, function() return size.width end, function(v) size.width = v; self:ScheduleUpdateAll() end)
				ui:Slider("Frame Height", 18, 80, 1, function() return size.height end, function(v) size.height = v; self:ScheduleUpdateAll() end)
				ui:Edit("Name Tag", function() return tags.name end, function(v) tags.name = v; self:ScheduleUpdateAll() end)
				ui:Edit("Level Tag", function() return tags.level end, function(v) tags.level = v; self:ScheduleUpdateAll() end)
				ui:Edit("Health Tag", function() return tags.health end, function(v) tags.health = v; self:ScheduleUpdateAll() end)
				ui:Edit("Power Tag", function() return tags.power end, function(v) tags.power = v; self:ScheduleUpdateAll() end)
				self._tagPresetSelection = self._tagPresetSelection or {}
				if not self._tagPresetSelection[tabKey] then
					self._tagPresetSelection[tabKey] = "COMPACT"
				end
				ui:Label("Tag Presets", false)
				ui:Dropdown("Preset", TAG_PRESETS, function()
					return self._tagPresetSelection[tabKey] or "COMPACT"
				end, function(v)
					self._tagPresetSelection[tabKey] = v
				end)
				ui:Button("Apply Selected Preset", function()
					ApplyUnitTagPreset(tabKey, self._tagPresetSelection[tabKey] or "COMPACT")
					frame:BuildTab(tabKey)
				end, true)
			end
			if ShowUnitSection("bars") and ui:Section("Bars", "unit.bars", true) then
				ui:Label("Main Bars Background", false)
			ui:Check("Use Global Main Bars Background", function()
				return unitSettings.mainBarsBackground.useGlobal ~= false
			end, function(v)
				unitSettings.mainBarsBackground.useGlobal = v and true or false
				self:ScheduleUpdateAll()
				frame:BuildTab(tabKey)
			end)
			if unitSettings.mainBarsBackground.useGlobal ~= false then
				ui:Paragraph("Using Global Main Bars Background settings.", true)
			else
				ui:Check("Enable Main Bars Background", function()
					return unitSettings.mainBarsBackground.enabled ~= false
				end, function(v)
					unitSettings.mainBarsBackground.enabled = v and true or false
					self:ScheduleUpdateAll()
				end)
				if #statusbarOptions > 0 then
					ui:Dropdown("Main Bars Background Texture", statusbarOptions, function()
						return unitSettings.mainBarsBackground.texture
					end, function(v)
						unitSettings.mainBarsBackground.texture = v
						self:ScheduleUpdateAll()
					end)
				else
					ui:Edit("Main Bars Background Texture", function()
						return unitSettings.mainBarsBackground.texture
					end, function(v)
						unitSettings.mainBarsBackground.texture = v
						self:ScheduleUpdateAll()
					end)
				end
				ui:Color("Main Bars Background Color", function()
					return unitSettings.mainBarsBackground.color
				end, function(r, g, b)
					unitSettings.mainBarsBackground.color[1], unitSettings.mainBarsBackground.color[2], unitSettings.mainBarsBackground.color[3] = r, g, b
					self:ScheduleUpdateAll()
				end)
				ui:Slider("Main Bars Background Opacity", 0, 1, 0.05, function()
					return unitSettings.mainBarsBackground.alpha
				end, function(v)
					unitSettings.mainBarsBackground.alpha = v
					self:ScheduleUpdateAll()
				end)
			end
			if #statusbarOptions > 0 then
				ui:Dropdown("Statusbar Texture", statusbarOptions, function() return unitSettings.media.statusbar end, function(v) unitSettings.media.statusbar = v; self:ScheduleUpdateAll() end)
			else
				ui:Edit("Statusbar Texture Name", function() return unitSettings.media.statusbar end, function(v) unitSettings.media.statusbar = v; self:ScheduleUpdateAll() end)
			end
			ui:Slider("Name Font Size", 8, 20, 1, function() return unitSettings.fontSizes.name end, function(v) unitSettings.fontSizes.name = v; self:ScheduleUpdateAll() end)
			ui:Slider("Level Font Size", 8, 20, 1, function() return unitSettings.fontSizes.level end, function(v) unitSettings.fontSizes.level = v; self:ScheduleUpdateAll() end)
			ui:Slider("Health Font Size", 8, 20, 1, function() return unitSettings.fontSizes.health end, function(v) unitSettings.fontSizes.health = v; self:ScheduleUpdateAll() end)
			ui:Slider("Power Font Size", 8, 20, 1, function() return unitSettings.fontSizes.power end, function(v) unitSettings.fontSizes.power = v; self:ScheduleUpdateAll() end)
			ui:Slider("Cast Font Size", 8, 20, 1, function() return unitSettings.fontSizes.cast end, function(v) unitSettings.fontSizes.cast = v; self:ScheduleUpdateAll() end)
			ui:Label("Power Cost Prediction", false)
			ui:Check("Enable Power Cost Prediction", function()
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				return cfg.enabled == true
			end, function(v)
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				cfg.enabled = v and true or false
				self:ScheduleUpdateUnitType(tabKey)
			end)
			ui:Slider("Power Prediction Height", 1, 16, 1, function()
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				return tonumber(cfg.height) or 3
			end, function(v)
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				cfg.height = v
				self:ScheduleUpdateUnitType(tabKey)
			end)
			ui:Slider("Power Prediction Opacity", 0.05, 1, 0.05, function()
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				return tonumber(cfg.opacity) or 0.70
			end, function(v)
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				cfg.opacity = v
				self:ScheduleUpdateUnitType(tabKey)
			end)
			ui:Color("Power Prediction Color", function()
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				return cfg.color
			end, function(r, g, b)
				local cfg = self:GetUnitPowerPredictionSettings(tabKey)
				cfg.color[1], cfg.color[2], cfg.color[3] = r, g, b
				self:ScheduleUpdateUnitType(tabKey)
			end)
			end
			if ShowUnitSection("castbar") and ui:Section("Castbar", "unit.castbar", true) then
			ui:Label("Castbar", false)
			ui:Check("Enable Castbar", function() return unitSettings.castbar.enabled ~= false end, function(v) unitSettings.castbar.enabled = v; self:ScheduleUpdateAll() end)
			ui:Check("Show Cast Spell Text", function() return unitSettings.castbar.showText ~= false end, function(v) unitSettings.castbar.showText = v; self:ScheduleUpdateAll() end)
			ui:Check("Show Cast Time", function() return unitSettings.castbar.showTime ~= false end, function(v) unitSettings.castbar.showTime = v; self:ScheduleUpdateAll() end)
			ui:Check("Reverse Cast Fill", function() return unitSettings.castbar.reverseFill == true end, function(v) unitSettings.castbar.reverseFill = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Castbar Color Profile", {
				{ value = "GLOBAL", text = "Use Global" },
				{ value = "UUF", text = "UUF" },
				{ value = "Blizzard", text = "Blizzard" },
				{ value = "HighContrast", text = "High Contrast" },
			}, function() return unitSettings.castbar.colorProfile end, function(v) unitSettings.castbar.colorProfile = v; self:ScheduleUpdateAll() end)
			ui:Slider("Castbar Width (% of frame)", 50, 150, 1, function() return unitSettings.castbar.widthPercent end, function(v) unitSettings.castbar.widthPercent = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Castbar Anchor", {
				{ value = "BELOW_FRAME", text = "Below Frame" },
				{ value = "ABOVE_FRAME", text = "Above Frame" },
				{ value = "BELOW_CLASSPOWER", text = "Below ClassPower" },
			}, function() return unitSettings.castbar.anchor end, function(v) unitSettings.castbar.anchor = v; self:ScheduleUpdateAll() end)
			ui:Slider("Castbar Gap", 0, 40, 1, function() return unitSettings.castbar.gap end, function(v) unitSettings.castbar.gap = v; self:ScheduleUpdateAll() end)
			ui:Slider("Castbar Fine Offset", -40, 40, 1, function() return unitSettings.castbar.offsetY end, function(v) unitSettings.castbar.offsetY = v; self:ScheduleUpdateAll() end)
			end
			if ShowUnitSection("plugins") and ui:Section("Plugins", "unit.plugins", true) then
				if unitPluginProfile then
					ui:Label("Plugin Overrides", false)
					ui:Check("Use Global Plugin Settings", function()
						return unitPluginProfile.useGlobal ~= false
					end, function(v)
						if v then
							unitPluginProfile.useGlobal = true
						else
							self:SeedUnitPluginOverridesFromGlobal(tabKey)
							unitPluginProfile = self:GetPluginSettings().units[tabKey]
						end
						self:SchedulePluginUpdate(tabKey)
						frame:BuildTab(tabKey)
					end)
					if unitPluginProfile.useGlobal ~= false then
						ui:Paragraph("Using global plugin configuration for this unit type.", true)
					else
					ui:Check("Raid Debuffs", function()
						return unitPluginProfile.raidDebuffs.enabled ~= false
					end, function(v)
						unitPluginProfile.raidDebuffs.enabled = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Raid Debuff Icon Size", 12, 36, 1, function()
						return tonumber(unitPluginProfile.raidDebuffs.size) or 18
					end, function(v)
						unitPluginProfile.raidDebuffs.size = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Raid Debuff Glow", function()
						return unitPluginProfile.raidDebuffs.glow ~= false
					end, function(v)
						unitPluginProfile.raidDebuffs.glow = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end, not LibCustomGlow)
					ui:Dropdown("Raid Debuff Glow Mode", {
						{ value = "ALL", text = "All Debuffs" },
						{ value = "DISPELLABLE", text = "Dispellable Only" },
						{ value = "PRIORITY", text = "Boss/Priority Only" },
					}, function()
						return unitPluginProfile.raidDebuffs.glowMode or "ALL"
					end, function(v)
						unitPluginProfile.raidDebuffs.glowMode = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Aura Watch", function()
						return unitPluginProfile.auraWatch.enabled ~= false
					end, function(v)
						unitPluginProfile.auraWatch.enabled = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Aura Watch Icon Size", 8, 22, 1, function()
						return tonumber(unitPluginProfile.auraWatch.size) or 10
					end, function(v)
						unitPluginProfile.auraWatch.size = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Aura Watch Buff Slots", 0, 8, 1, function()
						return tonumber(unitPluginProfile.auraWatch.numBuffs) or 3
					end, function(v)
						unitPluginProfile.auraWatch.numBuffs = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Aura Watch Debuff Slots", 0, 8, 1, function()
						return tonumber(unitPluginProfile.auraWatch.numDebuffs) or 3
					end, function(v)
						unitPluginProfile.auraWatch.numDebuffs = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Aura Watch Debuff Overlay", function()
						return unitPluginProfile.auraWatch.showDebuffType ~= false
					end, function(v)
						unitPluginProfile.auraWatch.showDebuffType = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Aura Watch Replace Defaults", function()
						return unitPluginProfile.auraWatch.replaceDefaults == true
					end, function(v)
						unitPluginProfile.auraWatch.replaceDefaults = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					RenderAuraWatchSpellListEditor(unitPluginProfile.auraWatch, function()
						self:SchedulePluginUpdate(tabKey)
						frame:BuildTab(tabKey)
					end)
					ui:Check("Frame Fader", function()
						return unitPluginProfile.fader.enabled == true
					end, function(v)
						unitPluginProfile.fader.enabled = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Fader Min Alpha", 0.05, 1, 0.05, function()
						return tonumber(unitPluginProfile.fader.minAlpha) or 0.45
					end, function(v)
						unitPluginProfile.fader.minAlpha = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Fader Max Alpha", 0.05, 1, 0.05, function()
						return tonumber(unitPluginProfile.fader.maxAlpha) or 1
					end, function(v)
						unitPluginProfile.fader.maxAlpha = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Slider("Fader Smooth", 0, 1, 0.05, function()
						return tonumber(unitPluginProfile.fader.smooth) or 0.2
					end, function(v)
						unitPluginProfile.fader.smooth = v
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Fader: Combat", function()
						return unitPluginProfile.fader.combat ~= false
					end, function(v)
						unitPluginProfile.fader.combat = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Fader: Hover", function()
						return unitPluginProfile.fader.hover ~= false
					end, function(v)
						unitPluginProfile.fader.hover = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Fader: Player Target", function()
						return unitPluginProfile.fader.playerTarget ~= false
					end, function(v)
						unitPluginProfile.fader.playerTarget = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Fader: Action Targeting", function()
						return unitPluginProfile.fader.actionTarget == true
					end, function(v)
						unitPluginProfile.fader.actionTarget = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Fader: Unit Target", function()
						return unitPluginProfile.fader.unitTarget == true
					end, function(v)
						unitPluginProfile.fader.unitTarget = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					ui:Check("Fader: Casting", function()
						return unitPluginProfile.fader.casting == true
					end, function(v)
						unitPluginProfile.fader.casting = v and true or false
						self:SchedulePluginUpdate(tabKey)
					end)
					end
				else
					ui:Paragraph("This unit type does not support plugin overrides.", true)
				end
			end
			if ShowUnitSection("auras") and ui:Section("Auras", "unit.auras", true) then
			ui:Label("Heal Prediction", false)
			ui:Check("Enable Heal Prediction", function() return unitSettings.healPrediction.enabled ~= false end, function(v) unitSettings.healPrediction.enabled = v; self:ScheduleUpdateAll() end)
			ui:Check("Incoming Heals", function() return unitSettings.healPrediction.incoming.enabled ~= false end, function(v) unitSettings.healPrediction.incoming.enabled = v; self:ScheduleUpdateAll() end)
			ui:Check("Split Incoming Heals", function() return unitSettings.healPrediction.incoming.split == true end, function(v) unitSettings.healPrediction.incoming.split = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Incoming Value Mode", {
				{ value = "SAFE", text = "Safe (Placeholder on Secret)" },
				{ value = "SYMBOLIC", text = "Symbolic (~ / ~~ / ~~~)" },
				{ value = "SELF_ONLY", text = "Self Only (Show Your Incoming +)" },
				{ value = "HYBRID_ESTIMATE", text = "Hybrid (Try Estimate, Then Placeholder)" },
			}, function()
				local mode = unitSettings.healPrediction.incoming.valueMode
				if mode == "HYBRID_ESTIMATE" or mode == "SELF_ONLY" or mode == "SYMBOLIC" then
					return mode
				end
				return "SAFE"
			end, function(v)
				if v == "HYBRID_ESTIMATE" then
					unitSettings.healPrediction.incoming.valueMode = "HYBRID_ESTIMATE"
				elseif v == "SYMBOLIC" then
					unitSettings.healPrediction.incoming.valueMode = "SYMBOLIC"
				elseif v == "SELF_ONLY" then
					unitSettings.healPrediction.incoming.valueMode = "SELF_ONLY"
				else
					unitSettings.healPrediction.incoming.valueMode = "SAFE"
				end
				self:ScheduleUpdateAll()
			end)
			ui:Check("Incoming Value Text", function() return unitSettings.healPrediction.incoming.showValueText ~= false end, function(v) unitSettings.healPrediction.incoming.showValueText = v; self:ScheduleUpdateAll() end)
			ui:Edit("Incoming Value Placeholder (Secret)", function() return unitSettings.healPrediction.incoming.valuePlaceholder or "~" end, function(v)
				local text = SafeText(v, "~") or "~"
				if text == "" then
					text = "~"
				end
				if #text > 8 then
					text = string.sub(text, 1, 8)
				end
				unitSettings.healPrediction.incoming.valuePlaceholder = text
				self:ScheduleUpdateAll()
			end)
			ui:Slider("Incoming Value Font Size", 8, 20, 1, function() return unitSettings.healPrediction.incoming.valueFontSize or 10 end, function(v) unitSettings.healPrediction.incoming.valueFontSize = v; self:ScheduleUpdateAll() end)
			ui:Color("Incoming Value Color", function()
				return unitSettings.healPrediction.incoming.valueColor
			end, function(r, g, b)
				unitSettings.healPrediction.incoming.valueColor[1], unitSettings.healPrediction.incoming.valueColor[2], unitSettings.healPrediction.incoming.valueColor[3] = r, g, b
				self:ScheduleUpdateAll()
			end)
			ui:Slider("Incoming Value Offset X", -30, 30, 1, function() return unitSettings.healPrediction.incoming.valueOffsetX or 2 end, function(v) unitSettings.healPrediction.incoming.valueOffsetX = v; self:ScheduleUpdateAll() end)
			ui:Slider("Incoming Value Offset Y", -20, 20, 1, function() return unitSettings.healPrediction.incoming.valueOffsetY or 0 end, function(v) unitSettings.healPrediction.incoming.valueOffsetY = v; self:ScheduleUpdateAll() end)
			ui:Slider("Incoming Opacity", 0.05, 1, 0.05, function() return unitSettings.healPrediction.incoming.opacity end, function(v) unitSettings.healPrediction.incoming.opacity = v; self:ScheduleUpdateAll() end)
			ui:Slider("Incoming Height", 0.3, 1, 0.05, function() return unitSettings.healPrediction.incoming.height end, function(v) unitSettings.healPrediction.incoming.height = v; self:ScheduleUpdateAll() end)
			ui:Color("Incoming All Color", function() return unitSettings.healPrediction.incoming.colorAll end, function(r, g, b) unitSettings.healPrediction.incoming.colorAll[1], unitSettings.healPrediction.incoming.colorAll[2], unitSettings.healPrediction.incoming.colorAll[3] = r, g, b; self:ScheduleUpdateAll() end)
			ui:Color("Incoming Player Color", function() return unitSettings.healPrediction.incoming.colorPlayer end, function(r, g, b) unitSettings.healPrediction.incoming.colorPlayer[1], unitSettings.healPrediction.incoming.colorPlayer[2], unitSettings.healPrediction.incoming.colorPlayer[3] = r, g, b; self:ScheduleUpdateAll() end)
			ui:Color("Incoming Other Color", function() return unitSettings.healPrediction.incoming.colorOther end, function(r, g, b) unitSettings.healPrediction.incoming.colorOther[1], unitSettings.healPrediction.incoming.colorOther[2], unitSettings.healPrediction.incoming.colorOther[3] = r, g, b; self:ScheduleUpdateAll() end)
			ui:Check("Damage Absorb", function() return unitSettings.healPrediction.absorbs.enabled ~= false end, function(v) unitSettings.healPrediction.absorbs.enabled = v; self:ScheduleUpdateAll() end)
			ui:Slider("Damage Absorb Opacity", 0.05, 1, 0.05, function() return unitSettings.healPrediction.absorbs.opacity end, function(v) unitSettings.healPrediction.absorbs.opacity = v; self:ScheduleUpdateAll() end)
			ui:Slider("Damage Absorb Height", 0.3, 1, 0.05, function() return unitSettings.healPrediction.absorbs.height end, function(v) unitSettings.healPrediction.absorbs.height = v; self:ScheduleUpdateAll() end)
			ui:Color("Damage Absorb Color", function() return unitSettings.healPrediction.absorbs.color end, function(r, g, b) unitSettings.healPrediction.absorbs.color[1], unitSettings.healPrediction.absorbs.color[2], unitSettings.healPrediction.absorbs.color[3] = r, g, b; self:ScheduleUpdateAll() end)
			ui:Check("Damage Absorb Glow", function() return unitSettings.healPrediction.absorbs.showGlow ~= false end, function(v) unitSettings.healPrediction.absorbs.showGlow = v; self:ScheduleUpdateAll() end)
			ui:Slider("Damage Glow Opacity", 0.1, 1, 0.05, function() return unitSettings.healPrediction.absorbs.glowOpacity end, function(v) unitSettings.healPrediction.absorbs.glowOpacity = v; self:ScheduleUpdateAll() end)
			ui:Check("Heal Absorb", function() return unitSettings.healPrediction.healAbsorbs.enabled ~= false end, function(v) unitSettings.healPrediction.healAbsorbs.enabled = v; self:ScheduleUpdateAll() end)
			ui:Slider("Heal Absorb Opacity", 0.05, 1, 0.05, function() return unitSettings.healPrediction.healAbsorbs.opacity end, function(v) unitSettings.healPrediction.healAbsorbs.opacity = v; self:ScheduleUpdateAll() end)
			ui:Slider("Heal Absorb Height", 0.3, 1, 0.05, function() return unitSettings.healPrediction.healAbsorbs.height end, function(v) unitSettings.healPrediction.healAbsorbs.height = v; self:ScheduleUpdateAll() end)
			ui:Color("Heal Absorb Color", function() return unitSettings.healPrediction.healAbsorbs.color end, function(r, g, b) unitSettings.healPrediction.healAbsorbs.color[1], unitSettings.healPrediction.healAbsorbs.color[2], unitSettings.healPrediction.healAbsorbs.color[3] = r, g, b; self:ScheduleUpdateAll() end)
			ui:Check("Heal Absorb Glow", function() return unitSettings.healPrediction.healAbsorbs.showGlow ~= false end, function(v) unitSettings.healPrediction.healAbsorbs.showGlow = v; self:ScheduleUpdateAll() end)
			ui:Slider("Heal Glow Opacity", 0.1, 1, 0.05, function() return unitSettings.healPrediction.healAbsorbs.glowOpacity end, function(v) unitSettings.healPrediction.healAbsorbs.glowOpacity = v; self:ScheduleUpdateAll() end)
			if tabKey == "player" or tabKey == "target" then
				ui:Slider("Aura Icon Size", 12, 40, 1, function() return self:GetUnitAuraSize(tabKey) end, function(v) unitSettings.auraSize = v; self:ScheduleUpdateAll() end)
			end
			local auraLayout = self:GetUnitAuraLayoutSettings(tabKey)
			ui:Label("Aura Layout", false)
			ui:Check("Enable Auras", function() return auraLayout.enabled ~= false end, function(v) auraLayout.enabled = v and true or false; self:ScheduleUpdateAll() end)
			ui:Slider("Buff Count", 0, 20, 1, function() return tonumber(auraLayout.numBuffs) or 8 end, function(v) auraLayout.numBuffs = v; self:ScheduleUpdateAll() end, function() return auraLayout.enabled == false end)
			ui:Slider("Debuff Count", 0, 20, 1, function() return tonumber(auraLayout.numDebuffs) or 8 end, function(v) auraLayout.numDebuffs = v; self:ScheduleUpdateAll() end, function() return auraLayout.enabled == false end)
			ui:Slider("Aura Spacing X", 0, 12, 1, function() return tonumber(auraLayout.spacingX) or 4 end, function(v) auraLayout.spacingX = v; self:ScheduleUpdateAll() end, function() return auraLayout.enabled == false end)
			ui:Slider("Aura Spacing Y", 0, 12, 1, function() return tonumber(auraLayout.spacingY) or 4 end, function(v) auraLayout.spacingY = v; self:ScheduleUpdateAll() end, function() return auraLayout.enabled == false end)
			ui:Slider("Aura Max Columns", 1, 20, 1, function() return tonumber(auraLayout.maxCols) or 8 end, function(v) auraLayout.maxCols = v; self:ScheduleUpdateAll() end, function() return auraLayout.enabled == false end)
			ui:Dropdown("Aura Anchor", {
				{ value = "BOTTOMLEFT", text = "Bottom Left" },
				{ value = "BOTTOMRIGHT", text = "Bottom Right" },
				{ value = "TOPLEFT", text = "Top Left" },
				{ value = "TOPRIGHT", text = "Top Right" },
			}, function() return tostring(auraLayout.initialAnchor or "BOTTOMLEFT") end, function(v) auraLayout.initialAnchor = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Aura Growth X", {
				{ value = "RIGHT", text = "Right" },
				{ value = "LEFT", text = "Left" },
			}, function() return tostring(auraLayout.growthX or "RIGHT") end, function(v) auraLayout.growthX = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Aura Growth Y", {
				{ value = "UP", text = "Up" },
				{ value = "DOWN", text = "Down" },
			}, function() return tostring(auraLayout.growthY or "UP") end, function(v) auraLayout.growthY = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Aura Sort", {
				{ value = "DEFAULT", text = "Default" },
				{ value = "TIME_REMAINING", text = "Time Remaining" },
				{ value = "NAME", text = "Name" },
			}, function() return tostring(auraLayout.sortMethod or "DEFAULT") end, function(v) auraLayout.sortMethod = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Aura Sort Direction", {
				{ value = "ASC", text = "Ascending" },
				{ value = "DESC", text = "Descending" },
			}, function() return tostring(auraLayout.sortDirection or "ASC") end, function(v) auraLayout.sortDirection = v; self:ScheduleUpdateAll() end)
			ui:Check("Auras: Only Player Casts", function() return auraLayout.onlyShowPlayer == true end, function(v) auraLayout.onlyShowPlayer = v and true or false; self:ScheduleUpdateAll() end)
			ui:Check("Auras: Show Stealable Buffs", function() return auraLayout.showStealableBuffs ~= false end, function(v) auraLayout.showStealableBuffs = v and true or false; self:ScheduleUpdateAll() end)
			end
			if ShowUnitSection("advanced") and ui:Section("Advanced", "unit.advanced", false) then
			ui:Check("Show Resting Indicator", function() return unitSettings.showResting end, function(v) unitSettings.showResting = v; self:ScheduleUpdateAll() end)
			ui:Check("Show PvP Indicator", function() return unitSettings.showPvp end, function(v) unitSettings.showPvp = v; self:ScheduleUpdateAll() end)
			ui:Label("Target Glow", false)
			ui:Check("Enable Target Glow", function()
				local cfg = self:GetUnitTargetGlowSettings(tabKey)
				return cfg.enabled == true
			end, function(v)
				local cfg = self:GetUnitTargetGlowSettings(tabKey)
				cfg.enabled = v and true or false
				self:ScheduleUpdateUnitType(tabKey)
			end)
			ui:Slider("Target Glow Inset", 0, 12, 1, function()
				local cfg = self:GetUnitTargetGlowSettings(tabKey)
				return tonumber(cfg.inset) or 3
			end, function(v)
				local cfg = self:GetUnitTargetGlowSettings(tabKey)
				cfg.inset = v
				self:ScheduleUpdateUnitType(tabKey)
			end)
			ui:Color("Target Glow Color", function()
				local cfg = self:GetUnitTargetGlowSettings(tabKey)
				return cfg.color
			end, function(r, g, b)
				local cfg = self:GetUnitTargetGlowSettings(tabKey)
				cfg.color[1], cfg.color[2], cfg.color[3] = r, g, b
				self:ScheduleUpdateUnitType(tabKey)
			end)
			ui:Dropdown("Portrait Mode", {
				{ value = "none", text = "None" },
				{ value = "2D", text = "2D" },
				{ value = "3D", text = "3D" },
				{ value = "3DMotion", text = "3D Motion" },
			}, function() return unitSettings.portrait.mode end, function(v) unitSettings.portrait.mode = v; self:ScheduleUpdateAll() end)
			ui:Slider("Portrait Size", 16, 64, 1, function() return unitSettings.portrait.size end, function(v) unitSettings.portrait.size = v; self:ScheduleUpdateAll() end)
			ui:Check("Portrait Show Class", function() return unitSettings.portrait.showClass end, function(v) unitSettings.portrait.showClass = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Portrait Position", {
				{ value = "LEFT", text = "Left" },
				{ value = "RIGHT", text = "Right" },
			}, function() return unitSettings.portrait.position end, function(v) unitSettings.portrait.position = v; self:ScheduleUpdateAll() end)
			ui:Label("Resource Layout", false)
			ui:Slider("Secondary Power Gap (Top)", -6, 24, 1, function() return unitSettings.layout.secondaryToFrame end, function(v) unitSettings.layout.secondaryToFrame = v; self:ScheduleUpdateAll() end)
			ui:Slider("Class Resource Gap (Top)", -6, 24, 1, function() return unitSettings.layout.classToSecondary end, function(v) unitSettings.layout.classToSecondary = v; self:ScheduleUpdateAll() end)
			ui:Label("Unit Test Helpers", false)
			ui:Paragraph(("Current test mode: %s"):format(self.testMode and "enabled" or "disabled"), true)
			ui:Button("Force Show This Unit Type", function()
				self:SetTestModeForUnitType(tabKey)
			end, true)
			ui:Button("Force Show All Unit Types", function()
				self:SetTestMode(true)
			end, true)
			ui:Button("Disable Test Mode", function()
				self:SetTestMode(false)
			end, true)
			ui:Label("Quick Unit Actions", false)
			self._quickUnitCopyState = self._quickUnitCopyState or {}
			self._quickUnitCopyState[tabKey] = self._quickUnitCopyState[tabKey] or "player"
			ui:Dropdown("Quick Copy Source Unit", {
				{ value = "player", text = "Player" },
				{ value = "target", text = "Target" },
				{ value = "tot", text = "TargetOfTarget" },
				{ value = "focus", text = "Focus" },
				{ value = "pet", text = "Pet" },
				{ value = "party", text = "Party" },
				{ value = "raid", text = "Raid" },
				{ value = "boss", text = "Boss" },
			}, function()
				return self._quickUnitCopyState[tabKey]
			end, function(v)
				self._quickUnitCopyState[tabKey] = v
			end)
			ui:Button("Quick Copy Unit Layout/Tags/Size", function()
				local src = self._quickUnitCopyState[tabKey]
				if not src or src == tabKey then
					self:Print(addonName .. ": Select a different source unit.")
					return
				end
				self.db.profile.units[tabKey] = CopyTableDeep(self.db.profile.units[src] or defaults.profile.units[src] or defaults.profile.units.player)
				self.db.profile.tags[tabKey] = CopyTableDeep(self.db.profile.tags[src] or defaults.profile.tags[src] or defaults.profile.tags.player)
				self.db.profile.sizes[tabKey] = CopyTableDeep(self.db.profile.sizes[src] or defaults.profile.sizes[src] or defaults.profile.sizes.player)
				self:ScheduleUpdateUnitType(tabKey)
				frame:BuildTab(tabKey)
			end, true)
			ui:Button("Quick Reset This Unit to Defaults", function()
				self.db.profile.units[tabKey] = CopyTableDeep(defaults.profile.units[tabKey])
				self.db.profile.tags[tabKey] = CopyTableDeep(defaults.profile.tags[tabKey])
				self.db.profile.sizes[tabKey] = CopyTableDeep(defaults.profile.sizes[tabKey])
				if self:IsGroupUnitType(tabKey) then
					local pluginCfg = self:GetPluginSettings()
					pluginCfg.units = pluginCfg.units or CopyTableDeep(defaults.profile.plugins.units)
					pluginCfg.units[tabKey] = CopyTableDeep(defaults.profile.plugins.units[tabKey])
					pluginCfg.units[tabKey].useGlobal = true
					self:SchedulePluginUpdate(tabKey)
				end
				self:ScheduleUpdateUnitType(tabKey)
				frame:BuildTab(tabKey)
			end, true)
			ui:Label("Module Copy / Reset", false)
			self._moduleSelection = self._moduleSelection or {}
			self._moduleSelection[tabKey] = self._moduleSelection[tabKey] or {}
			local moduleState = self._moduleSelection[tabKey]
			moduleState.module = moduleState.module or "castbar"
			moduleState.sourceUnit = moduleState.sourceUnit or tabKey
			moduleState.profile = moduleState.profile or (self.db and self.db.GetCurrentProfile and self.db:GetCurrentProfile()) or "Global"
			if self.db.profile.optionsUI.moduleApplyConfirm == nil then
				self.db.profile.optionsUI.moduleApplyConfirm = true
			end
			moduleState.confirmApply = self.db.profile.optionsUI.moduleApplyConfirm ~= false
			local moduleOptions = {}
			for i = 1, #MODULE_KEYS do
				local candidate = MODULE_KEYS[i]
				if self:IsModuleSupportedForUnit(candidate.value, tabKey) then
					moduleOptions[#moduleOptions + 1] = candidate
				end
			end
			if #moduleOptions == 0 then
				moduleOptions = { { value = "castbar", text = "Castbar" } }
			end
			ui:Dropdown("Module", moduleOptions, function()
				local selected = moduleState.module or moduleOptions[1].value
				if not self:IsModuleSupportedForUnit(selected, tabKey) then
					return moduleOptions[1].value
				end
				return selected
			end, function(v)
				moduleState.module = v
			end)
			local unitOptions = {}
			for _, unitKey in ipairs(UNIT_TYPE_ORDER) do
				if self:IsModuleSupportedForUnit(moduleState.module, unitKey) then
					unitOptions[#unitOptions + 1] = { value = unitKey, text = GetUnitLabel(unitKey) }
				end
			end
			if #unitOptions == 0 then
				unitOptions = { { value = tabKey, text = GetUnitLabel(tabKey) } }
			end
			ui:Dropdown("Copy From Unit (Current Profile)", unitOptions, function()
				return moduleState.sourceUnit or tabKey
			end, function(v)
				moduleState.sourceUnit = v
			end)
			local profileOptions = {}
			local profiles = self:GetAvailableProfiles()
			for i = 1, #profiles do
				profileOptions[#profileOptions + 1] = { value = profiles[i], text = profiles[i] }
			end
			if #profileOptions == 0 then
				profileOptions[1] = { value = "Global", text = "Global" }
			end
			ui:Dropdown("Copy From Profile", profileOptions, function()
				return moduleState.profile
			end, function(v)
				moduleState.profile = v
			end)
			local function ResolveSourcePayloadFromUnit()
				local sourceUnit = moduleState.sourceUnit or tabKey
				if moduleState.module == "castbar" then
					local sourceSettings = self:GetUnitSettings(sourceUnit)
					return sourceSettings and sourceSettings.castbar
				end
				if moduleState.module == "fader" and self:IsGroupUnitType(sourceUnit) then
					local sourcePlugins = self:GetPluginSettings()
					return sourcePlugins and sourcePlugins.units and sourcePlugins.units[sourceUnit] and sourcePlugins.units[sourceUnit].fader
				end
				if moduleState.module == "aurawatch" and self:IsGroupUnitType(sourceUnit) then
					local sourcePlugins = self:GetPluginSettings()
					return sourcePlugins and sourcePlugins.units and sourcePlugins.units[sourceUnit] and sourcePlugins.units[sourceUnit].auraWatch
				end
				return nil
			end
			ui:Label("Dry-Run Preview", false)
			local previewFromUnit = self:BuildModuleChangePreview(moduleState.module, tabKey, ResolveSourcePayloadFromUnit(), "copy-from-unit")
			local previewFromProfile = self:BuildModuleChangePreview(moduleState.module, tabKey, self:GetModulePayloadFromProfile(moduleState.profile, moduleState.module, tabKey), "copy-from-profile")
			local previewReset = self:BuildModuleResetPreview(moduleState.module, tabKey)
			ui:Paragraph("Copy From Unit: " .. SafeText(previewFromUnit.summary, "Unavailable"), true)
			if previewFromUnit.lines and #previewFromUnit.lines > 0 then
				ui:Paragraph(table.concat(previewFromUnit.lines, "\n"), true)
			end
			ui:Paragraph("Copy From Profile: " .. SafeText(previewFromProfile.summary, "Unavailable"), true)
			if previewFromProfile.lines and #previewFromProfile.lines > 0 then
				ui:Paragraph(table.concat(previewFromProfile.lines, "\n"), true)
			end
			ui:Paragraph("Reset Module: " .. SafeText(previewReset.summary, "Unavailable"), true)
			if previewReset.lines and #previewReset.lines > 0 then
				ui:Paragraph(table.concat(previewReset.lines, "\n"), true)
			end
			ui:Check("Require Confirmation Before Apply", function()
				return moduleState.confirmApply ~= false
			end, function(v)
				moduleState.confirmApply = v and true or false
				self.db.profile.optionsUI.moduleApplyConfirm = moduleState.confirmApply
			end)
			ui:Button("Copy Module From Unit", function()
				local sourceUnit = moduleState.sourceUnit or tabKey
				local sourcePayload = ResolveSourcePayloadFromUnit()
				local details = ("Unit: %s\nModule: %s\nSource Unit: %s"):format(GetUnitLabel(tabKey), self:GetModuleLabel(moduleState.module), GetUnitLabel(sourceUnit))
				self:RunWithOptionalModuleApplyConfirmation(moduleState.confirmApply ~= false, "Apply module copy from selected unit?", details, function()
					if self:CopyModuleIntoCurrent(moduleState.module, tabKey, sourcePayload) then
						self:Print(addonName .. ": Copied " .. tostring(moduleState.module) .. " from " .. tostring(sourceUnit) .. " to " .. tostring(tabKey) .. ".")
						frame:BuildTab(tabKey)
					else
						self:Print(addonName .. ": Unable to copy module from selected unit.")
					end
				end)
			end, true)
			ui:Button("Copy Module From Profile", function()
				local payload = self:GetModulePayloadFromProfile(moduleState.profile, moduleState.module, tabKey)
				local details = ("Unit: %s\nModule: %s\nSource Profile: %s"):format(GetUnitLabel(tabKey), self:GetModuleLabel(moduleState.module), tostring(moduleState.profile))
				self:RunWithOptionalModuleApplyConfirmation(moduleState.confirmApply ~= false, "Apply module copy from selected profile?", details, function()
					if self:CopyModuleIntoCurrent(moduleState.module, tabKey, payload) then
						self:Print(addonName .. ": Copied " .. tostring(moduleState.module) .. " from profile " .. tostring(moduleState.profile) .. ".")
						frame:BuildTab(tabKey)
					else
						self:Print(addonName .. ": No compatible module data found in profile " .. tostring(moduleState.profile) .. ".")
					end
				end)
			end, true)
			ui:Button("Reset Selected Module (This Unit)", function()
				local details = ("Unit: %s\nModule: %s"):format(GetUnitLabel(tabKey), self:GetModuleLabel(moduleState.module))
				self:RunWithOptionalModuleApplyConfirmation(moduleState.confirmApply ~= false, "Reset selected module for this unit?", details, function()
					if self:ResetModuleForUnit(moduleState.module, tabKey) then
						self:Print(addonName .. ": Reset " .. tostring(moduleState.module) .. " for " .. tostring(tabKey) .. ".")
						frame:BuildTab(tabKey)
					else
						self:Print(addonName .. ": Reset is unavailable for this module on " .. tostring(tabKey) .. ".")
					end
				end)
			end, true)
			end
		end

		local wanted = ui:GetHeight()
		page:SetHeight(wanted)
		page:Show()
		content:SetHeight(wanted)
		self.isBuildingOptions = false
	end

	searchBox:SetText(frame.searchText or "")
	frame.searchResultIndex = frame.searchResultIndex or 1
	local function GetCurrentSearchResults()
		local groups = frame.searchResultGroups
		if type(groups) ~= "table" then
			return nil, 0
		end
		return groups, #groups
	end
	local function JumpSearchResult(offset)
		local groups, count = GetCurrentSearchResults()
		if not groups or count == 0 then
			return
		end
		local idx = tonumber(frame.searchResultIndex) or 1
		idx = idx + (offset or 0)
		if idx < 1 then
			idx = count
		elseif idx > count then
			idx = 1
		end
		frame.searchResultIndex = idx
		local target = groups[idx]
		if target and target.tabKey then
			frame:BuildTab(target.tabKey)
		end
	end
	searchBox:SetScript("OnTextChanged", function(box, userInput)
		if not userInput then
			return
		end
		frame.searchText = box:GetText() or ""
		frame.searchResultIndex = 1
		if frame.currentTab then
			frame:BuildTab(frame.currentTab)
		end
	end)
	searchBox:SetScript("OnEnterPressed", function(box)
		local groups, count = GetCurrentSearchResults()
		if groups and count > 0 then
			local idx = tonumber(frame.searchResultIndex) or 1
			idx = math.max(1, math.min(count, idx))
			local target = groups[idx]
			if target and target.tabKey then
				frame:BuildTab(target.tabKey)
				box:ClearFocus()
				return
			end
		end
		box:ClearFocus()
	end)
	searchBox:SetScript("OnKeyDown", function(_, key)
		if IsAltKeyDown() and key == "DOWN" then
			JumpSearchResult(1)
			return
		end
		if IsAltKeyDown() and key == "UP" then
			JumpSearchResult(-1)
			return
		end
	end)

	self.db.profile.optionsUI = self.db.profile.optionsUI or {}
	self.db.profile.optionsUI.navState = self.db.profile.optionsUI.navState or {}

	local function StyleNavButton(button, isChild)
		button:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		self:ApplySUFBackdropColors(button, UI_STYLE.navDefault, UI_STYLE.navDefaultBorder, false)
		local fs = button:CreateFontString(nil, "OVERLAY", isChild and "GameFontHighlightSmall" or "GameFontNormal")
		fs:SetPoint("LEFT", button, "LEFT", isChild and 12 or 8, 0)
		fs:SetJustifyH("LEFT")
		fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
		button._sufText = fs
		button._sufSelected = false
		button._sufMatchSearch = false
		button:SetScript("OnEnter", function(selfButton)
			if selfButton._sufSelected then
				return
			end
			self:ApplySUFBackdropColors(selfButton, UI_STYLE.navHover, UI_STYLE.navHoverBorder, false)
		end)
		button:SetScript("OnLeave", function(selfButton)
			if selfButton.__sufSetSelected then
				selfButton:__sufSetSelected(selfButton._sufSelected, selfButton._sufMatchSearch)
			end
		end)
		button.__sufSetSelected = function(selfButton, selected, matchSearch)
			selfButton._sufSelected = selected and true or false
			selfButton._sufMatchSearch = matchSearch and true or false
			if selected then
				self:ApplySUFBackdropColors(selfButton, UI_STYLE.navSelected, UI_STYLE.navSelectedBorder, false)
				if selfButton._sufText then
					selfButton._sufText:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
				end
			else
				if matchSearch then
					self:ApplySUFBackdropColors(selfButton, UI_STYLE.navSearch, UI_STYLE.navSearchBorder, false)
					if selfButton._sufText then
						selfButton._sufText:SetTextColor(UI_STYLE.accentSoft[1], UI_STYLE.accentSoft[2], UI_STYLE.accentSoft[3])
					end
				else
					self:ApplySUFBackdropColors(selfButton, UI_STYLE.navDefault, UI_STYLE.navDefaultBorder, false)
					if selfButton._sufText then
						selfButton._sufText:SetTextColor(UI_STYLE.textMuted[1], UI_STYLE.textMuted[2], UI_STYLE.textMuted[3])
					end
				end
			end
		end
	end

	local menuScroll = CreateFrame("ScrollFrame", nil, tabsHost)
	menuScroll:SetPoint("TOPLEFT", tabsHost, "TOPLEFT", 8, -(iconSize + 24))
	menuScroll:SetPoint("BOTTOMRIGHT", tabsHost, "BOTTOMRIGHT", -8, 8)
	self:ApplySUFBackdropColors(menuScroll, UI_STYLE.panelBg, UI_STYLE.panelBorder, true)
	menuScroll:Show()
	
	-- Style scrollbar thumb and buttons with theme colors
	if menuScroll.ScrollBar then
		local scrollBar = menuScroll.ScrollBar
		if scrollBar.ThumbTexture then
			scrollBar.ThumbTexture:SetVertexColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3], 0.8)
		end
		-- ScrollUpButton/ScrollDownButton don't support SetBackdropColor, skip styling
	end
	
	local menuContent = CreateFrame("Frame", nil, menuScroll)
	menuContent:SetSize(220, 1)
	menuScroll:SetScrollChild(menuContent)
	menuContent:Show()

	local navButtons = {}
	local sectionNavButtons = {}
	local function RebuildSidebar()
		for i = 1, #navButtons do
			navButtons[i]:Hide()
			navButtons[i]:SetParent(nil)
			navButtons[i] = nil
		end
		wipe(tabButtons)
		wipe(sectionNavButtons)

		local y = -2
		local width = 220
		for g = 1, #sidebarGroups do
			local group = sidebarGroups[g]
			local expanded = self.db.profile.optionsUI.navState[group.key]
			if expanded == nil then
				expanded = true
				self.db.profile.optionsUI.navState[group.key] = true
			end

			local parentBtn = CreateFrame("Button", nil, menuContent, "BackdropTemplate")
			parentBtn:SetSize(width, 24)
			parentBtn:SetPoint("TOPLEFT", menuContent, "TOPLEFT", 0, y)
			StyleNavButton(parentBtn, false)
			parentBtn._sufText:SetText((expanded and "[-] " or "[+] ") .. tostring(group.label))
			parentBtn:SetScript("OnClick", function()
				self.db.profile.optionsUI.navState[group.key] = not self.db.profile.optionsUI.navState[group.key]
				RebuildSidebar()
				if frame.currentTab then
					frame:BuildTab(frame.currentTab)
				end
			end)
			navButtons[#navButtons + 1] = parentBtn
			y = y - 26

			if expanded then
				for i = 1, #group.items do
					local tabKey = group.items[i]
					local tab = tabIndexByKey[tabKey]
					if tab then
						local childBtn = CreateFrame("Button", nil, menuContent, "BackdropTemplate")
						childBtn:SetSize(width - 8, 22)
						childBtn:SetPoint("TOPLEFT", menuContent, "TOPLEFT", 8, y)
						StyleNavButton(childBtn, true)
						local isUnitNav = group.key == "grp_units" and unitTabLookup[tab.key]
						local unitStateKey = "unitsec_" .. tostring(tab.key)
						local unitExpanded = false
						if isUnitNav then
							local stored = self.db.profile.optionsUI.navState[unitStateKey]
							if stored == nil then
								stored = frame.currentTab == tab.key
								self.db.profile.optionsUI.navState[unitStateKey] = stored and true or false
							end
							unitExpanded = stored and true or false
							if childBtn._sufText then
								childBtn._sufText:ClearAllPoints()
								childBtn._sufText:SetPoint("LEFT", childBtn, "LEFT", 26, 0)
							end
							local expander = CreateFrame("Button", nil, childBtn)
							expander:SetSize(14, 14)
							expander:SetPoint("LEFT", childBtn, "LEFT", 8, 0)
							local expanderText = expander:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
							expanderText:SetPoint("CENTER", expander, "CENTER", 0, 0)
							expanderText:SetText(unitExpanded and "-" or "+")
							expander:SetScript("OnClick", function()
								self.db.profile.optionsUI.navState[unitStateKey] = not self.db.profile.optionsUI.navState[unitStateKey]
								RebuildSidebar()
								if frame.currentTab then
									frame:BuildTab(frame.currentTab)
								end
							end)
							childBtn._sufText:SetText(tostring(tab.label))
						else
							childBtn._sufText:SetText(tab.label)
						end
						childBtn:SetScript("OnClick", function()
							if isUnitNav then
								self.db.profile.optionsUI.navState[unitStateKey] = true
								RebuildSidebar()
							end
							frame:BuildTab(tab.key)
						end)
						tabButtons[tab.key] = childBtn
						navButtons[#navButtons + 1] = childBtn
						y = y - 24

						if isUnitNav and unitExpanded then
							for sectionIndex = 1, #UNIT_SECTION_NAV do
								local section = UNIT_SECTION_NAV[sectionIndex]
								local sectionBtn = CreateFrame("Button", nil, menuContent, "BackdropTemplate")
								sectionBtn:SetSize(width - 22, 18)
								sectionBtn:SetPoint("TOPLEFT", menuContent, "TOPLEFT", 22, y)
								StyleNavButton(sectionBtn, true)
								sectionBtn._sufText:SetText("- " .. tostring(section.label))
								sectionBtn:SetScript("OnClick", function()
									self.db.profile.optionsUI.unitSubTabs = self.db.profile.optionsUI.unitSubTabs or {}
									self.db.profile.optionsUI.unitSubTabs[tab.key] = section.key
									self.db.profile.optionsUI.navState[unitStateKey] = true
									frame:BuildTab(tab.key, section.key)
								end)
								local compoundKey = tostring(tab.key) .. "::" .. tostring(section.key)
								sectionNavButtons[compoundKey] = sectionBtn
								navButtons[#navButtons + 1] = sectionBtn
								y = y - 20
							end
						end
					end
				end
			end
		end
		menuContent:SetHeight(math.max(1, -y + 6))
		frame.sectionNavButtons = sectionNavButtons
	end
	RebuildSidebar()
	frame.RebuildSidebar = RebuildSidebar

	frame:SetScript("OnSizeChanged", function()
		ClampOptionsHeight(frame)
		if frame.currentTab and frame:IsShown() then
			C_Timer.After(0, function()
				if frame:IsShown() and frame.currentTab then
					frame:BuildTab(frame.currentTab)
				end
			end)
		end
	end)
	frame:HookScript("OnHide", function()
		StopPerformanceSnapshotTicker()
	end)

	do
		local buildTabInternal = frame.BuildTab
		if type(buildTabInternal) == "function" then
			frame.BuildTab = function(_, tabKey, unitSubTabOverride)
				buildTabInternal(frame, tabKey, unitSubTabOverride)
				if self.ApplySUFControlSkinsInFrame then
					self:ApplySUFControlSkinsInFrame(frame)
				end
			end
		end
	end

	self:PrepareWindowForDisplay(frame)
	frame:Show()
	self:PlayWindowOpenAnimation(frame)
	frame:BuildTab("global")
	self.optionsFrame = frame
end
