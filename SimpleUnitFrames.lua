local addonName = "SUF"
local addonId = "SimpleUnitFrames"
local function GetOuf()
	local global
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		global = C_AddOns.GetAddOnMetadata(addonId, "X-oUF")
	else
		global = GetAddOnMetadata(addonId, "X-oUF")
	end

	if global and _G[global] then
		return _G[global]
	end

	return _G.oUF
end

local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LibDualSpec = LibStub("LibDualSpec-1.0", true)
local LSM = LibStub("LibSharedMedia-3.0", true)
local LibSerialize = LibStub("LibSerialize", true)
local LibDeflate = LibStub("LibDeflate", true)
local LDB = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)

local addon = AceAddon:NewAddon("SimpleUnitFrames", "AceEvent-3.0", "AceConsole-3.0")

local DEFAULT_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local DEFAULT_FONT = STANDARD_TEXT_FONT
local ICON_PATH = "Interface\\AddOns\\SimpleUnitFrames\\Media\\AddonIcon"

local function ChatMsg(message)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	else
		print(message)
	end
end

local defaults = {
	profile = {
		media = {
			statusbar = "Blizzard",
			font = "Friz Quadrata TT",
		},
		fontSizes = {
			name = 12,
			level = 10,
			health = 11,
			power = 10,
			cast = 10,
		},
		units = {
			player = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard" },
				showResting = true,
				showPvp = true,
				portrait = { mode = "none", size = 36, showClass = false, motion = false, position = "LEFT" },
			},
			target = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 36, showClass = false, motion = false, position = "LEFT" },
			},
			tot = {
				fontSizes = { name = 11, level = 9, health = 10, power = 9, cast = 9 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 28, showClass = false, motion = false, position = "LEFT" },
			},
			focus = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 32, showClass = false, motion = false, position = "LEFT" },
			},
			pet = {
				fontSizes = { name = 11, level = 9, health = 10, power = 9, cast = 9 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = false,
				portrait = { mode = "none", size = 28, showClass = false, motion = false, position = "LEFT" },
			},
			party = {
				fontSizes = { name = 11, level = 9, health = 10, power = 9, cast = 9 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 26, showClass = false, motion = false, position = "LEFT" },
			},
			raid = {
				fontSizes = { name = 10, level = 8, health = 9, power = 8, cast = 8 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = false,
				portrait = { mode = "none", size = 22, showClass = false, motion = false, position = "LEFT" },
			},
			boss = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard" },
				showResting = false,
				showPvp = false,
				portrait = { mode = "none", size = 30, showClass = false, motion = false, position = "LEFT" },
			},
		},
		tags = {
			player = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			target = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			tot = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			focus = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			pet = { name = "[name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			party = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			raid = { name = "[raidcolor][name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
			boss = { name = "[name]", level = "[level]", health = "[curhp]", power = "[curpp]" },
		},
		sizes = {
			player = { width = 220, height = 36 },
			target = { width = 220, height = 36 },
			tot = { width = 160, height = 28 },
			focus = { width = 200, height = 32 },
			pet = { width = 160, height = 26 },
			party = { width = 160, height = 26 },
			raid = { width = 120, height = 22 },
			boss = { width = 200, height = 30 },
		},
		powerHeight = 8,
		classPowerHeight = 8,
		classPowerSpacing = 2,
		castbarHeight = 16,
		castbar = {
			iconEnabled = true,
			iconPosition = "LEFT",
			iconSize = 20,
			iconGap = 2,
			showShield = true,
			showSafeZone = true,
			safeZoneAlpha = 0.35,
			showSpark = true,
			spellMaxChars = 18,
			timeDecimals = 1,
			showDelay = true,
			colorProfile = "UUF",
		},
		powerBgAlpha = 0.35,
		visibility = {
			hideVehicle = true,
			hidePetBattle = true,
			hideOverride = true,
			hidePossess = true,
			hideExtra = true,
		},
		indicators = {
			version = 1,
			size = 24,
			offsetX = 10,
			offsetY = -7,
		},
		party = {
			showPlayerInParty = true,
			showPlayerWhenSolo = false,
			spacing = 10,
		},
		absorbValueTag = "[suf:absorbs:abbr]",
		performance = {
			enabled = true,
			optionsAutoRefresh = true,
		},
		minimap = {
			hide = false,
			minimapPos = 220,
		},
		debug = {
			enabled = false,
			showPanel = false,
			timestamp = true,
			maxMessages = 500,
			systems = {
				General = true,
				Performance = true,
				Events = false,
				Frames = false,
			},
		},
	},
}

local UNIT_TYPE_ORDER = {
	"player",
	"target",
	"tot",
	"focus",
	"pet",
	"party",
	"raid",
	"boss",
}

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

local GROUP_UNIT_TYPES = {
	party = true,
	raid = true,
}

local DEFAULT_UNIT_CASTBAR = {
	enabled = true,
	showText = true,
	showTime = true,
	reverseFill = false,
	widthPercent = 100,
	anchor = "BELOW_FRAME",
	gap = 8,
	offsetY = 0,
	colorProfile = "GLOBAL",
}

local DEFAULT_UNIT_LAYOUT = {
	version = 3,
	secondaryToFrame = 0,
	classToSecondary = 0,
}

local HasVisibleClassPower

local DEFAULT_HEAL_PREDICTION = {
	enabled = true,
	incoming = {
		enabled = true,
		split = false,
		opacity = 0.40,
		height = 1.00,
		colorAll = { 0.35, 0.95, 0.45 },
		colorPlayer = { 0.35, 0.95, 0.45 },
		colorOther = { 0.20, 0.75, 0.35 },
	},
	absorbs = {
		enabled = true,
		opacity = 0.55,
		height = 1.00,
		color = { 0.25, 0.78, 0.92 },
		showGlow = true,
		glowOpacity = 0.95,
	},
	healAbsorbs = {
		enabled = true,
		opacity = 0.55,
		height = 1.00,
		color = { 0.95, 0.25, 0.25 },
		showGlow = true,
		glowOpacity = 0.95,
	},
}

local CASTBAR_COLOR_PROFILES = {
	Blizzard = {
		casting = { 1.00, 0.70, 0.00 },
		channeling = { 0.20, 0.60, 1.00 },
		complete = { 0.00, 1.00, 0.00 },
		failed = { 1.00, 0.10, 0.10 },
		nonInterruptible = { 0.75, 0.75, 0.75 },
		background = { 0.00, 0.00, 0.00, 0.55 },
	},
	UUF = {
		casting = { 0.95, 0.82, 0.24 },
		channeling = { 0.31, 0.78, 0.98 },
		complete = { 0.24, 0.90, 0.24 },
		failed = { 0.96, 0.25, 0.25 },
		nonInterruptible = { 0.66, 0.66, 0.66 },
		background = { 0.02, 0.02, 0.02, 0.65 },
	},
	HighContrast = {
		casting = { 1.00, 0.90, 0.10 },
		channeling = { 0.10, 0.85, 1.00 },
		complete = { 0.10, 1.00, 0.25 },
		failed = { 1.00, 0.15, 0.15 },
		nonInterruptible = { 0.85, 0.85, 0.85 },
		background = { 0.00, 0.00, 0.00, 0.72 },
	},
}

local PERF_EVENT_PRIORITY = {
	UNIT_HEALTH = 1,
	UNIT_POWER_UPDATE = 1,
	UNIT_MAXHEALTH = 2,
	UNIT_HEAL_PREDICTION = 2,
	UNIT_ABSORB_AMOUNT_CHANGED = 2,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = 2,
	UNIT_MAXPOWER = 2,
	UNIT_DISPLAYPOWER = 3,
	UNIT_AURA = 2,
	UNIT_THREAT_SITUATION_UPDATE = 3,
	UNIT_THREAT_LIST_UPDATE = 3,
	PLAYER_TOTEM_UPDATE = 3,
	RUNE_POWER_UPDATE = 3,
	UNIT_SPELLCAST_CHANNEL_UPDATE = 3,
	UNIT_PORTRAIT_UPDATE = 4,
	UNIT_MODEL_CHANGED = 4,
	UNIT_NAME_UPDATE = 4,
	UNIT_FACTION = 4,
}

local PERF_DIRTY_PRIORITY = {
	[1] = 4,
	[2] = 3,
	[3] = 2,
	[4] = 1,
}

local EVENT_COALESCE_CONFIG = {
	UNIT_HEALTH = { delay = 0.13, priority = 2 },
	UNIT_HEAL_PREDICTION = { delay = 0.12, priority = 2 },
	UNIT_ABSORB_AMOUNT_CHANGED = { delay = 0.10, priority = 2 },
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = { delay = 0.10, priority = 2 },
	UNIT_POWER_UPDATE = { delay = 0.13, priority = 2 },
	UNIT_MAXHEALTH = { delay = 0.12, priority = 2 },
	UNIT_MAXPOWER = { delay = 0.12, priority = 2 },
	UNIT_DISPLAYPOWER = { delay = 0.12, priority = 3 },
	UNIT_AURA = { delay = 0.14, priority = 2 },
	UNIT_THREAT_SITUATION_UPDATE = { delay = 0.14, priority = 3 },
	UNIT_THREAT_LIST_UPDATE = { delay = 0.14, priority = 3 },
	PLAYER_TOTEM_UPDATE = { delay = 0.05, priority = 3 },
	RUNE_POWER_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_SPELLCAST_CHANNEL_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_PORTRAIT_UPDATE = { delay = 0.20, priority = 4 },
	UNIT_MODEL_CHANGED = { delay = 0.20, priority = 4 },
	UNIT_NAME_UPDATE = { delay = 0.15, priority = 4 },
	UNIT_FACTION = { delay = 0.15, priority = 4 },
}

local NON_UNIT_EVENT_TARGETS = {
	PLAYER_TOTEM_UPDATE = { "player" },
	RUNE_POWER_UPDATE = { "player" },
}

local UNIT_SCOPED_EVENTS = {
	UNIT_HEALTH = true,
	UNIT_POWER_UPDATE = true,
	UNIT_MAXHEALTH = true,
	UNIT_HEAL_PREDICTION = true,
	UNIT_ABSORB_AMOUNT_CHANGED = true,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = true,
	UNIT_MAXPOWER = true,
	UNIT_DISPLAYPOWER = true,
	UNIT_AURA = true,
	UNIT_THREAT_SITUATION_UPDATE = true,
	UNIT_THREAT_LIST_UPDATE = true,
	UNIT_SPELLCAST_CHANNEL_UPDATE = true,
	UNIT_PORTRAIT_UPDATE = true,
	UNIT_MODEL_CHANGED = true,
	UNIT_NAME_UPDATE = true,
	UNIT_FACTION = true,
}

local function ResolveUnitType(unit)
	if unit == "player" then
		return "player"
	elseif unit == "target" then
		return "target"
	elseif unit == "targettarget" then
		return "tot"
	elseif unit == "focus" then
		return "focus"
	elseif unit == "pet" then
		return "pet"
	elseif unit and unit:match("^party") then
		return "party"
	elseif unit and unit:match("^raid") then
		return "raid"
	elseif unit and unit:match("^boss") then
		return "boss"
	end

	return "player"
end

local function IsInAnyPartyOrRaid()
	local inGroup = (IsInGroup and IsInGroup()) or false
	local inRaid = (IsInRaid and IsInRaid()) or false

	local instanceCategory = _G.LE_PARTY_CATEGORY_INSTANCE
	if instanceCategory then
		if not inGroup and IsInGroup then
			inGroup = IsInGroup(instanceCategory) or false
		end
		if not inRaid and IsInRaid then
			inRaid = IsInRaid(instanceCategory) or false
		end
	end

	if not inGroup and UnitExists then
		for index = 1, 4 do
			if UnitExists("party" .. index) then
				inGroup = true
				break
			end
		end
	end

	if not inRaid and UnitExists and UnitExists("raid1") then
		inRaid = true
	end

	return inGroup, inRaid
end

local function CreateFontString(parent, size, outline)
	local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetFont(DEFAULT_FONT, size, outline or "")
	font:SetJustifyH("LEFT")
	font:SetJustifyV("MIDDLE")
	return font
end

local function CreateStatusBar(parent, height)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetHeight(height)
	bar:SetStatusBarTexture(DEFAULT_TEXTURE)
	return bar
end

local function BuildMediaList(values)
	local list = {}
	for _, value in ipairs(values or {}) do
		list[value] = value
	end
	return list
end

