local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local LSM = LibStub("LibSharedMedia-3.0", true)

function addon:GetOptionsV2Pages()
	if self._optionsV2Pages then
		return self._optionsV2Pages
	end

	self._optionsV2Pages = {
		{ key = "global", label = "Global", group = "General", desc = "Global defaults and core behavior." },
		{ key = "performance", label = "Performance", group = "General", desc = "PerformanceLib integration and update behavior." },
		{ key = "importexport", label = "Import / Export", group = "General", desc = "Profile import, export, validation, and previews." },
		{ key = "tags", label = "Tags", group = "General", desc = "Text tags and format strings across unit frames." },
		{ key = "customtrackers", label = "Custom Trackers", group = "General", desc = "Draggable icon bars for tracking spells, items, trinkets, and consumables." },
		{ key = "player", label = "Player", group = "Units", desc = "Player unit frame settings and modules." },
		{ key = "target", label = "Target", group = "Units", desc = "Target unit frame settings and modules." },
		{ key = "tot", label = "TargetOfTarget", group = "Units", desc = "Target-of-target unit frame settings." },
		{ key = "focus", label = "Focus", group = "Units", desc = "Focus unit frame settings and modules." },
		{ key = "pet", label = "Pet", group = "Units", desc = "Pet unit frame settings and modules." },
		{ key = "party", label = "Party", group = "Units", desc = "Party frame layout and plugin behavior." },
		{ key = "raid", label = "Raid", group = "Units", desc = "Raid frame layout and plugin behavior." },
		{ key = "boss", label = "Boss", group = "Units", desc = "Boss frame layout and castbar behavior." },
		{ key = "credits", label = "Credits", group = "Advanced", desc = "Libraries, references, and project attribution." },
	}

	return self._optionsV2Pages
end

function addon:GetOptionsV2Groups()
	return { "General", "Units", "Advanced" }
end

