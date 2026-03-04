local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local LSM = LibStub("LibSharedMedia-3.0", true)

local function RefreshOptionsV2CurrentPage()
	if addon.optionsV2Frame and addon.optionsV2Frame.RefreshCurrentPage then
		addon.optionsV2Frame:RefreshCurrentPage()
	end
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

local function BuildGlobalPageSpec()
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
					{
						type = "color",
						label = "Accent Color",
						tooltip = "Pick a color to theme all UI elements (buttons, controls, text).",
						get = function()
							if addon.GetAccentColor then
								local r, g, b = addon:GetAccentColor()
								return { r, g, b, 1 }
							end
							return { 0.74, 0.58, 0.99, 1 }
						end,
						set = function(r, g, b)
							if addon.db and addon.db.profile then
								addon.db.profile.media = addon.db.profile.media or {}
								addon.db.profile.media.accentColor = { r, g, b }
							end
							if addon.UpdateAccentColor then
								addon:UpdateAccentColor(r, g, b)
								addon:ScheduleUpdateAll()
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

addon._optionsV2Builders = addon._optionsV2Builders or {}
addon._optionsV2Builders["global"] = BuildGlobalPageSpec