local function FormatCompactValue(value)
	value = tonumber(value) or 0
	if value >= 1000000 then
		return string.format("%.1fm", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.1fk", value / 1000)
	end
	return tostring(math.floor(value + 0.5))
end

local function IsSecretValue(value)
	return type(issecretvalue) == "function" and issecretvalue(value) or false
end

local function SafeNumber(value, fallback)
	local num = tonumber(value)
	if not num or IsSecretValue(num) then
		return fallback
	end
	return num
end

local function SafeBoolean(value, fallback)
	if IsSecretValue(value) then
		return fallback
	end
	if type(value) == "boolean" then
		return value
	end
	return fallback
end

local function SafeText(value, fallback)
	if value == nil or IsSecretValue(value) then
		return fallback
	end
	local ok, text = pcall(tostring, value)
	if not ok or not text or IsSecretValue(text) then
		return fallback
	end
	return text
end

local function SafeAPICall(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn, ...)
	if not ok or IsSecretValue(result) then
		return nil
	end
	return result
end

local function CopyTableDeep(source)
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = CopyTableDeep(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function MergeDefaults(target, defaultsTable)
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

local function GetPowerColor(powerToken)
	if _G.PowerBarColor and powerToken and _G.PowerBarColor[powerToken] then
		local color = _G.PowerBarColor[powerToken]
		return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1
	end

	return 1, 1, 1
end

local function OverrideDisableBlizzard(oUF)
	if not oUF or oUF._sufDisableBlizzardOverridden then
		return
	end

	oUF._sufOriginalDisableBlizzard = oUF.DisableBlizzard
	oUF.DisableBlizzard = function()
		-- Keep Blizzard frames intact so Edit Mode can move and save layouts.
		return
	end
	oUF._sufDisableBlizzardOverridden = true
end

_G.SimpleUnitFrames_UnitBuilders = _G.SimpleUnitFrames_UnitBuilders or {}
addon.unitBuilders = _G.SimpleUnitFrames_UnitBuilders

function addon:RegisterUnitBuilder(unitType, builder)
	if not unitType or not builder then
		return
	end

	self.unitBuilders[unitType] = builder
	_G.SimpleUnitFrames_UnitBuilders[unitType] = builder
end

function addon:GetStatusbarTexture()
	if LSM then
		local texture = LSM:Fetch("statusbar", self.db.profile.media.statusbar)
		if texture then
			return texture
		end
	end

	return DEFAULT_TEXTURE
end

function addon:GetFont()
	if LSM then
		local font = LSM:Fetch("font", self.db.profile.media.font)
		if font then
			return font
		end
	end

	return DEFAULT_FONT
end

function addon:GetUnitSettings(unitType)
	return self.db.profile.units[unitType] or {}
end

function addon:GetUnitFontSizes(unitType)
	local unit = self:GetUnitSettings(unitType)
	if unit.fontSizes then
		return unit.fontSizes
	end

	return self.db.profile.fontSizes
end

function addon:GetUnitStatusbarTexture(unitType)
	local unit = self:GetUnitSettings(unitType)
	if LSM and unit.media and unit.media.statusbar then
		local texture = LSM:Fetch("statusbar", unit.media.statusbar)
		if texture then
			return texture
		end
	end

	return self:GetStatusbarTexture()
end

function addon:GetUnitCastbarSettings(unitType)
	local unit = self:GetUnitSettings(unitType)
	if not unit then
		return DEFAULT_UNIT_CASTBAR
	end

	if unit.castbar == nil then
		unit.castbar = CopyTableDeep(DEFAULT_UNIT_CASTBAR)
	else
		if unit.castbar.gap == nil then
			local legacyOffset = tonumber(unit.castbar.offsetY)
			unit.castbar.gap = legacyOffset and math.max(0, math.abs(legacyOffset)) or DEFAULT_UNIT_CASTBAR.gap
			if legacyOffset ~= nil then
				unit.castbar.offsetY = 0
			end
		end
		for key, value in pairs(DEFAULT_UNIT_CASTBAR) do
			if unit.castbar[key] == nil then
				unit.castbar[key] = value
			end
		end
	end

	return unit.castbar
end

function addon:GetUnitLayoutSettings(unitType)
	local unit = self:GetUnitSettings(unitType)
	if not unit then
		return DEFAULT_UNIT_LAYOUT
	end

	if unit.layout == nil then
		unit.layout = CopyTableDeep(DEFAULT_UNIT_LAYOUT)
	else
		MergeDefaults(unit.layout, DEFAULT_UNIT_LAYOUT)
	end
	if (unit.layout.version or 0) < DEFAULT_UNIT_LAYOUT.version then
		if unit.layout.secondaryToFrame == 2 then
			unit.layout.secondaryToFrame = 0
		end
		if unit.layout.classToSecondary == 2 then
			unit.layout.classToSecondary = 0
		end
		unit.layout.version = DEFAULT_UNIT_LAYOUT.version
	end

	return unit.layout
end

function addon:GetUnitHealPredictionSettings(unitType)
	local unit = self:GetUnitSettings(unitType)
	if not unit then
		return DEFAULT_HEAL_PREDICTION
	end

	if unit.healPrediction == nil then
		unit.healPrediction = CopyTableDeep(DEFAULT_HEAL_PREDICTION)
	else
		MergeDefaults(unit.healPrediction, DEFAULT_HEAL_PREDICTION)
	end

	return unit.healPrediction
end

function addon:GetAbsorbTextForUnit(unit, useAbbrev)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end
	if type(UnitGetTotalAbsorbs) ~= "function" then
		return ""
	end

	local absorbValue = SafeNumber(SafeAPICall(UnitGetTotalAbsorbs, unit), 0)
	if absorbValue <= 0 then
		return ""
	end

	if C_StringUtil and C_StringUtil.TruncateWhenZero then
		local ok, textValue = pcall(C_StringUtil.TruncateWhenZero, absorbValue)
		if ok and textValue and not IsSecretValue(textValue) and textValue ~= "" then
			return textValue
		end
	end

	if useAbbrev then
		local okAbbr, abbrText = pcall(FormatCompactValue, absorbValue)
		if okAbbr and abbrText and not IsSecretValue(abbrText) and abbrText ~= "0" then
			return abbrText
		end
	end

	local rawText = SafeText(absorbValue, nil)
	if rawText and rawText ~= "0" then
		return rawText
	end

	return ""
end

function addon:RegisterCustomTags()
	if self._customTagsRegistered then
		return
	end

	local ouf = self.oUF or GetOuf()
	if not (ouf and ouf.Tags and ouf.Tags.Methods and ouf.Tags.Events) then
		return
	end

	ouf.Tags.Methods["suf:absorbs"] = function(unit)
		return addon:GetAbsorbTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:absorbs:abbr"] = function(unit)
		return addon:GetAbsorbTextForUnit(unit, true)
	end
	ouf.Tags.Events["suf:absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:absorbs:abbr"] = "UNIT_ABSORB_AMOUNT_CHANGED UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"

	self._customTagsRegistered = true
end

function addon:GetCastbarColors()
	local profileName = self.db and self.db.profile and self.db.profile.castbar and self.db.profile.castbar.colorProfile
	local palette = CASTBAR_COLOR_PROFILES[profileName or ""] or CASTBAR_COLOR_PROFILES.UUF
	return palette
end

function addon:GetUnitCastbarColors(unitType)
	local unitCfg = self:GetUnitCastbarSettings(unitType)
	local profileName = unitCfg and unitCfg.colorProfile
	if not profileName or profileName == "GLOBAL" then
		return self:GetCastbarColors()
	end
	return CASTBAR_COLOR_PROFILES[profileName] or self:GetCastbarColors()
end

function addon:GetUnitInterruptState(unit)
	if not unit or not UnitExists or not UnitExists(unit) then
		return nil
	end

	if UnitCastingInfo then
		local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
		if notInterruptible ~= nil then
			return not notInterruptible
		end
	end

	if UnitChannelInfo then
		local _, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
		if notInterruptible ~= nil then
			return not notInterruptible
		end
	end

	return nil
end

function addon:GetUnitAuraSize(unitType)
	local unit = self:GetUnitSettings(unitType)
	if unit and type(unit.auraSize) == "number" and unit.auraSize > 0 then
		return unit.auraSize
	end
	if unitType == "player" or unitType == "target" then
		return math.floor((18 * 1.25) + 0.5)
	end
	return 18
end

local function BuildVisibilityDriver(profile)
	local clauses = {}
	if profile.visibility.hideVehicle then
		table.insert(clauses, "[vehicleui] hide")
	end
	if profile.visibility.hidePetBattle then
		table.insert(clauses, "[petbattle] hide")
	end
	if profile.visibility.hideOverride then
		table.insert(clauses, "[overridebar] hide")
	end
	if profile.visibility.hidePossess then
		table.insert(clauses, "[possessbar] hide")
	end
	if profile.visibility.hideExtra then
		table.insert(clauses, "[extrabar] hide")
	end

	return table.concat(clauses, "; ") .. "; show"
end

function addon:SetupPerformanceLib()
	self.performanceLib = _G.PerformanceLib
	if not (self.performanceLib and self.performanceLib.Initialize) then
		if self.db and self.db.profile then
			self:DebugLog("Performance", "PerformanceLib not detected during setup.", 2)
		end
		return
	end

	local okInit = pcall(self.performanceLib.Initialize, self.performanceLib, addonId)
	if not okInit then
		self.performanceLib = nil
		if self.db and self.db.profile then
			self:DebugLog("Performance", "PerformanceLib Initialize failed.", 1)
		end
		return
	end
	if self.db and self.db.profile then
		self:DebugLog("Performance", "PerformanceLib initialized for SUF.", 2)
	end

	if self.performanceLib.SetOutputSink then
		self.performanceLib:SetOutputSink(function(context, message, system, tier)
			if context and context.DebugLog then
				context:DebugLog(system or "Performance", tostring(message or ""), tier or 2)
			end
		end, self)
	end

	if self.performanceLib.SetPreset and self.performanceLib.db and (not self.performanceLib.db.presets or self.performanceLib.db.presets == "") then
		pcall(self.performanceLib.SetPreset, self.performanceLib, "Medium")
	end

	local optimizer = self.performanceLib.MLOptimizer
	if optimizer and optimizer.RegisterSequence then
		optimizer:RegisterSequence("UNIT_HEALTH", "UNIT_POWER_UPDATE", 0.75)
		optimizer:RegisterSequence("UNIT_POWER_UPDATE", "UNIT_DISPLAYPOWER", 0.65)
		optimizer:RegisterSequence("UNIT_MAXHEALTH", "UNIT_HEALTH", 0.60)
	end
end

function addon:RecordProfilerEvent(eventName, durationMs)
	if not eventName then
		return
	end
	local profiler = self.performanceLib and self.performanceLib.PerformanceProfiler
	if not (profiler and profiler.RecordEvent) then
		return
	end
	local duration = SafeNumber(durationMs, 0) or 0
	if duration < 0 then
		duration = 0
	end
	pcall(profiler.RecordEvent, profiler, tostring(eventName), duration)
end

function addon:SetupEventBus()
	if self.sufEventBus then
		return
	end

	local bus = {
		handlers = {},
	}

	function bus:Register(event, key, fn, once)
		if type(event) ~= "string" or type(key) ~= "string" or type(fn) ~= "function" then
			return false
		end
		local entry = self.handlers[event]
		if not entry then
			entry = { list = {}, index = {} }
			self.handlers[event] = entry
		end
		if entry.index[key] then
			return false
		end
		local position = #entry.list + 1
		entry.list[position] = { key = key, fn = fn, once = once and true or false, dead = false }
		entry.index[key] = position
		return true
	end

	function bus:Unregister(event, key)
		local entry = self.handlers[event]
		if not entry or not entry.index[key] then
			return false
		end
		local position = entry.index[key]
		local handler = entry.list[position]
		if handler then
			handler.dead = true
			entry.dirty = true
		end
		return true
	end

	function bus:Compact(event)
		local entry = self.handlers[event]
		if not entry then
			return
		end
		for key in pairs(entry.index) do
			entry.index[key] = nil
		end
		local write = 0
		for i = 1, #entry.list do
			local handler = entry.list[i]
			if handler and not handler.dead then
				write = write + 1
				entry.list[write] = handler
				entry.index[handler.key] = write
			end
		end
		for i = write + 1, #entry.list do
			entry.list[i] = nil
		end
		entry.dirty = false
	end

	function bus:Dispatch(event, ...)
		local entry = self.handlers[event]
		if not entry then
			return
		end
		for i = 1, #entry.list do
			local handler = entry.list[i]
			if handler and not handler.dead then
				handler.fn(...)
				if handler.once then
					handler.dead = true
					entry.dirty = true
				end
			end
		end
		if entry.dirty then
			self:Compact(event)
		end
	end

	self.sufEventBus = bus
	self.EventBus = bus

	self.sufEventBus:Register("PERF_EVENT_INPUT", "queue-performance-event", function(eventName, ...)
		if self:IsPerformanceIntegrationEnabled() then
			self:QueuePerformanceEvent(eventName, ...)
		else
			self:HandleCoalescedEvent(eventName, ...)
		end
	end)

	self.sufEventBus:Register("COALESCED_EVENT", "handle-coalesced-event", function(eventName, ...)
		self:HandleCoalescedEvent(eventName, ...)
	end)
end

function addon:DispatchSUFEvent(event, ...)
	if self.sufEventBus and self.sufEventBus.Dispatch then
		self.sufEventBus:Dispatch(event, ...)
	end
end

function addon:GetDirtyPriorityForEvent(eventName, frame)
	local perfPriority = PERF_EVENT_PRIORITY[eventName] or 3
	local basePriority = PERF_DIRTY_PRIORITY[perfPriority] or 2
	local optimizer = self.performanceLib and self.performanceLib.DirtyPriorityOptimizer
	if optimizer and optimizer.LearnPriority then
		local ok, learnedPriority = pcall(optimizer.LearnPriority, optimizer, frame, basePriority)
		if ok and type(learnedPriority) == "number" then
			return math.max(1, math.min(4, learnedPriority))
		end
	end
	return basePriority
end

local function ClearTableInPlace(tbl)
	if not tbl then
		return
	end
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end

local function SafeUpdateElement(frame, element, eventName)
	if not frame or not element then
		return false
	end

	if frame.UpdateElement then
		local ok = pcall(frame.UpdateElement, frame, element, eventName)
		return ok
	end

	local widget = frame[element]
	if widget and widget.ForceUpdate then
		local ok = pcall(widget.ForceUpdate, widget)
		return ok
	end

	return false
end

local function IsRightClick(mouseButton)
	return type(mouseButton) == "string" and mouseButton:find("RightButton", 1, true) ~= nil
end

function addon:IsFrameEventRelevant(frame, eventName)
	if not frame or not eventName then
		return false
	end

	if eventName == "UNIT_AURA" then
		return frame.Auras ~= nil
	elseif eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		return frame.Castbar ~= nil
	elseif eventName == "UNIT_HEALTH" or eventName == "UNIT_MAXHEALTH" or eventName == "UNIT_THREAT_SITUATION_UPDATE" or eventName == "UNIT_THREAT_LIST_UPDATE" or eventName == "UNIT_HEAL_PREDICTION" or eventName == "UNIT_ABSORB_AMOUNT_CHANGED" or eventName == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
		return frame.Health ~= nil
	elseif eventName == "UNIT_POWER_UPDATE" or eventName == "UNIT_MAXPOWER" or eventName == "UNIT_DISPLAYPOWER" or eventName == "RUNE_POWER_UPDATE" or eventName == "PLAYER_TOTEM_UPDATE" then
		return (frame.Power ~= nil) or (frame.AdditionalPower ~= nil) or (frame.ClassPower ~= nil)
	elseif eventName == "UNIT_PORTRAIT_UPDATE" or eventName == "UNIT_MODEL_CHANGED" or eventName == "UNIT_NAME_UPDATE" or eventName == "UNIT_FACTION" then
		local settings = self:GetUnitSettings(frame.sufUnitType)
		return settings and settings.portrait and settings.portrait.mode and settings.portrait.mode ~= "none"
	end

	return true
end

function addon:UpdateFrameFromDirtyEvents(frame, dirtyEvents)
	if not frame then
		return
	end
	local profileStart = debugprofilestop and debugprofilestop() or nil

	if type(dirtyEvents) ~= "table" then
		frame:UpdateAllElements("SimpleUnitFrames_PerfDirty")
		return
	end

	local eventCount = 0
	for eventName in pairs(dirtyEvents) do
		eventCount = eventCount + 1
		if eventCount > 4 then
			frame:UpdateAllElements("SimpleUnitFrames_PerfDirtyBatch")
			return
		end
	end

	local touched = false
	for eventName in pairs(dirtyEvents) do
		if eventName == "UNIT_HEALTH" or eventName == "UNIT_MAXHEALTH" or eventName == "UNIT_THREAT_SITUATION_UPDATE" or eventName == "UNIT_THREAT_LIST_UPDATE" or eventName == "UNIT_HEAL_PREDICTION" or eventName == "UNIT_ABSORB_AMOUNT_CHANGED" or eventName == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
			touched = SafeUpdateElement(frame, "Health", eventName) or touched
			touched = SafeUpdateElement(frame, "HealthPrediction", eventName) or touched
			self:UpdateAbsorbValue(frame)
		elseif eventName == "UNIT_POWER_UPDATE" or eventName == "UNIT_MAXPOWER" or eventName == "UNIT_DISPLAYPOWER" or eventName == "RUNE_POWER_UPDATE" or eventName == "PLAYER_TOTEM_UPDATE" then
			touched = SafeUpdateElement(frame, "Power", eventName) or touched
			touched = SafeUpdateElement(frame, "AdditionalPower", eventName) or touched
			touched = SafeUpdateElement(frame, "ClassPower", eventName) or touched
		elseif eventName == "UNIT_AURA" then
			touched = SafeUpdateElement(frame, "Auras", eventName) or touched
		elseif eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
			touched = SafeUpdateElement(frame, "Castbar", eventName) or touched
		elseif eventName == "UNIT_PORTRAIT_UPDATE" or eventName == "UNIT_MODEL_CHANGED" or eventName == "UNIT_NAME_UPDATE" or eventName == "UNIT_FACTION" then
			touched = SafeUpdateElement(frame, "Portrait", eventName) or touched
		else
			frame:UpdateAllElements("SimpleUnitFrames_PerfDirtyFallback")
			return
		end
	end

	if not touched then
		frame:UpdateAllElements("SimpleUnitFrames_PerfDirtyFallback")
	end

	if profileStart then
		local profileEnd = debugprofilestop() or profileStart
		self:RecordProfilerEvent("suf:dirty.update", profileEnd - profileStart)
	end
end

function addon:MarkFrameDirty(frame, eventName)
	if not frame then
		return
	end
	if not self:IsFrameEventRelevant(frame, eventName) then
		return
	end

	frame.__sufDirtyEvents = frame.__sufDirtyEvents or {}
	frame.__sufDirtyEvents[eventName or "UNKNOWN"] = true
	if frame.__sufDirtyQueued then
		return
	end
	frame.__sufDirtyQueued = true

	local priority = self:GetDirtyPriorityForEvent(eventName, frame)
	local dirtyManager = self.performanceLib and self.performanceLib.DirtyFlagManager
	if dirtyManager and dirtyManager.MarkDirty then
		dirtyManager:MarkDirty(frame, priority)
	else
		local events = frame.__sufDirtyEvents
		frame.__sufDirtyQueued = false
		frame.__sufDirtyEvents = {}
		self:UpdateFrameFromDirtyEvents(frame, events)
		ClearTableInPlace(events)
	end
end

function addon:HandleCoalescedUnitEvent(eventName, unit)
	if not unit then
		return
	end

	local hasDirectMatch = false
	for _, frame in ipairs(self.frames or {}) do
		if frame and frame.unit == unit then
			hasDirectMatch = true
			self:MarkFrameDirty(frame, eventName)
		end
	end

	if not hasDirectMatch then
		local unitType = ResolveUnitType(unit)
		for _, frame in ipairs(self.frames or {}) do
			if frame and frame.sufUnitType == unitType then
				self:MarkFrameDirty(frame, eventName)
			end
		end
	end

	if unit == "target" then
		for _, frame in ipairs(self.frames or {}) do
			if frame and frame.sufUnitType == "tot" then
				self:MarkFrameDirty(frame, eventName)
			end
		end
	end
end

function addon:QueuePerformanceEvent(eventName, ...)
	if not self:IsPerformanceIntegrationEnabled() then
		return
	end
	local profileStart = debugprofilestop and debugprofilestop() or nil

	local eventConfig = EVENT_COALESCE_CONFIG[eventName]
	local priority = (eventConfig and eventConfig.priority) or PERF_EVENT_PRIORITY[eventName] or 3
	self:DebugLog("Events", "Queued event: " .. tostring(eventName), 3)
	local optimizer = self.performanceLib and self.performanceLib.MLOptimizer
	if optimizer and optimizer.TrackPattern then
		pcall(optimizer.TrackPattern, optimizer, eventName, "SUF:QueuePerformanceEvent")
	end

	if self.performanceLib and self.performanceLib.QueueEvent then
		self.performanceLib:QueueEvent(eventName, priority, ...)
	else
		self:HandleCoalescedEvent(eventName, ...)
	end

	if profileStart then
		local profileEnd = debugprofilestop() or profileStart
		self:RecordProfilerEvent("suf:queue." .. tostring(eventName), profileEnd - profileStart)
	end
end

function addon:HandleCoalescedEvent(eventName, ...)
	local unitToken = ...
	if UNIT_SCOPED_EVENTS[eventName] then
		if type(unitToken) == "string" and unitToken ~= "" then
			self:HandleCoalescedUnitEvent(eventName, unitToken)
			return
		end
	end

	local fallbackUnits = NON_UNIT_EVENT_TARGETS[eventName]
	if fallbackUnits then
		for i = 1, #fallbackUnits do
			self:HandleCoalescedUnitEvent(eventName, fallbackUnits[i])
		end
		return
	end

	for _, frame in ipairs(self.frames or {}) do
		if frame then
			self:MarkFrameDirty(frame, eventName)
		end
	end
end

function addon:RegisterPerformanceCoalescedHandlers()
	if self._performanceHandlersRegistered then
		return
	end

	local coalescer = self.performanceLib and self.performanceLib.EventCoalescer
	self.performanceHandlers = self.performanceHandlers or {}

	if coalescer and coalescer.CoalesceEvent then
		for eventName, config in pairs(EVENT_COALESCE_CONFIG) do
			local callback = function(...)
				local profileStart = debugprofilestop and debugprofilestop() or nil
				self:DispatchSUFEvent("COALESCED_EVENT", eventName, ...)
				if profileStart then
					local profileEnd = debugprofilestop() or profileStart
					self:RecordProfilerEvent("suf:coalesced." .. tostring(eventName), profileEnd - profileStart)
				end
			end
			self.performanceHandlers[eventName] = callback
			coalescer:CoalesceEvent(eventName, config.delay, callback, config.priority)
			if coalescer.SetEventDelay then
				local delay = config.delay
				local optimizer = self.performanceLib and self.performanceLib.MLOptimizer
				if optimizer and optimizer.GetOptimalDelay then
					local okDelay, learnedDelay = pcall(optimizer.GetOptimalDelay, optimizer, eventName)
					if okDelay and type(learnedDelay) == "number" then
						delay = math.max(0.01, math.min(0.25, learnedDelay))
					end
				end
				coalescer:SetEventDelay(eventName, delay)
			end
		end
		self._performanceHandlersRegistered = true
		self:DebugLog("Performance", "Registered coalesced handlers for " .. tostring(#(coalescer.GetCoalescedEvents and coalescer:GetCoalescedEvents() or {})) .. " events.", 2)
		return
	end

	local eventBus = self.performanceLib and self.performanceLib.Architecture and self.performanceLib.Architecture.EventBus
	if eventBus and eventBus.Register then
		for eventName in pairs(EVENT_COALESCE_CONFIG) do
			local callback = function(context, ...)
				context:DispatchSUFEvent("COALESCED_EVENT", eventName, ...)
			end
			self.performanceHandlers[eventName] = callback
			eventBus:Register(eventName, callback, self)
		end
		self._performanceHandlersRegistered = true
	end
end

function addon:UnregisterPerformanceCoalescedHandlers()
	if not self._performanceHandlersRegistered then
		return
	end

	local coalescer = self.performanceLib and self.performanceLib.EventCoalescer
	if coalescer and coalescer.UncoalesceEvent and self.performanceHandlers then
		for eventName, callback in pairs(self.performanceHandlers) do
			pcall(coalescer.UncoalesceEvent, coalescer, eventName, callback)
		end
	end

	local eventBus = self.performanceLib and self.performanceLib.Architecture and self.performanceLib.Architecture.EventBus
	if eventBus and eventBus.Unregister and self.performanceHandlers then
		for eventName, callback in pairs(self.performanceHandlers) do
			eventBus:Unregister(eventName, callback)
		end
	end

	self.performanceHandlers = {}
	self._performanceHandlersRegistered = nil
end

function addon:SetupMLCoalescerIntegration()
	if self._mlCoalescerHooks then
		return
	end

	local optimizer = self.performanceLib and self.performanceLib.MLOptimizer
	local coalescer = self.performanceLib and self.performanceLib.EventCoalescer
	if not (optimizer and coalescer) then
		return
	end

	self._mlCoalescerHooks = {}

	if coalescer.QueueEvent and not self._mlCoalescerHooks.queue then
		local originalQueueEvent = coalescer.QueueEvent
		self._mlCoalescerHooks.queue = originalQueueEvent
		coalescer.QueueEvent = function(instance, eventName, ...)
			local accepted = originalQueueEvent(instance, eventName, ...)
			if accepted and eventName and optimizer.TrackPattern then
				pcall(optimizer.TrackPattern, optimizer, eventName, "EventCoalescer:" .. tostring(eventName))
			end
			return accepted
		end
	end

	if coalescer._DispatchCoalesced and not self._mlCoalescerHooks.dispatch then
		local originalDispatch = coalescer._DispatchCoalesced
		self._mlCoalescerHooks.dispatch = originalDispatch
		coalescer._DispatchCoalesced = function(instance, eventName)
			local fpsBefore = GetFramerate and GetFramerate() or 0
			local result = originalDispatch(instance, eventName)
			if C_Timer and C_Timer.After then
				C_Timer.After(0, function()
					local fpsAfter = GetFramerate and GetFramerate() or fpsBefore
					local success = fpsBefore <= 0 or fpsAfter >= (fpsBefore * 0.9)
					local currentDelay = 0.05
					if instance.GetEventDelay then
						local okDelay, delay = pcall(instance.GetEventDelay, instance, eventName)
						if okDelay and type(delay) == "number" then
							currentDelay = delay
						end
					end
					if optimizer.LearnDelay then
						pcall(optimizer.LearnDelay, optimizer, eventName, currentDelay, success)
					end
				end)
			end
			return result
		end
	end

	if not self._mlDelayTicker and C_Timer and C_Timer.NewTicker then
		self._mlDelayTicker = C_Timer.NewTicker(5, function()
			if not self:IsPerformanceIntegrationEnabled() then
				return
			end
			local coalescerNow = self.performanceLib and self.performanceLib.EventCoalescer
			local optimizerNow = self.performanceLib and self.performanceLib.MLOptimizer
			if not (coalescerNow and optimizerNow and optimizerNow.GetOptimalDelay and coalescerNow.GetCoalescedEvents and coalescerNow.GetEventDelay and coalescerNow.SetEventDelay) then
				return
			end
			if optimizerNow.UpdateContext then
				pcall(optimizerNow.UpdateContext, optimizerNow)
			end
			local okEvents, events = pcall(coalescerNow.GetCoalescedEvents, coalescerNow)
			if not okEvents or type(events) ~= "table" then
				return
			end
			for i = 1, #events do
				local eventName = events[i]
				local okOptimal, optimalDelay = pcall(optimizerNow.GetOptimalDelay, optimizerNow, eventName)
				local okCurrent, currentDelay = pcall(coalescerNow.GetEventDelay, coalescerNow, eventName)
				if okOptimal and okCurrent and type(optimalDelay) == "number" and type(currentDelay) == "number" then
					optimalDelay = math.max(0.01, math.min(0.25, optimalDelay))
					if math.abs(currentDelay - optimalDelay) > 0.01 then
						pcall(coalescerNow.SetEventDelay, coalescerNow, eventName, optimalDelay)
					end
				end
			end
		end)
	end
end

function addon:TeardownMLCoalescerIntegration()
	local coalescer = self.performanceLib and self.performanceLib.EventCoalescer
	if coalescer and self._mlCoalescerHooks then
		if self._mlCoalescerHooks.queue then
			coalescer.QueueEvent = self._mlCoalescerHooks.queue
		end
		if self._mlCoalescerHooks.dispatch then
			coalescer._DispatchCoalesced = self._mlCoalescerHooks.dispatch
		end
	end
	self._mlCoalescerHooks = nil

	if self._mlDelayTicker then
		self._mlDelayTicker:Cancel()
		self._mlDelayTicker = nil
	end
end

function addon:RegisterPerformanceEventFrame()
	if not self.performanceEventFrame then
		local frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", function(_, eventName, ...)
			if UNIT_SCOPED_EVENTS[eventName] then
				local unitToken = ...
				if type(unitToken) ~= "string" or unitToken == "" then
					if not NON_UNIT_EVENT_TARGETS[eventName] then
						return
					end
				end
			end
			self:DispatchSUFEvent("PERF_EVENT_INPUT", eventName, ...)
		end)
		self.performanceEventFrame = frame
	end

	for eventName in pairs(EVENT_COALESCE_CONFIG) do
		self.performanceEventFrame:RegisterEvent(eventName)
	end
end

function addon:UnregisterPerformanceEventFrame()
	if self.performanceEventFrame then
		self.performanceEventFrame:UnregisterAllEvents()
	end
end

function addon:IsPerformanceIntegrationEnabled()
	return self.performanceLib and self.db and self.db.profile and self.db.profile.performance and self.db.profile.performance.enabled
end

function addon:SetPerformanceIntegrationEnabled(enabled, silent)
	enabled = enabled and true or false
	self.db.profile.performance = self.db.profile.performance or {}

	if not self.performanceLib then
		self:SetupPerformanceLib()
	end

	if not self.performanceLib then
		self.db.profile.performance.enabled = false
		if not silent then
			self:Print(addonName .. ": PerformanceLib is not loaded.")
		end
		self:DebugLog("Performance", "Performance integration requested but library is unavailable.", 1)
		return false
	end

	self.db.profile.performance.enabled = enabled
	if self.performanceLib.SetEnabled then
		self.performanceLib:SetEnabled(enabled)
	end

	if enabled then
		self:SetupEventBus()
		self:EnsureRuntimePools()
		self:RegisterPerformanceCoalescedHandlers()
		self:RegisterPerformanceEventFrame()
		self:SetupMLCoalescerIntegration()
	else
		if self.performanceLib.EventCoalescer and self.performanceLib.EventCoalescer.Flush then
			self.performanceLib.EventCoalescer:Flush()
		end
		self:UnregisterPerformanceEventFrame()
		self:UnregisterPerformanceCoalescedHandlers()
		self:TeardownMLCoalescerIntegration()
	end

	if not silent then
		self:Print(addonName .. ": PerformanceLib integration " .. (enabled and "enabled." or "disabled."))
	end
	self:DebugLog("Performance", "Performance integration " .. (enabled and "enabled" or "disabled") .. ".", 2)

	return true
end

function addon:EnsureDebugConfig()
	self.db.profile.debug = self.db.profile.debug or CopyTableDeep(defaults.profile.debug)
	local dbg = self.db.profile.debug
	if dbg.enabled == nil then dbg.enabled = defaults.profile.debug.enabled end
	if dbg.showPanel == nil then dbg.showPanel = defaults.profile.debug.showPanel end
	if dbg.timestamp == nil then dbg.timestamp = defaults.profile.debug.timestamp end
	if type(dbg.maxMessages) ~= "number" then dbg.maxMessages = defaults.profile.debug.maxMessages end
	dbg.systems = dbg.systems or CopyTableDeep(defaults.profile.debug.systems)
	for system, defaultValue in pairs(defaults.profile.debug.systems) do
		if dbg.systems[system] == nil then
			dbg.systems[system] = defaultValue
		end
	end
end

function addon:IsDebugEnabled()
	return self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.enabled
end

function addon:DebugLog(system, message, tier)
	self:EnsureDebugConfig()
	self.debugMessages = self.debugMessages or {}
	system = system or "General"
	tier = tier or 3 -- 1=critical,2=info,3=debug

	local dbg = self.db.profile.debug
	if tier >= 3 and (not dbg.enabled or not dbg.systems[system]) then
		return
	end

	local timestamp = dbg.timestamp and date("%H:%M:%S") or ""
	local prefix = timestamp ~= "" and ("[" .. timestamp .. "] ") or ""
	local line = prefix .. system .. ": " .. tostring(message)

	table.insert(self.debugMessages, line)
	if #self.debugMessages > dbg.maxMessages then
		table.remove(self.debugMessages, 1)
	end

	if self.debugPanel and self.debugPanel:IsShown() then
		self:RefreshDebugPanel()
	end
end

function addon:RefreshDebugPanel()
	if not self.debugPanel or not self.debugPanel.messagesText then
		return
	end
	local text = table.concat(self.debugMessages or {}, "\n")
	self.debugPanel.messagesText:SetText(text)
	local height = self.debugPanel.messagesText:GetStringHeight()
	self.debugPanel.textFrame:SetHeight(math.max(height + 10, 1))
end

local function SetSUFWindowTitle(frame, text)
	if not frame then
		return
	end

	local titleText = frame.TitleText
	if titleText and titleText.SetText then
		titleText:ClearAllPoints()
		titleText:SetPoint("TOP", frame, "TOP", 0, -4)
		titleText:SetText(text or "")
		return
	end

	local fallback = frame._sufTitleFallback
	if not fallback then
		fallback = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		frame._sufTitleFallback = fallback
	end
	fallback:ClearAllPoints()
	fallback:SetPoint("TOP", frame, "TOP", 0, -4)
	fallback:SetText(text or "")
end

function addon:GetPerformanceLibPreset()
	local perf = self.performanceLib
	if not (perf and perf.db) then
		return "Medium"
	end
	local preset = tostring(perf.db.presets or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if preset == "" then
		return "Medium"
	end
	return preset
end

function addon:IsPerformanceProfiling()
	local profiler = self.performanceLib and self.performanceLib.PerformanceProfiler
	if not (profiler and profiler.GetStats) then
		return false
	end
	local ok, stats = pcall(profiler.GetStats, profiler)
	return ok and stats and stats.isRecording and true or false
end

function addon:StartPerformanceProfileFromUI()
	if not (self.performanceLib and self.performanceLib.StartProfiling) then
		self:DebugLog("Performance", "PerformanceLib profiler is unavailable.", 1)
		return
	end
	self.performanceLib:StartProfiling()
	self:DebugLog("Performance", "Profile capture started.", 2)
end

function addon:StopPerformanceProfileFromUI()
	if not (self.performanceLib and self.performanceLib.StopProfiling) then
		self:DebugLog("Performance", "PerformanceLib profiler is unavailable.", 1)
		return
	end
	self.performanceLib:StopProfiling()
	self:DebugLog("Performance", "Profile capture stopped.", 2)
end

function addon:AnalyzePerformanceProfileFromUI()
	if not self.performanceLib then
		self:DebugLog("Performance", "PerformanceLib is unavailable.", 1)
		return
	end
	if self.performanceLib.AnalyzePerformance then
		self.performanceLib:AnalyzePerformance("all")
		self:DebugLog("Performance", "Profile analysis completed.", 2)
		return
	end
	local profiler = self.performanceLib.PerformanceProfiler
	if profiler and profiler.Analyze then
		profiler:Analyze()
		self:DebugLog("Performance", "Profiler analysis completed.", 2)
	else
		self:DebugLog("Performance", "Performance analysis API is unavailable.", 1)
	end
end

function addon:ShowDebugExportDialog()
	local exportText = table.concat(self.debugMessages or {}, "\n")
	if exportText == "" then
		self:Print(addonName .. ": No debug messages to export.")
		return
	end

	if not self.debugExportFrame then
		local frame = CreateFrame("Frame", "SUFDebugExportFrame", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(520, 420)
		frame:SetPoint("CENTER")
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		frame:SetFrameStrata("DIALOG")

		SetSUFWindowTitle(frame, "SUF Debug Export")

		local note = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		note:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
		note:SetText("Ctrl+A then Ctrl+C to copy.")

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -56)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

		local editBox = CreateFrame("EditBox", nil, scroll)
		editBox:SetMultiLine(true)
		editBox:SetFontObject(GameFontHighlightSmall)
		editBox:SetWidth(470)
		editBox:SetAutoFocus(false)
		editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
		scroll:SetScrollChild(editBox)
		frame.editBox = editBox

		self.debugExportFrame = frame
	end

	SetSUFWindowTitle(self.debugExportFrame, "SUF Debug Export")
	self.debugExportFrame.editBox:SetText(exportText)
	self.debugExportFrame.editBox:SetCursorPosition(0)
	self.debugExportFrame.editBox:HighlightText()
	self.debugExportFrame:Show()
end

function addon:ShowDebugSettings()
	self:EnsureDebugConfig()
	if not self.debugSettingsFrame then
		local frame = CreateFrame("Frame", "SUFDebugSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(320, 360)
		frame:SetPoint("CENTER", UIParent, "CENTER", -360, 0)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

		SetSUFWindowTitle(frame, "SUF Debug Settings")

		local enableAll = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		enableAll:SetSize(90, 24)
		enableAll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -36)
		enableAll:SetText("Enable All")
		enableAll:SetScript("OnClick", function()
			for key in pairs(self.db.profile.debug.systems) do
				self.db.profile.debug.systems[key] = true
			end
			self:ShowDebugSettings()
		end)

		local disableAll = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		disableAll:SetSize(90, 24)
		disableAll:SetPoint("LEFT", enableAll, "RIGHT", 10, 0)
		disableAll:SetText("Disable All")
		disableAll:SetScript("OnClick", function()
			for key in pairs(self.db.profile.debug.systems) do
				self.db.profile.debug.systems[key] = false
			end
			self:ShowDebugSettings()
		end)

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -68)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
		local child = CreateFrame("Frame", nil, scroll)
		child:SetSize(250, 1)
		scroll:SetScrollChild(child)
		frame.scrollChild = child

		self.debugSettingsFrame = frame
	end

	local frame = self.debugSettingsFrame
	SetSUFWindowTitle(frame, "SUF Debug Settings")
	local child = frame.scrollChild
	for i = child:GetNumChildren(), 1, -1 do
		local element = select(i, child:GetChildren())
		if element then
			element:Hide()
			element:SetParent(nil)
		end
	end

	local y = -6
	for system, value in pairs(self.db.profile.debug.systems) do
		local cb = CreateFrame("CheckButton", nil, child, "UICheckButtonTemplate")
		cb:SetPoint("TOPLEFT", child, "TOPLEFT", 6, y)
		cb:SetChecked(value)
		cb:SetScript("OnClick", function(btn)
			self.db.profile.debug.systems[system] = btn:GetChecked() and true or false
		end)
		local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
		label:SetText(system)
		y = y - 24
	end
	child:SetHeight(math.max(math.abs(y) + 8, 1))
	frame:Show()
end

function addon:ShowDebugPanel()
	self:EnsureDebugConfig()
	if not self.debugPanel then
		local frame = CreateFrame("Frame", "SUFDebugPanel", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(620, 420)
		frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

		SetSUFWindowTitle(frame, "|cFF00B0F7SUF Debug Console|r")

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -36)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 46)
		local textFrame = CreateFrame("Frame", nil, scroll)
		textFrame:SetSize(560, 1)
		local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 4, 0)
		text:SetWidth(550)
		text:SetJustifyH("LEFT")
		text:SetJustifyV("TOP")
		scroll:SetScrollChild(textFrame)
		frame.messagesText = text
		frame.textFrame = textFrame

		local toggleBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		toggleBtn:SetSize(100, 24)
		toggleBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
		local function UpdateToggleLabel()
			toggleBtn:SetText(self:IsDebugEnabled() and "Enabled" or "Disabled")
		end
		UpdateToggleLabel()
		toggleBtn:SetScript("OnClick", function()
			self.db.profile.debug.enabled = not self.db.profile.debug.enabled
			UpdateToggleLabel()
			self:DebugLog("General", "Debug mode " .. (self.db.profile.debug.enabled and "enabled" or "disabled"), 2)
		end)
		frame.toggleBtn = toggleBtn

		local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		clearBtn:SetSize(80, 24)
		clearBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
		clearBtn:SetText("Clear")
		clearBtn:SetScript("OnClick", function()
			self.debugMessages = {}
			self:RefreshDebugPanel()
		end)

		local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		exportBtn:SetSize(80, 24)
		exportBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
		exportBtn:SetText("Export")
		exportBtn:SetScript("OnClick", function()
			self:ShowDebugExportDialog()
		end)

		local settingsBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		settingsBtn:SetSize(70, 24)
		settingsBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
		settingsBtn:SetText("Settings")
		settingsBtn:SetScript("OnClick", function()
			self:ShowDebugSettings()
		end)
		frame.settingsBtn = settingsBtn

		local profileStartBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		profileStartBtn:SetSize(72, 24)
		profileStartBtn:SetPoint("LEFT", settingsBtn, "RIGHT", 8, 0)
		profileStartBtn:SetText("Start")
		profileStartBtn:SetScript("OnClick", function()
			self:StartPerformanceProfileFromUI()
			if self.debugPanel and self.debugPanel.UpdateProfileButtons then
				self.debugPanel:UpdateProfileButtons()
			end
		end)
		frame.profileStartBtn = profileStartBtn

		local profileStopBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		profileStopBtn:SetSize(64, 24)
		profileStopBtn:SetPoint("LEFT", profileStartBtn, "RIGHT", 8, 0)
		profileStopBtn:SetText("Stop")
		profileStopBtn:SetScript("OnClick", function()
			self:StopPerformanceProfileFromUI()
			if self.debugPanel and self.debugPanel.UpdateProfileButtons then
				self.debugPanel:UpdateProfileButtons()
			end
		end)
		frame.profileStopBtn = profileStopBtn

		local profileAnalyzeBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		profileAnalyzeBtn:SetSize(72, 24)
		profileAnalyzeBtn:SetPoint("LEFT", profileStopBtn, "RIGHT", 8, 0)
		profileAnalyzeBtn:SetText("Analyze")
		profileAnalyzeBtn:SetScript("OnClick", function()
			self:AnalyzePerformanceProfileFromUI()
		end)
		frame.profileAnalyzeBtn = profileAnalyzeBtn

		function frame:UpdateProfileButtons()
			local recording = addon:IsPerformanceProfiling()
			if self.profileStartBtn then
				self.profileStartBtn:SetEnabled(not recording)
			end
			if self.profileStopBtn then
				self.profileStopBtn:SetEnabled(recording)
			end
		end

		self.debugPanel = frame
	end

	if self.debugPanel.toggleBtn then
		self.debugPanel.toggleBtn:SetText(self:IsDebugEnabled() and "Enabled" or "Disabled")
	end
	if self.debugPanel.UpdateProfileButtons then
		self.debugPanel:UpdateProfileButtons()
	end
	SetSUFWindowTitle(self.debugPanel, "|cFF00B0F7SUF Debug Console|r")
	self.debugPanel:Show()
	self.db.profile.debug.showPanel = true
	self:RefreshDebugPanel()
end

function addon:HideDebugPanel()
	if self.debugPanel then
		self.debugPanel:Hide()
	end
	if self.db and self.db.profile and self.db.profile.debug then
		self.db.profile.debug.showPanel = false
	end
end

function addon:ToggleDebugPanel()
	if self.debugPanel and self.debugPanel:IsShown() then
		self:HideDebugPanel()
	else
		self:ShowDebugPanel()
	end
end

function addon:HandleDebugSlash(msg)
	self:EnsureDebugConfig()
	local command = (msg or ""):lower():match("^%s*(.-)%s*$")

	if command == "" then
		self:ToggleDebugPanel()
	elseif command == "on" or command == "enable" then
		self.db.profile.debug.enabled = true
		self:ShowDebugPanel()
	elseif command == "off" or command == "disable" then
		self.db.profile.debug.enabled = false
		self:HideDebugPanel()
	elseif command == "clear" then
		self.debugMessages = {}
		self:RefreshDebugPanel()
	elseif command == "export" then
		self:ShowDebugExportDialog()
	elseif command == "settings" then
		self:ShowDebugSettings()
	elseif command == "help" then
		self:Print(addonName .. ": /sufdebug, /sufdebug on|off|clear|export|settings")
	else
		local systems = self.db.profile.debug.systems
		local matchedKey
		for key in pairs(systems) do
			if key:lower() == command then
				matchedKey = key
				break
			end
		end
		if matchedKey then
			systems[matchedKey] = not systems[matchedKey]
			self:Print(addonName .. ": Debug system " .. matchedKey .. " = " .. tostring(systems[matchedKey]))
		else
			self:Print(addonName .. ": Unknown debug command. Use /sufdebug help")
		end
	end
end

function addon:TogglePerformanceDashboard()
	if self.performanceLib then
		if self.performanceLib.ToggleDashboard then
			self.performanceLib:ToggleDashboard()
			return
		end
		if self.performanceLib.ShowDashboard then
			self.performanceLib:ShowDashboard()
			return
		end
	end
	self:Print(addonName .. ": PerformanceLib dashboard is unavailable.")
end

function addon:ShowLauncherHelp()
	self:Print(addonName .. ": /suf (options)")
	self:Print(addonName .. ": /suf minimap show|hide|toggle|reset")
	self:Print(addonName .. ": /suf perflib")
	self:Print(addonName .. ": /suf debug")
	self:Print(addonName .. ": /suf help")
end

function addon:ApplyLauncherVisibility()
	if not self.db or not self.db.profile then
		return
	end
	self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)

	local function EnsureLibDBIconButtonClicks()
		if not (LibDBIcon and LibDBIcon.GetMinimapButton) then
			return
		end
		local button = LibDBIcon:GetMinimapButton("SimpleUnitFrames")
		if button and button.RegisterForClicks then
			button:RegisterForClicks("AnyUp")
		end
	end

	if self.ldbObject and LibDBIcon then
		if not LibDBIcon:IsRegistered("SimpleUnitFrames") then
			LibDBIcon:Register("SimpleUnitFrames", self.ldbObject, self.db.profile.minimap)
		end
		EnsureLibDBIconButtonClicks()
		if self.db.profile.minimap.hide then
			LibDBIcon:Hide("SimpleUnitFrames")
		else
			LibDBIcon:Show("SimpleUnitFrames")
		end
		if self.minimapButton then
			self.minimapButton:Hide()
		end
		return
	end

	self:CreateFallbackMinimapButton()
	if self.minimapButton then
		self.minimapButton:SetShown(not self.db.profile.minimap.hide)
	end