local function BuildMediaOptions(kind, fallback)
	local out = {}
	if LSM and LSM.List then
		local list = LSM:List(kind)
		if type(list) == "table" then
			for i = 1, #list do
				local value = tostring(list[i])
				local row = { value = value, text = value }
				if LSM.Fetch and (kind == "statusbar" or kind == "background") then
					local ok, fetched = pcall(LSM.Fetch, LSM, kind, value)
					if ok and type(fetched) == "string" and fetched ~= "" then
						row.previewTexture = fetched
					end
				elseif LSM.Fetch and kind == "font" then
					local ok, fetched = pcall(LSM.Fetch, LSM, kind, value)
					if ok and type(fetched) == "string" and fetched ~= "" then
						row.previewFont = fetched
					end
				end
				out[#out + 1] = row
			end
		end
	end
	if #out == 0 then
		local row = { value = fallback, text = fallback }
		if LSM and LSM.Fetch and (kind == "statusbar" or kind == "background") then
			local ok, fetched = pcall(LSM.Fetch, LSM, kind, fallback)
			if ok and type(fetched) == "string" and fetched ~= "" then
				row.previewTexture = fetched
			end
		elseif LSM and LSM.Fetch and kind == "font" then
			local ok, fetched = pcall(LSM.Fetch, LSM, kind, fallback)
			if ok and type(fetched) == "string" and fetched ~= "" then
				row.previewFont = fetched
			end
		end
		out[1] = row
	end
	return out
end

local function CopyTableDeepLocal(source)
	local core = addon._core or {}
	if type(core.CopyTableDeep) == "function" then
		return core.CopyTableDeep(source)
	end
	local function Copy(src)
		if type(src) ~= "table" then
			return src
		end
		local out = {}
		for key, value in pairs(src) do
			out[key] = Copy(value)
		end
		return out
	end
	return Copy(source)
end

local function BuildThemePresetOptions()
	return {
		{ value = "classic", text = "Classic" },
		{ value = "midnight", text = "Midnight" },
		{ value = "dark", text = "Dark Mode" },
	}
end

local function BuildAbsorbTagOptions()
	return {
		{ value = "[suf:absorbs:abbr]", text = "Absorbs (Abbreviated)" },
		{ value = "[suf:absorbs]", text = "Absorbs (Raw)" },
		{ value = "[suf:incoming:abbr]", text = "Incoming Heals (Abbreviated)" },
		{ value = "[suf:incoming]", text = "Incoming Heals (Raw)" },
		{ value = "[suf:ehp:abbr]", text = "Effective Health (Abbreviated)" },
		{ value = "[suf:ehp]", text = "Effective Health (Raw)" },
	}
end

local UNIT_LABELS = {
	player = "Player",
	target = "Target",
	tot = "TargetOfTarget",
	focus = "Focus",
	pet = "Pet",
	party = "Party",
	raid = "Raid",
	boss = "Boss",
}

local UNIT_TYPE_ORDER = { "player", "target", "tot", "focus", "pet", "party", "raid", "boss" }

local function GetUnitLabel(unitKey)
	return UNIT_LABELS[unitKey] or tostring(unitKey or "Unit")
end

local function CollectOUFTagsLocal()
	local ouf = addon.oUF or (_G and _G.oUF)
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

local function CategorizeTagLocal(tagName)
	local t = string.lower(tagName or "")
	if t:find("health", 1, true) or t:find("hp", 1, true) or t:find("absorb", 1, true) then
		return "Health"
	end
	if t:find("power", 1, true) or t:find("pp", 1, true) or t:find("mana", 1, true) or t:find("energy", 1, true) or t:find("rage", 1, true) or t:find("rune", 1, true) then
		return "Power"
	end
	if t:find("cast", 1, true) or t:find("channel", 1, true) then
		return "Cast"
	end
	if t:find("aura", 1, true) or t:find("buff", 1, true) or t:find("debuff", 1, true) then
		return "Auras"
	end
	if t:find("threat", 1, true) or t:find("combat", 1, true) or t:find("status", 1, true) or t:find("dead", 1, true) or t:find("offline", 1, true) then
		return "Status"
	end
	if t:find("name", 1, true) or t:find("level", 1, true) or t:find("class", 1, true) or t:find("race", 1, true) then
		return "Identity"
	end
	return "Other"
end

local function RefreshOptionsV2CurrentPage()
	if addon.optionsV2Frame and addon.optionsV2Frame.RefreshCurrentPage then
		addon.optionsV2Frame:RefreshCurrentPage()
	end
end

local function BuildUnitCoreSpec(unitKey)
	local unitLabel = GetUnitLabel(unitKey)
	local isGroup = (unitKey == "party" or unitKey == "raid")
	local moduleStateStore = addon._optionsV2ModuleState or {}
	addon._optionsV2ModuleState = moduleStateStore
	moduleStateStore[unitKey] = moduleStateStore[unitKey] or {
		module = "castbar",
		sourceUnit = unitKey,
		profile = (addon.db and addon.db.GetCurrentProfile and addon.db:GetCurrentProfile()) or "Global",
		confirmApply = true,
	}
	local moduleState = moduleStateStore[unitKey]
	local function GetUnit()
		return addon:GetUnitSettings(unitKey) or {}
	end
	local function GetActiveSection()
		addon.db.profile.optionsUI = addon.db.profile.optionsUI or {}
		addon.db.profile.optionsUI.unitSubTabs = addon.db.profile.optionsUI.unitSubTabs or {}
		return tostring(addon.db.profile.optionsUI.unitSubTabs[unitKey] or "general")
	end
	local function SetActiveSection(key)
		addon.db.profile.optionsUI = addon.db.profile.optionsUI or {}
		addon.db.profile.optionsUI.unitSubTabs = addon.db.profile.optionsUI.unitSubTabs or {}
		addon.db.profile.optionsUI.unitSubTabs[unitKey] = tostring(key or "all")
	end
	local function GetModuleOptions()
		local base = {
			{ value = "castbar", text = "Castbar" },
			{ value = "fader", text = "Frame Fader (Group Units)" },
			{ value = "aurawatch", text = "AuraWatch (Group Units)" },
		}
		local out = {}
		for i = 1, #base do
			local candidate = base[i]
			if addon:IsModuleSupportedForUnit(candidate.value, unitKey) then
				out[#out + 1] = candidate
			end
		end
		if #out == 0 then
			out[1] = { value = "castbar", text = "Castbar" }
		end
		return out
	end
	local function GetSupportedUnitOptionsForModule(moduleKey)
		local out = {}
		for i = 1, #UNIT_TYPE_ORDER do
			local uk = UNIT_TYPE_ORDER[i]
			if addon:IsModuleSupportedForUnit(moduleKey, uk) then
				out[#out + 1] = { value = uk, text = GetUnitLabel(uk) }
			end
		end
		if #out == 0 then
			out[1] = { value = unitKey, text = GetUnitLabel(unitKey) }
		end
		return out
	end
	local function GetSourcePayloadFromUnit()
		local src = moduleState.sourceUnit or unitKey
		if moduleState.module == "castbar" then
			local srcSettings = addon:GetUnitSettings(src)
			return srcSettings and srcSettings.castbar
		end
		if moduleState.module == "fader" and addon:IsGroupUnitType(src) then
			local plugins = addon:GetPluginSettings()
			return plugins and plugins.units and plugins.units[src] and plugins.units[src].fader
		end
		if moduleState.module == "aurawatch" and addon:IsGroupUnitType(src) then
			local plugins = addon:GetPluginSettings()
			return plugins and plugins.units and plugins.units[src] and plugins.units[src].auraWatch
		end
		return nil
	end
	local function BuildModulePreviewText()
		local srcPayload = GetSourcePayloadFromUnit()
		local copyFromUnit = addon:BuildModuleChangePreview(moduleState.module, unitKey, srcPayload, "copy-from-unit")
		local copyFromProfile = addon:BuildModuleChangePreview(moduleState.module, unitKey, addon:GetModulePayloadFromProfile(moduleState.profile, moduleState.module, unitKey), "copy-from-profile")
		local resetPreview = addon:BuildModuleResetPreview(moduleState.module, unitKey)
		local lines = {
			"Copy From Unit: " .. tostring(copyFromUnit and copyFromUnit.summary or "Unavailable"),
			"Copy From Profile: " .. tostring(copyFromProfile and copyFromProfile.summary or "Unavailable"),
			"Reset Module: " .. tostring(resetPreview and resetPreview.summary or "Unavailable"),
		}
		return table.concat(lines, "\n")
	end
	return {
		sectionTabs = {
			{ key = "general", label = "General" },
			{ key = "bars", label = "Bars" },
			{ key = "castbar", label = "Castbar" },
			{ key = "auras", label = "Auras" },
			{ key = "plugins", label = "Plugins" },
			{ key = "advanced", label = "Advanced" },
			{ key = "all", label = "All" },
		},
		getActiveSection = GetActiveSection,
		setActiveSection = SetActiveSection,
		sections = {
			{
				tab = "general",
				title = unitLabel .. " - General",
				desc = "Core frame dimensions and tag strings.",
				controls = {
					{
						type = "slider",
						label = "Frame Width",
						min = 80,
						max = 400,
						step = 1,
						format = "%.0f",
						get = function()
							local size = addon.db.profile.sizes[unitKey] or {}
							return tonumber(size.width) or 220
						end,
						set = function(v)
							addon.db.profile.sizes[unitKey] = addon.db.profile.sizes[unitKey] or {}
							addon.db.profile.sizes[unitKey].width = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Frame Height",
						min = 18,
						max = 80,
						step = 1,
						format = "%.0f",
						get = function()
							local size = addon.db.profile.sizes[unitKey] or {}
							return tonumber(size.height) or 36
						end,
						set = function(v)
							addon.db.profile.sizes[unitKey] = addon.db.profile.sizes[unitKey] or {}
							addon.db.profile.sizes[unitKey].height = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "edit",
						label = "Name Tag",
						get = function()
							local tags = addon.db.profile.tags[unitKey] or {}
							return tags.name or ""
						end,
						set = function(v)
							addon.db.profile.tags[unitKey] = addon.db.profile.tags[unitKey] or {}
							addon.db.profile.tags[unitKey].name = tostring(v or "")
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "edit",
						label = "Level Tag",
						get = function()
							local tags = addon.db.profile.tags[unitKey] or {}
							return tags.level or ""
						end,
						set = function(v)
							addon.db.profile.tags[unitKey] = addon.db.profile.tags[unitKey] or {}
							addon.db.profile.tags[unitKey].level = tostring(v or "")
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "edit",
						label = "Health Tag",
						get = function()
							local tags = addon.db.profile.tags[unitKey] or {}
							return tags.health or ""
						end,
						set = function(v)
							addon.db.profile.tags[unitKey] = addon.db.profile.tags[unitKey] or {}
							addon.db.profile.tags[unitKey].health = tostring(v or "")
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "edit",
						label = "Power Tag",
						get = function()
							local tags = addon.db.profile.tags[unitKey] or {}
							return tags.power or ""
						end,
						set = function(v)
							addon.db.profile.tags[unitKey] = addon.db.profile.tags[unitKey] or {}
							addon.db.profile.tags[unitKey].power = tostring(v or "")
							addon:ScheduleUpdateAll()
						end,
					},
				},
			},
			{
				tab = "bars",
				title = unitLabel .. " - Media & Fonts",
				desc = "Per-unit statusbar and font sizing.",
				controls = {
					{
						type = "dropdown",
						label = "Statusbar Texture",
						options = function()
							return BuildMediaOptions("statusbar", "Blizzard")
						end,
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.media = unit.media or {}
							return unit.media.statusbar or addon.db.profile.media.statusbar or "Blizzard"
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.media = unit.media or {}
							unit.media.statusbar = tostring(v)
							addon:ScheduleUpdateAll()
						end,
						disabled = function()
							return addon.db.profile.media.globalStatusbarOverride ~= false
						end,
					},
					{
						type = "dropdown",
						label = "Font",
						options = function()
							return BuildMediaOptions("font", "Friz Quadrata TT")
						end,
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.media = unit.media or {}
							return unit.media.font or addon.db.profile.media.font or "Friz Quadrata TT"
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.media = unit.media or {}
							unit.media.font = tostring(v)
							addon:ScheduleUpdateAll()
						end,
						disabled = function()
							return addon.db.profile.media.globalFontOverride ~= false
						end,
					},
					{
						type = "slider",
						label = "Name Font Size",
						min = 8,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.fontSizes = unit.fontSizes or {}
							return tonumber(unit.fontSizes.name) or 12
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.fontSizes = unit.fontSizes or {}
							unit.fontSizes.name = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Level Font Size",
						min = 8,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.fontSizes = unit.fontSizes or {}
							return tonumber(unit.fontSizes.level) or 10
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.fontSizes = unit.fontSizes or {}
							unit.fontSizes.level = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Health Font Size",
						min = 8,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.fontSizes = unit.fontSizes or {}
							return tonumber(unit.fontSizes.health) or 11
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.fontSizes = unit.fontSizes or {}
							unit.fontSizes.health = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Power Font Size",
						min = 8,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.fontSizes = unit.fontSizes or {}
							return tonumber(unit.fontSizes.power) or 10
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.fontSizes = unit.fontSizes or {}
							unit.fontSizes.power = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Cast Font Size",
						min = 8,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.fontSizes = unit.fontSizes or {}
							return tonumber(unit.fontSizes.cast) or 10
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.fontSizes = unit.fontSizes or {}
							unit.fontSizes.cast = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
				},
			},
			{
				tab = "castbar",
				title = unitLabel .. " - Castbar",
				desc = "Core castbar toggles and placement.",
				controls = {
					{
						type = "check",
						label = "Enable Castbar",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return unit.castbar.enabled ~= false
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.enabled = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Show Cast Spell Text",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return unit.castbar.showText ~= false
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.showText = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Show Cast Time",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return unit.castbar.showTime ~= false
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.showTime = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Reverse Cast Fill",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return unit.castbar.reverseFill == true
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.reverseFill = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Castbar Width (% of frame)",
						min = 50,
						max = 150,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return tonumber(unit.castbar.widthPercent) or 100
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.widthPercent = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Castbar Anchor",
						options = function()
							return {
								{ value = "BELOW_FRAME", text = "Below Frame" },
								{ value = "ABOVE_FRAME", text = "Above Frame" },
								{ value = "BELOW_CLASSPOWER", text = "Below ClassPower" },
							}
						end,
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return tostring(unit.castbar.anchor or "BELOW_FRAME")
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.anchor = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Castbar Color Profile",
						options = function()
							return {
								{ value = "GLOBAL", text = "Use Global" },
								{ value = "UUF", text = "UUF" },
								{ value = "Blizzard", text = "Blizzard" },
								{ value = "HighContrast", text = "High Contrast" },
							}
						end,
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return tostring(unit.castbar.colorProfile or "GLOBAL")
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.colorProfile = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Castbar Gap",
						min = 0,
						max = 40,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return tonumber(unit.castbar.gap) or 8
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.gap = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Castbar Fine Offset",
						min = -40,
						max = 40,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = addon:GetUnitSettings(unitKey) or {}
							unit.castbar = unit.castbar or {}
							return tonumber(unit.castbar.offsetY) or 0
						end,
						set = function(v)
							local unit = addon:GetUnitSettings(unitKey)
							unit.castbar = unit.castbar or {}
							unit.castbar.offsetY = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
				},
			},
			{
				tab = "auras",
				title = unitLabel .. " - Auras",
				desc = "Aura layout controls and prediction toggles.",
				controls = {
					{
						type = "check",
						label = "Enable Auras",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return aura.enabled ~= false
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.enabled = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Buff Count",
						min = 0,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tonumber(aura.numBuffs) or 8
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.numBuffs = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Debuff Count",
						min = 0,
						max = 20,
						step = 1,
						format = "%.0f",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tonumber(aura.numDebuffs) or 8
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.numDebuffs = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Aura Spacing X",
						min = 0,
						max = 12,
						step = 1,
						format = "%.0f",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tonumber(aura.spacingX) or 4
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.spacingX = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Aura Spacing Y",
						min = 0,
						max = 12,
						step = 1,
						format = "%.0f",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tonumber(aura.spacingY) or 4
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.spacingY = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Aura Anchor",
						options = function()
							return {
								{ value = "BOTTOMLEFT", text = "Bottom Left" },
								{ value = "BOTTOMRIGHT", text = "Bottom Right" },
								{ value = "TOPLEFT", text = "Top Left" },
								{ value = "TOPRIGHT", text = "Top Right" },
							}
						end,
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tostring(aura.initialAnchor or "BOTTOMLEFT")
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.initialAnchor = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Aura Growth X",
						options = function()
							return {
								{ value = "RIGHT", text = "Right" },
								{ value = "LEFT", text = "Left" },
							}
						end,
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tostring(aura.growthX or "RIGHT")
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.growthX = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Aura Growth Y",
						options = function()
							return {
								{ value = "UP", text = "Up" },
								{ value = "DOWN", text = "Down" },
							}
						end,
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tostring(aura.growthY or "UP")
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.growthY = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Aura Sort",
						options = function()
							return {
								{ value = "DEFAULT", text = "Default" },
								{ value = "TIME_REMAINING", text = "Time Remaining" },
								{ value = "NAME", text = "Name" },
							}
						end,
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tostring(aura.sortMethod or "DEFAULT")
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.sortMethod = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Aura Sort Direction",
						options = function()
							return {
								{ value = "ASC", text = "Ascending" },
								{ value = "DESC", text = "Descending" },
							}
						end,
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return tostring(aura.sortDirection or "ASC")
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.sortDirection = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Incoming Heals",
						get = function()
							local unit = GetUnit()
							unit.healPrediction = unit.healPrediction or {}
							unit.healPrediction.incoming = unit.healPrediction.incoming or {}
							return unit.healPrediction.incoming.enabled ~= false
						end,
						set = function(v)
							local unit = GetUnit()
							unit.healPrediction = unit.healPrediction or {}
							unit.healPrediction.incoming = unit.healPrediction.incoming or {}
							unit.healPrediction.incoming.enabled = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Auras: Only Player Casts",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return aura.onlyShowPlayer == true
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.onlyShowPlayer = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Auras: Show Stealable Buffs",
						get = function()
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							return aura.showStealableBuffs ~= false
						end,
						set = function(v)
							local aura = addon:GetUnitAuraLayoutSettings(unitKey)
							aura.showStealableBuffs = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
				},
			},
			{
				tab = "plugins",
				title = unitLabel .. " - Plugins",
				desc = "Per-unit plugin overrides for group units.",
				controls = {
					{
						type = "paragraph",
						getText = function()
							if not isGroup then
								return "This unit type uses global plugin settings. Open Global -> Plugins to configure them."
							end
							local plugins = addon:GetPluginSettings()
							plugins.units = plugins.units or {}
							local unitProfile = plugins.units[unitKey]
							if not unitProfile then
								return "Using global plugin settings."
							end
							return "Plugin overrides available for this unit."
						end,
					},
					{
						type = "button",
						label = "Open Global Plugin Settings",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								local cfg = addon:EnsureOptionsV2Config()
								cfg.sectionState = cfg.sectionState or {}
								cfg.sectionState.global = "plugins"
								addon.optionsV2Frame:SetPage("global")
							end
						end,
					},
					{
						type = "check",
						label = "Use Global Plugin Settings",
						disabled = function()
							return not isGroup
						end,
						get = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							plugins.units = plugins.units or {}
							plugins.units[unitKey] = plugins.units[unitKey] or {}
							return plugins.units[unitKey].useGlobal ~= false
						end,
						set = function(v)
							if not isGroup then
								return
							end
							local plugins = addon:GetPluginSettings()
							plugins.units = plugins.units or {}
							plugins.units[unitKey] = plugins.units[unitKey] or {}
							if v then
								plugins.units[unitKey].useGlobal = true
							else
								addon:SeedUnitPluginOverridesFromGlobal(unitKey)
							end
							addon:SchedulePluginUpdate(unitKey)
							RefreshOptionsV2CurrentPage()
						end,
					},
					{
						type = "check",
						label = "Raid Debuffs",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							if not isGroup then
								return false
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.raidDebuffs = up.raidDebuffs or {}
							return up.raidDebuffs.enabled ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.raidDebuffs = up.raidDebuffs or {}
							up.raidDebuffs.enabled = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Raid Debuff Icon Size",
						min = 12,
						max = 36,
						step = 1,
						format = "%.0f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.raidDebuffs = up.raidDebuffs or {}
							return tonumber(up.raidDebuffs.size) or 18
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.raidDebuffs = up.raidDebuffs or {}
							up.raidDebuffs.size = math.floor(v + 0.5)
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Raid Debuff Glow",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.raidDebuffs = up.raidDebuffs or {}
							return up.raidDebuffs.glow ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.raidDebuffs = up.raidDebuffs or {}
							up.raidDebuffs.glow = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "dropdown",
						label = "Raid Debuff Glow Mode",
						options = function()
							return {
								{ value = "ALL", text = "All Debuffs" },
								{ value = "DISPELLABLE", text = "Dispellable Only" },
								{ value = "PRIORITY", text = "Boss/Priority Only" },
							}
						end,
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.raidDebuffs = up.raidDebuffs or {}
							return tostring(up.raidDebuffs.glowMode or "ALL")
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.raidDebuffs = up.raidDebuffs or {}
							up.raidDebuffs.glowMode = tostring(v)
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Aura Watch",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							if not isGroup then
								return false
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return up.auraWatch.enabled ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.enabled = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Aura Watch Icon Size",
						min = 8,
						max = 22,
						step = 1,
						format = "%.0f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return tonumber(up.auraWatch.size) or 10
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.size = math.floor(v + 0.5)
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Aura Watch Buff Slots",
						min = 0,
						max = 8,
						step = 1,
						format = "%.0f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return tonumber(up.auraWatch.numBuffs) or 3
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.numBuffs = math.floor(v + 0.5)
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Aura Watch Debuff Slots",
						min = 0,
						max = 8,
						step = 1,
						format = "%.0f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return tonumber(up.auraWatch.numDebuffs) or 3
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.numDebuffs = math.floor(v + 0.5)
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Aura Watch Debuff Overlay",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return up.auraWatch.showDebuffType ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.showDebuffType = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Aura Watch Replace Defaults",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return up.auraWatch.replaceDefaults == true
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.replaceDefaults = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "edit",
						label = "Aura Watch Custom Spell List",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.auraWatch = up.auraWatch or {}
							return tostring(up.auraWatch.customSpellList or "")
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.auraWatch = up.auraWatch or {}
							up.auraWatch.customSpellList = tostring(v or "")
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Frame Fader",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							if not isGroup then
								return false
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.enabled == true
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.enabled = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Fader Min Alpha",
						min = 0.05,
						max = 1,
						step = 0.05,
						format = "%.2f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return tonumber(up.fader.minAlpha) or 0.45
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.minAlpha = tonumber(v) or 0.45
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Fader Max Alpha",
						min = 0.05,
						max = 1,
						step = 0.05,
						format = "%.2f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return tonumber(up.fader.maxAlpha) or 1
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.maxAlpha = tonumber(v) or 1
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Fader Smooth",
						min = 0,
						max = 1,
						step = 0.05,
						format = "%.2f",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return tonumber(up.fader.smooth) or 0.2
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.smooth = tonumber(v) or 0.2
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Fader: Combat",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.combat ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.combat = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Fader: Hover",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.hover ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.hover = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Fader: Player Target",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.playerTarget ~= false
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.playerTarget = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Fader: Action Targeting",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.actionTarget == true
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.actionTarget = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Fader: Unit Target",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.unitTarget == true
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.unitTarget = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
					{
						type = "check",
						label = "Fader: Casting",
						disabled = function()
							if not isGroup then
								return true
							end
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							return not up or up.useGlobal ~= false
						end,
						get = function()
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							up = up or {}
							up.fader = up.fader or {}
							return up.fader.casting == true
						end,
						set = function(v)
							local plugins = addon:GetPluginSettings()
							local up = plugins.units and plugins.units[unitKey]
							if not up then
								return
							end
							up.fader = up.fader or {}
							up.fader.casting = v and true or false
							addon:SchedulePluginUpdate(unitKey)
						end,
					},
				},
			},
			{
				tab = "advanced",
				title = unitLabel .. " - Advanced",
				desc = "Portrait, layout, glow, and module copy/reset tools.",
				controls = {
					{
						type = "dropdown",
						label = "Portrait Mode",
						options = function()
							return {
								{ value = "none", text = "None" },
								{ value = "2D", text = "2D" },
								{ value = "3D", text = "3D" },
								{ value = "3DMotion", text = "3D Motion" },
							}
						end,
						get = function()
							local unit = GetUnit()
							unit.portrait = unit.portrait or {}
							return tostring(unit.portrait.mode or "none")
						end,
						set = function(v)
							local unit = GetUnit()
							unit.portrait = unit.portrait or {}
							unit.portrait.mode = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "slider",
						label = "Portrait Size",
						min = 16,
						max = 64,
						step = 1,
						format = "%.0f",
						get = function()
							local unit = GetUnit()
							unit.portrait = unit.portrait or {}
							return tonumber(unit.portrait.size) or 32
						end,
						set = function(v)
							local unit = GetUnit()
							unit.portrait = unit.portrait or {}
							unit.portrait.size = math.floor(v + 0.5)
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Show PvP Indicator",
						get = function()
							local unit = GetUnit()
							return unit.showPvp ~= false
						end,
						set = function(v)
							local unit = GetUnit()
							unit.showPvp = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Show Resting Indicator",
						get = function()
							local unit = GetUnit()
							return unit.showResting == true
						end,
						set = function(v)
							local unit = GetUnit()
							unit.showResting = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Enable Target Glow",
						get = function()
							local cfg = addon:GetUnitTargetGlowSettings(unitKey)
							return cfg.enabled == true
						end,
						set = function(v)
							local cfg = addon:GetUnitTargetGlowSettings(unitKey)
							cfg.enabled = v and true or false
							addon:ScheduleUpdateUnitType(unitKey)
						end,
					},
					{
						type = "slider",
						label = "Target Glow Inset",
						min = 0,
						max = 12,
						step = 1,
						format = "%.0f",
						get = function()
							local cfg = addon:GetUnitTargetGlowSettings(unitKey)
							return tonumber(cfg.inset) or 3
						end,
						set = function(v)
							local cfg = addon:GetUnitTargetGlowSettings(unitKey)
							cfg.inset = math.floor(v + 0.5)
							addon:ScheduleUpdateUnitType(unitKey)
						end,
					},
					{
						type = "color",
						label = "Target Glow Color",
						get = function()
							local cfg = addon:GetUnitTargetGlowSettings(unitKey)
							return cfg.color
						end,
						set = function(r, g, b)
							local cfg = addon:GetUnitTargetGlowSettings(unitKey)
							cfg.color[1], cfg.color[2], cfg.color[3] = r, g, b
							addon:ScheduleUpdateUnitType(unitKey)
						end,
					},
				},
			},
			{
				tab = "advanced",
				title = unitLabel .. " - Module Copy / Reset",
				desc = "Copy module data between units/profiles and reset selected modules.",
				controls = {
					{
						type = "dropdown",
						label = "Module",
						options = GetModuleOptions,
						get = function()
							if not addon:IsModuleSupportedForUnit(moduleState.module, unitKey) then
								local options = GetModuleOptions()
								moduleState.module = options[1] and options[1].value or "castbar"
							end
							return moduleState.module
						end,
						set = function(v)
							moduleState.module = tostring(v)
						end,
					},
					{
						type = "dropdown",
						label = "Copy From Unit",
						options = function()
							return GetSupportedUnitOptionsForModule(moduleState.module)
						end,
						get = function()
							return moduleState.sourceUnit or unitKey
						end,
						set = function(v)
							moduleState.sourceUnit = tostring(v)
						end,
					},
					{
						type = "dropdown",
						label = "Copy From Profile",
						options = function()
							local names = addon:GetAvailableProfiles() or {}
							local out = {}
							for i = 1, #names do
								out[#out + 1] = { value = names[i], text = names[i] }
							end
							if #out == 0 then
								out[1] = { value = "Global", text = "Global" }
							end
							return out
						end,
						get = function()
							return moduleState.profile or "Global"
						end,
						set = function(v)
							moduleState.profile = tostring(v)
						end,
					},
					{
						type = "check",
						label = "Require Confirmation Before Apply",
						get = function()
							return moduleState.confirmApply ~= false
						end,
						set = function(v)
							moduleState.confirmApply = v and true or false
						end,
					},
					{
						type = "paragraph",
						getText = BuildModulePreviewText,
					},
					{
						type = "button",
						label = "Copy Module From Unit",
						onClick = function()
							local payload = GetSourcePayloadFromUnit()
							local details = ("Unit: %s\nModule: %s\nSource Unit: %s"):format(
								GetUnitLabel(unitKey),
								addon:GetModuleLabel(moduleState.module),
								GetUnitLabel(moduleState.sourceUnit or unitKey)
							)
							addon:RunWithOptionalModuleApplyConfirmation(moduleState.confirmApply ~= false, "Apply module copy from selected unit?", details, function()
								addon:CopyModuleIntoCurrent(moduleState.module, unitKey, payload)
							end)
						end,
					},
					{
						type = "button",
						label = "Copy Module From Profile",
						onClick = function()
							local payload = addon:GetModulePayloadFromProfile(moduleState.profile, moduleState.module, unitKey)
							local details = ("Unit: %s\nModule: %s\nSource Profile: %s"):format(
								GetUnitLabel(unitKey),
								addon:GetModuleLabel(moduleState.module),
								tostring(moduleState.profile)
							)
							addon:RunWithOptionalModuleApplyConfirmation(moduleState.confirmApply ~= false, "Apply module copy from selected profile?", details, function()
								addon:CopyModuleIntoCurrent(moduleState.module, unitKey, payload)
							end)
						end,
					},
					{
						type = "button",
						label = "Reset Selected Module",
						onClick = function()
							local details = ("Unit: %s\nModule: %s"):format(
								GetUnitLabel(unitKey),
								addon:GetModuleLabel(moduleState.module)
							)
							addon:RunWithOptionalModuleApplyConfirmation(moduleState.confirmApply ~= false, "Reset selected module for this unit?", details, function()
								addon:ResetModuleForUnit(moduleState.module, unitKey)
							end)
						end,
					},
				},
			},
			{
				tab = "advanced",
				title = unitLabel .. " - Actions",
				desc = "Quick helpers and native navigation.",
				controls = {
					{
						type = "button",
						label = "Force Show This Unit Type",
						onClick = function()
							if InCombatLockdown and InCombatLockdown() then
								if addon.Print then
									addon:Print("SimpleUnitFrames: Test mode changes are blocked during combat.")
								end
								return
							end
							addon:SetTestModeForUnitType(unitKey)
							addon:ScheduleUpdateAll()
							RefreshOptionsV2CurrentPage()
						end,
					},
					{
						type = "button",
						label = "Reset This Unit to Defaults",
						onClick = function()
							local defaults = addon._core and addon._core.defaults
							if not defaults or not defaults.profile then
								return
							end
							if defaults.profile.units and defaults.profile.units[unitKey] then
								addon.db.profile.units[unitKey] = CopyTableDeepLocal(defaults.profile.units[unitKey])
							end
							if defaults.profile.tags and defaults.profile.tags[unitKey] then
								addon.db.profile.tags[unitKey] = CopyTableDeepLocal(defaults.profile.tags[unitKey])
							end
							if defaults.profile.sizes and defaults.profile.sizes[unitKey] then
								addon.db.profile.sizes[unitKey] = CopyTableDeepLocal(defaults.profile.sizes[unitKey])
							end
							if isGroup then
								local pluginCfg = addon:GetPluginSettings()
								pluginCfg.units = pluginCfg.units or CopyTableDeepLocal(defaults.profile.plugins.units)
								pluginCfg.units[unitKey] = CopyTableDeepLocal(defaults.profile.plugins.units[unitKey])
								pluginCfg.units[unitKey].useGlobal = true
								addon:SchedulePluginUpdate(unitKey)
							end
							addon:ScheduleUpdateUnitType(unitKey)
						end,
					},
					{
						type = "button",
						label = "Open Tags Page",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								addon.optionsV2Frame:SetPage("tags")
							end
						end,
					},
					{
						type = "button",
						label = "Open Import / Export",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								addon.optionsV2Frame:SetPage("importexport")
							end
						end,
					},
				},
			},
		},
	}
end

local function BuildTagsNativeSpec()
	local function TagWidthCharsFor(unitKey, fieldKey)
		local tags = addon.db.profile.tags[unitKey] or {}
		local value = tostring(tags[fieldKey] or "")
		return math.max(12, math.min(48, #value + 2))
	end

	local function GetTagsSection()
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.tags = cfg.sectionState.tags or "overview"
		return tostring(cfg.sectionState.tags)
	end
	local function SetTagsSection(key)
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.tags = tostring(key or "overview")
	end

	local sections = {
		{
			tab = "overview",
			title = "Tags Overview",
			desc = "Edit per-unit tag strings directly in V2.",
			controls = {
				{ type = "paragraph", text = "Use oUF tags and SUF custom tags in fields below. Example: [raidcolor][name] [suf:status]" },
			},
		},
	}
	local function BuildCategoryTagText(category)
		local tags = CollectOUFTagsLocal()
		local filtered = {}
		for i = 1, #tags do
			if CategorizeTagLocal(tags[i]) == category then
				filtered[#filtered + 1] = tags[i]
			end
		end
		return table.concat(filtered, ", ")
	end
	local function BuildTagDump(prefix)
		local tags = CollectOUFTagsLocal()
		local out = {}
		for i = 1, #tags do
			local tag = tags[i]
			if not prefix or tag:sub(1, #prefix) == prefix then
				out[#out + 1] = "[" .. tag .. "]"
			end
		end
		return table.concat(out, ", ")
	end
	local function BuildReferenceControls()
		local controls = {
			{ type = "paragraph", text = "Each tag below has its own copy field. Click and copy directly." },
		}
		local tags = CollectOUFTagsLocal()
		local grouped = {
			Identity = {},
			Health = {},
			Power = {},
			Cast = {},
			Auras = {},
			Status = {},
			Other = {},
		}
		for i = 1, #tags do
			local tag = tags[i]
			local category = CategorizeTagLocal(tag)
			grouped[category] = grouped[category] or {}
			grouped[category][#grouped[category] + 1] = tag
		end
		local ordered = { "Identity", "Health", "Power", "Cast", "Auras", "Status", "Other" }
		for i = 1, #ordered do
			local category = ordered[i]
			local list = grouped[category]
			if list and #list > 0 then
				controls[#controls + 1] = { type = "label", text = category .. " Tags" }
				for j = 1, #list do
					local wrapped = "[" .. tostring(list[j]) .. "]"
					controls[#controls + 1] = {
						type = "edit",
						label = wrapped,
						widthChars = #wrapped + 2,
						get = function()
							return wrapped
						end,
						set = function() end,
					}
				end
			end
		end
		return controls
	end
	for i = 1, #UNIT_TYPE_ORDER do
		local unitKey = UNIT_TYPE_ORDER[i]
		local uk = unitKey
		local unitLabel = GetUnitLabel(uk)
		sections[#sections + 1] = {
			tab = "units",
			title = unitLabel,
			desc = "Tag strings for " .. unitLabel .. ".",
			controls = {
				{
					type = "edit",
					label = "Name Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "name")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.name or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].name = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
				{
					type = "edit",
					label = "Level Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "level")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.level or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].level = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
				{
					type = "edit",
					label = "Health Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "health")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.health or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].health = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
				{
					type = "edit",
					label = "Power Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "power")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.power or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].power = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
			},
		}
	end
	sections[#sections + 1] = {
		tab = "reference",
		title = "Advanced Reference",
		desc = "Copy-ready oUF/SUF tag containers, including dynamically discovered tags.",
		controls = (function()
			local controls = BuildReferenceControls()
			controls[#controls + 1] = {
				type = "edit",
				label = "SUF Tags (combined)",
				get = function()
					return BuildTagDump("suf:")
				end,
				set = function() end,
			}
			controls[#controls + 1] = {
				type = "edit",
				label = "All oUF/SUF Tags (combined)",
				get = function()
					return BuildTagDump(nil)
				end,
				set = function() end,
			}
			controls[#controls + 1] = {
				type = "button",
				label = "Open Performance Page",
				onClick = function()
					if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
						addon.optionsV2Frame:SetPage("performance")
					end
				end,
			}
			return controls
		end)(),
	}
	return {
		sectionTabs = {
			{ key = "overview", label = "Overview" },
			{ key = "units", label = "Units" },
			{ key = "reference", label = "Reference" },
			{ key = "all", label = "All" },
		},
		getActiveSection = GetTagsSection,
		setActiveSection = SetTagsSection,
		sections = sections,
	}
end

function addon:GetOptionsV2PageSpec(pageKey)
	local defaults = {
		sections = {
			{
				title = "Unavailable Page",
				desc = "This page key is not registered in Options V2.",
				controls = {
					{
						type = "button",
						label = "Open Global Page",
						help = "Return to a valid Options V2 page.",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								addon.optionsV2Frame:SetPage("global")
							end
						end,
					},
				},
			},
		},
	}

	local function Clamp(v, min, max, fallback)
		local n = tonumber(v)
		if not n then
			return fallback
		end
		if n < min then
			return min
		end
		if n > max then
			return max
		end
		return n
	end

	local function BuildClassResourceStatusText()
		local data = addon.GetClassResourceAuditData and addon:GetClassResourceAuditData() or {}
		local statusText = "IDLE"
		if not data.hasPlayerFrame then
			statusText = "NOT SPAWNED"
		elseif data.active and data.classPowerVisible and (tonumber(data.visibleSlots) or 0) > 0 then
			statusText = "HEALTHY"
		elseif data.active and not data.classPowerVisible then
			statusText = "CONTEXT ACTIVE / BAR HIDDEN"
		elseif (not data.active) and data.classPowerVisible then
			statusText = "CONTEXT INACTIVE / BAR VISIBLE"
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
		return table.concat(lines, "\n")
	end

	local function BuildPerformanceSnapshotText()
		local frameStats = addon.performanceLib and addon.performanceLib.GetFrameTimeStats and addon.performanceLib:GetFrameTimeStats() or {}
		local eventStats = addon.performanceLib and addon.performanceLib.EventCoalescer and addon.performanceLib.EventCoalescer.GetStats and addon.performanceLib.EventCoalescer:GetStats() or {}
		local dirtyStats = addon.performanceLib and addon.performanceLib.DirtyFlagManager and addon.performanceLib.DirtyFlagManager.GetStats and addon.performanceLib.DirtyFlagManager:GetStats() or {}
		local poolStats = addon.performanceLib and addon.performanceLib.FramePoolManager and addon.performanceLib.FramePoolManager.GetStats and addon.performanceLib.FramePoolManager:GetStats() or {}
		local profilerStats = addon.performanceLib and addon.performanceLib.PerformanceProfiler and addon.performanceLib.PerformanceProfiler.GetStats and addon.performanceLib.PerformanceProfiler:GetStats() or {}
		local preset = addon.GetPerformanceLibPreset and addon:GetPerformanceLibPreset() or "Medium"
		local isRecording = profilerStats.isRecording and "Yes" or "No"
		return ("Preset: %s\nFrame: avg %.2fms | p95 %.2f | p99 %.2f\nEventBus: coalesced=%d dispatched=%d queued=%d savings=%.1f%%\nDirty: processed=%d batches=%d queued=%d\nPools: created=%d reused=%d released=%d\nProfiler: recording=%s events=%d"):format(
			tostring(preset),
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

	if pageKey == "performance" then
		local function GetPerformanceSection()
			local cfg = addon:EnsureOptionsV2Config()
			cfg.sectionState.performance = cfg.sectionState.performance or "integration"
			return tostring(cfg.sectionState.performance)
		end
		local function SetPerformanceSection(key)
			local cfg = addon:EnsureOptionsV2Config()
			cfg.sectionState.performance = tostring(key or "integration")
		end
		return {
			sectionTabs = {
				{ key = "integration", label = "Integration" },
				{ key = "actions", label = "Actions" },
				{ key = "resources", label = "Resources" },
				{ key = "snapshot", label = "Snapshot" },
				{ key = "status", label = "Status" },
				{ key = "all", label = "All" },
			},
			getActiveSection = GetPerformanceSection,
			setActiveSection = SetPerformanceSection,
			sections = {
				{
					tab = "integration",
					title = "PerformanceLib",
					desc = "Tune presets, launch tools, and control snapshot behavior.",
					controls = {
						{
							type = "check",
							label = "Enable PerformanceLib Integration",
							get = function()
								return addon.db.profile.performance and addon.db.profile.performance.enabled ~= false
							end,
							set = function(v)
								addon:SetPerformanceIntegrationEnabled(v and true or false)
							end,
							disabled = function()
								return not addon.performanceLib
							end,
						},
						{
							type = "dropdown",
							label = "Active Preset",
							options = function()
								return {
									{ value = "Low", text = "Low" },
									{ value = "Medium", text = "Medium" },
									{ value = "High", text = "High" },
									{ value = "Ultra", text = "Ultra" },
								}
							end,
							get = function()
								return addon.GetPerformanceLibPreset and addon:GetPerformanceLibPreset() or "Medium"
							end,
							set = function(v)
								if addon.performanceLib and addon.performanceLib.SetPreset then
									addon.performanceLib:SetPreset(v)
								end
							end,
							disabled = function()
								return not (addon.performanceLib and addon.performanceLib.SetPreset)
							end,
						},
						{
							type = "check",
							label = "Auto-refresh Snapshot (1s)",
							get = function()
								return addon.db.profile.performance.optionsAutoRefresh ~= false
							end,
							set = function(v)
								addon.db.profile.performance.optionsAutoRefresh = v and true or false
							end,
						},
					},
				},
				{
					tab = "actions",
					title = "Actions",
					desc = "Common PerformanceLib and diagnostic actions.",
					controls = {
						{ type = "button", label = "Open SUF Performance UI", onClick = function() if addon.performanceLib and addon.performanceLib.ToggleDashboard then addon.performanceLib:ToggleDashboard() end end },
						{ type = "button", label = "Open SUF Debug", onClick = function() addon:ShowDebugPanel() end },
						{ type = "button", label = "Profile Start", onClick = function() if addon.StartPerformanceProfileFromUI then addon:StartPerformanceProfileFromUI() end end },
						{ type = "button", label = "Profile Stop", onClick = function() if addon.StopPerformanceProfileFromUI then addon:StopPerformanceProfileFromUI() end end },
						{ type = "button", label = "Profile Analyze", onClick = function() if addon.AnalyzePerformanceProfileFromUI then addon:AnalyzePerformanceProfileFromUI() end end },
						{ type = "button", label = "Print Status Report", onClick = function() addon:PrintStatusReport() end },
						{ type = "button", label = "Refresh Snapshot", onClick = function() if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then addon.optionsV2Frame:SetPage("performance") end end },
					},
				},
				{
					tab = "resources",
					title = "Class Resource Status",
					desc = "Current class resource context as seen by SUF.",
					controls = {
						{ type = "paragraph", getText = BuildClassResourceStatusText },
					},
				},
				{
					tab = "snapshot",
					title = "Current Snapshot",
					desc = "Current performance snapshot from PerformanceLib components.",
					controls = {
						{ type = "paragraph", getText = BuildPerformanceSnapshotText },
					},
				},
				{
					tab = "status",
					title = "SUF Status Report",
					desc = "High-level addon status summary.",
					controls = {
						{
							type = "paragraph",
							getText = function()
								return addon.BuildStatusReportText and addon:BuildStatusReportText() or "Status report unavailable."
							end,
						},
					},
				},
			},
		}
	end

	if pageKey == "tags" then
		return BuildTagsNativeSpec()
	end
	if pageKey == "credits" then
		return {
			sections = {
				{
					title = "Credits",
					desc = "Project and library attribution.",
					controls = {
						{ type = "paragraph", text = "SimpleUnitFrames (SUF)\nPrimary Author: Grevin" },
						{ type = "paragraph", text = "Core Framework Credits:\noUF authors and Ace3 community maintainers." },
						{ type = "paragraph", text = "Optional Integration Credits:\nPerformanceLib, LibSharedMedia-3.0, LibDualSpec-1.0, LibDataBroker-1.1, LibDBIcon-1.0." },
						{ type = "paragraph", text = "Utility Library Credits:\nLibSerialize, LibDeflate, LibCustomGlow-1.0, LibSimpleSticky, LibTranslit-1.0, UTF8, TaintLess, LibDispel-1.0." },
						{ type = "paragraph", text = "Reference Credits:\nGethe/wow-ui-source and Warcraft Wiki API contributors." },
						{
							type = "button",
							label = "Open README",
							onClick = function()
								if addon.Print then
									addon:Print("SimpleUnitFrames: See README.md for full credits and attribution.")
								end
							end,
						},
					},
				},
			},
		}
	end
	if pageKey == "player" or pageKey == "target" or pageKey == "tot" or pageKey == "focus" or pageKey == "pet" or pageKey == "party" or pageKey == "raid" or pageKey == "boss" then
		return BuildUnitCoreSpec(pageKey)
	end

	---------------------------------------------------------------------------
	-- CUSTOM TRACKERS PAGE
	---------------------------------------------------------------------------
	if pageKey == "customtrackers" then
		local CT = addon.CustomTrackers
		local ctState = addon._ctOptionsState or {}
		addon._ctOptionsState = ctState

		local function GetCTDB()
			return addon.db and addon.db.profile and addon.db.profile.customTrackers
		end

		local function GetBars()
			local db = GetCTDB()
			return (db and db.bars) or {}
		end

		local function GetSelectedBarID()
			return ctState.selectedBarID
		end

		local function GetSelectedBar()
			local barID = GetSelectedBarID()
			if not barID or not CT then return nil end
			return CT:GetBarConfig(barID)
		end

		local function SetSelectedBarID(id)
			ctState.selectedBarID = id
		end

		local function GetSection()
			ctState.section = ctState.section or "manage"
			return tostring(ctState.section)
		end

		local function SetSection(key)
			ctState.section = tostring(key or "manage")
		end

		local function BuildBarOptions()
			local bars = GetBars()
			local out = {}
			for _, b in ipairs(bars) do
				out[#out + 1] = { value = b.id, text = (b.name or b.id) }
			end
			if #out == 0 then
				out[1] = { value = "", text = "(No bars yet)" }
			end
			return out
		end

		local function RefreshPage()
			if addon.optionsV2Frame and addon.optionsV2Frame.RefreshCurrentPage then
				addon.optionsV2Frame:RefreshCurrentPage()
			end
		end

		local function GetBarField(field, fallback)
			local b = GetSelectedBar()
			if not b then return fallback end
			local v = b[field]
			if v == nil then return fallback end
			return v
		end

		local function GetAutoLearnField(field, fallback)
			local db = GetCTDB()
			local auto = db and db.autoLearn
			if not auto then return fallback end
			local v = auto[field]
			if v == nil then return fallback end
			return v
		end

		local function SetAutoLearnField(field, value)
			local db = GetCTDB()
			if not db then return end
			db.autoLearn = db.autoLearn or {}
			db.autoLearn[field] = value
		end

		local function SetBarField(field, value)
			local b = GetSelectedBar()
			if not b then return end
			b[field] = value
			if CT then CT:UpdateBar(b.id) end
		end

		local function SetBarFieldAndRefresh(field, value)
			SetBarField(field, value)
			RefreshPage()
		end

		local function BuildEntryListText()
			local b = GetSelectedBar()
			if not b or not b.entries or #b.entries == 0 then
				return "(No entries — add spells or items below)"
			end
			local lines = {}
			for i, entry in ipairs(b.entries) do
				local label = entry.type .. " " .. tostring(entry.id)
				if entry.type == "spell" then
					local info = C_Spell.GetSpellInfo(entry.id)
					if info and info.name then label = "[Spell] " .. info.name .. " (" .. entry.id .. ")" end
				elseif entry.type == "item" then
					local name = C_Item.GetItemInfo(entry.id)
					if name then label = "[Item] " .. name .. " (" .. entry.id .. ")" end
				end
				lines[#lines + 1] = i .. ". " .. label
			end
			return table.concat(lines, "\n")
		end

		local function BuildEntryLabel(entry, index)
			if not entry then
				return tostring(index or "?") .. ". (unknown)"
			end
			local label = entry.type .. " " .. tostring(entry.id)
			if entry.type == "spell" then
				local info = C_Spell.GetSpellInfo(entry.id)
				if info and info.name then
					label = "[Spell] " .. info.name .. " (" .. entry.id .. ")"
				end
			elseif entry.type == "item" then
				local name = C_Item.GetItemInfo(entry.id)
				if name then
					label = "[Item] " .. name .. " (" .. entry.id .. ")"
				end
			end
			return tostring(index or "?") .. ". " .. label
		end

		local function BuildGrowDirOptions()
			return {
				{ value = "RIGHT", text = "Right" },
				{ value = "LEFT",  text = "Left" },
				{ value = "DOWN",  text = "Down" },
				{ value = "UP",    text = "Up" },
				{ value = "CENTER", text = "Center (horizontal)" },
				{ value = "CENTER_VERTICAL", text = "Center (vertical)" },
			}
		end

		local function BuildLockPositionOptions()
			return {
				{ value = "topcenter",    text = "Top Center" },
				{ value = "topleft",      text = "Top Left" },
				{ value = "topright",     text = "Top Right" },
				{ value = "bottomcenter", text = "Bottom Center" },
				{ value = "bottomleft",   text = "Bottom Left" },
				{ value = "bottomright",  text = "Bottom Right" },
			}
		end

		local function BuildGlowTypeOptions()
			return {
				{ value = "Pixel Glow",    text = "Pixel Glow" },
				{ value = "Autocast Shine", text = "Autocast Shine" },
			}
		end

		-- Manage section (no bar selected / bar list management)
		local manageControls = {
			{
				type = "paragraph",
				getText = function()
					local bars = GetBars()
					if #bars == 0 then
						return "No custom tracker bars created yet. Click 'New Bar' to create one."
					end
					local names = {}
					for _, b in ipairs(bars) do
						names[#names + 1] = "• " .. (b.name or b.id) .. (b.enabled and "" or " [disabled]")
					end
					return "Bars:\n" .. table.concat(names, "\n")
				end,
			},
			{
				type = "check",
				label = "Auto-Learn From Usage",
				get = function() return GetAutoLearnField("enabled", false) end,
				set = function(v)
					SetAutoLearnField("enabled", v and true or false)
					if v and CT and CT.RebuildItemSpellIndex then
						CT:RebuildItemSpellIndex()
					end
				end,
			},
			{
				type = "check",
				label = "  Learn Spells",
				disabled = function() return GetAutoLearnField("enabled", false) ~= true end,
				get = function() return GetAutoLearnField("learnSpells", true) end,
				set = function(v) SetAutoLearnField("learnSpells", v and true or false) end,
			},
			{
				type = "check",
				label = "  Learn Items",
				disabled = function() return GetAutoLearnField("enabled", false) ~= true end,
				get = function() return GetAutoLearnField("learnItems", true) end,
				set = function(v) SetAutoLearnField("learnItems", v and true or false) end,
			},
			{
				type = "dropdown",
				label = "  Auto-Learn Destination Bar",
				disabled = function() return GetAutoLearnField("enabled", false) ~= true end,
				options = function()
					local out = {
						{ value = "", text = "(Auto: First Bar)" },
					}
					local bars = GetBars()
					for i = 1, #bars do
						local b = bars[i]
						out[#out + 1] = { value = b.id, text = (b.name or b.id) }
					end
					return out
				end,
				get = function() return tostring(GetAutoLearnField("targetBarID", "") or "") end,
				set = function(v) SetAutoLearnField("targetBarID", tostring(v or "")) end,
			},
			{
				type = "button",
				label = "New Bar",
				onClick = function()
					if CT then
						local newID = CT:CreateNewBar()
						if newID then
							SetSelectedBarID(newID)
							SetSection("layout")
							RefreshPage()
						end
					end
				end,
			},
			{
				type = "dropdown",
				label = "Select Bar to Configure",
				options = BuildBarOptions,
				get = function()
					return GetSelectedBarID() or ""
				end,
				set = function(v)
					SetSelectedBarID(v ~= "" and v or nil)
					RefreshPage()
				end,
			},
			{
				type = "button",
				label = "Delete Selected Bar",
				disabled = function() return GetSelectedBar() == nil end,
				onClick = function()
					local barID = GetSelectedBarID()
					if barID and CT then
						CT:DeleteBarByID(barID)
						SetSelectedBarID(nil)
						RefreshPage()
					end
				end,
			},
		}

		-- Layout section
		local layoutControls = {
			{
				type = "dropdown",
				label = "Bar",
				options = BuildBarOptions,
				get = function() return GetSelectedBarID() or "" end,
				set = function(v)
					SetSelectedBarID(v ~= "" and v or nil)
					RefreshPage()
				end,
			},
			{
				type = "edit",
				label = "Bar Name",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("name", "") end,
				set = function(v) SetBarFieldAndRefresh("name", v ~= "" and v or "Bar") end,
			},
			{
				type = "check",
				label = "Enabled",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("enabled", true) end,
				set = function(v) SetBarField("enabled", v); RefreshPage() end,
			},
			{
				type = "slider",
				label = "Icon Size",
				min = 16, max = 80, step = 1, format = "%d px",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("iconSize", 36) end,
				set = function(v) SetBarField("iconSize", math.floor(v + 0.5)) end,
			},
			{
				type = "slider",
				label = "Icon Spacing",
				min = 0, max = 20, step = 1, format = "%d px",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("spacing", 4) end,
				set = function(v) SetBarField("spacing", math.floor(v + 0.5)) end,
			},
			{
				type = "slider",
				label = "Border Size",
				min = 0, max = 6, step = 1, format = "%d px",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("borderSize", 2) end,
				set = function(v) SetBarField("borderSize", math.floor(v + 0.5)) end,
			},
			{
				type = "slider",
				label = "Aspect Ratio Crop (1.0 = square, 1.33 = flat 4:3)",
				min = 1.0, max = 2.0, step = 0.01, format = "%.2f",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("aspectRatioCrop", 1.0) end,
				set = function(v) SetBarField("aspectRatioCrop", v) end,
			},
			{
				type = "slider",
				label = "Icon Zoom (0 = default crop)",
				min = 0, max = 0.15, step = 0.005, format = "%.3f",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("zoom", 0) end,
				set = function(v) SetBarField("zoom", v) end,
			},
			{
				type = "dropdown",
				label = "Grow Direction",
				options = BuildGrowDirOptions,
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("growDirection", "RIGHT") end,
				set = function(v) SetBarField("growDirection", v) end,
			},
			{
				type = "slider",
				label = "Background Opacity",
				min = 0, max = 1, step = 0.05, format = "%.2f",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("bgOpacity", 0) end,
				set = function(v) SetBarField("bgOpacity", v) end,
			},
			{
				type = "color",
				label = "Background Color",
				disabled = function() return GetSelectedBar() == nil end,
				get = function()
					local c = GetBarField("bgColor", nil)
					return c or { 0, 0, 0 }
				end,
				set = function(r, g, b)
					local b2 = GetSelectedBar()
					if not b2 then return end
					if not b2.bgColor then b2.bgColor = { 0, 0, 0, 1 } end
					b2.bgColor[1], b2.bgColor[2], b2.bgColor[3] = r, g, b
					if CT then CT:UpdateBar(b2.id) end
				end,
			},
		}

		-- Position section
		local positionControls = {
			{
				type = "dropdown",
				label = "Bar",
				options = BuildBarOptions,
				get = function() return GetSelectedBarID() or "" end,
				set = function(v)
					SetSelectedBarID(v ~= "" and v or nil)
					RefreshPage()
				end,
			},
			{
				type = "check",
				label = "Lock Position (disable dragging)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("locked", false) end,
				set = function(v) SetBarField("locked", v) end,
			},
			{
				type = "check",
				label = "Lock to Player Frame",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("lockedToPlayer", false) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.lockedToPlayer = v
						if v then b.lockedToTarget = false end
						if CT then CT:UpdateBar(b.id); CT:RefreshBarPosition(b.id) end
					end
				end,
			},
			{
				type = "dropdown",
				label = "Player Frame Anchor",
				options = BuildLockPositionOptions,
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("lockedToPlayer", false)
				end,
				get = function() return GetBarField("lockPosition", "bottomcenter") end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.lockPosition = v
						if CT then CT:UpdateBar(b.id); CT:RefreshBarPosition(b.id) end
					end
				end,
			},
			{
				type = "check",
				label = "Lock to Target Frame",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("lockedToTarget", false) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.lockedToTarget = v
						if v then b.lockedToPlayer = false end
						if CT then CT:UpdateBar(b.id); CT:RefreshBarPosition(b.id) end
					end
				end,
			},
			{
				type = "dropdown",
				label = "Target Frame Anchor",
				options = BuildLockPositionOptions,
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("lockedToTarget", false)
				end,
				get = function() return GetBarField("targetLockPosition", "bottomcenter") end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.targetLockPosition = v
						if CT then CT:UpdateBar(b.id); CT:RefreshBarPosition(b.id) end
					end
				end,
			},
			{
				type = "slider",
				label = "Offset X",
				min = -2000, max = 2000, step = 1, format = "%d",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("offsetX", 0) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.offsetX = math.floor(v + 0.5)
						if CT then CT:RefreshBarPosition(b.id) end
					end
				end,
			},
			{
				type = "slider",
				label = "Offset Y",
				min = -1500, max = 1500, step = 1, format = "%d",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("offsetY", -300) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.offsetY = math.floor(v + 0.5)
						if CT then CT:RefreshBarPosition(b.id) end
					end
				end,
			},
		}

		-- Visibility section
		local visibilityControls = {
			{
				type = "dropdown",
				label = "Bar",
				options = BuildBarOptions,
				get = function() return GetSelectedBarID() or "" end,
				set = function(v)
					SetSelectedBarID(v ~= "" and v or nil)
					RefreshPage()
				end,
			},
			{
				type = "check",
				label = "Hide Unknown / Unlearned Spells",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("hideNonUsable", false) end,
				set = function(v) SetBarField("hideNonUsable", v) end,
			},
			{
				type = "check",
				label = "Dynamic Layout (bar collapses when icons hide)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("dynamicLayout", false) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.dynamicLayout = v
						if v then b.clickableIcons = false end
						if CT then CT:UpdateBar(b.id) end
						RefreshPage()
					end
				end,
			},
			{
				type = "check",
				label = "Show Only When On Cooldown",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showOnlyOnCooldown", false) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.showOnlyOnCooldown = v
						if v then b.showOnlyWhenActive = false; b.showOnlyWhenOffCooldown = false end
						if CT then CT:UpdateBar(b.id) end
					end
				end,
			},
			{
				type = "check",
				label = "  Keep Color When Charges Remain (with Show Only On Cooldown)",
				disabled = function() return GetSelectedBar() == nil or not GetBarField("showOnlyOnCooldown", false) end,
				get = function() return GetBarField("noDesaturateWithCharges", false) end,
				set = function(v) SetBarField("noDesaturateWithCharges", v) end,
			},
			{
				type = "check",
				label = "Show Only When Active (casting / channeling / buff)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showOnlyWhenActive", false) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.showOnlyWhenActive = v
						if v then b.showOnlyOnCooldown = false; b.showOnlyWhenOffCooldown = false end
						if CT then CT:UpdateBar(b.id) end
					end
				end,
			},
			{
				type = "check",
				label = "Show Only When Off Cooldown (ready)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showOnlyWhenOffCooldown", false) end,
				set = function(v)
					local b = GetSelectedBar()
					if b then
						b.showOnlyWhenOffCooldown = v
						if v then b.showOnlyOnCooldown = false; b.showOnlyWhenActive = false end
						if CT then CT:UpdateBar(b.id) end
					end
				end,
			},
			{
				type = "check",
				label = "Show Only In Combat",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showOnlyInCombat", false) end,
				set = function(v) SetBarField("showOnlyInCombat", v) end,
			},
		}

		-- Cooldown & Appearance section
		local cooldownControls = {
			{
				type = "dropdown",
				label = "Bar",
				options = BuildBarOptions,
				get = function() return GetSelectedBarID() or "" end,
				set = function(v)
					SetSelectedBarID(v ~= "" and v or nil)
					RefreshPage()
				end,
			},
			{
				type = "check",
				label = "Hide GCD (suppress Global Cooldown display)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("hideGCD", true) end,
				set = function(v) SetBarField("hideGCD", v) end,
			},
			{
				type = "check",
				label = "Show Recharge Swipe (for charge-based spells)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showRechargeSwipe", false) end,
				set = function(v) SetBarField("showRechargeSwipe", v) end,
			},
			{
				type = "check",
				label = "Hide Duration Countdown Text",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("hideDurationText", false) end,
				set = function(v) SetBarField("hideDurationText", v) end,
			},
			{
				type = "slider",
				label = "  Duration Text Size",
				min = 8, max = 24, step = 1, format = "%d px",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideDurationText", false) end,
				get = function() return GetBarField("durationSize", 14) end,
				set = function(v) SetBarField("durationSize", math.floor(v + 0.5)) end,
			},
			{
				type = "dropdown",
				label = "  Duration Text Font",
				options = function() return BuildMediaOptions("font", STANDARD_TEXT_FONT) end,
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideDurationText", false) end,
				get = function() return GetBarField("durationFont", nil) or "" end,
				set = function(v) SetBarField("durationFont", v ~= "" and v or nil) end,
			},
			{
				type = "color",
				label = "  Duration Text Color",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideDurationText", false) end,
				get = function()
					local c = GetBarField("durationColor", nil)
					return c or { 1, 1, 1 }
				end,
				set = function(r, g, b)
					local b2 = GetSelectedBar()
					if not b2 then return end
					if not b2.durationColor then b2.durationColor = { 1, 1, 1, 1 } end
					b2.durationColor[1], b2.durationColor[2], b2.durationColor[3] = r, g, b
					if CT then CT:UpdateBar(b2.id) end
				end,
			},
			{
				type = "slider",
				label = "  Duration Text Offset X",
				min = -30, max = 30, step = 1, format = "%d",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideDurationText", false) end,
				get = function() return GetBarField("durationOffsetX", 0) end,
				set = function(v) SetBarField("durationOffsetX", math.floor(v + 0.5)) end,
			},
			{
				type = "slider",
				label = "  Duration Text Offset Y",
				min = -30, max = 30, step = 1, format = "%d",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideDurationText", false) end,
				get = function() return GetBarField("durationOffsetY", 0) end,
				set = function(v) SetBarField("durationOffsetY", math.floor(v + 0.5)) end,
			},
			{
				type = "check",
				label = "Hide Stack / Charge Count Text",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("hideStackText", false) end,
				set = function(v) SetBarField("hideStackText", v) end,
			},
			{
				type = "slider",
				label = "  Stack Text Size",
				min = 7, max = 18, step = 1, format = "%d px",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideStackText", false) end,
				get = function() return GetBarField("stackSize", 12) end,
				set = function(v) SetBarField("stackSize", math.floor(v + 0.5)) end,
			},
			{
				type = "dropdown",
				label = "  Stack Text Font",
				options = function() return BuildMediaOptions("font", STANDARD_TEXT_FONT) end,
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideStackText", false) end,
				get = function() return GetBarField("stackFont", nil) or "" end,
				set = function(v) SetBarField("stackFont", v ~= "" and v or nil) end,
			},
			{
				type = "color",
				label = "  Stack Text Color",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideStackText", false) end,
				get = function()
					local c = GetBarField("stackColor", nil)
					return c or { 1, 1, 1 }
				end,
				set = function(r, g, b)
					local b2 = GetSelectedBar()
					if not b2 then return end
					if not b2.stackColor then b2.stackColor = { 1, 1, 1, 1 } end
					b2.stackColor[1], b2.stackColor[2], b2.stackColor[3] = r, g, b
					if CT then CT:UpdateBar(b2.id) end
				end,
			},
			{
				type = "slider",
				label = "  Stack Text Offset X",
				min = -30, max = 30, step = 1, format = "%d",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideStackText", false) end,
				get = function() return GetBarField("stackOffsetX", -2) end,
				set = function(v) SetBarField("stackOffsetX", math.floor(v + 0.5)) end,
			},
			{
				type = "slider",
				label = "  Stack Text Offset Y",
				min = -30, max = 30, step = 1, format = "%d",
				disabled = function() return GetSelectedBar() == nil or GetBarField("hideStackText", false) end,
				get = function() return GetBarField("stackOffsetY", 2) end,
				set = function(v) SetBarField("stackOffsetY", math.floor(v + 0.5)) end,
			},
			{
				type = "check",
				label = "Show Item Charges (count uses, not stacks)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showItemCharges", true) end,
				set = function(v) SetBarField("showItemCharges", v) end,
			},
			{
				type = "check",
				label = "Show Active State (glow when casting / buff active)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return GetBarField("showActiveState", true) end,
				set = function(v) SetBarField("showActiveState", v) end,
			},
			{
				type = "check",
				label = "Active Glow Enabled",
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("showActiveState", true)
				end,
				get = function() return GetBarField("activeGlowEnabled", true) end,
				set = function(v) SetBarField("activeGlowEnabled", v) end,
			},
			{
				type = "dropdown",
				label = "Glow Type",
				options = BuildGlowTypeOptions,
				disabled = function()
					return GetSelectedBar() == nil
					       or not GetBarField("showActiveState", true)
					       or not GetBarField("activeGlowEnabled", true)
				end,
				get = function() return GetBarField("activeGlowType", "Pixel Glow") end,
				set = function(v) SetBarField("activeGlowType", v) end,
			},
			{
				type = "color",
				label = "Glow Color",
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("showActiveState", true) or not GetBarField("activeGlowEnabled", true)
				end,
				get = function()
					local c = GetBarField("activeGlowColor", nil)
					return c or { 1, 0.85, 0.3 }
				end,
				set = function(r, g, b)
					local b2 = GetSelectedBar()
					if not b2 then return end
					if not b2.activeGlowColor then b2.activeGlowColor = { 1, 0.85, 0.3, 1 } end
					b2.activeGlowColor[1], b2.activeGlowColor[2], b2.activeGlowColor[3] = r, g, b
					if CT then CT:UpdateBar(b2.id) end
				end,
			},
			{
				type = "slider",
				label = "Glow Lines (Pixel Glow only)",
				min = 4, max = 16, step = 1, format = "%d",
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("showActiveState", true) or not GetBarField("activeGlowEnabled", true)
				end,
				get = function() return GetBarField("activeGlowLines", 8) end,
				set = function(v) SetBarField("activeGlowLines", math.floor(v + 0.5)) end,
			},
			{
				type = "slider",
				label = "Glow Speed / Frequency",
				min = 0.05, max = 1.0, step = 0.05, format = "%.2f",
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("showActiveState", true) or not GetBarField("activeGlowEnabled", true)
				end,
				get = function() return GetBarField("activeGlowFrequency", 0.25) end,
				set = function(v) SetBarField("activeGlowFrequency", v) end,
			},
			{
				type = "slider",
				label = "Glow Thickness (Pixel Glow only)",
				min = 1, max = 5, step = 0.5, format = "%.1f",
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("showActiveState", true) or not GetBarField("activeGlowEnabled", true)
				end,
				get = function() return GetBarField("activeGlowThickness", 2) end,
				set = function(v) SetBarField("activeGlowThickness", v) end,
			},
			{
				type = "slider",
				label = "Glow Scale (Autocast Shine only)",
				min = 0.5, max = 2.0, step = 0.1, format = "%.1f",
				disabled = function()
					return GetSelectedBar() == nil or not GetBarField("showActiveState", true) or not GetBarField("activeGlowEnabled", true)
				end,
				get = function() return GetBarField("activeGlowScale", 1.0) end,
				set = function(v) SetBarField("activeGlowScale", v) end,
			},
			{
				type = "check",
				label = "Clickable Icons (left-click casts spell / uses item)",
				disabled = function()
					return GetSelectedBar() == nil or GetBarField("dynamicLayout", false)
				end,
				get = function() return GetBarField("clickableIcons", false) end,
				set = function(v) SetBarField("clickableIcons", v) end,
			},
		}

		-- Entries section
		local entriesControls = {
			{
				type = "dropdown",
				label = "Bar",
				options = BuildBarOptions,
				get = function() return GetSelectedBarID() or "" end,
				set = function(v)
					SetSelectedBarID(v ~= "" and v or nil)
					ctState.addID = nil
					ctState.addType = "spell"
					RefreshPage()
				end,
			},
			{
				type = "paragraph",
				getText = function()
					local b = GetSelectedBar()
					if not b or not b.entries or #b.entries == 0 then
						return "(No entries — add spells or items below)"
					end
					return "Entries:"
				end,
			},
			{
				type = "dropzone",
				label = "Add Entry — Drop Spell or Item",
				height = 52,
				disabled = function() return GetSelectedBar() == nil end,
				onDrop = function(dropType, dropID)
					if not CT then return end
					local barID = GetSelectedBarID()
					if not barID then return end
					if CT:AddEntry(barID, dropType, dropID) then
						RefreshPage()
					end
				end,
			},
			{
				type = "dropdown",
				label = "Entry Type to Add",
				options = function()
					return {
						{ value = "spell", text = "Spell" },
						{ value = "item",  text = "Item" },
					}
				end,
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return ctState.addType or "spell" end,
				set = function(v) ctState.addType = v end,
			},
			{
				type = "edit",
				label = "Spell / Item ID or Name",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return tostring(ctState.addID or "") end,
				set = function(v) ctState.addID = v end,
			},
			{
				type = "button",
				label = "Add Entry",
				disabled = function()
					return GetSelectedBar() == nil or not ctState.addID or ctState.addID == ""
				end,
				onClick = function()
					if not CT then return end
					local barID = GetSelectedBarID()
					if not barID then return end

					local entryType = ctState.addType or "spell"
					local raw = (tostring(ctState.addID or "")):match("^%s*(.-)%s*$") or ""

					-- Try as numeric ID first
					local entryID = tonumber(raw)

					-- If not numeric, try spell name lookup
					if not entryID and entryType == "spell" then
						if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
							local ok2, result = pcall(C_Spell.GetSpellIDForSpellIdentifier, raw)
							if ok2 and result and result.spellID then
								entryID = result.spellID
							end
						end
					end

					if entryID then
						local ok = CT:AddEntry(barID, entryType, entryID)
						if ok then
							ctState.addID = nil
						end
					end
					RefreshPage()
				end,
			},
			{
				type = "paragraph",
				text = "Tip: Use inline - / U / D buttons above each entry, or the legacy controls below.",
			},
			{
				type = "edit",
				label = "Remove Entry # (position number from list above)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return tostring(ctState.removeIndex or "") end,
				set = function(v)
					ctState.removeIndex = tostring(v or "")
					RefreshPage()
				end,
			},
			{
				type = "button",
				label = "Remove Entry",
				disabled = function()
					local b = GetSelectedBar()
					if not b or not b.entries then return true end
					local idx = tonumber((tostring(ctState.removeIndex or "")):match("^%s*(.-)%s*$") or "")
					return not idx or idx < 1 or idx > #b.entries
				end,
				onClick = function()
					if not CT then return end
					local b = GetSelectedBar()
					if not b or not b.entries then return end
					local idx = tonumber((tostring(ctState.removeIndex or "")):match("^%s*(.-)%s*$") or "")
					if not idx or idx < 1 or idx > #b.entries then return end
					local entry = b.entries[idx]
					if entry then
						CT:RemoveEntry(b.id, entry.type, entry.id)
						ctState.removeIndex = nil
						RefreshPage()
					end
				end,
			},
			{
				type = "edit",
				label = "Move Entry # Up or Down (+1 / -1)",
				disabled = function() return GetSelectedBar() == nil end,
				get = function() return tostring(ctState.moveIndex or "") end,
				set = function(v)
					ctState.moveIndex = tostring(v or "")
					RefreshPage()
				end,
			},
			{
				type = "button",
				label = "Move Up",
				disabled = function()
					local b = GetSelectedBar()
					if not b or not b.entries then return true end
					local idx = tonumber((tostring(ctState.moveIndex or "")):match("^%s*(.-)%s*$") or "")
					return not idx or idx <= 1 or idx > #b.entries
				end,
				onClick = function()
					if not CT then return end
					local b = GetSelectedBar()
					if not b then return end
					local idx = tonumber((tostring(ctState.moveIndex or "")):match("^%s*(.-)%s*$") or "")
					if not idx then return end
					if CT:MoveEntry(b.id, idx, -1) then
						ctState.moveIndex = idx - 1
						RefreshPage()
					end
				end,
			},
			{
				type = "button",
				label = "Move Down",
				disabled = function()
					local b = GetSelectedBar()
					if not b or not b.entries then return true end
					local idx = tonumber((tostring(ctState.moveIndex or "")):match("^%s*(.-)%s*$") or "")
					return not idx or idx < 1 or idx >= #b.entries
				end,
				onClick = function()
					if not CT then return end
					local b = GetSelectedBar()
					if not b then return end
					local idx = tonumber((tostring(ctState.moveIndex or "")):match("^%s*(.-)%s*$") or "")
					if not idx then return end
					if CT:MoveEntry(b.id, idx, 1) then
						ctState.moveIndex = idx + 1
						RefreshPage()
					end
				end,
			},
		}

		do
			local b = GetSelectedBar()
			if b and b.entries and #b.entries > 0 then
				local insertAt = 4 -- after bar dropdown, entries paragraph, dropzone
				for i = #b.entries, 1, -1 do
					local idx = i
					local entry = b.entries[idx]
					table.insert(entriesControls, insertAt, {
						type = "button_row",
						text = BuildEntryLabel(entry, idx),
						buttons = {
							{
								label = "-",
								width = 24,
								onClick = function()
									if not CT then return end
									local current = GetSelectedBar()
									if not current or not current.entries or not current.entries[idx] then return end
									local e = current.entries[idx]
									CT:RemoveEntry(current.id, e.type, e.id)
									RefreshPage()
								end,
							},
							{
								label = "U",
								width = 24,
								disabled = function()
									return idx <= 1
								end,
								onClick = function()
									if not CT then return end
									local current = GetSelectedBar()
									if not current then return end
									if CT:MoveEntry(current.id, idx, -1) then
										RefreshPage()
									end
								end,
							},
							{
								label = "D",
								width = 24,
								disabled = function()
									local current = GetSelectedBar()
									return not current or not current.entries or idx >= #current.entries
								end,
								onClick = function()
									if not CT then return end
									local current = GetSelectedBar()
									if not current then return end
									if CT:MoveEntry(current.id, idx, 1) then
										RefreshPage()
									end
								end,
							},
						},
					})
				end
			end
		end

		return {
			sectionTabs = {
				{ key = "manage",     label = "Manage" },
				{ key = "layout",     label = "Layout" },
				{ key = "position",   label = "Position" },
				{ key = "visibility", label = "Visibility" },
				{ key = "cooldown",   label = "Cooldown" },
				{ key = "entries",    label = "Entries" },
			},
			getActiveSection = GetSection,
			setActiveSection = SetSection,
			sections = {
				{
					tab = "manage",
					title = "Bar Management",
					desc = "Create, delete, and select tracker bars.",
					controls = manageControls,
				},
				{
					tab = "layout",
					title = "Layout & Appearance",
					desc = "Icon size, spacing, grow direction, and visual settings.",
					controls = layoutControls,
				},
				{
					tab = "position",
					title = "Position & Anchoring",
					desc = "Drag position offsets and frame-lock settings.",
					controls = positionControls,
				},
				{
					tab = "visibility",
					title = "Visibility Conditions",
					desc = "Control when icons and bars show.",
					controls = visibilityControls,
				},
				{
					tab = "cooldown",
					title = "Cooldowns & Active State",
					desc = "Cooldown display, GCD, charges, and glow effects.",
					controls = cooldownControls,
				},
				{
					tab = "entries",
					title = "Tracked Spells & Items",
					desc = "Add or remove spells and items tracked by the selected bar.",
					controls = entriesControls,
				},
			},
		}
	end
	---------------------------------------------------------------------------
	-- END CUSTOM TRACKERS PAGE
	---------------------------------------------------------------------------

	if pageKey ~= "global" then
		return defaults
	end

	local function GetGlobalSection()
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.global = cfg.sectionState.global or "theme"
		return tostring(cfg.sectionState.global)
	end
	local function SetGlobalSection(key)
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.global = tostring(key or "all")
	end
	local function ApplyTestModeAction(enabled)
		if InCombatLockdown and InCombatLockdown() then
			if addon.Print then
				addon:Print("SimpleUnitFrames: Test mode changes are blocked during combat.")
			end
			return
		end
		addon:SetTestMode(enabled and true or false)
		addon:ScheduleUpdateAll()
		RefreshOptionsV2CurrentPage()
	end

	return {
		sectionTabs = {
			{ key = "theme", label = "Theme" },
			{ key = "media", label = "Media" },
			{ key = "castbar", label = "Castbar" },
			{ key = "plugins", label = "Plugins" },
			{ key = "performance", label = "Performance" },
			{ key = "visibility", label = "Visibility" },
			{ key = "blizzard", label = "Blizzard" },
			{ key = "party", label = "Party" },
			{ key = "data", label = "Data" },
			{ key = "test", label = "Test" },
			{ key = "advanced", label = "Advanced" },
			{ key = "all", label = "All" },
		},
		getActiveSection = GetGlobalSection,
		setActiveSection = SetGlobalSection,
		sections = {
			{
				tab = "theme",
				title = "Theme",
				desc = "OptionsV2 visual preset.",
				controls = {
					{
						type = "dropdown",
						label = "Preset",
						options = BuildThemePresetOptions,
						get = function()
							local cfg = addon:EnsureOptionsV2Config()
							return (cfg.theme and cfg.theme.preset) or "classic"
						end,
						set = function(v)
							local cfg = addon:EnsureOptionsV2Config()
							cfg.theme = cfg.theme or {}
							if v == "dark" then
								cfg.theme.preset = "dark"
							elseif v == "midnight" then
								cfg.theme.preset = "midnight"
							else
								cfg.theme.preset = "classic"
							end
							if addon.SyncThemeFromOptionsV2 then
								addon:SyncThemeFromOptionsV2()
							end
							if addon.debugPanel and addon.debugPanel:IsShown() and addon.ShowDebugPanel then
								addon:ShowDebugPanel()
							end
							if addon.debugSettingsFrame and addon.debugSettingsFrame:IsShown() and addon.ShowDebugSettings then
								addon:ShowDebugSettings()
							end
							if addon.debugExportFrame and addon.debugExportFrame:IsShown() and addon.ShowDebugExportDialog then
								addon:ShowDebugExportDialog()
							end
							if addon.ApplyThemeToPerformanceWindows then
								addon:ApplyThemeToPerformanceWindows()
							end
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								if addon.optionsV2Frame.RebuildNav then
									addon.optionsV2Frame:RebuildNav()
								end
								addon.optionsV2Frame:SetPage(addon.optionsV2Frame.currentPage or "global")
							end
						end,
					},
				},
			},
			{
				tab = "media",
				title = "Media",
				desc = "Global media defaults used by unit frames.",
				controls = {
					{
						type = "dropdown",
						label = "Statusbar Texture",
						help = "Select from available LibSharedMedia statusbars.",
						options = function()
							return BuildMediaOptions("statusbar", "Blizzard")
						end,
						get = function()
							return addon.db.profile.media.statusbar
						end,
						set = function(v)
							addon.db.profile.media.statusbar = v
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Apply Global Statusbar Texture To All Unit Bars",
						get = function()
							return addon.db.profile.media.globalStatusbarOverride ~= false
						end,
						set = function(v)
							addon.db.profile.media.globalStatusbarOverride = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "dropdown",
						label = "Font",
						help = "Select from available LibSharedMedia fonts.",
						options = function()
							return BuildMediaOptions("font", "Friz Quadrata TT")
						end,
						get = function()
							return addon.db.profile.media.font
						end,
						set = function(v)
							addon.db.profile.media.font = v
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "check",
						label = "Apply Global Font To All Unit Frames",
						get = function()
							return addon.db.profile.media.globalFontOverride ~= false
						end,
						set = function(v)
							addon.db.profile.media.globalFontOverride = v and true or false
							addon:ScheduleUpdateAll()
						end,
					},
				},
			},
			{
				tab = "castbar",
				title = "Castbar Enhancements",
				desc = "Global castbar visuals, timing, and non-interruptible indicators.",
				controls = {
					{
						type = "slider",
						label = "Castbar Height",
						min = 8,
						max = 30,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.castbarHeight) or 16 end,
						set = function(v) addon.db.profile.castbarHeight = math.floor(v + 0.5); addon:ScheduleUpdateAll() end,
					},
					{
						type = "dropdown",
						label = "Global Castbar Color Profile",
						options = function()
							return {
								{ value = "UUF", text = "UUF" },
								{ value = "Blizzard", text = "Blizzard" },
								{ value = "HighContrast", text = "High Contrast" },
							}
						end,
						get = function() return tostring(addon.db.profile.castbar.colorProfile or "UUF") end,
						set = function(v) addon.db.profile.castbar.colorProfile = tostring(v); addon:ScheduleUpdateAll() end,
					},
					{ type = "check", label = "Castbar Icon", get = function() return addon.db.profile.castbar.iconEnabled ~= false end, set = function(v) addon.db.profile.castbar.iconEnabled = v and true or false; addon:ScheduleUpdateAll() end },
					{
						type = "dropdown",
						label = "Castbar Icon Position",
						options = function() return { { value = "LEFT", text = "Left" }, { value = "RIGHT", text = "Right" } } end,
						get = function() return tostring(addon.db.profile.castbar.iconPosition or "LEFT") end,
						set = function(v) addon.db.profile.castbar.iconPosition = tostring(v); addon:ScheduleUpdateAll() end,
					},
					{ type = "slider", label = "Castbar Icon Size", min = 12, max = 40, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.iconSize) or 20 end, set = function(v) addon.db.profile.castbar.iconSize = math.floor(v + 0.5); addon:ScheduleUpdateAll() end },
					{ type = "slider", label = "Castbar Icon Gap", min = 0, max = 12, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.iconGap) or 2 end, set = function(v) addon.db.profile.castbar.iconGap = math.floor(v + 0.5); addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Castbar Shield", get = function() return addon.db.profile.castbar.showShield ~= false end, set = function(v) addon.db.profile.castbar.showShield = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Castbar Latency Safe Zone", get = function() return addon.db.profile.castbar.showSafeZone ~= false end, set = function(v) addon.db.profile.castbar.showSafeZone = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "slider", label = "Safe Zone Opacity", min = 0.05, max = 1, step = 0.05, format = "%.2f", get = function() return tonumber(addon.db.profile.castbar.safeZoneAlpha) or 0.35 end, set = function(v) addon.db.profile.castbar.safeZoneAlpha = tonumber(v) or 0.35; addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Castbar Spark", get = function() return addon.db.profile.castbar.showSpark ~= false end, set = function(v) addon.db.profile.castbar.showSpark = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Castbar Direction Indicator", get = function() return addon.db.profile.castbar.showDirectionIndicator == true end, set = function(v) addon.db.profile.castbar.showDirectionIndicator = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Castbar Channel Ticks", get = function() return addon.db.profile.castbar.showChannelTicks == true end, set = function(v) addon.db.profile.castbar.showChannelTicks = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "slider", label = "Channel Tick Width", min = 1, max = 6, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.channelTickWidth) or 2 end, set = function(v) addon.db.profile.castbar.channelTickWidth = math.floor(v + 0.5); addon:ScheduleUpdateAll() end, disabled = function() return addon.db.profile.castbar.showChannelTicks ~= true end },
					{ type = "check", label = "Castbar Empower Pips", get = function() return addon.db.profile.castbar.showEmpowerPips ~= false end, set = function(v) addon.db.profile.castbar.showEmpowerPips = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Castbar Latency Text", get = function() return addon.db.profile.castbar.showLatencyText == true end, set = function(v) addon.db.profile.castbar.showLatencyText = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "slider", label = "Latency Warn (ms)", min = 40, max = 400, step = 5, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.latencyWarnMs) or 120 end, set = function(v) addon.db.profile.castbar.latencyWarnMs = math.floor(v + 0.5); if (tonumber(addon.db.profile.castbar.latencyHighMs) or 220) < (tonumber(v) or 120) then addon.db.profile.castbar.latencyHighMs = math.floor(v + 0.5) end; addon:ScheduleUpdateAll() end, disabled = function() return addon.db.profile.castbar.showLatencyText ~= true end },
					{ type = "slider", label = "Latency High (ms)", min = 60, max = 600, step = 5, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.latencyHighMs) or 220 end, set = function(v) addon.db.profile.castbar.latencyHighMs = math.max(math.floor(v + 0.5), tonumber(addon.db.profile.castbar.latencyWarnMs) or 120); addon:ScheduleUpdateAll() end, disabled = function() return addon.db.profile.castbar.showLatencyText ~= true end },
					{ type = "slider", label = "Spell Name Max Chars", min = 6, max = 40, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.spellMaxChars) or 26 end, set = function(v) addon.db.profile.castbar.spellMaxChars = math.floor(v + 0.5); addon:ScheduleUpdateAll() end },
					{ type = "slider", label = "Cast Time Decimals", min = 0, max = 2, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.castbar.timeDecimals) or 1 end, set = function(v) addon.db.profile.castbar.timeDecimals = math.floor(v + 0.5); addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Show Cast Delay", get = function() return addon.db.profile.castbar.showDelay ~= false end, set = function(v) addon.db.profile.castbar.showDelay = v and true or false; addon:ScheduleUpdateAll() end },
					{ type = "check", label = "Non-Interruptible Castbar Glow", get = function() return addon.db.profile.enhancements.castbarNonInterruptibleGlow ~= false end, set = function(v) addon.db.profile.enhancements.castbarNonInterruptibleGlow = v and true or false; addon:ScheduleUpdateAll() end },
				},
			},
			{
				tab = "plugins",
				title = "oUF Plugin Integrations",
				desc = "Global plugin settings used by party/raid and per-unit overrides.",
				controls = {
					{ type = "check", label = "Raid Debuffs (Party/Raid)", get = function() return addon.db.profile.plugins.raidDebuffs.enabled ~= false end, set = function(v) addon.db.profile.plugins.raidDebuffs.enabled = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Raid Debuff Glow", get = function() return addon.db.profile.plugins.raidDebuffs.glow ~= false end, set = function(v) addon.db.profile.plugins.raidDebuffs.glow = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "dropdown", label = "Raid Debuff Glow Mode", options = function() return { { value = "ALL", text = "All Debuffs" }, { value = "DISPELLABLE", text = "Dispellable Only" }, { value = "PRIORITY", text = "Boss/Priority Only" } } end, get = function() return tostring(addon.db.profile.plugins.raidDebuffs.glowMode or "ALL") end, set = function(v) addon.db.profile.plugins.raidDebuffs.glowMode = tostring(v); addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Raid Debuff Icon Size", min = 12, max = 36, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.plugins.raidDebuffs.size) or 18 end, set = function(v) addon.db.profile.plugins.raidDebuffs.size = math.floor(v + 0.5); addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Aura Watch (Party/Raid)", get = function() return addon.db.profile.plugins.auraWatch.enabled ~= false end, set = function(v) addon.db.profile.plugins.auraWatch.enabled = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Aura Watch Icon Size", min = 8, max = 22, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.plugins.auraWatch.size) or 10 end, set = function(v) addon.db.profile.plugins.auraWatch.size = math.floor(v + 0.5); addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Aura Watch Buff Slots", min = 0, max = 8, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.plugins.auraWatch.numBuffs) or 3 end, set = function(v) addon.db.profile.plugins.auraWatch.numBuffs = math.floor(v + 0.5); addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Aura Watch Debuff Slots", min = 0, max = 8, step = 1, format = "%.0f", get = function() return tonumber(addon.db.profile.plugins.auraWatch.numDebuffs) or 3 end, set = function(v) addon.db.profile.plugins.auraWatch.numDebuffs = math.floor(v + 0.5); addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Aura Watch Debuff Overlay", get = function() return addon.db.profile.plugins.auraWatch.showDebuffType ~= false end, set = function(v) addon.db.profile.plugins.auraWatch.showDebuffType = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Aura Watch Replace Defaults", get = function() return addon.db.profile.plugins.auraWatch.replaceDefaults == true end, set = function(v) addon.db.profile.plugins.auraWatch.replaceDefaults = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "edit", label = "Aura Watch Custom Spell List", get = function() return tostring(addon.db.profile.plugins.auraWatch.customSpellList or "") end, set = function(v) addon.db.profile.plugins.auraWatch.customSpellList = tostring(v or ""); addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Frame Fader", get = function() return addon.db.profile.plugins.fader.enabled == true end, set = function(v) addon.db.profile.plugins.fader.enabled = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Fader Min Alpha", min = 0.05, max = 1, step = 0.05, format = "%.2f", get = function() return tonumber(addon.db.profile.plugins.fader.minAlpha) or 0.45 end, set = function(v) addon.db.profile.plugins.fader.minAlpha = tonumber(v) or 0.45; addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Fader Max Alpha", min = 0.05, max = 1, step = 0.05, format = "%.2f", get = function() return tonumber(addon.db.profile.plugins.fader.maxAlpha) or 1 end, set = function(v) addon.db.profile.plugins.fader.maxAlpha = tonumber(v) or 1; addon:SchedulePluginUpdate() end },
					{ type = "slider", label = "Fader Smooth", min = 0, max = 1, step = 0.05, format = "%.2f", get = function() return tonumber(addon.db.profile.plugins.fader.smooth) or 0.2 end, set = function(v) addon.db.profile.plugins.fader.smooth = tonumber(v) or 0.2; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Fader: Combat", get = function() return addon.db.profile.plugins.fader.combat ~= false end, set = function(v) addon.db.profile.plugins.fader.combat = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Fader: Hover", get = function() return addon.db.profile.plugins.fader.hover ~= false end, set = function(v) addon.db.profile.plugins.fader.hover = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Fader: Player Target", get = function() return addon.db.profile.plugins.fader.playerTarget ~= false end, set = function(v) addon.db.profile.plugins.fader.playerTarget = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Fader: Action Targeting", get = function() return addon.db.profile.plugins.fader.actionTarget == true end, set = function(v) addon.db.profile.plugins.fader.actionTarget = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Fader: Unit Target", get = function() return addon.db.profile.plugins.fader.unitTarget == true end, set = function(v) addon.db.profile.plugins.fader.unitTarget = v and true or false; addon:SchedulePluginUpdate() end },
					{ type = "check", label = "Fader: Casting", get = function() return addon.db.profile.plugins.fader.casting == true end, set = function(v) addon.db.profile.plugins.fader.casting = v and true or false; addon:SchedulePluginUpdate() end },
				},
			},
			{
				tab = "performance",
				title = "Performance",
				desc = "Runtime update and performance integration behavior.",
				controls = {
					{
						type = "check",
						label = "Enable PerformanceLib Integration",
						get = function()
							return addon.db.profile.performance.enabled ~= false
						end,
						set = function(v)
							addon:SetPerformanceIntegrationEnabled(v and true or false, true)
						end,
						disabled = function()
							return not addon.performanceLib
						end,
					},
					{
						type = "check",
						label = "Auto Refresh Performance Widgets",
						get = function()
							return addon.db.profile.performance.optionsAutoRefresh ~= false
						end,
						set = function(v)
							addon.db.profile.performance.optionsAutoRefresh = v and true or false
						end,
					},
				},
			},
			{
				tab = "advanced",
				title = "Enhancements",
				desc = "Quality-of-life behavior used by SUF windows and interactions.",
				controls = {
					{
						type = "check",
						label = "Window Open Animation",
						get = function()
							return addon.db.profile.enhancements.uiOpenAnimation ~= false
						end,
						set = function(v)
							addon.db.profile.enhancements.uiOpenAnimation = v and true or false
						end,
					},
					{
						type = "slider",
						label = "Window Animation Duration",
						min = 0.05,
						max = 0.60,
						step = 0.01,
						format = "%.2f",
						get = function()
							return tonumber(addon.db.profile.enhancements.uiOpenAnimationDuration) or 0.18
						end,
						set = function(v)
							addon.db.profile.enhancements.uiOpenAnimationDuration = Clamp(v, 0.05, 0.60, 0.18)
						end,
					},
					{
						type = "slider",
						label = "Window Animation Offset Y",
						min = -40,
						max = 40,
						step = 1,
						format = "%.0f",
						get = function()
							return tonumber(addon.db.profile.enhancements.uiOpenAnimationOffsetY) or 12
						end,
						set = function(v)
							addon.db.profile.enhancements.uiOpenAnimationOffsetY = Clamp(v, -40, 40, 12)
						end,
					},
					{
						type = "check",
						label = "Sticky Windows",
						get = function()
							return addon.db.profile.enhancements.stickyWindows ~= false
						end,
						set = function(v)
							addon.db.profile.enhancements.stickyWindows = v and true or false
						end,
					},
					{
						type = "check",
						label = "Pixel Snap Windows",
						get = function()
							return addon.db.profile.enhancements.pixelSnapWindows ~= false
						end,
						set = function(v)
							addon.db.profile.enhancements.pixelSnapWindows = v and true or false
						end,
					},
				},
			},
			{
				tab = "visibility",
				title = "Visibility",
				desc = "Global visibility rules for SUF frames.",
				controls = {
					{
						type = "check",
						label = "Hide in Vehicle",
						get = function() return addon.db.profile.visibility.hideVehicle ~= false end,
						set = function(v) addon.db.profile.visibility.hideVehicle = v and true or false; addon:ScheduleApplyVisibility() end,
					},
					{
						type = "check",
						label = "Hide in Pet Battles",
						get = function() return addon.db.profile.visibility.hidePetBattle ~= false end,
						set = function(v) addon.db.profile.visibility.hidePetBattle = v and true or false; addon:ScheduleApplyVisibility() end,
					},
					{
						type = "check",
						label = "Hide with Override Bar",
						get = function() return addon.db.profile.visibility.hideOverride ~= false end,
						set = function(v) addon.db.profile.visibility.hideOverride = v and true or false; addon:ScheduleApplyVisibility() end,
					},
					{
						type = "check",
						label = "Hide with Possess Bar",
						get = function() return addon.db.profile.visibility.hidePossess ~= false end,
						set = function(v) addon.db.profile.visibility.hidePossess = v and true or false; addon:ScheduleApplyVisibility() end,
					},
					{
						type = "check",
						label = "Hide with Extra Bar",
						get = function() return addon.db.profile.visibility.hideExtra ~= false end,
						set = function(v) addon.db.profile.visibility.hideExtra = v and true or false; addon:ScheduleApplyVisibility() end,
					},
				},
			},
			{
				tab = "blizzard",
				title = "Blizzard Frames",
				desc = "Toggle default Blizzard frame visibility and optional skinning integration.",
				controls = {
					{
						type = "paragraph",
						getText = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							local state = (cfg.labMode == true) and "|cff66ff66ON|r" or "|cffff6666OFF|r"
							return "Lab Mode: " .. state
						end,
					},
					{
						type = "check",
						label = "Enable Blizzard UI Skinning (safe windows only)",
						get = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.enabled == true
						end,
						set = function(v)
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil
							if not cfg then return end
							cfg.enabled = v and true or false
							if cfg.enabled == true then
								if addon.PromptReloadUI then
									addon:PromptReloadUI("Enabling Blizzard UI skinning is safest after a reload.\nReload UI now?")
								end
							elseif addon.RemoveBlizzardSkinningNow then
								addon:RemoveBlizzardSkinningNow()
							end
						end,
					},
					{
						type = "dropdown",
						label = "Skin Intensity",
						options = function()
							return {
								{ value = "subtle", text = "Subtle" },
								{ value = "strong", text = "Strong" },
								{ value = "strongplus", text = "Strong+" },
							}
						end,
						disabled = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.enabled ~= true
						end,
						get = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return tostring(cfg.intensity or "subtle")
						end,
						set = function(v)
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil
							if not cfg then return end
							cfg.intensity = tostring(v or "subtle")
							if addon.ApplyBlizzardSkinningNow then
								addon:ApplyBlizzardSkinningNow()
							end
						end,
					},
					{
						type = "check",
						label = "Enable Lab Mode (Unsafe Experimental Skinning)",
						desc = "Unlocks aggressive recursive tinting and reassert hooks. Keep OFF for stable gameplay visuals.",
						disabled = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.enabled ~= true
						end,
						get = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.labMode == true
						end,
						set = function(v)
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil
							if not cfg then return end
							cfg.labMode = v and true or false
							if cfg.labMode ~= true then
								cfg.aggressiveRecursive = false
								cfg.aggressiveReassertHooks = false
							end
							if addon.ApplyBlizzardSkinningNow then
								addon:ApplyBlizzardSkinningNow(true)
							end
						end,
					},
					{
						type = "check",
						label = "Experimental: Aggressive Recursive Recolor",
						desc = "More aggressive tint pass on eligible Blizzard textures. Higher visual coverage, higher artifact risk.",
						disabled = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.enabled ~= true or cfg.labMode ~= true
						end,
						get = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.aggressiveRecursive == true
						end,
						set = function(v)
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil
							if not cfg then return end
							cfg.aggressiveRecursive = v and true or false
							if cfg.aggressiveRecursive == true then
								cfg.intensity = "strongplus"
							end
							if addon.ApplyBlizzardSkinningNow then
								addon:ApplyBlizzardSkinningNow(true)
							end
						end,
					},
					{
						type = "check",
						label = "Experimental: Reassert Texture Tints (Scoped Hooks)",
						desc = "Hooks SetVertexColor on aggressively-skinned textures under SUF-managed frames only.",
						disabled = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.enabled ~= true or cfg.labMode ~= true
						end,
						get = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.aggressiveReassertHooks == true
						end,
						set = function(v)
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil
							if not cfg then return end
							cfg.aggressiveReassertHooks = v and true or false
							if cfg.aggressiveReassertHooks == true then
								cfg.intensity = "strongplus"
							end
							if addon.ApplyBlizzardSkinningNow then
								addon:ApplyBlizzardSkinningNow(true)
							end
						end,
					},
					{
						type = "button",
						label = "Apply Safe Skin Profile (Recommended)",
						disabled = function()
							local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {}
							return cfg.enabled ~= true
						end,
						onClick = function()
							if addon.ApplyBlizzardSkinSafeProfile then
								addon:ApplyBlizzardSkinSafeProfile()
							elseif addon.GetBlizzardSkinSettings then
								local cfg = addon:GetBlizzardSkinSettings()
								if cfg then
									cfg.labMode = false
									cfg.aggressiveRecursive = false
									cfg.aggressiveReassertHooks = false
									cfg.intensity = "strongplus"
								end
								if addon.ApplyBlizzardSkinningNow then
									addon:ApplyBlizzardSkinningNow(true)
								end
							end
						end,
					},
					{
						type = "check",
						label = "Skin Character UI",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.character ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.character = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Spellbook / Talents",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.spellbook ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.spellbook = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Collections",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.collections ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.collections = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Quest Log",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.questlog ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.questlog = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin LFG / PvE",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.lfg ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.lfg = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin World Map",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.map ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.map = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Social (Friends / Guild)",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return (cfg.friends ~= false) or (cfg.guild ~= false) end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end local state = v and true or false; cfg.friends = state; cfg.guild = state; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Calendar",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.calendar ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.calendar = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Professions",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.professions ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.professions = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Housing Dashboard",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.housing ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.housing = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin DressUp",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.dressup ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.dressup = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Merchant / Mail / Gossip",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return (cfg.merchant ~= false) or (cfg.mail ~= false) or (cfg.gossip ~= false) end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end local state = v and true or false; cfg.merchant = state; cfg.mail = state; cfg.gossip = state; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Economy (Auction/Void/Socketing)",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.economy ~= false end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end cfg.economy = v and true or false; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "check",
						label = "Skin Achievements / Encounter Journal",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						get = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return (cfg.achievement ~= false) or (cfg.encounter ~= false) end,
						set = function(v) local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or nil if not cfg then return end local state = v and true or false; cfg.achievement = state; cfg.encounter = state; if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow() end end,
					},
					{
						type = "button",
						label = "Reapply Blizzard Skin Now",
						disabled = function() local cfg = (addon.GetBlizzardSkinSettings and addon:GetBlizzardSkinSettings()) or {} return cfg.enabled ~= true end,
						onClick = function() if addon.ApplyBlizzardSkinningNow then addon:ApplyBlizzardSkinningNow(true) end end,
					},
					{
						type = "button",
						label = "Remove Blizzard Skin Now",
						onClick = function() if addon.RemoveBlizzardSkinningNow then addon:RemoveBlizzardSkinningNow() end end,
					},
					{
						type = "button",
						label = "Print Blizzard Skin Report",
						onClick = function() if addon.PrintBlizzardSkinReport then addon:PrintBlizzardSkinReport() end end,
					},
					{ type = "check", label = "Hide Blizzard Player Frame", get = function() return addon.db.profile.blizzardFrames.player ~= false end, set = function(v) addon.db.profile.blizzardFrames.player = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Pet Frame", get = function() return addon.db.profile.blizzardFrames.pet ~= false end, set = function(v) addon.db.profile.blizzardFrames.pet = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Target Frame", get = function() return addon.db.profile.blizzardFrames.target ~= false end, set = function(v) addon.db.profile.blizzardFrames.target = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Target of Target", get = function() return addon.db.profile.blizzardFrames.tot ~= false end, set = function(v) addon.db.profile.blizzardFrames.tot = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Focus Frame", get = function() return addon.db.profile.blizzardFrames.focus ~= false end, set = function(v) addon.db.profile.blizzardFrames.focus = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Party Frames", get = function() return addon.db.profile.blizzardFrames.party ~= false end, set = function(v) addon.db.profile.blizzardFrames.party = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Raid Frames", get = function() return addon.db.profile.blizzardFrames.raid ~= false end, set = function(v) addon.db.profile.blizzardFrames.raid = v and true or false; addon:UpdateBlizzardFrames() end },
					{ type = "check", label = "Hide Blizzard Boss Frames", get = function() return addon.db.profile.blizzardFrames.boss ~= false end, set = function(v) addon.db.profile.blizzardFrames.boss = v and true or false; addon:UpdateBlizzardFrames() end },
				},
			},
			{
				tab = "party",
				title = "Party Header",
				desc = "Party display behavior.",
				controls = {
					{
						type = "check",
						label = "Show Player In Party",
						get = function() return addon.db.profile.party.showPlayerInParty ~= false end,
						set = function(v) addon.db.profile.party.showPlayerInParty = v and true or false; addon:TrySpawnGroupHeaders(); addon:ApplyPartyHeaderSettings() end,
					},
					{
						type = "check",
						label = "Show Player When Solo",
						get = function() return addon.db.profile.party.showPlayerWhenSolo == true end,
						set = function(v) addon.db.profile.party.showPlayerWhenSolo = v and true or false; addon:TrySpawnGroupHeaders(); addon:ApplyPartyHeaderSettings() end,
					},
					{
						type = "slider",
						label = "Party Vertical Spacing",
						min = 0,
						max = 40,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.party.spacing) or 10 end,
						set = function(v) addon.db.profile.party.spacing = math.floor(v + 0.5); addon:ApplyPartyHeaderSettings() end,
					},
				},
			},
			{
				tab = "data",
				title = "Data Bars",
				desc = "XP/Reputation bars and panel behavior.",
				controls = {
					{
						type = "check",
						label = "Enable Data Bars",
						get = function() return addon.db.profile.databars.enabled ~= false end,
						set = function(v) addon.db.profile.databars.enabled = v and true or false; addon:UpdateDataBars() end,
					},
					{
						type = "dropdown",
						label = "Data Bar Position Mode",
						options = function()
							return {
								{ value = "ANCHOR", text = "Anchor" },
								{ value = "EDIT_MODE", text = "Edit Mode" },
							}
						end,
						get = function() return tostring(addon.db.profile.databars.positionMode or "ANCHOR") end,
						set = function(v) addon.db.profile.databars.positionMode = tostring(v); addon:UpdateDataBars() end,
					},
					{
						type = "slider",
						label = "Data Bar Width",
						min = 280,
						max = 900,
						step = 10,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.databars.width) or 520 end,
						set = function(v) addon.db.profile.databars.width = math.floor(v + 0.5); addon:UpdateDataBars() end,
					},
					{
						type = "slider",
						label = "Data Bar Height",
						min = 8,
						max = 24,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.databars.height) or 10 end,
						set = function(v) addon.db.profile.databars.height = math.floor(v + 0.5); addon:UpdateDataBars() end,
					},
					{
						type = "slider",
						label = "Data Bar Offset X",
						min = -600,
						max = 600,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.databars.offsetX) or 0 end,
						set = function(v) addon.db.profile.databars.offsetX = math.floor(v + 0.5); addon:UpdateDataBars() end,
					},
					{
						type = "slider",
						label = "Data Bar Offset Y",
						min = -400,
						max = 400,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.databars.offsetY) or -14 end,
						set = function(v) addon.db.profile.databars.offsetY = math.floor(v + 0.5); addon:UpdateDataBars() end,
					},
					{
						type = "dropdown",
						label = "Data Bar Anchor",
						options = function()
							return {
								{ value = "TOP", text = "Top" },
								{ value = "BOTTOM", text = "Bottom" },
							}
						end,
						get = function() return tostring(addon.db.profile.databars.anchor or "TOP") end,
						set = function(v) addon.db.profile.databars.anchor = tostring(v); addon:UpdateDataBars() end,
					},
					{
						type = "check",
						label = "Show XP",
						get = function() return addon.db.profile.databars.showXP ~= false end,
						set = function(v) addon.db.profile.databars.showXP = v and true or false; addon:UpdateDataBars() end,
					},
					{
						type = "check",
						label = "Show Reputation",
						get = function() return addon.db.profile.databars.showReputation ~= false end,
						set = function(v) addon.db.profile.databars.showReputation = v and true or false; addon:UpdateDataBars() end,
					},
					{
						type = "check",
						label = "Show Pet XP",
						get = function() return addon.db.profile.databars.showPetXP ~= false end,
						set = function(v) addon.db.profile.databars.showPetXP = v and true or false; addon:UpdateDataBars() end,
					},
					{
						type = "check",
						label = "XP Bar Mouseover Fade",
						get = function()
							addon.db.profile.databars.xpFade = addon.db.profile.databars.xpFade or {}
							return addon.db.profile.databars.xpFade.enabled == true
						end,
						set = function(v)
							addon.db.profile.databars.xpFade = addon.db.profile.databars.xpFade or {}
							addon.db.profile.databars.xpFade.enabled = v and true or false
							addon:UpdateDataBars()
						end,
					},
					{
						type = "slider",
						label = "Fade In Duration",
						min = 0.05,
						max = 1.0,
						step = 0.05,
						format = "%.2f",
						get = function() return tonumber(addon.db.profile.databars.xpFade and addon.db.profile.databars.xpFade.fadeInDuration) or 0.2 end,
						set = function(v) addon.db.profile.databars.xpFade = addon.db.profile.databars.xpFade or {}; addon.db.profile.databars.xpFade.fadeInDuration = tonumber(v) or 0.2; addon:UpdateDataBars() end,
						disabled = function() return not (addon.db.profile.databars.xpFade and addon.db.profile.databars.xpFade.enabled == true) end,
					},
					{
						type = "slider",
						label = "Fade Out Duration",
						min = 0.05,
						max = 1.2,
						step = 0.05,
						format = "%.2f",
						get = function() return tonumber(addon.db.profile.databars.xpFade and addon.db.profile.databars.xpFade.fadeOutDuration) or 0.3 end,
						set = function(v) addon.db.profile.databars.xpFade = addon.db.profile.databars.xpFade or {}; addon.db.profile.databars.xpFade.fadeOutDuration = tonumber(v) or 0.3; addon:UpdateDataBars() end,
						disabled = function() return not (addon.db.profile.databars.xpFade and addon.db.profile.databars.xpFade.enabled == true) end,
					},
				},
			},
			{
				tab = "data",
				title = "Data Text",
				desc = "Top panel informational text widgets.",
				controls = {
					{
						type = "check",
						label = "Enable Data Text Panel",
						get = function() return addon.db.profile.datatext.enabled ~= false end,
						set = function(v) addon.db.profile.datatext.enabled = v and true or false; addon:UpdateDataTextPanel() end,
					},
					{
						type = "slider",
						label = "Data Text Width",
						min = 280,
						max = 900,
						step = 10,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.datatext.panel and addon.db.profile.datatext.panel.width) or 520 end,
						set = function(v) addon.db.profile.datatext.panel.width = math.floor(v + 0.5); addon:UpdateDataTextPanel() end,
					},
					{
						type = "slider",
						label = "Data Text Height",
						min = 14,
						max = 40,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.datatext.panel and addon.db.profile.datatext.panel.height) or 20 end,
						set = function(v) addon.db.profile.datatext.panel.height = math.floor(v + 0.5); addon:UpdateDataTextPanel() end,
					},
					{
						type = "dropdown",
						label = "Data Text Position Mode",
						options = function()
							return {
								{ value = "ANCHOR", text = "Anchor" },
								{ value = "EDIT_MODE", text = "Edit Mode" },
							}
						end,
						get = function() return tostring(addon.db.profile.datatext.positionMode or "ANCHOR") end,
						set = function(v) addon.db.profile.datatext.positionMode = tostring(v); addon:UpdateDataTextPanel() end,
					},
					{
						type = "dropdown",
						label = "Data Text Anchor",
						options = function() return { { value = "TOP", text = "Top" }, { value = "BOTTOM", text = "Bottom" } } end,
						get = function() return tostring((addon.db.profile.datatext.panel and addon.db.profile.datatext.panel.anchor) or "TOP") end,
						set = function(v) addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; addon.db.profile.datatext.panel.anchor = tostring(v); addon:UpdateDataTextPanel() end,
					},
					{
						type = "slider",
						label = "Data Text Offset X",
						min = -600,
						max = 600,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.datatext.panel and addon.db.profile.datatext.panel.offsetX) or 0 end,
						set = function(v) addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; addon.db.profile.datatext.panel.offsetX = math.floor(v + 0.5); addon:UpdateDataTextPanel() end,
					},
					{
						type = "slider",
						label = "Data Text Offset Y",
						min = -400,
						max = 400,
						step = 1,
						format = "%.0f",
						get = function() return tonumber(addon.db.profile.datatext.panel and addon.db.profile.datatext.panel.offsetY) or -14 end,
						set = function(v) addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; addon.db.profile.datatext.panel.offsetY = math.floor(v + 0.5); addon:UpdateDataTextPanel() end,
					},
					{
						type = "check",
						label = "Backdrop",
						get = function() addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; return addon.db.profile.datatext.panel.backdrop ~= false end,
						set = function(v) addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; addon.db.profile.datatext.panel.backdrop = v and true or false; addon:UpdateDataTextPanel() end,
					},
					{
						type = "check",
						label = "Mouseover Only",
						get = function() addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; return addon.db.profile.datatext.panel.mouseover == true end,
						set = function(v) addon.db.profile.datatext.panel = addon.db.profile.datatext.panel or {}; addon.db.profile.datatext.panel.mouseover = v and true or false; addon:UpdateDataTextPanel() end,
					},
					{
						type = "dropdown",
						label = "DataText Left Slot",
						options = function() return addon:GetAvailableDataTextSources() end,
						get = function() addon.db.profile.datatext.slots = addon.db.profile.datatext.slots or {}; return tostring(addon.db.profile.datatext.slots.left or "FPS") end,
						set = function(v) addon.db.profile.datatext.slots = addon.db.profile.datatext.slots or {}; addon.db.profile.datatext.slots.left = tostring(v); addon:UpdateDataTextPanel() end,
					},
					{
						type = "dropdown",
						label = "DataText Center Slot",
						options = function() return addon:GetAvailableDataTextSources() end,
						get = function() addon.db.profile.datatext.slots = addon.db.profile.datatext.slots or {}; return tostring(addon.db.profile.datatext.slots.center or "Time") end,
						set = function(v) addon.db.profile.datatext.slots = addon.db.profile.datatext.slots or {}; addon.db.profile.datatext.slots.center = tostring(v); addon:UpdateDataTextPanel() end,
					},
					{
						type = "dropdown",
						label = "DataText Right Slot",
						options = function() return addon:GetAvailableDataTextSources() end,
						get = function() addon.db.profile.datatext.slots = addon.db.profile.datatext.slots or {}; return tostring(addon.db.profile.datatext.slots.right or "Memory") end,
						set = function(v) addon.db.profile.datatext.slots = addon.db.profile.datatext.slots or {}; addon.db.profile.datatext.slots.right = tostring(v); addon:UpdateDataTextPanel() end,
					},
				},
			},
			{
				tab = "data",
				title = "Tag Display",
				desc = "Global absorb tag display helper.",
				controls = {
					{
						type = "dropdown",
						label = "Absorb Value Tag",
						options = BuildAbsorbTagOptions,
						get = function()
							return addon.db.profile.absorbValueTag or "[suf:absorbs:abbr]"
						end,
						set = function(v)
							addon.db.profile.absorbValueTag = tostring(v)
							addon:ScheduleUpdateAll()
						end,
					},
				},
			},
			{
				tab = "test",
				title = "Test Mode",
				desc = "Force-show helpers while tuning layout.",
				controls = {
					{
						type = "paragraph",
						getText = function()
							return ("Current test mode: %s"):format(addon.testMode and "enabled" or "disabled")
						end,
					},
					{
						type = "check",
						label = "Test Mode (Show All Frames)",
						get = function() return addon.testMode == true end,
						set = function(v) ApplyTestModeAction(v and true or false) end,
					},
					{
						type = "button",
						label = "Force Show All Unit Types",
						onClick = function() ApplyTestModeAction(true) end,
					},
					{
						type = "button",
						label = "Disable Test Mode",
						onClick = function() ApplyTestModeAction(false) end,
					},
				},
			},
			{
				tab = "advanced",
				title = "Actions",
				desc = "Quick navigation and workflows.",
				controls = {
					{
						type = "button",
						label = "Open Import / Export",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								addon.optionsV2Frame:SetPage("importexport")
							end
						end,
					},
					{
						type = "button",
						label = "Open Tags",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								addon.optionsV2Frame:SetPage("tags")
							end
						end,
					},
				},
			},
		},
	}
end
