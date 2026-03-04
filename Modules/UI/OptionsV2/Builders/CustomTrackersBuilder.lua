local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local LSM = LibStub("LibSharedMedia-3.0", true)

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

local function BuildCustomTrackersPageSpec()
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

addon._optionsV2Builders = addon._optionsV2Builders or {}
addon._optionsV2Builders["customtrackers"] = BuildCustomTrackersPageSpec