end

function addon:HandleSUFSlash(msg)
	local input = (msg or ""):match("^%s*(.-)%s*$")
	if input == "" then
		self:ShowOptions()
		return
	end

	local command, rest = input:match("^(%S+)%s*(.-)$")
	command = command and command:lower() or ""
	rest = rest and rest:lower() or ""

	if command == "help" then
		self:ShowLauncherHelp()
		return
	end

	if command == "debug" then
		self:ToggleDebugPanel()
		return
	end

	if command == "perflib" or command == "perf" then
		self:TogglePerformanceDashboard()
		return
	end

	if command == "minimap" or command == "icon" then
		self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)
		if rest == "show" then
			self.db.profile.minimap.hide = false
			self:InitializeLauncher()
			self:Print(addonName .. ": Minimap icon shown.")
			return
		elseif rest == "hide" then
			self.db.profile.minimap.hide = true
			self:ApplyLauncherVisibility()
			self:Print(addonName .. ": Minimap icon hidden.")
			return
		elseif rest == "toggle" then
			self.db.profile.minimap.hide = not self.db.profile.minimap.hide
			self:ApplyLauncherVisibility()
			self:Print(addonName .. ": Minimap icon " .. (self.db.profile.minimap.hide and "hidden." or "shown."))
			return
		elseif rest == "reset" then
			self.db.profile.minimap.hide = false
			self.db.profile.minimap.minimapPos = defaults.profile.minimap.minimapPos
			self:InitializeLauncher()
			self:Print(addonName .. ": Minimap icon reset.")
			return
		else
			self:Print(addonName .. ": /suf minimap show|hide|toggle|reset")
			return
		end
	end

	self:ShowOptions()
end

function addon:ShowLauncherMenu(anchorFrame)
	if (not UIDropDownMenu_Initialize or not ToggleDropDownMenu) and UIParentLoadAddOn then
		pcall(UIParentLoadAddOn, "Blizzard_UIDropDownMenu")
	end

	local function ShowFallbackMenu(anchor)
		if not self.launcherFallbackMenu then
			local menu = CreateFrame("Frame", "SUFLauncherFallbackMenu", UIParent, "BackdropTemplate")
			menu:SetSize(180, 120)
			menu:SetFrameStrata("TOOLTIP")
			menu:SetToplevel(true)
			menu:EnableMouse(true)
			menu:SetClampedToScreen(true)
			menu:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
			})
			menu:SetBackdropColor(0, 0, 0, 0.92)

			local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			title:SetPoint("TOP", menu, "TOP", 0, -10)
			title:SetText("SimpleUnitFrames")

			local function CreateMenuButton(parent, label, y, fn)
				local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
				btn:SetSize(150, 22)
				btn:SetPoint("TOP", parent, "TOP", 0, y)
				btn:SetText(label)
				btn:SetScript("OnClick", function()
					parent:Hide()
					fn()
				end)
				return btn
			end

			CreateMenuButton(menu, "Open SUF Options", -30, function() self:ShowOptions() end)
			CreateMenuButton(menu, "Open PerfLib UI", -56, function() self:TogglePerformanceDashboard() end)
			CreateMenuButton(menu, "Open SUF Debug", -82, function() self:ShowDebugPanel() end)

			menu:SetScript("OnMouseDown", function(_, button)
				if button == "RightButton" then
					menu:Hide()
				end
			end)

			self.launcherFallbackMenu = menu
		end

		local menu = self.launcherFallbackMenu
		menu:ClearAllPoints()
		if type(anchor) == "table" and anchor.GetCenter then
			menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
		else
			local x, y = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale() or 1
			menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
		end
		menu:Show()
	end

	if not UIDropDownMenu_Initialize or not ToggleDropDownMenu then
		ShowFallbackMenu(anchorFrame)
		return
	end

	if not self.launcherDropdown then
		self.launcherDropdown = CreateFrame("Frame", "SUFLauncherDropdown", UIParent, "UIDropDownMenuTemplate")
		self.launcherDropdown.displayMode = "MENU"
	end

	local menu = {
		{ text = "SimpleUnitFrames", isTitle = true, notCheckable = true },
		{ text = "Open SUF Options", notCheckable = true, func = function() self:ShowOptions() end },
		{ text = "Open PerfLib UI", notCheckable = true, func = function() self:TogglePerformanceDashboard() end },
		{ text = "Open SUF Debug", notCheckable = true, func = function() self:ShowDebugPanel() end },
		{ text = "Close", notCheckable = true, func = function() end },
	}

	local anchor = anchorFrame
	if type(anchor) ~= "table" or not anchor.GetObjectType then
		anchor = "cursor"
	end

	UIDropDownMenu_Initialize(self.launcherDropdown, function(_, level)
		if level ~= 1 then
			return
		end
		for i = 1, #menu do
			local info = UIDropDownMenu_CreateInfo()
			for key, value in pairs(menu[i]) do
				info[key] = value
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end, "MENU")

	CloseDropDownMenus()
	ToggleDropDownMenu(1, nil, self.launcherDropdown, anchor, 0, 0)
end

