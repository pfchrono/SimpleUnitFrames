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
					-- Health Bar Color Gradient Section
					{
						type = "check",
						label = "Smooth Health Gradient",
						tooltip = "Use smooth color transition from red (0% HP) → yellow (50% HP) → green (100% HP). Customize the colors below.",
						get = function()
							local unit = GetUnit()
							unit.health = unit.health or {}
							return unit.health.smooth == true
						end,
						set = function(v)
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.smooth = v and true or false
							-- Update colorSmooth on all frames for this unit type
							if addon and addon.frames then
								for _, frame in ipairs(addon.frames) do
									if frame and frame.sufUnitType == unitKey and frame.Health then
										frame.Health.colorSmooth = v and true or false
										if v and unit.health then
											-- Apply curve when enabling
											local success, err = pcall(function()
												if addon.ApplyHealthCurve then
													addon:ApplyHealthCurve(frame, unit.health)
												end
											end)
										end
									end
								end
							end
							addon:ScheduleUpdateAll()
						end,
					},
					{
						type = "color",
						label = "Gradient Color (0% HP - Critical)",
						tooltip = "Color at 0% health (critical/dead).",
						get = function()
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.gradientColors = unit.health.gradientColors or {}
							unit.health.gradientColors[0] = unit.health.gradientColors[0] or { 1, 0, 0, 1 }
							return unit.health.gradientColors[0]
						end,
						set = function(r, g, b)
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.gradientColors = unit.health.gradientColors or {}
							unit.health.gradientColors[0] = { r, g, b, 1 }
							-- Reapply curve with new colors
							if addon and addon.frames then
								for _, frame in ipairs(addon.frames) do
									if frame and frame.sufUnitType == unitKey and unit.health.smooth then
										local success = pcall(function()
											if addon.ApplyHealthCurve then
												addon:ApplyHealthCurve(frame, unit.health)
											end
										end)
										if success then
											frame.Health:ForceUpdate()
										end
									end
								end
							end
							addon:ScheduleUpdateAll()
						end,
						disabled = function()
							local unit = GetUnit()
							return not (unit and unit.health and unit.health.smooth)
						end,
					},
					{
						type = "color",
						label = "Gradient Color (50% HP - Warning)",
						tooltip = "Color at 50% health (moderate damage).",
						get = function()
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.gradientColors = unit.health.gradientColors or {}
							unit.health.gradientColors[0.5] = unit.health.gradientColors[0.5] or { 1, 1, 0, 1 }
							return unit.health.gradientColors[0.5]
						end,
						set = function(r, g, b)
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.gradientColors = unit.health.gradientColors or {}
							unit.health.gradientColors[0.5] = { r, g, b, 1 }
							-- Reapply curve with new colors
							if addon and addon.frames then
								for _, frame in ipairs(addon.frames) do
									if frame and frame.sufUnitType == unitKey and unit.health.smooth then
										local success = pcall(function()
											if addon.ApplyHealthCurve then
												addon:ApplyHealthCurve(frame, unit.health)
											end
										end)
										if success then
											frame.Health:ForceUpdate()
										end
									end
								end
							end
							addon:ScheduleUpdateAll()
						end,
						disabled = function()
							local unit = GetUnit()
							return not (unit and unit.health and unit.health.smooth)
						end,
					},
					{
						type = "color",
						label = "Gradient Color (100% HP - Healthy)",
						tooltip = "Color at 100% health (full health).",
						get = function()
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.gradientColors = unit.health.gradientColors or {}
							unit.health.gradientColors[1] = unit.health.gradientColors[1] or { 0, 1, 0, 1 }
							return unit.health.gradientColors[1]
						end,
						set = function(r, g, b)
							local unit = GetUnit()
							unit.health = unit.health or {}
							unit.health.gradientColors = unit.health.gradientColors or {}
							unit.health.gradientColors[1] = { r, g, b, 1 }
							-- Reapply curve with new colors
							if addon and addon.frames then
								for _, frame in ipairs(addon.frames) do
									if frame and frame.sufUnitType == unitKey and unit.health.smooth then
										local success = pcall(function()
											if addon.ApplyHealthCurve then
												addon:ApplyHealthCurve(frame, unit.health)
											end
										end)
										if success then
											frame.Health:ForceUpdate()
										end
									end
								end
							end
							addon:ScheduleUpdateAll()
						end,
						disabled = function()
							local unit = GetUnit()
							return not (unit and unit.health and unit.health.smooth)
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

function addon:GetOptionsV2UnitCoreSpec(unitKey)
	return BuildUnitCoreSpec(unitKey)
end

function addon:GetOptionsV2PageSpec(pageKey, skipBuilderLookup)
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

	-- DELEGATION: Check if a modular builder exists for this page
	if not skipBuilderLookup and self._optionsV2Builders and self._optionsV2Builders[pageKey] then
		local builder = self._optionsV2Builders[pageKey]
		if type(builder) == "function" then
			local success, result = pcall(builder)
			if success and result then
				return result
			end
		end
	end

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


	-- All pages now served by modular builders registered via addon._optionsV2Builders

	return defaults
end