function addon:CreateFallbackMinimapButton()
	if self.minimapButton then
		return
	end

	local button = CreateFrame("Button", "SUFMinimapButton", Minimap)
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	bg:SetSize(54, 54)
	bg:SetPoint("TOPLEFT")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ICON_PATH)
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER")
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local function UpdatePosition()
		if not self.db or not self.db.profile then
			return
		end
		self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)
		local angle = math.rad(self.db.profile.minimap.minimapPos or 220)
		local x = math.cos(angle) * 80
		local y = math.sin(angle) * 80
		button:ClearAllPoints()
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end

	button:SetScript("OnDragStart", function()
		button:StartMoving()
	end)
	button:SetScript("OnDragStop", function()
		button:StopMovingOrSizing()
		local mx, my = Minimap:GetCenter()
		local bx, by = button:GetCenter()
		if mx and my and bx and by then
			local angle = math.deg(math.atan2(by - my, bx - mx))
			self.db.profile.minimap.minimapPos = angle
			UpdatePosition()
		end
	end)
	button:SetMovable(true)

	button:SetScript("OnClick", function(_, mouseButton)
		if IsRightClick(mouseButton) then
			self:ShowLauncherMenu(button)
		else
			self:ShowOptions()
		end
	end)

	button:SetScript("OnEnter", function()
		GameTooltip:SetOwner(button, "ANCHOR_LEFT")
		GameTooltip:SetText("SimpleUnitFrames")
		GameTooltip:AddLine("Left Click: Open Options", 1, 1, 1)
		GameTooltip:AddLine("Right Click: Quick Menu", 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self.minimapButton = button
	UpdatePosition()
end

function addon:InitializeLauncher()
	if not self.db or not self.db.profile then
		return
	end
	self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)

	if LDB and not self.ldbObject then
		self.ldbObject = LDB:NewDataObject("SimpleUnitFrames", {
			type = "launcher",
			text = "SimpleUnitFrames",
			icon = ICON_PATH,
			OnClick = function(frameRef, mouseButton)
				if IsRightClick(mouseButton) then
					self:ShowLauncherMenu(frameRef or "cursor")
				else
					self:ShowOptions()
				end
			end,
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then
					return
				end
				tooltip:AddLine("SimpleUnitFrames")
				tooltip:AddLine("Left Click: Open Options", 1, 1, 1)
				tooltip:AddLine("Right Click: Quick Menu", 1, 1, 1)
			end,
		})
	end

	self:ApplyLauncherVisibility()
end

function addon:IsEditModeActive()
	if C_EditMode and C_EditMode.IsEditModeActive then
		return C_EditMode.IsEditModeActive()
	end

	if _G.EditModeManagerFrame then
		if _G.EditModeManagerFrame.editModeActive then
			return true
		end
		return _G.EditModeManagerFrame:IsShown()
	end

	return false
end

function addon:ScheduleUpdateAll()
	if self.isBuildingOptions then
		return
	end

	if self.updateTimer then
		self.updatePending = true
		return
	end

	self.updateTimer = C_Timer.NewTimer(0.05, function()
		self.updateTimer = nil
		self.updatePending = nil
		self:UpdateAllFrames()
	end)
end

function addon:ScheduleApplyVisibility()
	if self.isBuildingOptions then
		return
	end

	if self.visibilityTimer then
		self.visibilityPending = true
		return
	end

	self.visibilityTimer = C_Timer.NewTimer(0.05, function()
		self.visibilityTimer = nil
		self.visibilityPending = nil
		self:ApplyVisibilityRules()
	end)
end

function addon:StartSpawnTicker()
	if self.spawnTicker then
		return
	end

	self.spawnTicker = C_Timer.NewTicker(1, function()
		if not self.pendingSpawn and not self.pendingGroupHeaders then
			return
		end

		if not InCombatLockdown() and not self:IsEditModeActive() then
			local shouldSpawn = self.pendingSpawn
			local shouldSpawnGroups = self.pendingGroupHeaders
			self.pendingSpawn = nil
			self.pendingGroupHeaders = nil
			self.spawnTicker:Cancel()
			self.spawnTicker = nil
			if shouldSpawn then
				self:SpawnFrames()
			end
			if shouldSpawnGroups then
				self:SpawnGroupHeaders()
			end
		end
	end)
end

function addon:OnSpawnRegen()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:TrySpawnFrames()
	self:TrySpawnGroupHeaders()
end

function addon:TrySpawnFrames()
	if not self.isLoggedIn then
		self.pendingSpawn = true
		return
	end

	if InCombatLockdown() then
		self.pendingSpawn = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnSpawnRegen")
		return
	end

	if self.optionsFrame then
		self.pendingSpawn = true
		return
	end

	if C_EditMode and not _G.EditModeManagerFrame then
		self.pendingSpawn = true
		self:StartSpawnTicker()
		return
	end

	if self:IsEditModeActive() then
		self.pendingSpawn = true
		self:StartSpawnTicker()
		return
	end

	self.pendingSpawn = nil
	if self.spawnTicker then
		self.spawnTicker:Cancel()
		self.spawnTicker = nil
	end

	self:SpawnFrames()
end

function addon:ScheduleGroupHeaders(delay)
	if self.groupHeaderTimer then
		return
	end

	local wait = delay or 0.5
	self.groupHeaderTimer = C_Timer.NewTimer(wait, function()
		self.groupHeaderTimer = nil
		self:TrySpawnGroupHeaders()
	end)
end

function addon:TrySpawnGroupHeaders()
	if not self.isLoggedIn then
		self.pendingGroupHeaders = true
		return
	end

	local inGroup, inRaid = IsInAnyPartyOrRaid()
	local showPartySolo = self.db and self.db.profile and self.db.profile.party and self.db.profile.party.showPlayerWhenSolo
	if not inRaid and not inGroup and not showPartySolo then
		self.pendingGroupHeaders = nil
		return
	end

	if InCombatLockdown() then
		self.pendingGroupHeaders = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnSpawnRegen")
		return
	end

	if self.optionsFrame then
		self.pendingGroupHeaders = true
		return
	end

	if C_EditMode and not _G.EditModeManagerFrame then
		self.pendingGroupHeaders = true
		self:StartSpawnTicker()
		return
	end

	if self:IsEditModeActive() then
		self.pendingGroupHeaders = true
		self:StartSpawnTicker()
		return
	end

	if not self.spawned then
		self.pendingGroupHeaders = true
		self:TrySpawnFrames()
		return
	end

	self.pendingGroupHeaders = nil
	self:SpawnGroupHeaders()
end

function addon:ApplyTags(frame)
	local unitType = frame.sufUnitType
	local tags = self.db.profile.tags[unitType]
	if not tags then
		return
	end

	if frame.NameText then
		frame:Untag(frame.NameText)
		frame:Tag(frame.NameText, tags.name)
	end

	if frame.LevelText then
		frame:Untag(frame.LevelText)
		frame:Tag(frame.LevelText, tags.level)
	end

	if frame.HealthValue then
		frame:Untag(frame.HealthValue)
		frame:Tag(frame.HealthValue, tags.health)
	end

	if frame.PowerValue then
		frame:Untag(frame.PowerValue)
		frame:Tag(frame.PowerValue, tags.power)
	end

	if frame.AdditionalPowerValue then
		frame:Untag(frame.AdditionalPowerValue)
		frame:Tag(frame.AdditionalPowerValue, "[curmana]")
	end

	if frame.AbsorbValue then
		frame:Untag(frame.AbsorbValue)
		local absorbTag = self.db and self.db.profile and self.db.profile.absorbValueTag or "[suf:absorbs:abbr]"
		if absorbTag and absorbTag ~= "" then
			frame:Tag(frame.AbsorbValue, absorbTag)
			frame.AbsorbValue.__isSUFTaggedAbsorb = true
		else
			frame.AbsorbValue:SetText("")
			frame.AbsorbValue.__isSUFTaggedAbsorb = false
		end
	end
end

local function EnsureTextureOutline(bar)
	if not bar then
		return nil
	end
	if bar._sufOutline then
		return bar._sufOutline
	end

	local outline = CreateFrame("Frame", nil, bar)
	outline:SetFrameLevel(bar:GetFrameLevel() + 2)

	local top = outline:CreateTexture(nil, "OVERLAY")
	top:SetColorTexture(0, 0, 0, 0.95)
	top:SetHeight(1)
	top:SetPoint("TOPLEFT")
	top:SetPoint("TOPRIGHT")

	local bottom = outline:CreateTexture(nil, "OVERLAY")
	bottom:SetColorTexture(0, 0, 0, 0.95)
	bottom:SetHeight(1)
	bottom:SetPoint("BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT")

	local left = outline:CreateTexture(nil, "OVERLAY")
	left:SetColorTexture(0, 0, 0, 0.95)
	left:SetWidth(1)
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")

	local right = outline:CreateTexture(nil, "OVERLAY")
	right:SetColorTexture(0, 0, 0, 0.95)
	right:SetWidth(1)
	right:SetPoint("TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT")

	bar._sufOutline = outline
	return outline
end

local function UpdateBarTextureOutline(bar, shown)
	if not bar then
		return
	end
	local outline = EnsureTextureOutline(bar)
	if not outline then
		return
	end

	local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if shown and tex then
		outline:ClearAllPoints()
		outline:SetPoint("TOPLEFT", tex, "TOPLEFT", -1, 1)
		outline:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 1, -1)
		outline:Show()
	else
		outline:Hide()
	end
end

function addon:UpdateAbsorbValue(frame, unitToken)
	if not frame or not frame.AbsorbValue then
		return
	end
	if frame.AbsorbValue.__isSUFTaggedAbsorb then
		return
	end

	local hpCfg = self:GetUnitHealPredictionSettings(frame.sufUnitType)
	if not (hpCfg and hpCfg.enabled and hpCfg.absorbs and hpCfg.absorbs.enabled) then
		frame.AbsorbValue:SetText("")
		return
	end

	local unit = unitToken or frame.unit
	if not unit or not UnitExists or not UnitExists(unit) then
		frame.AbsorbValue:SetText("")
		return
	end

	if type(UnitGetTotalAbsorbs) ~= "function" then
		frame.AbsorbValue:SetText("")
		return
	end

	local absorbValue = SafeNumber(SafeAPICall(UnitGetTotalAbsorbs, unit), 0)
	if absorbValue <= 0 then
		frame.AbsorbValue:SetText("")
		return
	end

	if C_StringUtil and C_StringUtil.TruncateWhenZero then
		local ok, textValue = pcall(C_StringUtil.TruncateWhenZero, absorbValue)
		if ok and textValue and not IsSecretValue(textValue) and textValue ~= "" then
			frame.AbsorbValue:SetText(textValue)
			return
		end
	end

	local okAbbr, abbrText = pcall(FormatCompactValue, absorbValue)
	if okAbbr and abbrText and not IsSecretValue(abbrText) and abbrText ~= "0" then
		frame.AbsorbValue:SetText(abbrText)
		return
	end

	local rawText = SafeText(absorbValue, nil)
	if rawText and rawText ~= "0" then
		frame.AbsorbValue:SetText(rawText)
		return
	end

	frame.AbsorbValue:SetText("")
end

function addon:ApplyMedia(frame)
	local profileStart = debugprofilestop and debugprofilestop() or nil
	local texture = self:GetUnitStatusbarTexture(frame.sufUnitType)
	local font = self:GetFont()
	local sizes = self:GetUnitFontSizes(frame.sufUnitType)
	local castbarCfg = self.db.profile.castbar or {}
	local unitCastbarCfg = self:GetUnitCastbarSettings(frame.sufUnitType)
	local castbarColors = self:GetUnitCastbarColors(frame.sufUnitType)

	if frame.Health then
		frame.Health:SetStatusBarTexture(texture)
	end

	if frame.Power then
		frame.Power:SetStatusBarTexture(texture)
	end

	if frame.PowerBG then
		frame.PowerBG:SetTexture(texture)
		frame.PowerBG:SetVertexColor(0, 0, 0, 0.6)
	end

	if frame.HealthPrediction then
		local hpCfg = self:GetUnitHealPredictionSettings(frame.sufUnitType)
		local incomingCfg = hpCfg.incoming
		local absorbCfg = hpCfg.absorbs
		local healAbsorbCfg = hpCfg.healAbsorbs
		local healthHeight = frame.Health:GetHeight() or 1
		local incomingInset = math.floor((healthHeight * (1 - math.max(0.3, math.min(1, incomingCfg.height or 1)))) * 0.5 + 0.5)
		local absorbInset = math.floor((healthHeight * (1 - math.max(0.3, math.min(1, absorbCfg.height or 1)))) * 0.5 + 0.5)
		local healAbsorbInset = math.floor((healthHeight * (1 - math.max(0.3, math.min(1, healAbsorbCfg.height or 1)))) * 0.5 + 0.5)

		local statusTex = frame.Health:GetStatusBarTexture()

		if frame.HealthPrediction.healingAll then
			frame.HealthPrediction.healingAll:SetStatusBarTexture(texture)
			local c = incomingCfg.colorAll
			frame.HealthPrediction.healingAll:SetStatusBarColor(c[1] or 0.35, c[2] or 0.95, c[3] or 0.45, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			frame.HealthPrediction.healingAll:ClearAllPoints()
			frame.HealthPrediction.healingAll:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			frame.HealthPrediction.healingAll:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			frame.HealthPrediction.healingAll:SetPoint("LEFT", statusTex, "RIGHT")
			local shownAll = hpCfg.enabled and incomingCfg.enabled and not incomingCfg.split
			frame.HealthPrediction.healingAll:SetShown(shownAll)
			UpdateBarTextureOutline(frame.HealthPrediction.healingAll, shownAll)
		end
		if frame.HealthPrediction.healingPlayer then
			frame.HealthPrediction.healingPlayer:SetStatusBarTexture(texture)
			local c = incomingCfg.colorPlayer
			frame.HealthPrediction.healingPlayer:SetStatusBarColor(c[1] or 0.35, c[2] or 0.95, c[3] or 0.45, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			frame.HealthPrediction.healingPlayer:ClearAllPoints()
			frame.HealthPrediction.healingPlayer:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			frame.HealthPrediction.healingPlayer:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			frame.HealthPrediction.healingPlayer:SetPoint("LEFT", statusTex, "RIGHT")
			local shownPlayer = hpCfg.enabled and incomingCfg.enabled and incomingCfg.split
			frame.HealthPrediction.healingPlayer:SetShown(shownPlayer)
			UpdateBarTextureOutline(frame.HealthPrediction.healingPlayer, shownPlayer)
		end
		if frame.HealthPrediction.healingOther then
			frame.HealthPrediction.healingOther:SetStatusBarTexture(texture)
			local c = incomingCfg.colorOther
			frame.HealthPrediction.healingOther:SetStatusBarColor(c[1] or 0.20, c[2] or 0.75, c[3] or 0.35, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			frame.HealthPrediction.healingOther:ClearAllPoints()
			frame.HealthPrediction.healingOther:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			frame.HealthPrediction.healingOther:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			local healAnchor = frame.HealthPrediction.healingPlayer and frame.HealthPrediction.healingPlayer:GetStatusBarTexture() or statusTex
			frame.HealthPrediction.healingOther:SetPoint("LEFT", healAnchor, "RIGHT")
			local shownOther = hpCfg.enabled and incomingCfg.enabled and incomingCfg.split
			frame.HealthPrediction.healingOther:SetShown(shownOther)
			UpdateBarTextureOutline(frame.HealthPrediction.healingOther, shownOther)
		end
		if frame.HealthPrediction.damageAbsorb then
			frame.HealthPrediction.damageAbsorb:SetStatusBarTexture(texture)
			local c = absorbCfg.color
			frame.HealthPrediction.damageAbsorb:SetStatusBarColor(c[1] or 0.35, c[2] or 0.92, c[3] or 1.00, math.max(0.20, math.min(1, (absorbCfg.opacity or 0.55) + 0.15)))
			frame.HealthPrediction.damageAbsorb:ClearAllPoints()
			frame.HealthPrediction.damageAbsorb:SetPoint("TOP", frame.Health, "TOP", 0, -absorbInset)
			frame.HealthPrediction.damageAbsorb:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, absorbInset)
			frame.HealthPrediction.damageAbsorb:SetPoint("RIGHT", statusTex, "RIGHT")
			frame.HealthPrediction.damageAbsorb:SetReverseFill(true)
			frame.HealthPrediction.damageAbsorb:SetShown(hpCfg.enabled and absorbCfg.enabled)
		end
		if frame.HealthPrediction.healAbsorb then
			frame.HealthPrediction.healAbsorb:SetStatusBarTexture(texture)
			local c = healAbsorbCfg.color
			frame.HealthPrediction.healAbsorb:SetStatusBarColor(c[1] or 0.95, c[2] or 0.25, c[3] or 0.25, math.max(0.05, math.min(1, healAbsorbCfg.opacity or 0.55)))
			frame.HealthPrediction.healAbsorb:ClearAllPoints()
			frame.HealthPrediction.healAbsorb:SetPoint("TOP", frame.Health, "TOP", 0, -healAbsorbInset)
			frame.HealthPrediction.healAbsorb:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, healAbsorbInset)
			frame.HealthPrediction.healAbsorb:SetPoint("RIGHT", statusTex, "LEFT")
			frame.HealthPrediction.healAbsorb:SetShown(hpCfg.enabled and healAbsorbCfg.enabled)
		end
		if frame.HealthPrediction.overDamageAbsorbIndicator then
			frame.HealthPrediction.overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
			frame.HealthPrediction.overDamageAbsorbIndicator:SetBlendMode("ADD")
			frame.HealthPrediction.overDamageAbsorbIndicator:SetVertexColor(1, 1, 1, math.max(0.25, math.min(1, absorbCfg.glowOpacity or 0.95)))
			frame.HealthPrediction.overDamageAbsorbIndicator:SetShown(hpCfg.enabled and absorbCfg.enabled and absorbCfg.showGlow ~= false)
		end
		if frame.HealthPrediction.overHealAbsorbIndicator then
			frame.HealthPrediction.overHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
			frame.HealthPrediction.overHealAbsorbIndicator:SetBlendMode("ADD")
			frame.HealthPrediction.overHealAbsorbIndicator:SetVertexColor(1, 1, 1, math.max(0.1, math.min(1, healAbsorbCfg.glowOpacity or 0.95)))
			frame.HealthPrediction.overHealAbsorbIndicator:SetShown(hpCfg.enabled and healAbsorbCfg.enabled and healAbsorbCfg.showGlow ~= false)
		end

		self:UpdateAbsorbValue(frame)
	end

	if frame.AdditionalPower then
		frame.AdditionalPower:SetStatusBarTexture(texture)
	end

	if frame.AdditionalPowerBG then
		frame.AdditionalPowerBG:SetTexture(texture)
		frame.AdditionalPowerBG:SetVertexColor(0, 0, 0, 0.6)
	end

	if frame.Castbar then
		local castbarEnabled = unitCastbarCfg.enabled ~= false
		frame.Castbar:SetShown(castbarEnabled)
		if castbarEnabled then
			frame.Castbar:SetReverseFill(unitCastbarCfg.reverseFill == true)
			frame.Castbar:SetStatusBarTexture(texture)
			if frame.Castbar.Bg then
				frame.Castbar.Bg:SetTexture(texture)
				local bg = castbarColors.background or { 0, 0, 0, 0.55 }
				frame.Castbar.Bg:SetVertexColor(bg[1] or 0, bg[2] or 0, bg[3] or 0, bg[4] or 0.55)
			end
			local castingColor = castbarColors.casting or { 1, 0.7, 0 }
			frame.Castbar:SetStatusBarColor(castingColor[1] or 1, castingColor[2] or 0.7, castingColor[3] or 0)
			if frame.Castbar.Text then
				frame.Castbar.Text:SetShown(unitCastbarCfg.showText ~= false)
				frame.Castbar.Text:SetFont(font, sizes.cast, "OUTLINE")
			end
			if frame.Castbar.Time then
				frame.Castbar.Time:SetShown(unitCastbarCfg.showTime ~= false)
				frame.Castbar.Time:SetFont(font, sizes.cast, "OUTLINE")
			end
			if frame.Castbar.Icon then
				frame.Castbar.Icon:SetShown(castbarCfg.iconEnabled ~= false)
				frame.Castbar.Icon:SetSize(castbarCfg.iconSize or 20, castbarCfg.iconSize or 20)
				frame.Castbar.Icon:ClearAllPoints()
				local gap = castbarCfg.iconGap or 2
				if castbarCfg.iconPosition == "RIGHT" then
					frame.Castbar.Icon:SetPoint("LEFT", frame.Castbar, "RIGHT", gap, 0)
				else
					frame.Castbar.Icon:SetPoint("RIGHT", frame.Castbar, "LEFT", -gap, 0)
				end
			end
			if frame.Castbar.SafeZone then
				frame.Castbar.SafeZone:SetColorTexture(1, 0.2, 0.2, castbarCfg.safeZoneAlpha or 0.35)
				frame.Castbar.SafeZone:SetShown(castbarCfg.showSafeZone ~= false and frame.unit == "player")
			end
			if frame.Castbar.Spark then
				frame.Castbar.Spark:SetShown(castbarCfg.showSpark ~= false)
			end
			if frame.Castbar.Shield then
				frame.Castbar.Shield:SetShown(castbarCfg.showShield ~= false)
			end

			local function UpdateInterruptVisual(castbar)
				local isHostile = UnitCanAttack and castbar.unit and UnitCanAttack("player", castbar.unit)
				local isWatchedUnit = frame.sufUnitType == "target" or frame.sufUnitType == "boss"
				local interruptible = self:GetUnitInterruptState(castbar.unit)
				if not isHostile or not isWatchedUnit or interruptible == nil then
					return
				end

				if interruptible then
					local activeColor = castbar.channeling and (castbarColors.channeling or castbarColors.casting) or castbarColors.casting
					activeColor = activeColor or { 1, 0.7, 0 }
					castbar:SetStatusBarColor(activeColor[1] or 1, activeColor[2] or 0.7, activeColor[3] or 0)
					if castbar.Shield then
						castbar.Shield:SetShown(false)
					end
				else
					local niColor = castbarColors.nonInterruptible or { 0.75, 0.75, 0.75 }
					castbar:SetStatusBarColor(niColor[1] or 0.75, niColor[2] or 0.75, niColor[3] or 0.75)
					if castbar.Shield then
						castbar.Shield:SetShown(castbarCfg.showShield ~= false)
					end
				end
			end

			frame.Castbar.CustomTimeText = function(castbar, durationObject)
				if not castbar.Time then
					return
				end
				if unitCastbarCfg.showTime == false then
					castbar.Time:SetText("")
					return
				end
				local decimals = math.max(0, math.min(2, tonumber(castbarCfg.timeDecimals) or 1))
				local fmt = "%." .. decimals .. "f"
				local remaining = durationObject and SafeNumber(SafeAPICall(durationObject.GetRemainingDuration, durationObject), nil)
				if remaining == nil then
					castbar.Time:SetText("")
					return
				end
				castbar.Time:SetFormattedText(fmt, remaining)
			end
			frame.Castbar.CustomDelayText = function(castbar, durationObject)
				if not castbar.Time then
					return
				end
				if unitCastbarCfg.showTime == false then
					castbar.Time:SetText("")
					return
				end
				local decimals = math.max(0, math.min(2, tonumber(castbarCfg.timeDecimals) or 1))
				local baseFmt = "%." .. decimals .. "f"
				local delayFmt = "%." .. math.max(1, decimals + 1) .. "f"
				local remaining = durationObject and SafeNumber(SafeAPICall(durationObject.GetRemainingDuration, durationObject), nil)
				if remaining == nil then
					castbar.Time:SetText("")
					return
				end
				local delayValue = SafeNumber(castbar.delay, 0)
				if castbarCfg.showDelay == false then
					castbar.Time:SetFormattedText(baseFmt, remaining)
					return
				end
				local sign = SafeBoolean(castbar.channeling, false) and "-" or "+"
				castbar.Time:SetFormattedText(baseFmt .. "|cffff0000%s" .. delayFmt .. "|r", remaining, sign, delayValue)
			end
			frame.Castbar.PostCastStart = function(castbar)
				local color = castbarColors.casting or { 1, 0.7, 0 }
				castbar:SetStatusBarColor(color[1] or 1, color[2] or 0.7, color[3] or 0)
				UpdateInterruptVisual(castbar)
				if not castbar.Text then
					return
				end
				if unitCastbarCfg.showText == false then
					castbar.Text:SetText("")
					return
				end
				local maxChars = math.max(6, tonumber(castbarCfg.spellMaxChars) or 18)
				local rawName = castbar.spellName or (castbar.Text and castbar.Text.GetText and castbar.Text:GetText()) or ""
				if IsSecretValue(rawName) then
					castbar.Text:SetText("")
					return
				end
				local spellName = SafeText(rawName, "")
				if #spellName > maxChars then
					spellName = spellName:sub(1, maxChars - 3) .. "..."
				end
				castbar.Text:SetText(spellName)
			end
			frame.Castbar.PostChannelStart = function(castbar)
				local color = castbarColors.channeling or castbarColors.casting or { 0.2, 0.6, 1 }
				castbar:SetStatusBarColor(color[1] or 0.2, color[2] or 0.6, color[3] or 1)
				UpdateInterruptVisual(castbar)
			end
			frame.Castbar.PostCastInterruptible = function(castbar)
				local color = castbar.channeling and (castbarColors.channeling or castbarColors.casting) or castbarColors.casting
				color = color or { 1, 0.7, 0 }
				castbar:SetStatusBarColor(color[1] or 1, color[2] or 0.7, color[3] or 0)
				if castbar.Shield then
					castbar.Shield:SetShown(false)
				end
			end
			frame.Castbar.PostCastNotInterruptible = function(castbar)
				local color = castbarColors.nonInterruptible or { 0.75, 0.75, 0.75 }
				castbar:SetStatusBarColor(color[1] or 0.75, color[2] or 0.75, color[3] or 0.75)
				if castbar.Shield then
					castbar.Shield:SetShown(castbarCfg.showShield ~= false)
				end
			end
			frame.Castbar.PostCastFailed = function(castbar)
				local color = castbarColors.failed or { 1, 0.1, 0.1 }
				castbar:SetStatusBarColor(color[1] or 1, color[2] or 0.1, color[3] or 0.1)
			end
			frame.Castbar.PostCastInterrupted = frame.Castbar.PostCastFailed
			frame.Castbar.PostCastStop = function(castbar)
				local color = castbarColors.complete or { 0, 1, 0 }
				castbar:SetStatusBarColor(color[1] or 0, color[2] or 1, color[3] or 0)
			end
		else
			if frame.Castbar.Text then
				frame.Castbar.Text:SetText("")
			end
			if frame.Castbar.Time then
				frame.Castbar.Time:SetText("")
			end
		end
	end

	if frame.ClassPower then
		for _, bar in ipairs(frame.ClassPower) do
			bar:SetStatusBarTexture(texture)
		end
	end

	if frame.NameText then
		frame.NameText:SetFont(font, sizes.name, "OUTLINE")
	end

	if frame.LevelText then
		frame.LevelText:SetFont(font, sizes.level, "OUTLINE")
	end

	if frame.HealthValue then
		frame.HealthValue:SetFont(font, sizes.health, "OUTLINE")
	end

	if frame.AbsorbValue then
		frame.AbsorbValue:SetFont(font, math.max(8, sizes.health - 1), "OUTLINE")
		frame.AbsorbValue:SetTextColor(0.45, 0.95, 1.00, 0.95)
	end

	if frame.PowerValue then
		frame.PowerValue:SetFont(font, sizes.power, "OUTLINE")
	end

	if frame.AdditionalPowerValue then
		frame.AdditionalPowerValue:SetFont(font, math.max(8, sizes.power - 1), "OUTLINE")
	end

	if profileStart then
		local profileEnd = debugprofilestop() or profileStart
		self:RecordProfilerEvent("suf:apply.media", profileEnd - profileStart)
	end
end

function addon:ApplyIndicators(frame)
	local settings = self:GetUnitSettings(frame.sufUnitType)
	local indicators = self.db.profile.indicators
	local size = indicators.size or 24
	local offsetX = indicators.offsetX or 4
	local offsetY = indicators.offsetY or -7

	if frame.RestingIndicator then
		frame.RestingIndicator:SetSize(size, size)
		frame.RestingIndicator:ClearAllPoints()
		frame.RestingIndicator:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -offsetX, offsetY)
		if settings.showResting then
			frame.RestingIndicator:Show()
			if frame.EnableElement then
				frame:EnableElement("RestingIndicator")
			end
		else
			frame.RestingIndicator:Hide()
			if frame.DisableElement then
				frame:DisableElement("RestingIndicator")
			end
		end
	end

	if frame.PvPIndicator then
		frame.PvPIndicator:SetSize(size, size)
		frame.PvPIndicator:ClearAllPoints()
		frame.PvPIndicator:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", offsetX, offsetY)
		if settings.showPvp then
			frame.PvPIndicator:Show()
			if frame.EnableElement then
				frame:EnableElement("PvPIndicator")
			end
		else
			frame.PvPIndicator:Hide()
			if frame.DisableElement then
				frame:DisableElement("PvPIndicator")
			end
		end
	end
end

function addon:ApplyPortrait(frame)
	local settings = self:GetUnitSettings(frame.sufUnitType)
	local portrait = settings.portrait or { mode = "none", size = 0, position = "LEFT", showClass = false, motion = false }

	if frame.Portrait2D then
		frame.Portrait2D:Hide()
	end
	if frame.Portrait3D then
		frame.Portrait3D:Hide()
		frame.Portrait3D:SetScript("OnUpdate", nil)
	end

	if portrait.mode == "none" then
		if frame.DisableElement then
			frame:DisableElement("Portrait")
		end
		return
	end

	local widget
	if portrait.mode == "2D" then
		widget = frame.Portrait2D
	elseif portrait.mode == "3D" or portrait.mode == "3DMotion" then
		widget = frame.Portrait3D
	end

	if not widget then
		return
	end

	widget:ClearAllPoints()
	if portrait.position == "RIGHT" then
		widget:SetPoint("LEFT", frame, "RIGHT", 4, 0)
	else
		widget:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	end
	widget:SetSize(portrait.size, portrait.size)
	widget.showClass = portrait.showClass
	widget:Show()

	frame.Portrait = widget
	if frame.EnableElement then
		frame:EnableElement("Portrait")
	end

	if portrait.mode == "3DMotion" and widget.SetFacing then
		local facing = 0
		widget:SetScript("OnUpdate", function(_, elapsed)
			facing = facing + elapsed * 0.5
			widget:SetFacing(facing)
		end)
	end
end

function addon:LayoutClassPower(frame)
	if not (frame.ClassPowerAnchor and frame.ClassPower) then
		return
	end

	local count = #frame.ClassPower
	if count == 0 then
		return
	end

	local spacing = self.db.profile.classPowerSpacing
	local totalWidth = frame:GetWidth()
	local barWidth = math.floor((totalWidth - spacing * (count - 1)) / count)
	if barWidth < 4 then
		barWidth = 4
	end

	for index, bar in ipairs(frame.ClassPower) do
		bar:ClearAllPoints()
		if index == 1 then
			bar:SetPoint("TOPLEFT", frame.ClassPowerAnchor, "TOPLEFT", 0, 0)
		else
			bar:SetPoint("LEFT", frame.ClassPower[index - 1], "RIGHT", spacing, 0)
		end
		bar:SetWidth(barWidth)
	end
end

function addon:ApplySize(frame)
	local profileStart = debugprofilestop and debugprofilestop() or nil
	local unitType = frame.sufUnitType
	local size = self.db.profile.sizes[unitType]
	local unitLayout = self:GetUnitLayoutSettings(unitType)
	if not size then
		return
	end

	frame:SetSize(size.width, size.height)

	if frame.Health then
		frame.Health:SetHeight(size.height)
	end

	if frame.Power then
		frame.Power:SetHeight(self.db.profile.powerHeight)
	end

	if frame.AdditionalPower then
		frame.AdditionalPower:SetHeight(math.max(4, math.floor(self.db.profile.powerHeight * 0.7)))
		frame.AdditionalPower:ClearAllPoints()
		local secondaryGap = math.max(-6, math.min(24, math.floor((unitLayout.secondaryToFrame or 0) + 0.5)))
		frame.AdditionalPower:SetPoint("BOTTOMLEFT", frame.Health, "TOPLEFT", 0, secondaryGap)
		frame.AdditionalPower:SetPoint("BOTTOMRIGHT", frame.Health, "TOPRIGHT", 0, secondaryGap)
	end

	if frame.Castbar then
		local castbarUnit = self:GetUnitCastbarSettings(unitType)
		local widthPercent = tonumber(castbarUnit.widthPercent) or 100
		widthPercent = math.max(50, math.min(150, widthPercent))
		local castbarWidth = math.max(40, math.floor((size.width * widthPercent / 100) + 0.5))
		local castbarGap = math.max(0, tonumber(castbarUnit.gap) or 8)
		local castbarFineOffset = tonumber(castbarUnit.offsetY) or 0
		local anchorMode = castbarUnit.anchor or "BELOW_FRAME"
		local offsetY = ((anchorMode == "ABOVE_FRAME") and castbarGap or (-castbarGap)) + castbarFineOffset

		frame.Castbar:SetHeight(self.db.profile.castbarHeight)
		frame.Castbar:SetWidth(castbarWidth)
		frame.Castbar:ClearAllPoints()
		if anchorMode == "ABOVE_FRAME" then
			frame.Castbar:SetPoint("BOTTOM", frame, "TOP", 0, offsetY)
		elseif anchorMode == "BELOW_CLASSPOWER" and frame.ClassPowerAnchor then
			frame.Castbar:SetPoint("TOP", frame.ClassPowerAnchor, "BOTTOM", 0, offsetY)
		else
			local bottomAnchor = frame.Power or frame
			frame.Castbar:SetPoint("TOP", bottomAnchor, "BOTTOM", 0, offsetY)
		end
	end

	if frame.ClassPowerAnchor and frame.ClassPower then
		frame.ClassPowerAnchor:ClearAllPoints()
		local classGap = math.max(-6, math.min(24, math.floor((unitLayout.classToSecondary or 0) + 0.5)))
		if frame.AdditionalPower then
			frame.ClassPowerAnchor:SetPoint("BOTTOMLEFT", frame.AdditionalPower, "TOPLEFT", 0, classGap)
			frame.ClassPowerAnchor:SetPoint("BOTTOMRIGHT", frame.AdditionalPower, "TOPRIGHT", 0, classGap)
		else
			frame.ClassPowerAnchor:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, classGap)
			frame.ClassPowerAnchor:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, classGap)
		end
		frame.ClassPowerAnchor:SetHeight(self.db.profile.classPowerHeight)
		for _, bar in ipairs(frame.ClassPower) do
			bar:SetHeight(self.db.profile.classPowerHeight)
		end
		self:LayoutClassPower(frame)
	end

	if frame.Auras then
		local auraSize = self:GetUnitAuraSize(frame.sufUnitType)
		frame.Auras.size = auraSize
		frame.Auras.width = auraSize
		frame.Auras.height = auraSize
		frame.Auras:SetHeight(auraSize + 2)
		frame.Auras:ClearAllPoints()

		local topAnchor = frame
		if frame.AdditionalPower and frame.AdditionalPower.IsShown and frame.AdditionalPower:IsShown() then
			topAnchor = frame.AdditionalPower
		end
		if frame.ClassPowerAnchor and HasVisibleClassPower(frame) then
			topAnchor = frame.ClassPowerAnchor
		end

		frame.Auras:SetPoint("BOTTOMLEFT", topAnchor, "TOPLEFT", 0, 4)
		frame.Auras:SetPoint("BOTTOMRIGHT", topAnchor, "TOPRIGHT", 0, 4)
	end

	if profileStart then
		local profileEnd = debugprofilestop() or profileStart
		self:RecordProfilerEvent("suf:apply.size", profileEnd - profileStart)
	end
end

function addon:UpdateAllFrames()
	local totalStart = debugprofilestop and debugprofilestop() or nil
	for _, frame in ipairs(self.frames) do
		local frameStart = debugprofilestop and debugprofilestop() or nil
		self:ApplyTags(frame)
		self:ApplyMedia(frame)
		self:ApplySize(frame)
		self:ApplyIndicators(frame)
		self:ApplyPortrait(frame)
		frame:UpdateAllElements("SimpleUnitFrames_Update")
		self:UpdateAbsorbValue(frame)
		if frame.HealthPrediction and frame.HealthPrediction.ForceUpdate then
			pcall(frame.HealthPrediction.ForceUpdate, frame.HealthPrediction)
		end
		if frameStart then
			local frameEnd = debugprofilestop() or frameStart
			self:RecordProfilerEvent("suf:update.frame", frameEnd - frameStart)
		end
	end
	if totalStart then
		local totalEnd = debugprofilestop() or totalStart
		self:RecordProfilerEvent("suf:update.all", totalEnd - totalStart)
	end
end

function addon:EnsureRuntimePools()
	if self._runtimePoolsReady then
		return
	end

	if not self:IsPerformanceIntegrationEnabled() then
		return
	end

	local indicatorPooling = self.performanceLib and self.performanceLib.IndicatorPooling
	if indicatorPooling and indicatorPooling.CreatePool then
		indicatorPooling:CreatePool("SUF_RestingIndicator", function(parent)
			local tex = parent:CreateTexture(nil, "OVERLAY")
			tex:SetDrawLayer("OVERLAY", 7)
			return tex
		end, function(tex)
			tex:SetTexture(nil)
			tex:SetTexCoord(0, 1, 0, 1)
		end)

		indicatorPooling:CreatePool("SUF_PvPIndicator", function(parent)
			local tex = parent:CreateTexture(nil, "OVERLAY")
			tex:SetDrawLayer("OVERLAY", 7)
			return tex
		end, function(tex)
			tex:SetTexture(nil)
			tex:SetTexCoord(0, 1, 0, 1)
		end)
	end

	self._runtimePoolsReady = true
end

function addon:AcquireRuntimeFrame(frameType, parent, poolType)
	if self:IsPerformanceIntegrationEnabled() and self.performanceLib and self.performanceLib.AcquireFrame then
		local ok, frame = pcall(self.performanceLib.AcquireFrame, self.performanceLib, frameType, parent, poolType)
		if ok and frame then
			frame.__sufPooledFrame = true
			frame.__sufPoolType = poolType
			frame:ClearAllPoints()
			return frame
		end
	end

	local frame = CreateFrame(frameType, nil, parent)
	frame.__sufPooledFrame = false
	frame.__sufPoolType = nil
	return frame
end

function addon:AcquireRuntimeIndicator(poolName, parent)
	local indicatorPooling = self.performanceLib and self.performanceLib.IndicatorPooling
	if self:IsPerformanceIntegrationEnabled() and indicatorPooling and indicatorPooling.AcquireIndicator then
		self:EnsureRuntimePools()
		local ok, indicator = pcall(indicatorPooling.AcquireIndicator, indicatorPooling, poolName, parent)
		if ok and indicator then
			indicator.__sufPoolName = poolName
			return indicator
		end
	end

	local indicator = parent:CreateTexture(nil, "OVERLAY")
	indicator:SetDrawLayer("OVERLAY", 7)
	indicator.__sufPoolName = nil
	return indicator
end

function addon:ReleaseRuntimeIndicator(indicator)
	if not indicator then
		return
	end

	local poolName = indicator.__sufPoolName
	local indicatorPooling = self.performanceLib and self.performanceLib.IndicatorPooling
	if poolName and indicatorPooling and indicatorPooling.ReleaseIndicator then
		pcall(indicatorPooling.ReleaseIndicator, indicatorPooling, poolName, indicator)
		return
	end

	indicator:Hide()
end

function addon:ReleaseFramePooledResources(frame)
	if not frame then
		return
	end

	if frame.RestingIndicator then
		self:ReleaseRuntimeIndicator(frame.RestingIndicator)
		frame.RestingIndicator = nil
	end

	if frame.PvPIndicator then
		self:ReleaseRuntimeIndicator(frame.PvPIndicator)
		frame.PvPIndicator = nil
	end

	if frame.IndicatorFrame and frame.IndicatorFrame.__sufPooledFrame and self.performanceLib and self.performanceLib.ReleaseFrame then
		pcall(self.performanceLib.ReleaseFrame, self.performanceLib, frame.IndicatorFrame)
	end
	frame.IndicatorFrame = nil

	if frame.TextOverlay and frame.TextOverlay.__sufPooledFrame and self.performanceLib and self.performanceLib.ReleaseFrame then
		pcall(self.performanceLib.ReleaseFrame, self.performanceLib, frame.TextOverlay)
	end
	frame.TextOverlay = nil

	if frame.Auras then
		for i = 1, #frame.Auras do
			local button = frame.Auras[i]
			if button and button.__sufPooledFrame and self.performanceLib and self.performanceLib.ReleaseFrame then
				pcall(self.performanceLib.ReleaseFrame, self.performanceLib, button)
			end
			frame.Auras[i] = nil
		end
	end
	if frame.Auras and frame.Auras.__sufPooledFrame and self.performanceLib and self.performanceLib.ReleaseFrame then
		pcall(self.performanceLib.ReleaseFrame, self.performanceLib, frame.Auras)
	end
	frame.Auras = nil
end

function addon:ReleaseAllPooledResources()
	for _, frame in ipairs(self.frames or {}) do
		self:ReleaseFramePooledResources(frame)
	end
	self._runtimePoolsReady = nil
end

local function CreateCastbar(self, height, anchor)
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture(DEFAULT_TEXTURE)
	Castbar:SetHeight(height)
	if anchor then
		Castbar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
		Castbar:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -8)
	else
		Castbar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -8)
		Castbar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -8)
	end

	local Text = CreateFontString(Castbar, 10, "OUTLINE")
	Text:SetPoint("LEFT", Castbar, "LEFT", 4, 0)
	Text:SetJustifyH("LEFT")

	local Time = CreateFontString(Castbar, 10, "OUTLINE")
	Time:SetPoint("RIGHT", Castbar, "RIGHT", -4, 0)
	Time:SetJustifyH("RIGHT")

	local Bg = Castbar:CreateTexture(nil, "BACKGROUND")
	Bg:SetAllPoints(Castbar)
	Bg:SetTexture(DEFAULT_TEXTURE)
	Bg:SetVertexColor(0, 0, 0, 0.55)

	local Icon = Castbar:CreateTexture(nil, "ARTWORK")
	Icon:SetSize(20, 20)
	Icon:SetPoint("RIGHT", Castbar, "LEFT", -2, 0)
	Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local SafeZone = Castbar:CreateTexture(nil, "ARTWORK")
	SafeZone:SetColorTexture(1, 0.2, 0.2, 0.35)
	SafeZone:SetPoint("TOPRIGHT", Castbar, "TOPRIGHT")
	SafeZone:SetPoint("BOTTOMRIGHT", Castbar, "BOTTOMRIGHT")
	SafeZone:SetWidth(0)

	local Shield = Castbar:CreateTexture(nil, "OVERLAY")
	Shield:SetAllPoints(Castbar)
	Shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
	Shield:SetBlendMode("ADD")

	local Spark = Castbar:CreateTexture(nil, "OVERLAY")
	Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	Spark:SetBlendMode("ADD")
	Spark:SetSize(18, height + 10)
	Spark:SetPoint("CENTER", Castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
	Castbar:SetScript("OnSizeChanged", function(bar)
		if bar.Spark then
			bar.Spark:SetHeight(bar:GetHeight() + 10)
		end
	end)

	Castbar.Text = Text
	Castbar.Time = Time
	Castbar.Bg = Bg
	Castbar.Icon = Icon
	Castbar.SafeZone = SafeZone
	Castbar.Shield = Shield
	Castbar.Spark = Spark
	self.Castbar = Castbar
end

local function CreateClassPower(self, height)
	local ClassPower = {}
	local anchor = CreateFrame("Frame", nil, self)
	anchor:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
	anchor:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)
	anchor:SetHeight(height)

	for index = 1, 10 do
		local bar = CreateFrame("StatusBar", nil, anchor)
		bar:SetStatusBarTexture(DEFAULT_TEXTURE)
		bar:SetHeight(height)
		bar:SetPoint("TOPLEFT", anchor, "TOPLEFT", (index - 1) * 18, 0)
		bar:SetWidth(16)
		ClassPower[index] = bar
	end

	self.ClassPower = ClassPower
	self.ClassPowerAnchor = anchor
end

local function CreateHealthPrediction(self)
	if not self.Health then
		return
	end
	local predictionLevel = (self.Health:GetFrameLevel() or 1) + 1

	local healingAll = CreateFrame("StatusBar", nil, self.Health)
	healingAll:SetPoint("TOP")
	healingAll:SetPoint("BOTTOM")
	healingAll:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	healingAll:SetWidth(self.Health:GetWidth())
	healingAll:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingAll:SetStatusBarColor(0.35, 0.95, 0.45, 0.40)
	healingAll:SetFrameLevel(predictionLevel)

	local healingPlayer = CreateFrame("StatusBar", nil, self.Health)
	healingPlayer:SetPoint("TOP")
	healingPlayer:SetPoint("BOTTOM")
	healingPlayer:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	healingPlayer:SetWidth(self.Health:GetWidth())
	healingPlayer:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingPlayer:SetStatusBarColor(0.35, 0.95, 0.45, 0.40)
	healingPlayer:SetFrameLevel(predictionLevel)

	local healingOther = CreateFrame("StatusBar", nil, self.Health)
	healingOther:SetPoint("TOP")
	healingOther:SetPoint("BOTTOM")
	healingOther:SetPoint("LEFT", healingPlayer:GetStatusBarTexture(), "RIGHT")
	healingOther:SetWidth(self.Health:GetWidth())
	healingOther:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingOther:SetStatusBarColor(0.20, 0.75, 0.35, 0.40)
	healingOther:SetFrameLevel(predictionLevel)

	local damageAbsorb = CreateFrame("StatusBar", nil, self.Health)
	damageAbsorb:SetPoint("TOP")
	damageAbsorb:SetPoint("BOTTOM")
	damageAbsorb:SetPoint("RIGHT", self.Health:GetStatusBarTexture(), "RIGHT")
	damageAbsorb:SetWidth(self.Health:GetWidth())
	damageAbsorb:SetReverseFill(true)
	damageAbsorb:SetStatusBarTexture(DEFAULT_TEXTURE)
	damageAbsorb:SetStatusBarColor(0.35, 0.92, 1.00, 0.70)
	damageAbsorb:SetFrameLevel(predictionLevel)

	local healAbsorb = CreateFrame("StatusBar", nil, self.Health)
	healAbsorb:SetPoint("TOP")
	healAbsorb:SetPoint("BOTTOM")
	healAbsorb:SetPoint("RIGHT", self.Health:GetStatusBarTexture(), "LEFT")
	healAbsorb:SetWidth(self.Health:GetWidth())
	healAbsorb:SetReverseFill(true)
	healAbsorb:SetStatusBarTexture(DEFAULT_TEXTURE)
	healAbsorb:SetStatusBarColor(0.95, 0.25, 0.25, 0.55)
	healAbsorb:SetFrameLevel(predictionLevel)

	local overDamageAbsorbIndicator = self.Health:CreateTexture(nil, "OVERLAY")
	overDamageAbsorbIndicator:SetPoint("TOP")
	overDamageAbsorbIndicator:SetPoint("BOTTOM")
	overDamageAbsorbIndicator:SetPoint("RIGHT", self.Health, "RIGHT", 7, 0)
	overDamageAbsorbIndicator:SetWidth(12)
	overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	overDamageAbsorbIndicator:SetBlendMode("ADD")
	overDamageAbsorbIndicator:SetVertexColor(1, 1, 1, 0.95)

	local overHealAbsorbIndicator = self.Health:CreateTexture(nil, "OVERLAY")
	overHealAbsorbIndicator:SetPoint("TOP")
	overHealAbsorbIndicator:SetPoint("BOTTOM")
	overHealAbsorbIndicator:SetPoint("LEFT", self.Health, "LEFT", -7, 0)
	overHealAbsorbIndicator:SetWidth(12)
	overHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
	overHealAbsorbIndicator:SetBlendMode("ADD")
	overHealAbsorbIndicator:SetVertexColor(1, 1, 1, 0.95)

	self.HealthPrediction = {
		healingAll = healingAll,
		healingPlayer = healingPlayer,
		healingOther = healingOther,
		damageAbsorb = damageAbsorb,
		damageAbsorbClampMode = 2,
		healAbsorb = healAbsorb,
		healAbsorbClampMode = 1,
		healAbsorbMode = 1,
		overDamageAbsorbIndicator = overDamageAbsorbIndicator,
		overHealAbsorbIndicator = overHealAbsorbIndicator,
		incomingHealOverflow = 1.05,
	}
end

local function CreateAuras(self)
	local owner = addon
	local Auras = owner:AcquireRuntimeFrame("Frame", self, "SUF_AuraContainer")
	local auraSize = owner:GetUnitAuraSize(self.sufUnitType)
	Auras:Show()
	Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
	Auras:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 4)
	Auras:SetHeight(auraSize + 2)
	Auras.size = auraSize
	Auras.width = auraSize
	Auras.height = auraSize
	Auras.spacing = 4
	Auras.numBuffs = 8
	Auras.numDebuffs = 8
	Auras.disableCooldown = false
	Auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"
	Auras.createdButtons = 0
	Auras.CreateButton = function(element, position)
		local button = owner:AcquireRuntimeFrame("Button", element, "SUF_AuraButton")
		button:SetParent(element)
		button:SetID(position or 0)
		button:SetSize(element.size or 18, element.size or 18)
		button:Show()

		if not button.Cooldown then
			local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			cd:SetAllPoints()
			button.Cooldown = cd
		end
		button.Cooldown:SetScale(0.86)

		if not button.Icon then
			local icon = button:CreateTexture(nil, "BORDER")
			icon:SetAllPoints()
			button.Icon = icon
		end

		if not button.Count then
			local countFrame = CreateFrame("Frame", nil, button)
			countFrame:SetAllPoints(button)
			countFrame:SetFrameLevel((button.Cooldown and button.Cooldown:GetFrameLevel() or button:GetFrameLevel()) + 1)
			local count = countFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
			count:SetPoint("BOTTOMRIGHT", countFrame, "BOTTOMRIGHT", -1, 0)
			button.Count = count
		end

		if not button.Overlay then
			local overlay = button:CreateTexture(nil, "OVERLAY")
			overlay:SetTexture([[Interface\Buttons\UI-Debuff-Overlays]])
			overlay:SetAllPoints()
			overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
			button.Overlay = overlay
		end

		if not button.Stealable then
			local stealable = button:CreateTexture(nil, "OVERLAY")
			stealable:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
			stealable:SetPoint("TOPLEFT", -3, 3)
			stealable:SetPoint("BOTTOMRIGHT", 3, -3)
			stealable:SetBlendMode("ADD")
			button.Stealable = stealable
		end

		button.UpdateTooltip = function(widget)
			if GameTooltip and widget.auraInstanceID and widget:GetParent() and widget:GetParent().__owner and widget:GetParent().__owner.unit then
				GameTooltip:SetUnitAuraByAuraInstanceID(widget:GetParent().__owner.unit, widget.auraInstanceID)
			end
		end
		button:SetScript("OnEnter", function(widget)
			if GameTooltip and widget:IsVisible() then
				GameTooltip:SetOwner(widget, widget:GetParent().tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
				widget:UpdateTooltip()
			end
		end)
		button:SetScript("OnLeave", function()
			if GameTooltip then
				GameTooltip:Hide()
			end
		end)

		element.createdButtons = (element.createdButtons or 0) + 1
		return button
	end
	self.Auras = Auras
end

HasVisibleClassPower = function(frame)
	if not frame or not frame.ClassPower then
		return false
	end
	for _, bar in ipairs(frame.ClassPower) do
		if bar and bar.IsShown and bar:IsShown() then
			return true
		end
	end
	return false
end

function addon:Style(frame, unit)
	frame.sufUnitType = ResolveUnitType(unit)
	local unitLayout = self:GetUnitLayoutSettings(frame.sufUnitType)
	frame:SetScale(1)
	frame:RegisterForClicks("AnyUp")
	frame:SetAttribute("type2", "menu")
	frame.menu = UnitPopup_ShowMenu
	frame:SetScript("OnEnter", UnitFrame_OnEnter)
	frame:SetScript("OnLeave", UnitFrame_OnLeave)

	local size = self.db.profile.sizes[frame.sufUnitType]
	frame:SetSize(size.width, size.height)

	local Health = CreateStatusBar(frame, size.height)
	Health:SetAllPoints(frame)
	Health.colorClass = true
	Health.colorReaction = true
	frame.Health = Health
	CreateHealthPrediction(frame)
	if frame.HealthPrediction then
		frame.HealthPrediction.PostUpdate = function()
			addon:UpdateAbsorbValue(frame)
		end
	end

	local Power = CreateStatusBar(frame, self.db.profile.powerHeight)
	Power:SetPoint("TOPLEFT", Health, "BOTTOMLEFT", 0, -2)
	Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, -2)
	Power.colorPower = true
	frame.Power = Power

	local PowerBG = Power:CreateTexture(nil, "BACKGROUND")
	PowerBG:SetAllPoints(Power)
	PowerBG:SetColorTexture(0, 0, 0, 0.6)
	frame.PowerBG = PowerBG

	local TextOverlay = self:AcquireRuntimeFrame("Frame", frame, "SUF_TextOverlay")
	TextOverlay:Show()
	TextOverlay:SetAllPoints(frame)
	TextOverlay:SetFrameStrata(frame:GetFrameStrata())
	TextOverlay:SetFrameLevel((Health:GetFrameLevel() or frame:GetFrameLevel() or 1) + 8)
	frame.TextOverlay = TextOverlay

	local NameText = CreateFontString(TextOverlay, 12, "OUTLINE")
	NameText:SetPoint("TOPLEFT", Health, "TOPLEFT", 4, -2)
	NameText:SetDrawLayer("OVERLAY", 7)
	frame.NameText = NameText

	local LevelText = CreateFontString(TextOverlay, 10, "OUTLINE")
	LevelText:SetPoint("TOPRIGHT", Health, "TOPRIGHT", -4, -2)
	LevelText:SetJustifyH("RIGHT")
	LevelText:SetDrawLayer("OVERLAY", 7)
	frame.LevelText = LevelText

	local HealthValue = CreateFontString(TextOverlay, 11, "OUTLINE")
	HealthValue:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 4, 2)
	HealthValue:SetDrawLayer("OVERLAY", 7)
	frame.HealthValue = HealthValue

	local AbsorbValue = CreateFontString(TextOverlay, 10, "OUTLINE")
	AbsorbValue:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", -4, 2)
	AbsorbValue:SetJustifyH("RIGHT")
	AbsorbValue:SetDrawLayer("OVERLAY", 7)
	frame.AbsorbValue = AbsorbValue

	local PowerValue = CreateFontString(TextOverlay, 10, "OUTLINE")
	PowerValue:SetPoint("CENTER", Power, "CENTER", 0, 0)
	PowerValue:SetJustifyH("CENTER")
	PowerValue:SetDrawLayer("OVERLAY", 7)
	frame.PowerValue = PowerValue

	local IndicatorFrame = self:AcquireRuntimeFrame("Frame", frame, "SUF_IndicatorFrame")
	IndicatorFrame:Show()
	IndicatorFrame:SetAllPoints(frame)
	IndicatorFrame:SetFrameStrata("HIGH")
	IndicatorFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
	frame.IndicatorFrame = IndicatorFrame

	local RestingIndicator = self:AcquireRuntimeIndicator("SUF_RestingIndicator", IndicatorFrame)
	RestingIndicator:SetSize(48, 48)
	RestingIndicator:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -4, 6)
	RestingIndicator:SetDrawLayer("OVERLAY", 7)
	frame.RestingIndicator = RestingIndicator

	local PvPIndicator = self:AcquireRuntimeIndicator("SUF_PvPIndicator", IndicatorFrame)
	PvPIndicator:SetSize(48, 48)
	PvPIndicator:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 4, 6)
	PvPIndicator:SetDrawLayer("OVERLAY", 7)
	frame.PvPIndicator = PvPIndicator

	local Portrait2D = frame:CreateTexture(nil, "ARTWORK")
	Portrait2D:SetSize(32, 32)
	Portrait2D:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	frame.Portrait2D = Portrait2D

	local Portrait3D = CreateFrame("PlayerModel", nil, frame)
	Portrait3D:SetSize(32, 32)
	Portrait3D:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	frame.Portrait3D = Portrait3D

	if unit == "player" then
		CreateClassPower(frame, self.db.profile.classPowerHeight)
		CreateAuras(frame)

		local secondaryGap = math.max(-6, math.min(24, math.floor((unitLayout.secondaryToFrame or 0) + 0.5)))
		local AdditionalPower = CreateStatusBar(frame, math.max(4, math.floor(self.db.profile.powerHeight * 0.7)))
		AdditionalPower:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 0, secondaryGap)
		AdditionalPower:SetPoint("BOTTOMRIGHT", Health, "TOPRIGHT", 0, secondaryGap)
		AdditionalPower.colorPower = true
		frame.AdditionalPower = AdditionalPower

		local AdditionalPowerBG = AdditionalPower:CreateTexture(nil, "BACKGROUND")
		AdditionalPowerBG:SetAllPoints(AdditionalPower)
		AdditionalPowerBG:SetColorTexture(0, 0, 0, 0.6)
		frame.AdditionalPowerBG = AdditionalPowerBG

		local AdditionalPowerValue = CreateFontString(TextOverlay, 9, "OUTLINE")
		AdditionalPowerValue:SetPoint("CENTER", AdditionalPower, "CENTER", 0, 0)
		AdditionalPowerValue:SetJustifyH("CENTER")
		AdditionalPowerValue:SetDrawLayer("OVERLAY", 7)
		frame.AdditionalPowerValue = AdditionalPowerValue

		if frame.ClassPowerAnchor then
			local classGap = math.max(-6, math.min(24, math.floor((unitLayout.classToSecondary or 0) + 0.5)))
			frame.ClassPowerAnchor:ClearAllPoints()
			frame.ClassPowerAnchor:SetPoint("BOTTOMLEFT", AdditionalPower, "TOPLEFT", 0, classGap)
			frame.ClassPowerAnchor:SetPoint("BOTTOMRIGHT", AdditionalPower, "TOPRIGHT", 0, classGap)
		end
	end

	if unit == "player" or unit == "target" or (unit and unit:match("^boss%d*$")) then
		local anchor = frame.ClassPowerAnchor
		CreateCastbar(frame, self.db.profile.castbarHeight, anchor)
	end

	if unit == "player" or unit == "target" then
		if not frame.Auras then
			CreateAuras(frame)
		end
	end

	self:ApplyTags(frame)
	self:ApplyMedia(frame)
	self:ApplySize(frame)
	if not frame.Update then
		frame.Update = function(widget)
			local events = widget.__sufDirtyEvents
			widget.__sufDirtyQueued = false
			widget.__sufDirtyEvents = {}
			addon:UpdateFrameFromDirtyEvents(widget, events)
			ClearTableInPlace(events)
		end
	end
	table.insert(self.frames, frame)
end

function addon:HookAnchor(frame, anchorName)
	local anchor = _G[anchorName]
	frame:ClearAllPoints()
	if anchor then
		frame:SetPoint("CENTER", anchor, "CENTER")
	else
		frame:SetPoint("CENTER", UIParent, "CENTER")
	end
end

function addon:SpawnFrames()
	if InCombatLockdown() or self:IsEditModeActive() then
		self.pendingSpawn = true
		self:StartSpawnTicker()
		return
	end

	if self.optionsFrame then
		self.pendingSpawn = true
		return
	end

	if C_EditMode and not _G.EditModeManagerFrame then
		self.pendingSpawn = true
		self:StartSpawnTicker()
		return
	end

	if self.spawned then
		return
	end

	local oUF = GetOuf()
	if not oUF then
		ChatMsg(addonName .. ": oUF not available yet.")
		return
	end
	OverrideDisableBlizzard(oUF)

	self.oUF = oUF
	self:RegisterCustomTags()

	self:ReleaseAllPooledResources()
	self.frames = {}
	self.headers = {}
	oUF:RegisterStyle("SimpleUnitFrames", function(frame, unit)
		self:Style(frame, unit)
	end)
	oUF:SetActiveStyle("SimpleUnitFrames")

	self.allowGroupHeaders = false
	local builderCount = 0
	oUF:Factory(function()
		if InCombatLockdown() or self:IsEditModeActive() then
			self.pendingSpawn = true
			self:StartSpawnTicker()
			return
		end

		for _, unitType in ipairs(UNIT_TYPE_ORDER) do
			if not GROUP_UNIT_TYPES[unitType] then
				local builder = self.unitBuilders[unitType]
				if builder then
					builderCount = builderCount + 1
					builder(self)
				end
			end
		end

		self:UpdateAllFrames()
	end)

	local frameCount = 0
	for _ in ipairs(self.frames) do
		frameCount = frameCount + 1
	end

	if frameCount == 0 then
		ChatMsg(addonName .. ": No unit frames spawned. Builders: " .. builderCount)
	else
		ChatMsg(addonName .. ": Spawned " .. frameCount .. " unit frames.")
		self.spawned = true
	end

	self:ApplyVisibilityRules()
end

function addon:SpawnGroupHeaders()
	local oUF = self.oUF or GetOuf()
	if not oUF then
		return
	end
	OverrideDisableBlizzard(oUF)

	local inGroup, inRaid = IsInAnyPartyOrRaid()
	local showPartySolo = self.db and self.db.profile and self.db.profile.party and self.db.profile.party.showPlayerWhenSolo
	if not inRaid and not inGroup and not showPartySolo then
		return
	end

	self.oUF = oUF
	self.headers = self.headers or {}

	local needParty = ((inGroup and not inRaid) or (showPartySolo and not inRaid)) and not self.headers.party
	local needRaid = inRaid and not self.headers.raid
	if not needParty and not needRaid then
		return
	end

	self.allowGroupHeaders = true
	oUF:Factory(function()
		if InCombatLockdown() or self:IsEditModeActive() then
			self.pendingGroupHeaders = true
			self:StartSpawnTicker()
			return
		end

		if needParty then
			local builder = self.unitBuilders.party
			if builder then
				builder(self)
			end
		end

		if needRaid then
			local builder = self.unitBuilders.raid
			if builder then
				builder(self)
			end
		end
	end)
	self.allowGroupHeaders = false

	self:ApplyPartyHeaderSettings()
	self:ApplyVisibilityRules()
end

function addon:OnGroupRosterUpdate()
	self:TrySpawnGroupHeaders()
end

function addon:GetPartyHeaderYOffset()
	local partyCfg = (self.db and self.db.profile and self.db.profile.party) or {}
	local spacing = math.max(0, math.min(40, tonumber(partyCfg.spacing) or 10))
	local powerHeight = tonumber(self.db and self.db.profile and self.db.profile.powerHeight) or 8
	local size = self.db and self.db.profile and self.db.profile.sizes and self.db.profile.sizes.party
	local frameHeight = tonumber(size and size.height) or 26
	-- Party header initial config starts at 26px; account for extra frame height plus the lower power row.
	local extraHeight = math.max(0, frameHeight - 26)
	local effectiveSpacing = spacing + extraHeight + powerHeight + 3
	return -effectiveSpacing
end

function addon:ApplyPartyHeaderSettings()
	local header = self.headers and self.headers.party
	if not header or not self.db or not self.db.profile then
		return
	end

	local partyCfg = self.db.profile.party or defaults.profile.party
	local showSolo = partyCfg.showPlayerWhenSolo == true
	local showInParty = partyCfg.showPlayerInParty ~= false
	local showPlayer = showInParty or showSolo
	local yOffset = self:GetPartyHeaderYOffset()

	if InCombatLockdown() then
		self.pendingGroupHeaders = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnSpawnRegen")
		return
	end

	header:SetAttribute("showPlayer", showPlayer)
	header:SetAttribute("showSolo", showSolo)
	header:SetAttribute("yOffset", yOffset)
end

function addon:ApplyVisibilityRules()
	if InCombatLockdown() then
		self.pendingVisibilityUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegenEnabled")
		return
	end

	local driver = BuildVisibilityDriver(self.db.profile)

	for _, frame in ipairs(self.frames or {}) do
		if frame then
			UnregisterStateDriver(frame, "visibility")
			RegisterStateDriver(frame, "visibility", driver)
		end
	end

	for _, header in pairs(self.headers or {}) do
		if header then
			UnregisterStateDriver(header, "visibility")
			RegisterStateDriver(header, "visibility", driver)
		end
	end
end

function addon:SerializeProfile()
	if not (LibSerialize and LibDeflate) then
		return nil, "LibSerialize or LibDeflate is missing."
	end

	local serialized = LibSerialize:Serialize(self.db.profile)
	local compressed = LibDeflate:CompressDeflate(serialized)
	local encoded = LibDeflate:EncodeForPrint(compressed)
	return encoded
end

function addon:DeserializeProfile(input)
	if not (LibSerialize and LibDeflate) then
		return nil, "LibSerialize or LibDeflate is missing."
	end

	local decoded = LibDeflate:DecodeForPrint(input)
	if not decoded then
		return nil, "Invalid import string."
	end

	local decompressed = LibDeflate:DecompressDeflate(decoded)
	if not decompressed then
		return nil, "Unable to decompress import data."
	end

	local ok, data = LibSerialize:Deserialize(decompressed)
	if not ok then
		return nil, "Unable to deserialize import data."
	end

	return data
end

function addon:ApplyImportedProfile(data)
	if type(data) ~= "table" then
		return false, "Imported data is not a table."
	end

	local profile = CopyTableDeep(defaults.profile)
	for key, value in pairs(data) do
		if type(value) == "table" then
			profile[key] = CopyTableDeep(value)
		else
			profile[key] = value
		end
	end

	self.db.profile = profile
	self:UpdateAllFrames()
	self:ApplyVisibilityRules()
	return true
end

function addon:OnRegenEnabled()
	if self.pendingVisibilityUpdate then
		self.pendingVisibilityUpdate = nil
		self:ApplyVisibilityRules()
	end
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function addon:OnPlayerEnteringWorld()
	self.isLoggedIn = true
	self:UpdateBlizzardFrames()
	self:TrySpawnFrames()
	self:ScheduleGroupHeaders(0.5)
end

function addon:RefreshEditModeUnitSystems()
	-- Avoid direct calls into Blizzard unit-frame refresh routines from insecure code.
	-- Those calls can taint secure paths (CompactUnitFrame/UnitFrame) and trigger
	-- "secret value tainted" errors during Edit Mode and roster updates.
end

function addon:SetFramesVisible(isEditMode)
	local showBlizzard = isEditMode
	local alpha = showBlizzard and 1 or 0

	local blizzardFrames = {
		_G.PlayerFrame,
		_G.PetFrame,
		_G.TargetFrame,
		_G.TargetFrameToT,
		_G.FocusFrame,
		_G.PartyFrame,
		_G.CompactPartyFrame,
		_G.CompactRaidFrameContainer,
		_G.CompactRaidFrameManager,
		_G.BossTargetFrameContainer,
		_G.CastingBarFrame,
		_G.TargetFrameSpellBar,
	}

	for _, frame in ipairs(blizzardFrames) do
		if frame then
			frame:SetAlpha(alpha)
		end
	end

	if showBlizzard then
		for _, frame in ipairs(self.frames or {}) do
			UnregisterStateDriver(frame, "visibility")
			frame:Hide()
		end
		for _, header in pairs(self.headers or {}) do
			if header then
				UnregisterStateDriver(header, "visibility")
				header:Hide()
			end
		end
	else
		self:ApplyVisibilityRules()
	end
end

function addon:SetTestMode(enabled)
	if InCombatLockdown() then
		return
	end

	self.testMode = enabled
	if enabled then
		self:TrySpawnGroupHeaders()
		for _, frame in ipairs(self.frames or {}) do
			if frame._sufWasUnitWatch == nil then
				frame._sufWasUnitWatch = UnitWatchRegistered(frame)
			end
			if frame._sufWasUnitWatch then
				UnregisterUnitWatch(frame)
			end
			frame:Show()
		end

		for _, header in pairs(self.headers or {}) do
			header:Show()
		end
	else
		for _, frame in ipairs(self.frames or {}) do
			if frame._sufWasUnitWatch ~= nil then
				if frame._sufWasUnitWatch then
					RegisterUnitWatch(frame)
				end
				frame._sufWasUnitWatch = nil
			end
		end
	end
end

function addon:UpdateBlizzardFrames()
	self:SetFramesVisible(self:IsEditModeActive())
end

function addon:ShowOptions()
	if self.optionsFrame then
		self.optionsFrame:Show()
		return
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("SimpleUnitFrames")
	frame:SetLayout("List")
	local screenWidth = UIParent and UIParent:GetWidth() or 1024
	local screenHeight = UIParent and UIParent:GetHeight() or 768
	frame:SetWidth(math.min(520, screenWidth - 40))
	frame:SetHeight(math.min(600, screenHeight - 80))
	if frame.frame and frame.frame.SetClampedToScreen then
		frame.frame:SetClampedToScreen(true)
	end
	if frame.frame and frame.frame.ClearAllPoints then
		frame.frame:ClearAllPoints()
		frame.frame:SetPoint("CENTER", UIParent, "CENTER")
	end
	frame:SetCallback("OnClose", function(widget)
		self:SetTestMode(false)
		widget:Hide()
	end)

	local banner = AceGUI:Create("SimpleGroup")
	banner:SetLayout("Flow")
	banner:SetFullWidth(true)

	local icon = AceGUI:Create("Icon")
	icon:SetImage(ICON_PATH)
	icon:SetImageSize(32, 32)
	icon:SetWidth(36)
	icon:SetHeight(36)

	local label = AceGUI:Create("Label")
	label:SetText("SimpleUnitFrames")
	label:SetFontObject("GameFontNormalLarge")
	label:SetWidth(400)

	banner:AddChild(icon)
	banner:AddChild(label)
	frame:AddChild(banner)

	local tabs = {
		{ text = "GLOBAL", value = "global" },
		{ text = "IMPORT/EXPORT", value = "importexport" },
	}
	for _, unitType in ipairs(UNIT_TYPE_ORDER) do
		table.insert(tabs, { text = unitType:upper(), value = unitType })
	end

	local tabGroup = AceGUI:Create("TabGroup")
	tabGroup:SetLayout("Fill")
	tabGroup:SetTabs(tabs)
	tabGroup:SetFullWidth(true)
	tabGroup:SetFullHeight(true)
	tabGroup:SetCallback("OnGroupSelected", function(container, _, group)
		self.isBuildingOptions = true

		self.optionsPages = self.optionsPages or {}
		for _, page in pairs(self.optionsPages) do
			if page and page.frame then
				page.frame:Hide()
			end
		end

		local cached = self.optionsPages[group]
		if cached then
			if cached.frame and cached.frame:GetParent() ~= container.frame then
				container:AddChild(cached)
			end
			cached.frame:Show()
			self.isBuildingOptions = false
			return
		end

		local scroll = AceGUI:Create("ScrollFrame")
		scroll:SetLayout("Fill")
		scroll:SetFullWidth(true)
		scroll:SetFullHeight(true)
		container:AddChild(scroll)
		self.optionsPages[group] = scroll

		local content = AceGUI:Create("SimpleGroup")
		content:SetLayout("Flow")
		content:SetFullWidth(true)
		scroll:AddChild(content)

		local function SetControlWidth(control)
			if control and control.SetWidth then
				control:SetWidth(220)
			end
		end

		if group == "global" then
			local statusbarList = BuildMediaList(LSM and LSM:List("statusbar") or {})
			local fontList = BuildMediaList(LSM and LSM:List("font") or {})

			local statusbarDropdown = AceGUI:Create("Dropdown")
			statusbarDropdown:SetLabel("Statusbar Texture")
			statusbarDropdown:SetList(statusbarList)
			statusbarDropdown:SetValue(self.db.profile.media.statusbar)
			statusbarDropdown:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.media.statusbar = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(statusbarDropdown)

			local fontDropdown = AceGUI:Create("Dropdown")
			fontDropdown:SetLabel("Font")
			fontDropdown:SetList(fontList)
			fontDropdown:SetValue(self.db.profile.media.font)
			fontDropdown:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.media.font = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(fontDropdown)

			local powerHeight = AceGUI:Create("Slider")
			powerHeight:SetLabel("Power Bar Height")
			powerHeight:SetSliderValues(4, 20, 1)
			powerHeight:SetValue(self.db.profile.powerHeight)
			powerHeight:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.powerHeight = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(powerHeight)

			local classPowerHeight = AceGUI:Create("Slider")
			classPowerHeight:SetLabel("Class Power Height")
			classPowerHeight:SetSliderValues(4, 20, 1)
			classPowerHeight:SetValue(self.db.profile.classPowerHeight)
			classPowerHeight:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.classPowerHeight = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(classPowerHeight)

			local classPowerSpacing = AceGUI:Create("Slider")
			classPowerSpacing:SetLabel("Class Power Spacing")
			classPowerSpacing:SetSliderValues(0, 10, 1)
			classPowerSpacing:SetValue(self.db.profile.classPowerSpacing)
			classPowerSpacing:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.classPowerSpacing = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(classPowerSpacing)

			local castbarHeight = AceGUI:Create("Slider")
			castbarHeight:SetLabel("Castbar Height")
			castbarHeight:SetSliderValues(8, 30, 1)
			castbarHeight:SetValue(self.db.profile.castbarHeight)
			castbarHeight:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.castbarHeight = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(castbarHeight)

			local powerBgAlpha = AceGUI:Create("Slider")
			powerBgAlpha:SetLabel("Power Background Opacity")
			powerBgAlpha:SetSliderValues(0, 1, 0.05)
			powerBgAlpha:SetValue(self.db.profile.powerBgAlpha)
			powerBgAlpha:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.powerBgAlpha = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(powerBgAlpha)

			local nameSize = AceGUI:Create("Slider")
			nameSize:SetLabel("Name Font Size")
			nameSize:SetSliderValues(8, 20, 1)
			nameSize:SetValue(self.db.profile.fontSizes.name)
			nameSize:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.fontSizes.name = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(nameSize)

			local levelSize = AceGUI:Create("Slider")
			levelSize:SetLabel("Level Font Size")
			levelSize:SetSliderValues(8, 20, 1)
			levelSize:SetValue(self.db.profile.fontSizes.level)
			levelSize:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.fontSizes.level = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(levelSize)

			local healthSize = AceGUI:Create("Slider")
			healthSize:SetLabel("Health Font Size")
			healthSize:SetSliderValues(8, 20, 1)
			healthSize:SetValue(self.db.profile.fontSizes.health)
			healthSize:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.fontSizes.health = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(healthSize)

			local powerSize = AceGUI:Create("Slider")
			powerSize:SetLabel("Power Font Size")
			powerSize:SetSliderValues(8, 20, 1)
			powerSize:SetValue(self.db.profile.fontSizes.power)
			powerSize:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.fontSizes.power = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(powerSize)

			local castSize = AceGUI:Create("Slider")
			castSize:SetLabel("Cast Font Size")
			castSize:SetSliderValues(8, 20, 1)
			castSize:SetValue(self.db.profile.fontSizes.cast)
			castSize:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.fontSizes.cast = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(castSize)

			local hideVehicle = AceGUI:Create("CheckBox")
			hideVehicle:SetLabel("Hide in Vehicle")
			hideVehicle:SetValue(self.db.profile.visibility.hideVehicle)
			hideVehicle:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.visibility.hideVehicle = value
				self:ScheduleApplyVisibility()
			end)

			local hidePetBattle = AceGUI:Create("CheckBox")
			hidePetBattle:SetLabel("Hide in Pet Battles")
			hidePetBattle:SetValue(self.db.profile.visibility.hidePetBattle)
			hidePetBattle:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.visibility.hidePetBattle = value
				self:ScheduleApplyVisibility()
			end)

			local hideOverride = AceGUI:Create("CheckBox")
			hideOverride:SetLabel("Hide with Override Bar")
			hideOverride:SetValue(self.db.profile.visibility.hideOverride)
			hideOverride:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.visibility.hideOverride = value
				self:ScheduleApplyVisibility()
			end)

			local hidePossess = AceGUI:Create("CheckBox")
			hidePossess:SetLabel("Hide with Possess Bar")
			hidePossess:SetValue(self.db.profile.visibility.hidePossess)
			hidePossess:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.visibility.hidePossess = value
				self:ScheduleApplyVisibility()
			end)

			local hideExtra = AceGUI:Create("CheckBox")
			hideExtra:SetLabel("Hide with Extra Bar")
			hideExtra:SetValue(self.db.profile.visibility.hideExtra)
			hideExtra:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.visibility.hideExtra = value
				self:ScheduleApplyVisibility()
			end)

			local indicatorSize = AceGUI:Create("Slider")
			indicatorSize:SetLabel("Indicator Size")
			indicatorSize:SetSliderValues(16, 96, 1)
			indicatorSize:SetValue(self.db.profile.indicators.size)
			indicatorSize:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.indicators.size = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(indicatorSize)

			local indicatorOffsetX = AceGUI:Create("Slider")
			indicatorOffsetX:SetLabel("Indicator Offset X")
			indicatorOffsetX:SetSliderValues(-50, 50, 1)
			indicatorOffsetX:SetValue(self.db.profile.indicators.offsetX)
			indicatorOffsetX:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.indicators.offsetX = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(indicatorOffsetX)

			local indicatorOffsetY = AceGUI:Create("Slider")
			indicatorOffsetY:SetLabel("Indicator Offset Y")
			indicatorOffsetY:SetSliderValues(-50, 50, 1)
			indicatorOffsetY:SetValue(self.db.profile.indicators.offsetY)
			indicatorOffsetY:SetCallback("OnValueChanged", function(_, _, value)
				self.db.profile.indicators.offsetY = value
				self:ScheduleUpdateAll()
			end)
			SetControlWidth(indicatorOffsetY)

			local testModeToggle = AceGUI:Create("CheckBox")
			testModeToggle:SetLabel("Test Mode (Show All Frames)")
			testModeToggle:SetValue(self.testMode or false)
			testModeToggle:SetCallback("OnValueChanged", function(_, _, value)
				self:SetTestMode(value)
			end)

			local perfToggle = AceGUI:Create("CheckBox")
			perfToggle:SetLabel("Enable PerformanceLib Integration")
			perfToggle:SetValue(self.db.profile.performance and self.db.profile.performance.enabled or false)
			if not self.performanceLib then
				perfToggle:SetDisabled(true)
			end
			perfToggle:SetCallback("OnValueChanged", function(_, _, value)
				self:SetPerformanceIntegrationEnabled(value)
			end)

			content:AddChild(statusbarDropdown)
			content:AddChild(fontDropdown)
			content:AddChild(powerHeight)
			content:AddChild(classPowerHeight)
			content:AddChild(classPowerSpacing)
			content:AddChild(castbarHeight)
			content:AddChild(powerBgAlpha)
			content:AddChild(nameSize)
			content:AddChild(levelSize)
			content:AddChild(healthSize)
			content:AddChild(powerSize)
			content:AddChild(castSize)
			content:AddChild(hideVehicle)
			content:AddChild(hidePetBattle)
			content:AddChild(hideOverride)
			content:AddChild(hidePossess)
			content:AddChild(hideExtra)
			content:AddChild(indicatorSize)
			content:AddChild(indicatorOffsetX)
			content:AddChild(indicatorOffsetY)
			content:AddChild(testModeToggle)
			content:AddChild(perfToggle)
			self.isBuildingOptions = false
			return
		end

		if group == "importexport" then
			local ioBox = AceGUI:Create("MultiLineEditBox")
			ioBox:SetLabel("Import/Export Settings")
			ioBox:SetNumLines(10)
			ioBox:SetFullWidth(true)
			ioBox:DisableButton(true)

			local exportButton = AceGUI:Create("Button")
			exportButton:SetText("Export")
			exportButton:SetWidth(120)
			exportButton:SetCallback("OnClick", function()
				local data, err = self:SerializeProfile()
				if data then
					ioBox:SetText(data)
					self:Print(addonName .. ": Exported settings to the text box.")
				else
					self:Print(addonName .. ": " .. err)
				end
			end)

			local importButton = AceGUI:Create("Button")
			importButton:SetText("Import")
			importButton:SetWidth(120)
			importButton:SetCallback("OnClick", function()
				local text = ioBox:GetText() or ""
				local data, err = self:DeserializeProfile(text)
				if data then
					local ok, applyErr = self:ApplyImportedProfile(data)
					if ok then
						self:Print(addonName .. ": Imported settings.")
					else
						self:Print(addonName .. ": " .. applyErr)
					end
				else
					self:Print(addonName .. ": " .. err)
				end
			end)

			content:AddChild(ioBox)
			content:AddChild(exportButton)
			content:AddChild(importButton)
			self.isBuildingOptions = false
			return
		end

		local tags = self.db.profile.tags[group]
		if not tags then
			return
		end

		local unitSettings = self:GetUnitSettings(group)
		unitSettings.fontSizes = unitSettings.fontSizes or CopyTableDeep(self.db.profile.fontSizes)
		unitSettings.portrait = unitSettings.portrait or { mode = "none", size = 32, position = "LEFT", showClass = false, motion = false }
		unitSettings.media = unitSettings.media or { statusbar = self.db.profile.media.statusbar }

		local size = self.db.profile.sizes[group]
		local widthSlider = AceGUI:Create("Slider")
		widthSlider:SetLabel("Frame Width")
		widthSlider:SetSliderValues(80, 400, 1)
		widthSlider:SetValue(size.width)
		widthSlider:SetCallback("OnValueChanged", function(_, _, value)
			size.width = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(widthSlider)

		local heightSlider = AceGUI:Create("Slider")
		heightSlider:SetLabel("Frame Height")
		heightSlider:SetSliderValues(18, 80, 1)
		heightSlider:SetValue(size.height)
		heightSlider:SetCallback("OnValueChanged", function(_, _, value)
			size.height = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(heightSlider)

		local nameBox = AceGUI:Create("EditBox")
		nameBox:SetLabel("Name Tag")
		nameBox:SetText(tags.name)
		nameBox:SetWidth(220)
		nameBox:SetCallback("OnEnterPressed", function(_, _, value)
			tags.name = value
				self:ScheduleUpdateAll()
		end)

		local levelBox = AceGUI:Create("EditBox")
		levelBox:SetLabel("Level Tag")
		levelBox:SetText(tags.level)
		levelBox:SetWidth(220)
		levelBox:SetCallback("OnEnterPressed", function(_, _, value)
			tags.level = value
				self:ScheduleUpdateAll()
		end)

		local healthBox = AceGUI:Create("EditBox")
		healthBox:SetLabel("Health Tag")
		healthBox:SetText(tags.health)
		healthBox:SetWidth(220)
		healthBox:SetCallback("OnEnterPressed", function(_, _, value)
			tags.health = value
				self:ScheduleUpdateAll()
		end)

		local powerBox = AceGUI:Create("EditBox")
		powerBox:SetLabel("Power Tag")
		powerBox:SetText(tags.power)
		powerBox:SetWidth(220)
		powerBox:SetCallback("OnEnterPressed", function(_, _, value)
			tags.power = value
				self:ScheduleUpdateAll()
		end)

		local statusbarDropdown = AceGUI:Create("Dropdown")
		statusbarDropdown:SetLabel("Statusbar Texture")
		statusbarDropdown:SetList(BuildMediaList(LSM and LSM:List("statusbar") or {}))
		statusbarDropdown:SetValue(unitSettings.media.statusbar)
		statusbarDropdown:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.media.statusbar = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(statusbarDropdown)


		local nameSize = AceGUI:Create("Slider")
		nameSize:SetLabel("Name Font Size")
		nameSize:SetSliderValues(8, 20, 1)
		nameSize:SetValue(unitSettings.fontSizes.name)
		nameSize:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.fontSizes.name = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(nameSize)

		local levelSize = AceGUI:Create("Slider")
		levelSize:SetLabel("Level Font Size")
		levelSize:SetSliderValues(8, 20, 1)
		levelSize:SetValue(unitSettings.fontSizes.level)
		levelSize:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.fontSizes.level = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(levelSize)

		local healthSize = AceGUI:Create("Slider")
		healthSize:SetLabel("Health Font Size")
		healthSize:SetSliderValues(8, 20, 1)
		healthSize:SetValue(unitSettings.fontSizes.health)
		healthSize:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.fontSizes.health = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(healthSize)

		local powerSize = AceGUI:Create("Slider")
		powerSize:SetLabel("Power Font Size")
		powerSize:SetSliderValues(8, 20, 1)
		powerSize:SetValue(unitSettings.fontSizes.power)
		powerSize:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.fontSizes.power = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(powerSize)

		local castSize = AceGUI:Create("Slider")
		castSize:SetLabel("Cast Font Size")
		castSize:SetSliderValues(8, 20, 1)
		castSize:SetValue(unitSettings.fontSizes.cast)
		castSize:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.fontSizes.cast = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(castSize)

		local showResting = AceGUI:Create("CheckBox")
		showResting:SetLabel("Show Resting Indicator")
		showResting:SetValue(unitSettings.showResting)
		showResting:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.showResting = value
				self:ScheduleUpdateAll()
		end)

		local showPvp = AceGUI:Create("CheckBox")
		showPvp:SetLabel("Show PvP Indicator")
		showPvp:SetValue(unitSettings.showPvp)
		showPvp:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.showPvp = value
				self:ScheduleUpdateAll()
		end)

		local portraitModes = {
			none = "None",
			["2D"] = "2D",
			["3D"] = "3D",
			["3DMotion"] = "3D Motion",
		}
		local portraitMode = AceGUI:Create("Dropdown")
		portraitMode:SetLabel("Portrait Mode")
		portraitMode:SetList(portraitModes)
		portraitMode:SetValue(unitSettings.portrait.mode)
		portraitMode:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.portrait.mode = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(portraitMode)

		local portraitSize = AceGUI:Create("Slider")
		portraitSize:SetLabel("Portrait Size")
		portraitSize:SetSliderValues(16, 64, 1)
		portraitSize:SetValue(unitSettings.portrait.size)
		portraitSize:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.portrait.size = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(portraitSize)

		local portraitClass = AceGUI:Create("CheckBox")
		portraitClass:SetLabel("Portrait Show Class")
		portraitClass:SetValue(unitSettings.portrait.showClass)
		portraitClass:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.portrait.showClass = value
				self:ScheduleUpdateAll()
		end)

		local portraitPosition = AceGUI:Create("Dropdown")
		portraitPosition:SetLabel("Portrait Position")
		portraitPosition:SetList({ LEFT = "Left", RIGHT = "Right" })
		portraitPosition:SetValue(unitSettings.portrait.position)
		portraitPosition:SetCallback("OnValueChanged", function(_, _, value)
			unitSettings.portrait.position = value
				self:ScheduleUpdateAll()
		end)
		SetControlWidth(portraitPosition)

		content:AddChild(nameBox)
		content:AddChild(levelBox)
		content:AddChild(healthBox)
		content:AddChild(powerBox)
		content:AddChild(statusbarDropdown)
		content:AddChild(widthSlider)
		content:AddChild(heightSlider)
		content:AddChild(nameSize)
		content:AddChild(levelSize)
		content:AddChild(healthSize)
		content:AddChild(powerSize)
		content:AddChild(castSize)
		content:AddChild(showResting)
		content:AddChild(showPvp)
		content:AddChild(portraitMode)
		content:AddChild(portraitSize)
		content:AddChild(portraitClass)
		content:AddChild(portraitPosition)
		self.isBuildingOptions = false
	end)

	tabGroup:SelectTab("global")
	frame:AddChild(tabGroup)
	self.optionsFrame = frame
end

-- New lightweight options UI. This intentionally overrides the legacy ShowOptions above.
function addon:ShowOptions()
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
		self.optionsFrame:Show()
		if self.optionsFrame.BuildTab then
			self.optionsFrame:BuildTab(self.optionsFrame.currentTab or "global")
		end
		return
	end

	local frame = CreateFrame("Frame", "SUFOptionsWindow", UIParent, "BasicFrameTemplateWithInset")
	local maxHeightCap = math.max(500, math.floor(UIParent:GetHeight() * 0.65))
	local initialHeight = math.min(620, maxHeightCap)
	frame:SetSize(1140, initialHeight)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
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

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function()
		self:SetTestMode(false)
		frame:Hide()
	end)

	local okResize, resize = pcall(CreateFrame, "Button", nil, frame, "UIPanelResizeButtonTemplate")
	if not okResize or not resize then
		resize = CreateFrame("Button", nil, frame)
		resize:SetSize(16, 16)
		local tex = resize:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints()
		tex:SetColorTexture(0.8, 0.8, 0.8, 0.7)
		resize:SetNormalTexture(tex)
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
	tabsHost:SetWidth(170)

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

	local scroll = CreateFrame("ScrollFrame", nil, contentHost, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -28, 8)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(860, 200)
	scroll:SetScrollChild(content)

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
			page = page,
			y = -12,
			width = math.max(760, contentHost:GetWidth() - 52),
			colGap = 24,
			col = 1,
			rowHeight = 0,
		}
		builder.colWidth = math.max(280, math.floor((builder.width - builder.colGap) / 2))

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
			self:BeginNewLine()
			local fs = self.page:CreateFontString(nil, "OVERLAY", large and "GameFontNormalLarge" or "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			fs:SetText(text)
			self.y = self.y - (large and 26 or 18)
		end

		function builder:Edit(label, getter, setter)
			local x, y, width = self:Reserve(56, false)
			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			fs:SetText(label)
			local eb = CreateFrame("EditBox", nil, self.page, "InputBoxTemplate")
			eb:SetAutoFocus(false)
			eb:SetSize(width, 22)
			eb:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y - 20)
			eb:SetText(tostring(getter() or ""))
			eb:SetScript("OnEnterPressed", function(w)
				setter(w:GetText())
				w:ClearFocus()
			end)
			eb:SetScript("OnEscapePressed", function(w)
				w:ClearFocus()
			end)
		end

		function builder:Slider(label, minv, maxv, step, getter, setter)
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
			if text then text:SetText(label) end
			if low then low:SetText(tostring(minv)) end
			if high then high:SetText(tostring(maxv)) end
			s:SetScript("OnValueChanged", function(_, v)
				setter(v)
			end)
		end

		function builder:Check(label, getter, setter, disabled)
			local x, y = self:Reserve(28, false)
			local c = CreateFrame("CheckButton", nil, self.page, "UICheckButtonTemplate")
			c:SetPoint("TOPLEFT", self.page, "TOPLEFT", x - 2, y)
			if c.Text then c.Text:SetText(label) end
			c:SetChecked(getter() and true or false)
			c:SetEnabled(not disabled)
			c:SetScript("OnClick", function(w)
				setter(w:GetChecked() and true or false)
			end)
		end

		function builder:Dropdown(label, options, getter, setter)
			local x, y, width = self:Reserve(58, false)
			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			fs:SetText(label)
			addon._optDropdownId = (addon._optDropdownId or 0) + 1
			local name = "SUF_OptDropdown_" .. tabKey .. "_" .. addon._optDropdownId
			local dd = CreateFrame("Frame", name, self.page, "UIDropDownMenuTemplate")
			dd:SetPoint("TOPLEFT", self.page, "TOPLEFT", x - 16, y - 10)
			UIDropDownMenu_SetWidth(dd, math.max(180, width - 42))
			UIDropDownMenu_Initialize(dd, function(_, level)
				if level ~= 1 then
					return
				end
				for _, item in ipairs(options or {}) do
					local info = UIDropDownMenu_CreateInfo()
					info.text = item.text
					info.value = item.value
					info.checked = (getter() == item.value)
					info.func = function()
						UIDropDownMenu_SetSelectedValue(dd, item.value)
						UIDropDownMenu_SetText(dd, tostring(item.text))
						setter(item.value)
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end)

			local current = getter()
			if current ~= nil then
				UIDropDownMenu_SetSelectedValue(dd, current)
				local selectedText = tostring(current)
				for _, item in ipairs(options or {}) do
					if item.value == current then
						selectedText = tostring(item.text)
						break
					end
				end
				UIDropDownMenu_SetText(dd, selectedText)
			end
		end

		function builder:Color(label, getter, setter)
			local x, y, width = self:Reserve(38, false)
			local button = CreateFrame("Button", nil, self.page, "UIPanelButtonTemplate")
			button:SetSize(40, 20)
			button:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y - 2)
			button:SetText("")

			local swatch = button:CreateTexture(nil, "ARTWORK")
			swatch:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
			swatch:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
			swatch:SetColorTexture(1, 1, 1, 1)

			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("LEFT", button, "RIGHT", 8, 0)
			fs:SetWidth(math.max(120, width - 52))
			fs:SetJustifyH("LEFT")
			fs:SetText(label)

			local function RefreshSwatch()
				local c = getter and getter() or nil
				local r = c and c[1] or 1
				local g = c and c[2] or 1
				local b = c and c[3] or 1
				swatch:SetColorTexture(r, g, b, 1)
			end

			local function OpenColorPicker()
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
			RefreshSwatch()
		end

		function builder:Paragraph(text, small)
			self:BeginNewLine()
			local fs = self.page:CreateFontString(nil, "OVERLAY", small and "GameFontHighlightSmall" or "GameFontHighlight")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			fs:SetWidth(self.width)
			fs:SetJustifyH("LEFT")
			fs:SetJustifyV("TOP")
			fs:SetText(text or "")
			local height = math.max(16, math.floor((fs:GetStringHeight() or 0) + 0.5))
			self.y = self.y - (height + 8)
		end

		function builder:GetHeight()
			local tail = self.y - ((self.col == 2) and self.rowHeight or 0)
			return math.abs(tail) + 24
		end

		return builder
	end

	function frame.BuildTab(_, tabKey)
		frame.currentTab = tabKey
		StopPerformanceSnapshotTicker()
		for key, button in pairs(tabButtons) do
			button:SetEnabled(key ~= tabKey)
		end
		self.isBuildingOptions = true
		ClearContent()

		local page = CreateFrame("Frame", nil, content)
		page:SetPoint("TOPLEFT", content, "TOPLEFT")
		page:SetWidth(math.max(760, contentHost:GetWidth() - 44))
		local ui = NewBuilder(page, tabKey)
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
			return UNIT_LABELS[unitKey] or tostring(unitKey)
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

		if tabKey == "global" then
			ui:Label("Global Options", true)
			if #statusbarOptions > 0 then
				ui:Dropdown("Statusbar Texture", statusbarOptions, function() return self.db.profile.media.statusbar end, function(v) self.db.profile.media.statusbar = v; self:ScheduleUpdateAll() end)
			else
				ui:Edit("Statusbar Texture Name", function() return self.db.profile.media.statusbar end, function(v) self.db.profile.media.statusbar = v; self:ScheduleUpdateAll() end)
			end
			if #fontOptions > 0 then
				ui:Dropdown("Font", fontOptions, function() return self.db.profile.media.font end, function(v) self.db.profile.media.font = v; self:ScheduleUpdateAll() end)
			else
				ui:Edit("Font Name", function() return self.db.profile.media.font end, function(v) self.db.profile.media.font = v; self:ScheduleUpdateAll() end)
			end
			ui:Slider("Power Bar Height", 4, 20, 1, function() return self.db.profile.powerHeight end, function(v) self.db.profile.powerHeight = v; self:ScheduleUpdateAll() end)
			ui:Slider("Class Power Height", 4, 20, 1, function() return self.db.profile.classPowerHeight end, function(v) self.db.profile.classPowerHeight = v; self:ScheduleUpdateAll() end)
			ui:Slider("Class Power Spacing", 0, 10, 1, function() return self.db.profile.classPowerSpacing end, function(v) self.db.profile.classPowerSpacing = v; self:ScheduleUpdateAll() end)
			ui:Slider("Castbar Height", 8, 30, 1, function() return self.db.profile.castbarHeight end, function(v) self.db.profile.castbarHeight = v; self:ScheduleUpdateAll() end)
			ui:Label("Castbar Enhancements", false)
			ui:Dropdown("Castbar Color Profile", {
				{ value = "UUF", text = "UUF" },
				{ value = "Blizzard", text = "Blizzard" },
				{ value = "HighContrast", text = "High Contrast" },
			}, function() return self.db.profile.castbar.colorProfile end, function(v) self.db.profile.castbar.colorProfile = v; self:ScheduleUpdateAll() end)
			ui:Check("Castbar Icon", function() return self.db.profile.castbar.iconEnabled ~= false end, function(v) self.db.profile.castbar.iconEnabled = v; self:ScheduleUpdateAll() end)
			ui:Dropdown("Castbar Icon Position", {
				{ value = "LEFT", text = "Left" },
				{ value = "RIGHT", text = "Right" },
			}, function() return self.db.profile.castbar.iconPosition end, function(v) self.db.profile.castbar.iconPosition = v; self:ScheduleUpdateAll() end)
			ui:Slider("Castbar Icon Size", 12, 40, 1, function() return self.db.profile.castbar.iconSize end, function(v) self.db.profile.castbar.iconSize = v; self:ScheduleUpdateAll() end)
			ui:Slider("Castbar Icon Gap", 0, 12, 1, function() return self.db.profile.castbar.iconGap end, function(v) self.db.profile.castbar.iconGap = v; self:ScheduleUpdateAll() end)
			ui:Check("Castbar Shield", function() return self.db.profile.castbar.showShield ~= false end, function(v) self.db.profile.castbar.showShield = v; self:ScheduleUpdateAll() end)
			ui:Check("Castbar Latency Safe Zone", function() return self.db.profile.castbar.showSafeZone ~= false end, function(v) self.db.profile.castbar.showSafeZone = v; self:ScheduleUpdateAll() end)
			ui:Slider("Safe Zone Opacity", 0.05, 1, 0.05, function() return self.db.profile.castbar.safeZoneAlpha end, function(v) self.db.profile.castbar.safeZoneAlpha = v; self:ScheduleUpdateAll() end)
			ui:Check("Castbar Spark", function() return self.db.profile.castbar.showSpark ~= false end, function(v) self.db.profile.castbar.showSpark = v; self:ScheduleUpdateAll() end)
			ui:Slider("Spell Name Max Chars", 6, 40, 1, function() return self.db.profile.castbar.spellMaxChars end, function(v) self.db.profile.castbar.spellMaxChars = v; self:ScheduleUpdateAll() end)
			ui:Slider("Cast Time Decimals", 0, 2, 1, function() return self.db.profile.castbar.timeDecimals end, function(v) self.db.profile.castbar.timeDecimals = v; self:ScheduleUpdateAll() end)
			ui:Check("Show Cast Delay", function() return self.db.profile.castbar.showDelay ~= false end, function(v) self.db.profile.castbar.showDelay = v; self:ScheduleUpdateAll() end)
			ui:Check("Hide in Vehicle", function() return self.db.profile.visibility.hideVehicle end, function(v) self.db.profile.visibility.hideVehicle = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide in Pet Battles", function() return self.db.profile.visibility.hidePetBattle end, function(v) self.db.profile.visibility.hidePetBattle = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide with Override Bar", function() return self.db.profile.visibility.hideOverride end, function(v) self.db.profile.visibility.hideOverride = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide with Possess Bar", function() return self.db.profile.visibility.hidePossess end, function(v) self.db.profile.visibility.hidePossess = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide with Extra Bar", function() return self.db.profile.visibility.hideExtra end, function(v) self.db.profile.visibility.hideExtra = v; self:ScheduleApplyVisibility() end)
			ui:Label("Party Header", false)
			ui:Check("Show Player In Party", function() return self.db.profile.party.showPlayerInParty ~= false end, function(v)
				self.db.profile.party.showPlayerInParty = v
				self:TrySpawnGroupHeaders()
				self:ApplyPartyHeaderSettings()
			end)
			ui:Check("Show Player When Solo", function() return self.db.profile.party.showPlayerWhenSolo == true end, function(v)
				self.db.profile.party.showPlayerWhenSolo = v
				self:TrySpawnGroupHeaders()
				self:ApplyPartyHeaderSettings()
			end)
			ui:Slider("Party Vertical Spacing", 0, 40, 1, function() return self.db.profile.party.spacing end, function(v)
				self.db.profile.party.spacing = v
				self:ApplyPartyHeaderSettings()
			end)
			ui:Dropdown("Absorb Value Tag", {
				{ value = "[suf:absorbs:abbr]", text = "Abbreviated ([suf:absorbs:abbr])" },
				{ value = "[suf:absorbs]", text = "Raw ([suf:absorbs])" },
				{ value = "", text = "Hidden" },
			}, function()
				return self.db.profile.absorbValueTag or "[suf:absorbs:abbr]"
			end, function(v)
				self.db.profile.absorbValueTag = v
				self:ScheduleUpdateAll()
			end)
			ui:Check("Test Mode (Show All Frames)", function() return self.testMode end, function(v) self:SetTestMode(v) end)
			ui:Check("Enable PerformanceLib Integration", function() return self.db.profile.performance and self.db.profile.performance.enabled end, function(v) self:SetPerformanceIntegrationEnabled(v) end, not self.performanceLib)
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
			AddActionButton("Refresh Snapshot", function()
				frame:BuildTab("performance")
			end)

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
			local box = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			box:SetAutoFocus(false)
			box:SetMultiLine(true)
			box:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -36)
			box:SetSize(math.max(420, contentHost:GetWidth() - 72), 220)
			local exportBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			exportBtn:SetSize(140, 24)
			exportBtn:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
			exportBtn:SetText("Export")
			exportBtn:SetScript("OnClick", function()
				local data, err = self:SerializeProfile()
				if data then box:SetText(data) else self:Print(addonName .. ": " .. err) end
			end)
			local importBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			importBtn:SetSize(140, 24)
			importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 12, 0)
			importBtn:SetText("Import")
			importBtn:SetScript("OnClick", function()
				local data, err = self:DeserializeProfile(box:GetText() or "")
				if data then
					local ok, applyErr = self:ApplyImportedProfile(data)
					if not ok then self:Print(addonName .. ": " .. applyErr) end
				else
					self:Print(addonName .. ": " .. err)
				end
			end)
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
			ui:Label("SUF Custom Tags", false)
			ui:Paragraph("suf:absorbs, suf:absorbs:abbr", true)
		elseif tabKey == "credits" then
			ui:Label("Credits", true)
			ui:Paragraph("SimpleUnitFrames (SUF)\nPrimary Author: Grevin", true)
			ui:Paragraph("UnhaltedUnitFrames (UUF)\nReference architecture, performance patterns, and feature inspirations.\nIncludes UUF-inspired ports plus your personal custom changes that are not present in UUF mainline.", true)
			ui:Paragraph("Libraries Used\nAce3 (AceAddon/AceDB/AceGUI/AceSerializer), oUF, LibSharedMedia-3.0, LibDualSpec-1.0, LibSerialize, LibDeflate, LibDataBroker-1.1, LibDBIcon-1.0, CallbackHandler-1.0, LibStub, TaintLess.", true)
			ui:Paragraph("Special Thanks\nBlizzard UI Source and WoW addon ecosystem maintainers.", true)
		else
			local unitSettings = self:GetUnitSettings(tabKey)
			local tags = self.db.profile.tags[tabKey]
			local size = self.db.profile.sizes[tabKey]
			unitSettings.fontSizes = unitSettings.fontSizes or CopyTableDeep(self.db.profile.fontSizes)
			unitSettings.portrait = unitSettings.portrait or { mode = "none", size = 32, showClass = false, position = "LEFT" }
			unitSettings.media = unitSettings.media or { statusbar = self.db.profile.media.statusbar }
			unitSettings.castbar = unitSettings.castbar or CopyTableDeep(DEFAULT_UNIT_CASTBAR)
			unitSettings.layout = unitSettings.layout or CopyTableDeep(DEFAULT_UNIT_LAYOUT)
			unitSettings.healPrediction = unitSettings.healPrediction or CopyTableDeep(DEFAULT_HEAL_PREDICTION)
			ui:Label((tabKey == "tot" and "TargetOfTarget" or tabKey:upper()) .. " Options", true)
			ui:Slider("Frame Width", 80, 400, 1, function() return size.width end, function(v) size.width = v; self:ScheduleUpdateAll() end)
			ui:Slider("Frame Height", 18, 80, 1, function() return size.height end, function(v) size.height = v; self:ScheduleUpdateAll() end)
			ui:Edit("Name Tag", function() return tags.name end, function(v) tags.name = v; self:ScheduleUpdateAll() end)
			ui:Edit("Level Tag", function() return tags.level end, function(v) tags.level = v; self:ScheduleUpdateAll() end)
			ui:Edit("Health Tag", function() return tags.health end, function(v) tags.health = v; self:ScheduleUpdateAll() end)
			ui:Edit("Power Tag", function() return tags.power end, function(v) tags.power = v; self:ScheduleUpdateAll() end)
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
			ui:Label("Resource Layout", false)
			ui:Slider("Secondary Power Gap (Top)", -6, 24, 1, function() return unitSettings.layout.secondaryToFrame end, function(v) unitSettings.layout.secondaryToFrame = v; self:ScheduleUpdateAll() end)
			ui:Slider("Class Resource Gap (Top)", -6, 24, 1, function() return unitSettings.layout.classToSecondary end, function(v) unitSettings.layout.classToSecondary = v; self:ScheduleUpdateAll() end)
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
			ui:Label("Heal Prediction", false)
			ui:Check("Enable Heal Prediction", function() return unitSettings.healPrediction.enabled ~= false end, function(v) unitSettings.healPrediction.enabled = v; self:ScheduleUpdateAll() end)
			ui:Check("Incoming Heals", function() return unitSettings.healPrediction.incoming.enabled ~= false end, function(v) unitSettings.healPrediction.incoming.enabled = v; self:ScheduleUpdateAll() end)
			ui:Check("Split Incoming Heals", function() return unitSettings.healPrediction.incoming.split == true end, function(v) unitSettings.healPrediction.incoming.split = v; self:ScheduleUpdateAll() end)
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
			ui:Check("Show Resting Indicator", function() return unitSettings.showResting end, function(v) unitSettings.showResting = v; self:ScheduleUpdateAll() end)
			ui:Check("Show PvP Indicator", function() return unitSettings.showPvp end, function(v) unitSettings.showPvp = v; self:ScheduleUpdateAll() end)
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
		end

		local wanted = ui:GetHeight()
		page:SetHeight(wanted)
		content:SetHeight(wanted)
		self.isBuildingOptions = false
	end

	local tabStartY = -(iconSize + 24)
	for i, tab in ipairs(tabs) do
		local button = CreateFrame("Button", nil, tabsHost, "UIPanelButtonTemplate")
		button:SetSize(150, 24)
		button:SetPoint("TOPLEFT", tabsHost, "TOPLEFT", 10, tabStartY - ((i - 1) * 28))
		button:SetText(tab.label)
		button:SetScript("OnClick", function()
			frame:BuildTab(tab.key)
		end)
		tabButtons[tab.key] = button
	end

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

	frame:Show()
	frame:BuildTab("global")
	self.optionsFrame = frame
end

function addon:OnInitialize()
	ChatMsg(addonName .. ": OnInitialize")
	self.allowGroupHeaders = false
	self:SetupPerformanceLib()
	self:SetupEventBus()

	self.db = AceDB:New("SimpleUnitFramesDB", defaults, true)
	if self.db:GetCurrentProfile() ~= "Global" then
		self.db:SetProfile("Global")
	end

	if not self.db.profile.units then
		self.db.profile.units = CopyTableDeep(defaults.profile.units)
	end

	if not self.db.profile.indicators then
		self.db.profile.indicators = CopyTableDeep(defaults.profile.indicators)
	end
	if self.db.profile.indicators.version ~= defaults.profile.indicators.version then
		self.db.profile.indicators.size = defaults.profile.indicators.size
		self.db.profile.indicators.offsetX = defaults.profile.indicators.offsetX
		self.db.profile.indicators.offsetY = defaults.profile.indicators.offsetY
		self.db.profile.indicators.version = defaults.profile.indicators.version
	elseif self.db.profile.indicators.size == nil or self.db.profile.indicators.offsetX == nil or self.db.profile.indicators.offsetY == nil then
		if self.db.profile.indicators.size == nil then
			self.db.profile.indicators.size = defaults.profile.indicators.size
		end
		if self.db.profile.indicators.offsetX == nil then
			self.db.profile.indicators.offsetX = defaults.profile.indicators.offsetX
		end
		if self.db.profile.indicators.offsetY == nil then
			self.db.profile.indicators.offsetY = defaults.profile.indicators.offsetY
		end
	end

	if not self.db.profile.party then
		self.db.profile.party = CopyTableDeep(defaults.profile.party)
	else
		for key, value in pairs(defaults.profile.party) do
			if self.db.profile.party[key] == nil then
				self.db.profile.party[key] = value
			end
		end
	end
	if not self.db.profile.performance then
		self.db.profile.performance = CopyTableDeep(defaults.profile.performance)
	end
	if self.db.profile.performance.optionsAutoRefresh == nil then
		self.db.profile.performance.optionsAutoRefresh = defaults.profile.performance.optionsAutoRefresh
	end
	if not self.db.profile.minimap then
		self.db.profile.minimap = CopyTableDeep(defaults.profile.minimap)
	end
	if self.db.profile.absorbValueTag == nil then
		self.db.profile.absorbValueTag = defaults.profile.absorbValueTag
	end
	if self.db.profile.performance.enabled == nil then
		self.db.profile.performance.enabled = defaults.profile.performance.enabled
	end
	if not self.db.profile.castbar then
		self.db.profile.castbar = CopyTableDeep(defaults.profile.castbar)
	else
		for key, value in pairs(defaults.profile.castbar) do
			if self.db.profile.castbar[key] == nil then
				self.db.profile.castbar[key] = value
			end
		end
	end
	self:EnsureDebugConfig()
	self.debugMessages = self.debugMessages or {}

	for unitType, unitDefaults in pairs(defaults.profile.units) do
		if not self.db.profile.units[unitType] then
			self.db.profile.units[unitType] = CopyTableDeep(unitDefaults)
		else
			if not self.db.profile.units[unitType].fontSizes then
				self.db.profile.units[unitType].fontSizes = CopyTableDeep(unitDefaults.fontSizes)
			end
			if not self.db.profile.units[unitType].media then
				self.db.profile.units[unitType].media = CopyTableDeep(unitDefaults.media)
			end
			if not self.db.profile.units[unitType].portrait then
				self.db.profile.units[unitType].portrait = CopyTableDeep(unitDefaults.portrait)
			end
			if not self.db.profile.units[unitType].castbar then
				self.db.profile.units[unitType].castbar = CopyTableDeep(DEFAULT_UNIT_CASTBAR)
			else
				local castbar = self.db.profile.units[unitType].castbar
				if castbar.gap == nil then
					local legacyOffset = tonumber(castbar.offsetY)
					castbar.gap = legacyOffset and math.max(0, math.abs(legacyOffset)) or DEFAULT_UNIT_CASTBAR.gap
					if legacyOffset ~= nil then
						castbar.offsetY = 0
					end
				end
				for key, value in pairs(DEFAULT_UNIT_CASTBAR) do
					if castbar[key] == nil then
						castbar[key] = value
					end
				end
			end
			if not self.db.profile.units[unitType].layout then
				self.db.profile.units[unitType].layout = CopyTableDeep(DEFAULT_UNIT_LAYOUT)
			else
				local layout = self.db.profile.units[unitType].layout
				MergeDefaults(layout, DEFAULT_UNIT_LAYOUT)
				if (layout.version or 0) < DEFAULT_UNIT_LAYOUT.version then
					if layout.secondaryToFrame == 2 then
						layout.secondaryToFrame = 0
					end
					if layout.classToSecondary == 2 then
						layout.classToSecondary = 0
					end
					layout.version = DEFAULT_UNIT_LAYOUT.version
				end
			end
			if not self.db.profile.units[unitType].healPrediction then
				self.db.profile.units[unitType].healPrediction = CopyTableDeep(DEFAULT_HEAL_PREDICTION)
			else
				MergeDefaults(self.db.profile.units[unitType].healPrediction, DEFAULT_HEAL_PREDICTION)
			end
			if self.db.profile.units[unitType].auraSize == nil and unitDefaults.auraSize ~= nil then
				self.db.profile.units[unitType].auraSize = unitDefaults.auraSize
			end
		end
	end

	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, "SimpleUnitFrames")
	end

	self:RegisterChatCommand("suf", "HandleSUFSlash")
	self:RegisterChatCommand("sufdebug", "HandleDebugSlash")
end

function addon:OnEnable()
	ChatMsg(addonName .. ": OnEnable")
	self:DebugLog("General", "Addon enabled.", 2)
	self:InitializeLauncher()
	if not self.performanceLib then
		self:SetupPerformanceLib()
	end
	if self.db and self.db.profile and self.db.profile.performance then
		local enabled = self.db.profile.performance.enabled
		local ok = self:SetPerformanceIntegrationEnabled(enabled, true)
		if enabled and not ok then
			self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
		end
	end

	if IsLoggedIn and IsLoggedIn() then
		C_Timer.After(0, function()
			self:OnPlayerEnteringWorld()
		end)
	else
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
	end

	local function RegisterIfExists(eventName)
		local ok = pcall(self.RegisterEvent, self, eventName, "UpdateBlizzardFrames")
		return ok
	end

	RegisterIfExists("EDIT_MODE_ENTER")
	RegisterIfExists("EDIT_MODE_EXIT")
	RegisterIfExists("EDIT_MODE_LAYOUTS_UPDATED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnGroupRosterUpdate")

	if self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.showPanel then
		self:ShowDebugPanel()
	end
end

function addon:OnAddonLoaded(event, loadedAddon)
	if loadedAddon ~= "PerformanceLib" then
		return
	end

	self:UnregisterEvent("ADDON_LOADED")
	self:SetupPerformanceLib()
	if self.db and self.db.profile and self.db.profile.performance then
		self:SetPerformanceIntegrationEnabled(self.db.profile.performance.enabled, true)
	end
end

function addon:OnDisable()
	self:UnregisterPerformanceEventFrame()
	self:UnregisterPerformanceCoalescedHandlers()
	self:TeardownMLCoalescerIntegration()
	if self.minimapButton then
		self.minimapButton:Hide()
	end
	if self.performanceLib and self.performanceLib.SetOutputSink then
		self.performanceLib:SetOutputSink(nil, nil)
	end
	self:ReleaseAllPooledResources()
end
