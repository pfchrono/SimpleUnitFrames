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
local LibSimpleSticky = LibStub("LibSimpleSticky-1.0", true)
local LibTranslit = LibStub("LibTranslit-1.0", true)
local LibCustomGlow = LibStub("LibCustomGlow-1.0", true)

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
		optionsUI = {
			sectionState = {},
			searchShowCounts = true,
			searchKeyboardHints = true,
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
		mainBarsBackground = {
			enabled = true,
			texture = "Blizzard",
			color = { 0.05, 0.05, 0.05 },
			alpha = 0.40,
		},
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
		enhancements = {
			stickyWindows = true,
			stickyRange = 15,
			translitNames = false,
			translitMarker = "",
			castbarNonInterruptibleGlow = true,
			uiOpenAnimation = true,
			uiOpenAnimationDuration = 0.18,
			uiOpenAnimationOffsetY = 12,
		},
		plugins = {
			raidDebuffs = {
				enabled = true,
				size = 18,
				glow = true,
				glowMode = "ALL",
			},
			auraWatch = {
				enabled = true,
				size = 10,
				numBuffs = 3,
				numDebuffs = 3,
				showDebuffType = true,
				customSpellList = "",
				replaceDefaults = false,
			},
			fader = {
				enabled = false,
				minAlpha = 0.45,
				maxAlpha = 1.0,
				smooth = 0.2,
				combat = true,
				hover = true,
				playerTarget = true,
				actionTarget = false,
				unitTarget = false,
				casting = false,
			},
			units = {
				party = {
					useGlobal = true,
					raidDebuffs = {
						enabled = true,
						size = 18,
						glow = true,
						glowMode = "ALL",
					},
					auraWatch = {
						enabled = true,
						size = 10,
						numBuffs = 3,
						numDebuffs = 3,
						showDebuffType = true,
						customSpellList = "",
						replaceDefaults = false,
					},
					fader = {
						enabled = false,
						minAlpha = 0.45,
						maxAlpha = 1.0,
						smooth = 0.2,
						combat = true,
						hover = true,
						playerTarget = true,
						actionTarget = false,
						unitTarget = false,
						casting = false,
					},
				},
				raid = {
					useGlobal = true,
					raidDebuffs = {
						enabled = true,
						size = 18,
						glow = true,
						glowMode = "ALL",
					},
					auraWatch = {
						enabled = true,
						size = 10,
						numBuffs = 3,
						numDebuffs = 3,
						showDebuffType = true,
						customSpellList = "",
						replaceDefaults = false,
					},
					fader = {
						enabled = false,
						minAlpha = 0.45,
						maxAlpha = 1.0,
						smooth = 0.2,
						combat = true,
						hover = true,
						playerTarget = true,
						actionTarget = false,
						unitTarget = false,
						casting = false,
					},
				},
			},
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
				IncomingText = false,
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

local MODULE_COPY_RESET_KEYS = {
	{ value = "castbar", text = "Castbar" },
	{ value = "fader", text = "Frame Fader (Group Units)" },
	{ value = "aurawatch", text = "AuraWatch (Group Units)" },
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

local DEFAULT_UNIT_MAIN_BARS_BACKGROUND = {
	useGlobal = true,
	enabled = true,
	texture = "Blizzard",
	color = { 0.05, 0.05, 0.05 },
	alpha = 0.40,
}

local DEFAULT_AURAWATCH_WATCHED = {
	[17] = { enabled = true, anyUnit = true, point = "TOPLEFT", xOffset = 1, yOffset = -1 }, -- Power Word: Shield
	[774] = { enabled = true, anyUnit = true, point = "TOP", xOffset = 0, yOffset = -1 }, -- Rejuvenation
	[139] = { enabled = true, anyUnit = true, point = "TOPRIGHT", xOffset = -1, yOffset = -1 }, -- Renew
	[1022] = { enabled = true, anyUnit = true, point = "BOTTOMLEFT", xOffset = 1, yOffset = 1 }, -- Blessing of Protection
	[6940] = { enabled = true, anyUnit = true, point = "BOTTOM", xOffset = 0, yOffset = 1 }, -- Blessing of Sacrifice
	[33206] = { enabled = true, anyUnit = true, point = "BOTTOMRIGHT", xOffset = -1, yOffset = 1 }, -- Pain Suppression
}

local HasVisibleClassPower
local INCOMING_VALUE_FEATURE_ENABLED = false

local DEFAULT_HEAL_PREDICTION = {
	enabled = true,
	incoming = {
		enabled = true,
		split = false,
		valueMode = "SAFE",
		showValueText = false,
		valuePlaceholder = "~",
		valueFontSize = 10,
		valueColor = { 0.35, 0.95, 0.45 },
		valueOffsetX = 2,
		valueOffsetY = 0,
		opacity = 0.40,
		height = 1.00,
		colorAll = { 0.35, 0.95, 0.45 },
		colorPlayer = { 0.35, 0.95, 0.45 },
		colorOther = { 0.20, 0.75, 0.35 },
	},
	absorbs = {
		enabled = true,
		opacity = 0.75,
		height = 1.00,
		color = { 1.00, 0.95, 0.20 },
		position = "RIGHT",
		showGlow = true,
		glowOpacity = 0.95,
	},
	healAbsorbs = {
		enabled = true,
		opacity = 0.55,
		height = 1.00,
		color = { 0.95, 0.25, 0.25 },
		position = "RIGHT",
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
	UNIT_HEALTH = 2,
	UNIT_POWER_UPDATE = 2,
	UNIT_MAXHEALTH = 2,
	UNIT_HEAL_PREDICTION = 2,
	UNIT_ABSORB_AMOUNT_CHANGED = 2,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = 2,
	UNIT_MAXPOWER = 2,
	UNIT_DISPLAYPOWER = 3,
	UNIT_AURA = 3,
	UNIT_THREAT_SITUATION_UPDATE = 3,
	UNIT_THREAT_LIST_UPDATE = 3,
	PLAYER_TOTEM_UPDATE = 3,
	RUNE_POWER_UPDATE = 3,
	UNIT_SPELLCAST_CHANNEL_UPDATE = 3,
	UNIT_PORTRAIT_UPDATE = 4,
	UNIT_MODEL_CHANGED = 4,
	UNIT_NAME_UPDATE = 4,
	UNIT_FACTION = 4,
	UNIT_FLAGS = 4,
	UNIT_CONNECTION = 4,
	RAID_TARGET_UPDATE = 4,
	GROUP_ROSTER_UPDATE = 4,
	PLAYER_ROLES_ASSIGNED = 4,
	PARTY_LEADER_CHANGED = 4,
}

local PERF_DIRTY_PRIORITY = {
	[1] = 4,
	[2] = 3,
	[3] = 2,
	[4] = 1,
}

local EVENT_COALESCE_CONFIG = {
	UNIT_HEALTH = { delay = 0.16, priority = 3 },
	UNIT_HEAL_PREDICTION = { delay = 0.14, priority = 3 },
	UNIT_ABSORB_AMOUNT_CHANGED = { delay = 0.12, priority = 3 },
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = { delay = 0.12, priority = 3 },
	UNIT_POWER_UPDATE = { delay = 0.16, priority = 3 },
	UNIT_MAXHEALTH = { delay = 0.12, priority = 2 },
	UNIT_MAXPOWER = { delay = 0.12, priority = 2 },
	UNIT_DISPLAYPOWER = { delay = 0.12, priority = 3 },
	UNIT_AURA = { delay = 0.18, priority = 3 },
	UNIT_THREAT_SITUATION_UPDATE = { delay = 0.14, priority = 3 },
	UNIT_THREAT_LIST_UPDATE = { delay = 0.14, priority = 3 },
	PLAYER_TOTEM_UPDATE = { delay = 0.05, priority = 3 },
	RUNE_POWER_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_SPELLCAST_CHANNEL_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_PORTRAIT_UPDATE = { delay = 0.20, priority = 4 },
	UNIT_MODEL_CHANGED = { delay = 0.20, priority = 4 },
	UNIT_NAME_UPDATE = { delay = 0.15, priority = 4 },
	UNIT_FACTION = { delay = 0.15, priority = 4 },
	UNIT_FLAGS = { delay = 0.10, priority = 4 },
	UNIT_CONNECTION = { delay = 0.10, priority = 4 },
	RAID_TARGET_UPDATE = { delay = 0.05, priority = 4 },
	GROUP_ROSTER_UPDATE = { delay = 0.12, priority = 4 },
	PLAYER_ROLES_ASSIGNED = { delay = 0.12, priority = 4 },
	PARTY_LEADER_CHANGED = { delay = 0.12, priority = 4 },
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
	UNIT_FLAGS = true,
	UNIT_CONNECTION = true,
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

local function SetMousePassthrough(widget)
	if not widget then
		return
	end
	if widget.EnableMouse then
		widget:EnableMouse(false)
	end
	if widget.SetMouseClickEnabled then
		widget:SetMouseClickEnabled(false)
	end
	if widget.SetMouseMotionEnabled then
		widget:SetMouseMotionEnabled(false)
	end
	if widget.SetPropagateMouseClicks then
		widget:SetPropagateMouseClicks(true)
	end
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

local ABSORB_FALLBACK_UNITS = {
	"player",
	"pet",
	"target",
	"targettarget",
	"focus",
	"party1",
	"party2",
	"party3",
	"party4",
}

local function ResolveReadableAbsorbValue(unit, healthValues)
	local function Call(fn, ...)
		if type(fn) ~= "function" then
			return nil, false
		end
		local ok, result = pcall(fn, ...)
		if not ok then
			return nil, false
		end
		return result, true
	end

	local function GetAbsorbFromUnit(token)
		if type(UnitGetTotalAbsorbs) ~= "function" then
			return nil
		end
		local result = Call(UnitGetTotalAbsorbs, token)
		return SafeNumber(result, nil)
	end

	local value = GetAbsorbFromUnit(unit)
	if value ~= nil then
		return value, unit
	end

	if healthValues and healthValues.GetDamageAbsorbs then
		local result = Call(healthValues.GetDamageAbsorbs, healthValues)
		value = SafeNumber(result, nil)
		if value ~= nil then
			return value, unit
		end
	end

	if type(UnitIsUnit) == "function" and type(UnitExists) == "function" then
		for i = 1, #ABSORB_FALLBACK_UNITS do
			local token = ABSORB_FALLBACK_UNITS[i]
			if token ~= unit and UnitExists(token) then
				local sameUnit = SafeBoolean(Call(UnitIsUnit, unit, token), false)
				if sameUnit then
					value = GetAbsorbFromUnit(token)
					if value ~= nil then
						return value, token
					end
				end
			end
		end
	end

	return nil, unit
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

function addon:GetMainBarsBackgroundSettings()
	self.db.profile.mainBarsBackground = self.db.profile.mainBarsBackground or CopyTableDeep(defaults.profile.mainBarsBackground)
	local cfg = self.db.profile.mainBarsBackground
	if cfg.enabled == nil then cfg.enabled = defaults.profile.mainBarsBackground.enabled end
	if not cfg.texture then cfg.texture = defaults.profile.mainBarsBackground.texture end
	if type(cfg.color) ~= "table" then
		cfg.color = CopyTableDeep(defaults.profile.mainBarsBackground.color)
	end
	if cfg.color[1] == nil then cfg.color[1] = defaults.profile.mainBarsBackground.color[1] end
	if cfg.color[2] == nil then cfg.color[2] = defaults.profile.mainBarsBackground.color[2] end
	if cfg.color[3] == nil then cfg.color[3] = defaults.profile.mainBarsBackground.color[3] end
	if type(cfg.alpha) ~= "number" then cfg.alpha = defaults.profile.mainBarsBackground.alpha end
	cfg.alpha = math.max(0, math.min(1, cfg.alpha))
	return cfg
end

function addon:GetUnitMainBarsBackgroundSettings(unitType)
	local globalCfg = self:GetMainBarsBackgroundSettings()
	local unit = self:GetUnitSettings(unitType)
	unit.mainBarsBackground = unit.mainBarsBackground or CopyTableDeep(DEFAULT_UNIT_MAIN_BARS_BACKGROUND)
	MergeDefaults(unit.mainBarsBackground, DEFAULT_UNIT_MAIN_BARS_BACKGROUND)

	local cfg = unit.mainBarsBackground
	cfg.alpha = math.max(0, math.min(1, tonumber(cfg.alpha) or globalCfg.alpha or 0.4))

	if cfg.useGlobal then
		return {
			useGlobal = true,
			enabled = globalCfg.enabled,
			texture = globalCfg.texture,
			color = { globalCfg.color[1], globalCfg.color[2], globalCfg.color[3] },
			alpha = globalCfg.alpha,
		}
	end

	return {
		useGlobal = false,
		enabled = cfg.enabled,
		texture = cfg.texture,
		color = { cfg.color[1], cfg.color[2], cfg.color[3] },
		alpha = cfg.alpha,
	}
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
	-- Normalize absorb position to right-side style for all units/profiles.
	if unit.healPrediction and unit.healPrediction.absorbs then
		unit.healPrediction.absorbs.position = "RIGHT"
	end

	return unit.healPrediction
end

function addon:GetPluginSettings()
	self.db.profile.plugins = self.db.profile.plugins or CopyTableDeep(defaults.profile.plugins)
	MergeDefaults(self.db.profile.plugins, defaults.profile.plugins)
	return self.db.profile.plugins
end

local function IsGroupUnitType(unitType)
	return unitType == "party" or unitType == "raid"
end

local function TrimString(value)
	if type(value) ~= "string" then
		return ""
	end
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function TruncateUTF8(text, maxChars)
	local s = SafeText(text, "")
	if s == "" then
		return s
	end
	local limit = tonumber(maxChars) or 0
	if limit <= 0 then
		return s
	end

	if string.utf8len and string.utf8sub then
		local okLen, length = pcall(string.utf8len, s)
		if okLen and length and length > limit then
			if limit <= 3 then
				local okTiny, tiny = pcall(string.utf8sub, s, 1, limit)
				return okTiny and tiny or s
			end
			local okSub, truncated = pcall(string.utf8sub, s, 1, limit - 3)
			if okSub and truncated then
				return truncated .. "..."
			end
		elseif okLen and length then
			return s
		end
	end

	if #s > limit then
		if limit <= 3 then
			return s:sub(1, limit)
		end
		return s:sub(1, limit - 3) .. "..."
	end
	return s
end

function addon:GetUnitPluginSettings(unitType)
	local plugins = self:GetPluginSettings()
	if not IsGroupUnitType(unitType) then
		return plugins
	end

	plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
	MergeDefaults(plugins.units, defaults.profile.plugins.units)

	local unitCfg = plugins.units[unitType] or CopyTableDeep(defaults.profile.plugins.units[unitType])
	plugins.units[unitType] = unitCfg
	unitCfg.raidDebuffs = unitCfg.raidDebuffs or {}
	unitCfg.auraWatch = unitCfg.auraWatch or {}
	unitCfg.fader = unitCfg.fader or {}

	if unitCfg.useGlobal ~= false then
		return plugins
	end

	local merged = {
		raidDebuffs = CopyTableDeep(plugins.raidDebuffs),
		auraWatch = CopyTableDeep(plugins.auraWatch),
		fader = CopyTableDeep(plugins.fader),
	}
	MergeDefaults(unitCfg, merged)

	for key, value in pairs(unitCfg.raidDebuffs or {}) do
		merged.raidDebuffs[key] = value
	end
	for key, value in pairs(unitCfg.auraWatch or {}) do
		merged.auraWatch[key] = value
	end
	for key, value in pairs(unitCfg.fader or {}) do
		merged.fader[key] = value
	end

	return merged
end

function addon:SeedUnitPluginOverridesFromGlobal(unitType)
	if not IsGroupUnitType(unitType) then
		return
	end
	local plugins = self:GetPluginSettings()
	plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
	local unitCfg = plugins.units[unitType] or {}
	plugins.units[unitType] = unitCfg

	unitCfg.useGlobal = false
	unitCfg.raidDebuffs = CopyTableDeep(plugins.raidDebuffs or defaults.profile.plugins.raidDebuffs)
	unitCfg.auraWatch = CopyTableDeep(plugins.auraWatch or defaults.profile.plugins.auraWatch)
	unitCfg.fader = CopyTableDeep(plugins.fader or defaults.profile.plugins.fader)
end

function addon:NormalizePluginConfig()
	local plugins = self:GetPluginSettings()
	local function ClampNumber(value, minValue, maxValue, fallback)
		local n = tonumber(value)
		if not n then
			return fallback
		end
		if minValue and n < minValue then
			n = minValue
		end
		if maxValue and n > maxValue then
			n = maxValue
		end
		return n
	end

	plugins.raidDebuffs.size = ClampNumber(plugins.raidDebuffs.size, 12, 36, defaults.profile.plugins.raidDebuffs.size)
	if plugins.raidDebuffs.glowMode ~= "DISPELLABLE" and plugins.raidDebuffs.glowMode ~= "PRIORITY" then
		plugins.raidDebuffs.glowMode = "ALL"
	end
	plugins.auraWatch.size = ClampNumber(plugins.auraWatch.size, 8, 22, defaults.profile.plugins.auraWatch.size)
	plugins.auraWatch.numBuffs = ClampNumber(plugins.auraWatch.numBuffs, 0, 8, defaults.profile.plugins.auraWatch.numBuffs)
	plugins.auraWatch.numDebuffs = ClampNumber(plugins.auraWatch.numDebuffs, 0, 8, defaults.profile.plugins.auraWatch.numDebuffs)
	plugins.fader.minAlpha = ClampNumber(plugins.fader.minAlpha, 0.05, 1, defaults.profile.plugins.fader.minAlpha)
	plugins.fader.maxAlpha = ClampNumber(plugins.fader.maxAlpha, 0.05, 1, defaults.profile.plugins.fader.maxAlpha)
	plugins.fader.smooth = ClampNumber(plugins.fader.smooth, 0, 1, defaults.profile.plugins.fader.smooth)
	plugins.auraWatch.customSpellList = SafeText(plugins.auraWatch.customSpellList, "")
	local enhancement = self:GetEnhancementSettings()
	enhancement.uiOpenAnimationDuration = ClampNumber(enhancement.uiOpenAnimationDuration, 0.05, 0.60, 0.18)
	enhancement.uiOpenAnimationOffsetY = ClampNumber(enhancement.uiOpenAnimationOffsetY, -40, 40, 12)

	local unitPlugins = plugins.units or {}
	for unitType, unitCfg in pairs(unitPlugins) do
		if IsGroupUnitType(unitType) then
			unitCfg.raidDebuffs = unitCfg.raidDebuffs or {}
			unitCfg.auraWatch = unitCfg.auraWatch or {}
			unitCfg.fader = unitCfg.fader or {}
			unitCfg.raidDebuffs.size = ClampNumber(unitCfg.raidDebuffs.size, 12, 36, plugins.raidDebuffs.size)
			if unitCfg.raidDebuffs.glowMode ~= "DISPELLABLE" and unitCfg.raidDebuffs.glowMode ~= "PRIORITY" then
				unitCfg.raidDebuffs.glowMode = "ALL"
			end
			unitCfg.auraWatch.size = ClampNumber(unitCfg.auraWatch.size, 8, 22, plugins.auraWatch.size)
			unitCfg.auraWatch.numBuffs = ClampNumber(unitCfg.auraWatch.numBuffs, 0, 8, plugins.auraWatch.numBuffs)
			unitCfg.auraWatch.numDebuffs = ClampNumber(unitCfg.auraWatch.numDebuffs, 0, 8, plugins.auraWatch.numDebuffs)
			unitCfg.fader.minAlpha = ClampNumber(unitCfg.fader.minAlpha, 0.05, 1, plugins.fader.minAlpha)
			unitCfg.fader.maxAlpha = ClampNumber(unitCfg.fader.maxAlpha, 0.05, 1, plugins.fader.maxAlpha)
			unitCfg.fader.smooth = ClampNumber(unitCfg.fader.smooth, 0, 1, plugins.fader.smooth)
			unitCfg.auraWatch.customSpellList = SafeText(unitCfg.auraWatch.customSpellList, "")
		end
	end
end

function addon:GetModuleCopyResetKeys()
	return MODULE_COPY_RESET_KEYS
end

function addon:IsModuleSupportedForUnit(moduleKey, unitKey)
	if moduleKey == "castbar" then
		return true
	end
	if moduleKey == "fader" or moduleKey == "aurawatch" then
		return IsGroupUnitType(unitKey)
	end
	return false
end

function addon:GetAvailableProfiles()
	local list = {}
	if self.db and self.db.GetProfiles then
		pcall(function()
			self.db:GetProfiles(list)
		end)
	end
	table.sort(list)
	return list
end

function addon:GetSavedProfileByName(profileName)
	if not (self.db and self.db.sv and self.db.sv.profiles and profileName) then
		return nil
	end
	return self.db.sv.profiles[profileName]
end

function addon:GetModulePayloadFromProfile(profileName, moduleKey, unitKey)
	local srcProfile = self:GetSavedProfileByName(profileName)
	if not srcProfile then
		return nil
	end
	if moduleKey == "castbar" then
		return srcProfile.units and srcProfile.units[unitKey] and srcProfile.units[unitKey].castbar
	end
	if moduleKey == "fader" then
		return srcProfile.plugins and srcProfile.plugins.units and srcProfile.plugins.units[unitKey] and srcProfile.plugins.units[unitKey].fader
	end
	if moduleKey == "aurawatch" then
		return srcProfile.plugins and srcProfile.plugins.units and srcProfile.plugins.units[unitKey] and srcProfile.plugins.units[unitKey].auraWatch
	end
	return nil
end

local function SortTableKeys(input)
	local keys = {}
	for key in pairs(input or {}) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function FormatPreviewValue(value)
	local valueType = type(value)
	if valueType == "nil" then
		return "nil"
	end
	if valueType == "table" then
		return "<table>"
	end
	if valueType == "boolean" then
		return value and "true" or "false"
	end
	return tostring(value)
end

local function CollectPreviewDiffs(oldValue, newValue, path, outLines, maxLines, state)
	local oldType = type(oldValue)
	local newType = type(newValue)

	if oldType == "table" and newType == "table" then
		local keySet = {}
		for key in pairs(oldValue) do
			keySet[key] = true
		end
		for key in pairs(newValue) do
			keySet[key] = true
		end
		local keys = SortTableKeys(keySet)
		for i = 1, #keys do
			local key = keys[i]
			local childPath = path ~= "" and (path .. "." .. tostring(key)) or tostring(key)
			CollectPreviewDiffs(oldValue[key], newValue[key], childPath, outLines, maxLines, state)
		end
		return
	end

	if oldType == newType and oldType ~= "table" and oldValue == newValue then
		return
	end

	state.changed = state.changed + 1
	if #outLines < maxLines then
		outLines[#outLines + 1] = ("%s: %s -> %s"):format(path ~= "" and path or "<root>", FormatPreviewValue(oldValue), FormatPreviewValue(newValue))
	end
end

function addon:GetModuleLabel(moduleKey)
	for i = 1, #MODULE_COPY_RESET_KEYS do
		local entry = MODULE_COPY_RESET_KEYS[i]
		if entry.value == moduleKey then
			return entry.text or entry.value
		end
	end
	return tostring(moduleKey or "module")
end

function addon:GetModuleCurrentPayload(moduleKey, unitKey)
	if moduleKey == "castbar" then
		local unit = self:GetUnitSettings(unitKey)
		return unit and unit.castbar
	end
	if moduleKey == "fader" and IsGroupUnitType(unitKey) then
		local plugins = self:GetPluginSettings()
		local unitPlugins = plugins and plugins.units
		local unitCfg = unitPlugins and unitPlugins[unitKey]
		return unitCfg and unitCfg.fader
	end
	if moduleKey == "aurawatch" and IsGroupUnitType(unitKey) then
		local plugins = self:GetPluginSettings()
		local unitPlugins = plugins and plugins.units
		local unitCfg = unitPlugins and unitPlugins[unitKey]
		return unitCfg and unitCfg.auraWatch
	end
	return nil
end

function addon:GetModuleDefaultPayload(moduleKey, unitKey)
	if moduleKey == "castbar" then
		return DEFAULT_UNIT_CASTBAR
	end
	if moduleKey == "fader" and IsGroupUnitType(unitKey) then
		return defaults.profile.plugins.units[unitKey] and defaults.profile.plugins.units[unitKey].fader
	end
	if moduleKey == "aurawatch" and IsGroupUnitType(unitKey) then
		return defaults.profile.plugins.units[unitKey] and defaults.profile.plugins.units[unitKey].auraWatch
	end
	return nil
end

function addon:BuildModuleChangePreview(moduleKey, dstUnitKey, sourcePayload, originLabel)
	local preview = {
		ok = false,
		changed = 0,
		summary = "",
		lines = {},
		origin = originLabel or "preview",
	}

	if not self:IsModuleSupportedForUnit(moduleKey, dstUnitKey) then
		preview.summary = "Unsupported for this unit."
		return preview
	end
	if type(sourcePayload) ~= "table" then
		preview.summary = "No source module data found."
		return preview
	end

	local currentPayload = self:GetModuleCurrentPayload(moduleKey, dstUnitKey) or {}
	local targetPayload = CopyTableDeep(sourcePayload)

	if moduleKey == "castbar" then
		MergeDefaults(targetPayload, DEFAULT_UNIT_CASTBAR)
	elseif moduleKey == "fader" and IsGroupUnitType(dstUnitKey) then
		MergeDefaults(targetPayload, defaults.profile.plugins.units[dstUnitKey].fader)
	elseif moduleKey == "aurawatch" and IsGroupUnitType(dstUnitKey) then
		MergeDefaults(targetPayload, defaults.profile.plugins.units[dstUnitKey].auraWatch)
	end

	local state = { changed = 0 }
	CollectPreviewDiffs(currentPayload, targetPayload, "", preview.lines, 8, state)
	preview.changed = state.changed
	preview.ok = true

	if preview.changed == 0 then
		preview.summary = "No effective changes."
	else
		preview.summary = ("Will change %d setting(s)."):format(preview.changed)
	end
	return preview
end

function addon:BuildModuleResetPreview(moduleKey, unitKey)
	local defaultsPayload = self:GetModuleDefaultPayload(moduleKey, unitKey)
	return self:BuildModuleChangePreview(moduleKey, unitKey, defaultsPayload, "reset")
end

function addon:RunWithOptionalModuleApplyConfirmation(confirmEnabled, title, details, onAccept)
	if not onAccept then
		return false
	end
	if not confirmEnabled then
		onAccept()
		return true
	end

	StaticPopupDialogs["SUF_MODULE_APPLY_CONFIRM"] = StaticPopupDialogs["SUF_MODULE_APPLY_CONFIRM"] or {
		text = "",
		button1 = "Apply",
		button2 = "Cancel",
		OnAccept = function()
			if addon and addon._pendingModuleApplyCallback then
				local cb = addon._pendingModuleApplyCallback
				addon._pendingModuleApplyCallback = nil
				cb()
			end
		end,
		OnCancel = function()
			if addon then
				addon._pendingModuleApplyCallback = nil
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	self._pendingModuleApplyCallback = onAccept
	local popupText = tostring(title or "Confirm Apply")
	if details and details ~= "" then
		popupText = popupText .. "\n\n" .. tostring(details)
	end
	StaticPopup_Show("SUF_MODULE_APPLY_CONFIRM", popupText)
	return true
end

function addon:CopyModuleIntoCurrent(moduleKey, dstUnitKey, payload)
	if type(payload) ~= "table" then
		return false
	end
	if moduleKey == "castbar" then
		local dst = self:GetUnitSettings(dstUnitKey)
		dst.castbar = CopyTableDeep(payload)
		MergeDefaults(dst.castbar, DEFAULT_UNIT_CASTBAR)
		self:ScheduleUpdateAll()
		return true
	end
	if moduleKey == "fader" and IsGroupUnitType(dstUnitKey) then
		local plugins = self:GetPluginSettings()
		plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
		plugins.units[dstUnitKey] = plugins.units[dstUnitKey] or CopyTableDeep(defaults.profile.plugins.units[dstUnitKey])
		plugins.units[dstUnitKey].fader = CopyTableDeep(payload)
		MergeDefaults(plugins.units[dstUnitKey].fader, defaults.profile.plugins.units[dstUnitKey].fader)
		plugins.units[dstUnitKey].useGlobal = false
		self:SchedulePluginUpdate(dstUnitKey)
		return true
	end
	if moduleKey == "aurawatch" and IsGroupUnitType(dstUnitKey) then
		local plugins = self:GetPluginSettings()
		plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
		plugins.units[dstUnitKey] = plugins.units[dstUnitKey] or CopyTableDeep(defaults.profile.plugins.units[dstUnitKey])
		plugins.units[dstUnitKey].auraWatch = CopyTableDeep(payload)
		MergeDefaults(plugins.units[dstUnitKey].auraWatch, defaults.profile.plugins.units[dstUnitKey].auraWatch)
		plugins.units[dstUnitKey].useGlobal = false
		self:SchedulePluginUpdate(dstUnitKey)
		return true
	end
	return false
end

function addon:ResetModuleForUnit(moduleKey, unitKey)
	if moduleKey == "castbar" then
		local dst = self:GetUnitSettings(unitKey)
		dst.castbar = CopyTableDeep(DEFAULT_UNIT_CASTBAR)
		self:ScheduleUpdateAll()
		return true
	end
	if moduleKey == "fader" and IsGroupUnitType(unitKey) then
		local plugins = self:GetPluginSettings()
		plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
		plugins.units[unitKey] = plugins.units[unitKey] or CopyTableDeep(defaults.profile.plugins.units[unitKey])
		plugins.units[unitKey].fader = CopyTableDeep(defaults.profile.plugins.units[unitKey].fader)
		plugins.units[unitKey].useGlobal = false
		self:SchedulePluginUpdate(unitKey)
		return true
	end
	if moduleKey == "aurawatch" and IsGroupUnitType(unitKey) then
		local plugins = self:GetPluginSettings()
		plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
		plugins.units[unitKey] = plugins.units[unitKey] or CopyTableDeep(defaults.profile.plugins.units[unitKey])
		plugins.units[unitKey].auraWatch = CopyTableDeep(defaults.profile.plugins.units[unitKey].auraWatch)
		plugins.units[unitKey].useGlobal = false
		self:SchedulePluginUpdate(unitKey)
		return true
	end
	return false
end

local function SafeSetFaderOption(fader, key, value)
	if not (fader and fader.SetOption) then
		return
	end
	pcall(fader.SetOption, fader, key, value)
end

function addon:BuildAuraWatchWatchedList(customValue, replaceDefaults)
	local watched = replaceDefaults and {} or CopyTableDeep(DEFAULT_AURAWATCH_WATCHED)
	if type(customValue) == "table" then
		for key, value in pairs(customValue) do
			local spellID = tonumber(key)
			if spellID and spellID > 0 then
				if type(value) == "table" then
					watched[spellID] = CopyTableDeep(value)
					if watched[spellID].enabled == nil then
						watched[spellID].enabled = true
					end
					if watched[spellID].anyUnit == nil then
						watched[spellID].anyUnit = true
					end
				elseif value == true then
					watched[spellID] = { enabled = true, anyUnit = true }
				elseif value == false then
					watched[spellID] = nil
				end
			end
		end
		return watched
	end

	local parsed = self:ParseAuraWatchSpellTokens(customValue)
	for i = 1, #parsed.removes do
		watched[parsed.removes[i]] = nil
	end
	for i = 1, #parsed.adds do
		local spellID = parsed.adds[i]
		local existing = watched[spellID]
		if type(existing) == "table" then
			existing.enabled = true
			if existing.anyUnit == nil then
				existing.anyUnit = true
			end
		else
			watched[spellID] = { enabled = true, anyUnit = true }
		end
	end

	return watched
end

function addon:ParseAuraWatchSpellTokens(customValue)
	local result = {
		adds = {},
		removes = {},
		invalid = {},
	}

	local text = TrimString(SafeText(customValue, ""))
	if text == "" then
		return result
	end

	for token in text:gmatch("[^,%s;]+") do
		local value = TrimString(token)
		local isRemove = value:sub(1, 1) == "-"
		if value:sub(1, 1) == "+" or isRemove then
			value = value:sub(2)
		end
		local spellID = tonumber(value)
		if spellID and spellID > 0 then
			if isRemove then
				result.removes[#result.removes + 1] = spellID
			else
				result.adds[#result.adds + 1] = spellID
			end
		else
			result.invalid[#result.invalid + 1] = token
		end
	end

	return result
end

function addon:GetSpellNameForValidation(spellID)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if info and info.name then
			return info.name
		end
	end
	if GetSpellInfo then
		local name = GetSpellInfo(spellID)
		if name then
			return name
		end
	end
	return nil
end

function addon:ValidateAuraWatchSpellList(customValue)
	local parsed = self:ParseAuraWatchSpellTokens(customValue)
	local validAdds, validRemoves, invalidIDs = {}, {}, {}

	for i = 1, #parsed.adds do
		local id = parsed.adds[i]
		local name = self:GetSpellNameForValidation(id)
		if name then
			validAdds[#validAdds + 1] = id
		else
			invalidIDs[#invalidIDs + 1] = id
		end
	end
	for i = 1, #parsed.removes do
		local id = parsed.removes[i]
		local name = self:GetSpellNameForValidation(id)
		if name then
			validRemoves[#validRemoves + 1] = id
		else
			invalidIDs[#invalidIDs + 1] = id
		end
	end

	return {
		validAdds = validAdds,
		validRemoves = validRemoves,
		invalidIDs = invalidIDs,
		invalidTokens = parsed.invalid,
	}
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

function addon:GetNumericTextForUnit(unit, apiFn, useAbbrev)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end
	if type(apiFn) ~= "function" then
		return ""
	end

	local value = SafeNumber(SafeAPICall(apiFn, unit), 0)
	if value <= 0 then
		return ""
	end

	if C_StringUtil and C_StringUtil.TruncateWhenZero then
		local ok, textValue = pcall(C_StringUtil.TruncateWhenZero, value)
		if ok and textValue and not IsSecretValue(textValue) and textValue ~= "" then
			return textValue
		end
	end

	if useAbbrev then
		local okAbbr, abbrText = pcall(FormatCompactValue, value)
		if okAbbr and abbrText and not IsSecretValue(abbrText) and abbrText ~= "0" then
			return abbrText
		end
	end

	local rawText = SafeText(value, nil)
	if rawText and rawText ~= "0" then
		return rawText
	end

	return ""
end

function addon:GetIncomingHealsTextForUnit(unit, useAbbrev)
	return self:GetNumericTextForUnit(unit, UnitGetIncomingHeals, useAbbrev)
end

function addon:GetHealAbsorbsTextForUnit(unit, useAbbrev)
	return self:GetNumericTextForUnit(unit, UnitGetTotalHealAbsorbs, useAbbrev)
end

function addon:GetEffectiveHealthTextForUnit(unit, useAbbrev)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end

	local healthValue = SafeNumber(SafeAPICall(UnitHealth, unit), 0)
	local absorbValue = SafeNumber(SafeAPICall(UnitGetTotalAbsorbs, unit), 0)
	local totalValue = healthValue + absorbValue
	if totalValue <= 0 then
		return ""
	end

	if useAbbrev then
		local okAbbr, abbrText = pcall(FormatCompactValue, totalValue)
		if okAbbr and abbrText and not IsSecretValue(abbrText) and abbrText ~= "0" then
			return abbrText
		end
	end

	local rawText = SafeText(totalValue, nil)
	if rawText and rawText ~= "0" then
		return rawText
	end

	return ""
end

function addon:TrackRecentHealthGain(unit)
	if type(UnitGUID) ~= "function" or not unit then
		return
	end
	local guid = UnitGUID(unit)
	if not guid then
		return
	end
	if type(UnitHealth) ~= "function" then
		return
	end

	local currentHealth = SafeNumber(SafeAPICall(UnitHealth, unit), nil)
	if not currentHealth then
		return
	end
	local now = (GetTime and GetTime()) or 0
	local window = 1.5
	local store = self._incomingHealthTrendByGUID or {}
	self._incomingHealthTrendByGUID = store
	local entry = store[guid]
	if not entry then
		store[guid] = {
			lastHealth = currentHealth,
			lastAt = now,
			recentGain = 0,
			recentUntil = 0,
		}
		return
	end

	local lastHealth = SafeNumber(entry.lastHealth, currentHealth) or currentHealth
	local gain = currentHealth - lastHealth
	if gain > 0 then
		entry.recentGain = (SafeNumber(entry.recentGain, 0) or 0) + gain
		entry.recentUntil = now + window
	end
	entry.lastHealth = currentHealth
	entry.lastAt = now
end

function addon:GetHealthDeltaIncomingEstimateForUnit(unit)
	if type(UnitGUID) ~= "function" or not unit then
		return nil, false
	end
	local guid = UnitGUID(unit)
	if not guid then
		return nil, false
	end

	local store = self._incomingHealthTrendByGUID
	if type(store) ~= "table" then
		return nil, false
	end
	local entry = store[guid]
	if type(entry) ~= "table" then
		return nil, false
	end

	local now = (GetTime and GetTime()) or 0
	local window = 1.5
	local recentUntil = SafeNumber(entry.recentUntil, 0) or 0
	local remaining = recentUntil - now
	if remaining <= 0 then
		entry.recentGain = 0
		entry.recentUntil = 0
		return nil, false
	end

	local amount = SafeNumber(entry.recentGain, nil)
	if not amount or amount <= 0 then
		entry.recentGain = 0
		entry.recentUntil = 0
		return nil, false
	end

	-- Short decay curve so the estimate fades naturally.
	local ratio = math.max(0, math.min(1, remaining / window))
	local estimate = amount * ratio
	if estimate <= 1 then
		return nil, false
	end
	return estimate, true
end

function addon:RegisterIncomingEstimateFrame()
	self._incomingHealthTrendByGUID = self._incomingHealthTrendByGUID or {}
end

function addon:UnregisterIncomingEstimateFrame()
	self._incomingHealthTrendByGUID = nil
end

function addon:GetDisplayNameForUnit(unit)
	if not unit then
		return ""
	end

	local unitName = SafeText(UnitName and UnitName(unit), "")
	if unitName == "" then
		return ""
	end

	local enhancement = self:GetEnhancementSettings()
	if enhancement and enhancement.translitNames and LibTranslit and LibTranslit.Transliterate then
		local mark = SafeText(enhancement.translitMarker, "")
		local ok, transliterated = pcall(LibTranslit.Transliterate, LibTranslit, unitName, mark)
		if ok and type(transliterated) == "string" and transliterated ~= "" then
			return transliterated
		end
	end

	return unitName
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
	ouf.Tags.Methods["suf:incoming"] = function(unit)
		return addon:GetIncomingHealsTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:incoming:abbr"] = function(unit)
		return addon:GetIncomingHealsTextForUnit(unit, true)
	end
	ouf.Tags.Methods["suf:healabsorbs"] = function(unit)
		return addon:GetHealAbsorbsTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:healabsorbs:abbr"] = function(unit)
		return addon:GetHealAbsorbsTextForUnit(unit, true)
	end
	ouf.Tags.Methods["suf:ehp"] = function(unit)
		return addon:GetEffectiveHealthTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:ehp:abbr"] = function(unit)
		return addon:GetEffectiveHealthTextForUnit(unit, true)
	end
	ouf.Tags.Methods["suf:name"] = function(unit)
		return addon:GetDisplayNameForUnit(unit)
	end
	ouf.Tags.Events["suf:absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:absorbs:abbr"] = "UNIT_ABSORB_AMOUNT_CHANGED UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:incoming"] = "UNIT_HEAL_PREDICTION UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:incoming:abbr"] = "UNIT_HEAL_PREDICTION UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:healabsorbs"] = "UNIT_HEAL_ABSORB_AMOUNT_CHANGED UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:healabsorbs:abbr"] = "UNIT_HEAL_ABSORB_AMOUNT_CHANGED UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:ehp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:ehp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:name"] = "UNIT_NAME_UPDATE PLAYER_ENTERING_WORLD GROUP_ROSTER_UPDATE"

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

local function GetUnitDropdownName(unit)
	if unit == "player" then
		return "PlayerFrameDropDown"
	elseif unit == "target" then
		return "TargetFrameDropDown"
	elseif unit == "focus" then
		return "FocusFrameDropDown"
	elseif unit == "pet" then
		return "PetFrameDropDown"
	elseif unit == "targettarget" then
		return "TargetFrameToTDropDown"
	end

	local partyIndex = unit and unit:match("^party(%d+)$")
	if partyIndex then
		return "PartyMemberFrame" .. tostring(partyIndex) .. "DropDown"
	end

	return nil
end

function addon:OpenUnitContextMenu(frame)
	if not frame then
		return false
	end

	local unit = frame.unit
	if type(unit) ~= "string" or unit == "" then
		return false
	end
	if UnitExists and not UnitExists(unit) then
		return false
	end
	if InCombatLockdown and InCombatLockdown() then
		return false
	end

	local dropdownName = GetUnitDropdownName(unit)
	local dropdown = dropdownName and _G[dropdownName] or nil
	if dropdown and ToggleDropDownMenu then
		ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
		return true
	end

	if frame.__sufLegacyMenu and frame.__sufLegacyMenu ~= frame.menu then
		local ok = pcall(frame.__sufLegacyMenu, frame)
		return ok
	end

	return false
end

local function HookRightClickProxy(widget, ownerFrame)
	if not widget or not ownerFrame or widget.__sufRightClickProxy then
		return
	end
	if not widget.HookScript then
		return
	end

	if widget.SetPropagateMouseClicks then
		widget:SetPropagateMouseClicks(true)
	end

	widget:HookScript("OnMouseUp", function(_, mouseButton)
		if IsRightClick(mouseButton) then
			addon:OpenUnitContextMenu(ownerFrame)
		end
	end)
	widget.__sufRightClickProxy = true
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

function addon:HasRelevantFrameForUnitEvent(eventName, unitToken)
	if type(unitToken) ~= "string" or unitToken == "" then
		return false
	end

	local frames = self.frames or {}
	local unitType = ResolveUnitType(unitToken)
	local hasTypeMatch = false

	for i = 1, #frames do
		local frame = frames[i]
		if frame then
			if frame.unit == unitToken then
				if self:IsFrameEventRelevant(frame, eventName) then
					return true
				end
			end
			if unitType and frame.sufUnitType == unitType and self:IsFrameEventRelevant(frame, eventName) then
				hasTypeMatch = true
			end
			if unitToken == "target" and frame.sufUnitType == "tot" and self:IsFrameEventRelevant(frame, eventName) then
				hasTypeMatch = true
			end
		end
	end

	return hasTypeMatch
end

function addon:UpdateFrameFromDirtyEvents(frame, dirtyEvents)
	if not frame then
		return
	end
	local profileStart = debugprofilestop and debugprofilestop() or nil

	if type(dirtyEvents) ~= "table" then
		frame:UpdateAllElements("SimpleUnitFrames_PerfDirty")
		self:UpdateUnitFrameStatusIndicators(frame)
		return
	end

	local eventCount = 0
	for eventName in pairs(dirtyEvents) do
		eventCount = eventCount + 1
		if eventCount > 4 then
			frame:UpdateAllElements("SimpleUnitFrames_PerfDirtyBatch")
			self:UpdateUnitFrameStatusIndicators(frame)
			return
		end
	end

	local touched = false
	for eventName in pairs(dirtyEvents) do
		if eventName == "UNIT_HEALTH" or eventName == "UNIT_MAXHEALTH" or eventName == "UNIT_THREAT_SITUATION_UPDATE" or eventName == "UNIT_THREAT_LIST_UPDATE" or eventName == "UNIT_HEAL_PREDICTION" or eventName == "UNIT_ABSORB_AMOUNT_CHANGED" or eventName == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
			touched = SafeUpdateElement(frame, "Health", eventName) or touched
			self:UpdateAbsorbValue(frame)
			self:UpdateIncomingHealValue(frame)
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
		elseif eventName == "UNIT_FLAGS" or eventName == "UNIT_CONNECTION" or eventName == "RAID_TARGET_UPDATE" or eventName == "GROUP_ROSTER_UPDATE" or eventName == "PLAYER_ROLES_ASSIGNED" or eventName == "PARTY_LEADER_CHANGED" then
			touched = true
			self:UpdateUnitFrameStatusIndicators(frame)
		else
			frame:UpdateAllElements("SimpleUnitFrames_PerfDirtyFallback")
			self:UpdateUnitFrameStatusIndicators(frame)
			return
		end
	end

	if not touched then
		frame:UpdateAllElements("SimpleUnitFrames_PerfDirtyFallback")
	end
	self:UpdateUnitFrameStatusIndicators(frame)

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
		self._perfQueueAccepted = (self._perfQueueAccepted or 0) + 1
	else
		self:HandleCoalescedEvent(eventName, ...)
		self._perfQueueFallback = (self._perfQueueFallback or 0) + 1
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
					local fallbackUnits = NON_UNIT_EVENT_TARGETS[eventName]
					if not fallbackUnits then
						return
					end
					local hasRelevantFallback = false
					for i = 1, #fallbackUnits do
						if self:HasRelevantFrameForUnitEvent(eventName, fallbackUnits[i]) then
							hasRelevantFallback = true
							break
						end
					end
					if not hasRelevantFallback then
						return
					end
				elseif not self:HasRelevantFrameForUnitEvent(eventName, unitToken) then
					return
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

function addon:IsIncomingTextDebugEnabled()
	self:EnsureDebugConfig()
	return self:IsDebugEnabled() and self.db.profile.debug and self.db.profile.debug.systems and self.db.profile.debug.systems.IncomingText
end

function addon:DebugLog(system, message, tier)
	self:EnsureDebugConfig()
	self.debugMessages = self.debugMessages or {}
	self._perfQueueAccepted = 0
	self._perfQueueFallback = 0
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
		self:EnableMovableFrame(frame, true)
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
	self:PlayWindowOpenAnimation(self.debugExportFrame)
end

function addon:ShowDebugSettings()
	self:EnsureDebugConfig()
	if not self.debugSettingsFrame then
		local frame = CreateFrame("Frame", "SUFDebugSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(320, 360)
		frame:SetPoint("CENTER", UIParent, "CENTER", -360, 0)
		self:EnableMovableFrame(frame, true)

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
	self:PlayWindowOpenAnimation(frame)
end

function addon:ShowDebugPanel()
	self:EnsureDebugConfig()
	if not self.debugPanel then
		local frame = CreateFrame("Frame", "SUFDebugPanel", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(620, 420)
		frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
		self:EnableMovableFrame(frame, true)

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
	self:PlayWindowOpenAnimation(self.debugPanel)
	self:RefreshDebugPanel()
end

function addon:HideDebugPanel()
	if self.debugPanel then
		self.debugPanel:Hide()
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
	self:Print(addonName .. ": /suf resources")
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

function addon:GetClassResourceAuditData()
	local classTag = select(2, UnitClass("player")) or "UNKNOWN"
	local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization() or nil
	local specID = specIndex and C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo and C_SpecializationInfo.GetSpecializationInfo(specIndex) or nil
	local powerType = UnitPowerType and UnitPowerType("player") or nil
	local powerToken = _G[(powerType and ("SPELL_POWER_" .. tostring(powerType))) or ""] or tostring(powerType or "n/a")

	local expected = "None"
	local active = false

	if classTag == "ROGUE" then
		expected = "Combo Points"
		active = true
	elseif classTag == "DRUID" then
		expected = "Combo Points (Cat Form)"
		active = (powerType == (Enum.PowerType.Energy or 3))
	elseif classTag == "MONK" then
		expected = "Chi (Windwalker)"
		active = (specID == 269)
	elseif classTag == "PALADIN" then
		expected = "Holy Power"
		active = true
	elseif classTag == "MAGE" then
		expected = "Arcane Charges (Arcane)"
		active = (specID == 62)
	elseif classTag == "EVOKER" then
		expected = "Essence"
		active = true
	elseif classTag == "WARLOCK" then
		expected = "Soul Shards"
		active = true
	elseif classTag == "SHAMAN" then
		expected = "Maelstrom Weapon (Enhancement)"
		active = (specID == 263)
	elseif classTag == "DEMONHUNTER" then
		expected = "Soul Fragments (spec conditional)"
		active = (specID == 581)
	elseif classTag == "DEATHKNIGHT" then
		expected = "Runes (primary resource element)"
		active = true
	end

	local hasPlayerFrame = false
	local classPowerVisible = false
	local visibleSlots = 0
	for _, frame in ipairs(self.frames or {}) do
		if frame and frame.sufUnitType == "player" then
			hasPlayerFrame = true
			if frame.ClassPower and HasVisibleClassPower(frame) then
				classPowerVisible = true
				for _, bar in ipairs(frame.ClassPower) do
					if bar and bar.IsShown and bar:IsShown() then
						visibleSlots = visibleSlots + 1
					end
				end
			end
			break
		end
	end

	return {
		classTag = classTag,
		specID = specID,
		powerToken = powerToken,
		expected = expected,
		active = active,
		hasPlayerFrame = hasPlayerFrame,
		classPowerVisible = classPowerVisible,
		visibleSlots = visibleSlots,
	}
end

function addon:PrintClassResourceAudit()
	local data = self:GetClassResourceAuditData()
	if not data then
		return
	end

	local classTag = data.classTag
	local specID = data.specID
	local powerToken = data.powerToken
	local expected = data.expected
	local active = data.active
	local hasPlayerFrame = data.hasPlayerFrame
	local classPowerVisible = data.classPowerVisible
	local visibleSlots = data.visibleSlots

	self:Print(addonName .. ": Resource audit -> class=" .. tostring(classTag) .. " specID=" .. tostring(specID or "n/a") .. " powerType=" .. tostring(powerToken))
	self:Print(addonName .. ": Expected class resource: " .. expected .. " | activeContext=" .. tostring(active))
	self:Print(addonName .. ": Player frame found=" .. tostring(hasPlayerFrame) .. " | classResourceVisible=" .. tostring(classPowerVisible) .. " | visibleSlots=" .. tostring(visibleSlots))
	if classTag == "DRUID" then
		self:Print(addonName .. ": Druid combo points only appear in Cat Form (energy power type).")
	end
	if classTag == "DEATHKNIGHT" then
		self:Print(addonName .. ": DK runes are currently not rendered as a dedicated SUF top resource row.")
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

	if command == "resources" or command == "resource" or command == "classpower" then
		self:PrintClassResourceAudit()
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
	local function ApplyTagSafe(fontString, tagText, fallbackTag)
		if not fontString then
			return
		end
		frame:Untag(fontString)
		local value = (type(tagText) == "string" and tagText ~= "") and tagText or (fallbackTag or "")
		if value == "" then
			fontString:SetText("")
			return
		end
		local ok = pcall(frame.Tag, frame, fontString, value)
		if not ok and fallbackTag and fallbackTag ~= value then
			local fallbackOk = pcall(frame.Tag, frame, fontString, fallbackTag)
			if not fallbackOk then
				fontString:SetText("")
			end
		elseif not ok then
			fontString:SetText("")
		end
	end

	if frame.NameText then
		local nameTag = tags.name
		if self:GetEnhancementSettings().translitNames then
			nameTag = SafeText(nameTag, "[name]")
			nameTag = nameTag:gsub("%[name%]", "[suf:name]")
		end
		ApplyTagSafe(frame.NameText, nameTag, self:GetEnhancementSettings().translitNames and "[suf:name]" or "[name]")
	end

	if frame.LevelText then
		ApplyTagSafe(frame.LevelText, tags.level, "[level]")
	end

	if frame.HealthValue then
		ApplyTagSafe(frame.HealthValue, tags.health, "[curhp]")
	end

	if frame.PowerValue then
		ApplyTagSafe(frame.PowerValue, tags.power, "[curpp]")
	end

	if frame.AdditionalPowerValue then
		ApplyTagSafe(frame.AdditionalPowerValue, "[curmana]", "[curmana]")
	end

	if frame.AbsorbValue then
		frame:Untag(frame.AbsorbValue)
		local absorbTag = self.db and self.db.profile and self.db.profile.absorbValueTag or "[suf:absorbs:abbr]"
		if absorbTag and absorbTag ~= "" then
			local ok = pcall(frame.Tag, frame, frame.AbsorbValue, absorbTag)
			if ok then
				frame.AbsorbValue.__isSUFTaggedAbsorb = true
			else
				frame.AbsorbValue:SetText("")
				frame.AbsorbValue.__isSUFTaggedAbsorb = false
			end
		else
			frame.AbsorbValue:SetText("")
			frame.AbsorbValue.__isSUFTaggedAbsorb = false
		end
	end

	if frame.IncomingHealValue then
		frame:Untag(frame.IncomingHealValue)
		frame.IncomingHealValue:SetText("")
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

local function PositionPredictionBarUUF(bar, frame, position, height, reverseRight, anchorTexture)
	if not (bar and frame and frame.Health) then
		return
	end

	local anchorFrame = anchorTexture or frame.Health
	local healthWidth = frame.Health:GetWidth() or frame:GetWidth() or 200
	local barHeight = math.max(1, tonumber(height) or (frame.Health:GetHeight() or 1))

	bar:ClearAllPoints()
	if position == "RIGHT" then
		bar:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", 0, 0)
		bar:SetReverseFill(reverseRight and true or false)
	elseif position == "ATTACH" then
		if frame.Health.SetClipsChildren then
			frame.Health:SetClipsChildren(true)
		end
		local isReversed = frame.Health.GetReverseFill and frame.Health:GetReverseFill()
		local healthTexture = anchorTexture or (frame.Health.GetStatusBarTexture and frame.Health:GetStatusBarTexture()) or frame.Health
		if isReversed then
			bar:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
			bar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMLEFT", 0, 0)
			bar:SetReverseFill(true)
		else
			bar:SetPoint("TOPRIGHT", healthTexture, "TOPRIGHT", 0, 0)
			bar:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)
			bar:SetReverseFill(false)
		end
	else
		bar:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", 0, 0)
		bar:SetReverseFill(false)
	end

	bar:SetHeight(barHeight)
	bar:SetWidth(healthWidth)
end

local function GetHealthPredictionWidgets(frame)
	if not frame then
		return nil
	end

	local health = frame.Health
	local legacy = frame.HealthPrediction
	if not health and not legacy then
		return nil
	end

	return {
		healingAll = (health and health.HealingAll) or (legacy and legacy.healingAll),
		healingPlayer = (health and health.HealingPlayer) or (legacy and legacy.healingPlayer),
		healingOther = (health and health.HealingOther) or (legacy and legacy.healingOther),
		damageAbsorb = (health and health.DamageAbsorb) or (legacy and legacy.damageAbsorb),
		healAbsorb = (health and health.HealAbsorb) or (legacy and legacy.healAbsorb),
		overDamageAbsorbIndicator = (health and health.OverDamageAbsorbIndicator) or (legacy and legacy.overDamageAbsorbIndicator),
		overHealAbsorbIndicator = (health and health.OverHealAbsorbIndicator) or (legacy and legacy.overHealAbsorbIndicator),
	}
end

function addon:UpdateMainBarsBackgroundAnchors(frame)
	if not (frame and frame.MainBarsBackground) then
		return
	end

	local topAnchor = frame.Health or frame
	if frame.AdditionalPower and frame.AdditionalPower.IsShown and frame.AdditionalPower:IsShown() then
		topAnchor = frame.AdditionalPower
	end
	if frame.ClassPowerAnchor and HasVisibleClassPower and HasVisibleClassPower(frame) then
		topAnchor = frame.ClassPowerAnchor
	end

	local bottomAnchor = frame.Power or frame.Health or frame

	frame.MainBarsBackground:ClearAllPoints()
	frame.MainBarsBackground:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", 0, 0)
	frame.MainBarsBackground:SetPoint("TOPRIGHT", topAnchor, "TOPRIGHT", 0, 0)
	frame.MainBarsBackground:SetPoint("BOTTOMLEFT", bottomAnchor, "BOTTOMLEFT", 0, 0)
	frame.MainBarsBackground:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", 0, 0)
end

function addon:UpdateAbsorbValue(frame, unitToken)
	if not frame or not frame.AbsorbValue then
		return
	end

	local hpCfg = self:GetUnitHealPredictionSettings(frame.sufUnitType)
	if not (hpCfg and hpCfg.enabled and hpCfg.absorbs and hpCfg.absorbs.enabled) then
		frame.AbsorbValue:SetText("")
		local hpWidgetsDisabled = GetHealthPredictionWidgets(frame)
		if hpWidgetsDisabled and hpWidgetsDisabled.damageAbsorb then
			hpWidgetsDisabled.damageAbsorb:SetValue(0)
			hpWidgetsDisabled.damageAbsorb:Hide()
		end
		if frame.Health and frame.Health.AbsorbCap then
			frame.Health.AbsorbCap:Hide()
		end
		return
	end

	local unit = unitToken or frame.unit
	if not unit or not UnitExists or not UnitExists(unit) then
		frame.AbsorbValue:SetText("")
		local hpWidgetsNoUnit = GetHealthPredictionWidgets(frame)
		if hpWidgetsNoUnit and hpWidgetsNoUnit.damageAbsorb then
			hpWidgetsNoUnit.damageAbsorb:SetValue(0)
			hpWidgetsNoUnit.damageAbsorb:Hide()
		end
		if frame.Health and frame.Health.AbsorbCap then
			frame.Health.AbsorbCap:Hide()
		end
		return
	end

	if type(UnitGetTotalAbsorbs) ~= "function" then
		frame.AbsorbValue:SetText("")
		local hpWidgetsNoApi = GetHealthPredictionWidgets(frame)
		if hpWidgetsNoApi and hpWidgetsNoApi.damageAbsorb then
			hpWidgetsNoApi.damageAbsorb:SetValue(0)
			hpWidgetsNoApi.damageAbsorb:Hide()
		end
		if frame.Health and frame.Health.AbsorbCap then
			frame.Health.AbsorbCap:Hide()
		end
		return
	end

	local absorbValue, absorbValueUnit = ResolveReadableAbsorbValue(unit, frame.Health and frame.Health.values)
	local maxHealth = SafeNumber(SafeAPICall(UnitHealthMax, absorbValueUnit or unit), nil)
	if not maxHealth then
		maxHealth = SafeNumber(SafeAPICall(UnitHealthMax, unit), nil)
	end
	local hpWidgets = GetHealthPredictionWidgets(frame)
	if hpWidgets and hpWidgets.damageAbsorb then
		local absorbBar = hpWidgets.damageAbsorb
		if absorbValue ~= nil and maxHealth and maxHealth > 0 then
			local clamped = math.max(0, math.min(absorbValue, maxHealth))
			absorbBar:SetMinMaxValues(0, maxHealth)
			absorbBar:SetValue(clamped)
			absorbBar:SetShown(clamped > 0)
			if frame.Health and frame.Health.AbsorbCap then
				local cap = frame.Health.AbsorbCap
				if clamped > 0 then
					local dtex = absorbBar.GetStatusBarTexture and absorbBar:GetStatusBarTexture()
					cap:ClearAllPoints()
					if dtex then
						cap:SetPoint("TOP", dtex, "TOP", 0, 0)
						cap:SetPoint("BOTTOM", dtex, "BOTTOM", 0, 0)
						cap:SetPoint("LEFT", dtex, "LEFT", 0, 0)
					else
						cap:SetPoint("TOP", frame.Health, "TOP", 0, 0)
						cap:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, 0)
						cap:SetPoint("RIGHT", frame.Health, "RIGHT", 0, 0)
					end
					cap:SetShown(true)
				else
					cap:Hide()
				end
			end
		elseif absorbValue ~= nil then
			absorbBar:SetValue(0)
			absorbBar:Hide()
			if frame.Health and frame.Health.AbsorbCap then
				frame.Health.AbsorbCap:Hide()
			end
		end
	end

	if frame.AbsorbValue.__isSUFTaggedAbsorb then
		return
	end

	if absorbValue == nil or absorbValue <= 0 then
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

function addon:UpdateIncomingHealValue(frame, unitToken)
	if not frame or not frame.IncomingHealValue then
		return
	end
	if not INCOMING_VALUE_FEATURE_ENABLED then
		frame.IncomingHealValue:SetText("")
		frame.IncomingHealValue:Hide()
		return
	end
	local function Trace(reason, details)
		if not self:IsIncomingTextDebugEnabled() then
			return
		end
		local now = (GetTime and GetTime()) or 0
		local sameReason = frame._sufIncomingDebugReason == reason
		local nextAt = frame._sufIncomingDebugNext or 0
		if sameReason and now < nextAt then
			return
		end
		frame._sufIncomingDebugReason = reason
		frame._sufIncomingDebugNext = now + 0.75
		local unitName = tostring(frame.sufUnitType or frame.unit or "unknown")
		self:DebugLog("IncomingText", ("IncomingText[%s]: %s%s"):format(unitName, tostring(reason), details and (" | " .. details) or ""), 2)
	end
	local function RawCall(fn, ...)
		if type(fn) ~= "function" then
			return nil, false
		end
		local ok, result = pcall(fn, ...)
		if not ok then
			return nil, false
		end
		return result, true
	end
	local function RawDebug(value)
		if value == nil then
			return "<nil>"
		end
		if IsSecretValue(value) then
			return "<secret>"
		end
		return tostring(value)
	end

	local hpCfg = self:GetUnitHealPredictionSettings(frame.sufUnitType)
	local incomingCfg = hpCfg and hpCfg.incoming
	if not (hpCfg and hpCfg.enabled and incomingCfg and incomingCfg.enabled and incomingCfg.showValueText ~= false) then
		frame.IncomingHealValue:SetText("")
		frame.IncomingHealValue:Hide()
		Trace("CONFIG_HIDDEN", ("hpEnabled=%s incomingEnabled=%s showValueText=%s"):format(
			tostring(hpCfg and hpCfg.enabled),
			tostring(incomingCfg and incomingCfg.enabled),
			tostring(incomingCfg and incomingCfg.showValueText)
		))
		return
	end

	local unit = unitToken or frame.unit
	if not unit or not UnitExists or not UnitExists(unit) then
		frame.IncomingHealValue:SetText("")
		frame.IncomingHealValue:Hide()
		Trace("NO_UNIT", ("unit=%s"):format(tostring(unit)))
		return
	end

	if self.TrackRecentHealthGain then
		self:TrackRecentHealthGain(unit)
	end

	local hpWidgets = GetHealthPredictionWidgets(frame)
	local valueMode = tostring(incomingCfg and incomingCfg.valueMode or "SAFE")
	if valueMode ~= "SAFE" and valueMode ~= "HYBRID_ESTIMATE" and valueMode ~= "SELF_ONLY" and valueMode ~= "SYMBOLIC" then
		valueMode = "SAFE"
	end

	local function GetTextureWidth(statusBar)
		if not statusBar or not statusBar.GetStatusBarTexture then
			return 0
		end
		local tex = statusBar:GetStatusBarTexture()
		if not tex or not tex.GetWidth then
			return 0
		end
		return SafeNumber(tex:GetWidth(), 0) or 0
	end

	local function BuildSymbolicText()
		if not frame or not frame.Health then
			return "~"
		end
		local healthTex = frame.Health.GetStatusBarTexture and frame.Health:GetStatusBarTexture() or nil
		local healthWidth = (healthTex and healthTex.GetWidth and SafeNumber(healthTex:GetWidth(), 0)) or 0
		healthWidth = healthWidth > 0 and healthWidth or (SafeNumber(frame.Health.GetWidth and frame.Health:GetWidth(), 0) or 0)
		if healthWidth <= 0 then
			return "~"
		end

		local incomingWidth = 0
		local visibleCount = 0
		local totalVisible = false
		local splitVisible = false
		local function IsShownSafe(widget)
			if not widget or not widget.IsShown then
				return false
			end
			local ok, shown = pcall(widget.IsShown, widget)
			return ok and shown and true or false
		end
		if hpWidgets then
			if incomingCfg and incomingCfg.split then
				if IsShownSafe(hpWidgets.healingPlayer) then
					visibleCount = visibleCount + 1
				end
				if IsShownSafe(hpWidgets.healingOther) then
					visibleCount = visibleCount + 1
				end
				splitVisible = visibleCount > 0
				incomingWidth = math.max(incomingWidth, GetTextureWidth(hpWidgets.healingPlayer))
				incomingWidth = math.max(incomingWidth, GetTextureWidth(hpWidgets.healingOther))
			else
				totalVisible = IsShownSafe(hpWidgets.healingAll)
				incomingWidth = math.max(incomingWidth, GetTextureWidth(hpWidgets.healingAll))
			end
		end

		-- Fallback for clients where incoming texture width does not give usable values.
		if incomingWidth <= 0 then
			if splitVisible and visibleCount >= 2 then
				return "~~~"
			elseif splitVisible or totalVisible then
				return "~~"
			end
			return "~"
		end

		local ratio = incomingWidth / healthWidth
		if ratio >= 0.50 then
			return "~~~"
		elseif ratio >= 0.20 then
			return "~~"
		end
		return "~"
	end

	local function ApplyTextFromRaw(rawValue, allowPlaceholder)
		if rawValue == nil then
			return false
		end

		if IsSecretValue(rawValue) then
			if not allowPlaceholder then
				return false
			end
			-- Secret values must not be compared/inspected; use a safe placeholder.
			local placeholder
			if valueMode == "SYMBOLIC" then
				placeholder = BuildSymbolicText()
			else
				placeholder = incomingCfg and incomingCfg.valuePlaceholder or "~"
			end
			placeholder = SafeText(placeholder, "~") or "~"
			if placeholder == "" then
				placeholder = "~"
			end
			if #placeholder > 8 then
				placeholder = string.sub(placeholder, 1, 8)
			end
			local okSet = pcall(frame.IncomingHealValue.SetText, frame.IncomingHealValue, placeholder)
			if okSet then
				frame.IncomingHealValue:Show()
				return true
			end
			return false
		end

		if C_StringUtil and C_StringUtil.TruncateWhenZero then
			local ok, textValue = pcall(C_StringUtil.TruncateWhenZero, rawValue)
			if ok and textValue and not IsSecretValue(textValue) and textValue ~= "" and textValue ~= "0" then
				frame.IncomingHealValue:SetText(textValue)
				frame.IncomingHealValue:Show()
				return true
			end
		end

		local numeric = SafeNumber(rawValue, nil)
		if numeric and numeric > 0 then
			local okAbbr, abbrText = pcall(FormatCompactValue, numeric)
			if okAbbr and abbrText and not IsSecretValue(abbrText) and abbrText ~= "0" then
				frame.IncomingHealValue:SetText(abbrText)
				frame.IncomingHealValue:Show()
				return true
			end
			local rawText = SafeText(numeric, nil)
			if rawText and rawText ~= "0" then
				frame.IncomingHealValue:SetText(rawText)
				frame.IncomingHealValue:Show()
				return true
			end
		end
		return false
	end

	local function EstimateIncomingFromKnownCasters(unitID)
		if type(UnitGetIncomingHeals) ~= "function" or type(UnitExists) ~= "function" then
			return nil, false
		end

		local total = 0
		local found = false
		local function AddCaster(caster)
			if not caster or not UnitExists(caster) then
				return
			end
			local raw = SafeAPICall(UnitGetIncomingHeals, unitID, caster)
			local value = SafeNumber(raw, nil)
			if value and value > 0 then
				total = total + value
				found = true
			end
		end

		AddCaster("player")
		AddCaster("pet")
		if IsInRaid and IsInRaid() then
			for i = 1, 40 do
				AddCaster("raid" .. i)
				AddCaster("raidpet" .. i)
			end
		elseif IsInGroup and IsInGroup() then
			for i = 1, 4 do
				AddCaster("party" .. i)
				AddCaster("partypet" .. i)
			end
		end

		if found then
			return total, true
		end
		return nil, false
	end

	local incomingValue = nil
	local barCallOk = false
	if hpWidgets then
		-- Prefer total incoming from healingAll; it's updated even when split display is enabled.
		if hpWidgets.healingAll and hpWidgets.healingAll.GetValue then
			incomingValue, barCallOk = RawCall(hpWidgets.healingAll.GetValue, hpWidgets.healingAll)
		end
	end

	local apiIncoming = nil
	local apiCallOk = false
	local estimateIncoming = nil
	local estimateCallOk = false
	local deltaIncoming = nil
	local deltaOk = false
	local selfIncoming = nil
	local selfOk = false
	local allowPlaceholder = (valueMode == "SAFE")
	local shown = ApplyTextFromRaw(incomingValue, allowPlaceholder)
	if not shown then
		apiIncoming, apiCallOk = RawCall(UnitGetIncomingHeals, unit)
		shown = ApplyTextFromRaw(apiIncoming, allowPlaceholder)
	end
	if not shown and valueMode == "SELF_ONLY" then
		selfIncoming, selfOk = RawCall(UnitGetIncomingHeals, unit, "player")
		-- SELF_ONLY is intentionally "self contribution", not total, so keep it numeric only.
		shown = ApplyTextFromRaw(selfIncoming, false)
		if shown and frame.IncomingHealValue and frame.IncomingHealValue.GetText and frame.IncomingHealValue.SetText then
			local currentText = SafeText(frame.IncomingHealValue:GetText(), nil)
			if currentText and currentText ~= "" and currentText ~= "~" then
				frame.IncomingHealValue:SetText(currentText .. "+")
			end
		end
	end
	if not shown and valueMode == "HYBRID_ESTIMATE" then
		estimateIncoming, estimateCallOk = EstimateIncomingFromKnownCasters(unit)
		shown = ApplyTextFromRaw(estimateIncoming, false)
	end
	if not shown and valueMode == "HYBRID_ESTIMATE" and self.GetHealthDeltaIncomingEstimateForUnit then
		deltaIncoming, deltaOk = self:GetHealthDeltaIncomingEstimateForUnit(unit)
		shown = ApplyTextFromRaw(deltaIncoming, false)
	end
	if not shown and valueMode == "HYBRID_ESTIMATE" then
		shown = ApplyTextFromRaw(incomingValue, true)
	end
	if not shown and valueMode == "SYMBOLIC" then
		local symbolic = BuildSymbolicText()
		local okSet = pcall(frame.IncomingHealValue.SetText, frame.IncomingHealValue, symbolic)
		if okSet then
			frame.IncomingHealValue:Show()
			shown = true
		end
	end
	if not shown then
		frame.IncomingHealValue:SetText("")
		frame.IncomingHealValue:Hide()
		Trace("NO_VALUE", ("mode=%s barRaw=%s barOk=%s apiRaw=%s apiOk=%s selfRaw=%s selfOk=%s estimateRaw=%s estimateOk=%s deltaRaw=%s deltaOk=%s unit=%s"):format(
			tostring(valueMode),
			RawDebug(incomingValue),
			tostring(barCallOk),
			RawDebug(apiIncoming),
			tostring(apiCallOk),
			RawDebug(selfIncoming),
			tostring(selfOk),
			RawDebug(estimateIncoming),
			tostring(estimateCallOk),
			RawDebug(deltaIncoming),
			tostring(deltaOk),
			tostring(unit)
		))
		return
	end

	Trace("SHOW", ("mode=%s text=%s barRaw=%s barOk=%s apiRaw=%s apiOk=%s selfRaw=%s selfOk=%s estimateRaw=%s estimateOk=%s deltaRaw=%s deltaOk=%s visible=%s unit=%s"):format(
		tostring(valueMode),
		tostring(SafeText(frame.IncomingHealValue:GetText(), "<secret>")),
		RawDebug(incomingValue),
		tostring(barCallOk),
		RawDebug(apiIncoming),
		tostring(apiCallOk),
		RawDebug(selfIncoming),
		tostring(selfOk),
		RawDebug(estimateIncoming),
		tostring(estimateCallOk),
		RawDebug(deltaIncoming),
		tostring(deltaOk),
		tostring(frame.IncomingHealValue:IsShown()),
		tostring(unit)
	))
end

local NON_INTERRUPT_GLOW_KEY = "suf_castbar_non_interrupt"
local RAID_DEBUFF_GLOW_KEY = "suf_raiddebuff_glow"

local function StopCastbarNonInterruptGlow(castbar)
	if not (LibCustomGlow and castbar) then
		return
	end
	pcall(LibCustomGlow.PixelGlow_Stop, LibCustomGlow, castbar, NON_INTERRUPT_GLOW_KEY)
end

local function StartCastbarNonInterruptGlow(castbar, color)
	if not (LibCustomGlow and castbar) then
		return
	end
	StopCastbarNonInterruptGlow(castbar)
	local glowColor = color or { 1, 0.2, 0.2, 0.90 }
	pcall(
		LibCustomGlow.PixelGlow_Start,
		LibCustomGlow,
		castbar,
		glowColor,
		8,
		0.18,
		8,
		2,
		0,
		0,
		false,
		NON_INTERRUPT_GLOW_KEY,
		castbar:GetFrameLevel() + 6
	)
end

local function StopRaidDebuffGlow(element)
	if not (LibCustomGlow and element) then
		return
	end
	pcall(LibCustomGlow.PixelGlow_Stop, LibCustomGlow, element, RAID_DEBUFF_GLOW_KEY)
end

local function StartRaidDebuffGlow(element)
	if not (LibCustomGlow and element) then
		return
	end
	StopRaidDebuffGlow(element)
	pcall(
		LibCustomGlow.PixelGlow_Start,
		LibCustomGlow,
		element,
		{ 1.0, 0.25, 0.25, 0.95 },
		6,
		0.22,
		6,
		2,
		0,
		0,
		false,
		RAID_DEBUFF_GLOW_KEY,
		element:GetFrameLevel() + 4
	)
end

local SUF_DISPEL_FILTER = nil

local function IsDispellableDebuffType(debuffType)
	if not debuffType then
		return false
	end
	if SUF_DISPEL_FILTER == nil then
		local lib = LibStub and LibStub("LibDispel-1.0", true) or nil
		if lib and lib.GetMyDispelTypes then
			SUF_DISPEL_FILTER = lib:GetMyDispelTypes() or false
		else
			SUF_DISPEL_FILTER = false
		end
	end
	return type(SUF_DISPEL_FILTER) == "table" and SUF_DISPEL_FILTER[debuffType] and true or false
end

local function IsPriorityRaidDebuff(name, spellID)
	local rd = _G and _G.oUF_RaidDebuffs
	if not (rd and rd.DebuffData) then
		return false
	end
	if spellID and rd.DebuffData[spellID] then
		return true
	end
	if name and rd.DebuffData[name] then
		return true
	end
	return false
end

local function CreateAuraWatchIconElement(element)
	local button = CreateFrame("Button", nil, element)
	button:EnableMouse(false)
	button:Hide()

	local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetReverse(true)
	cd:SetDrawBling(false)
	cd:SetDrawEdge(false)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()

	local countFrame = CreateFrame("Frame", nil, button)
	countFrame:SetAllPoints(button)
	countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

	local count = countFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	count:SetPoint("BOTTOMRIGHT", countFrame, "BOTTOMRIGHT", -1, 0)

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture([[Interface\Buttons\UI-Debuff-Overlays]])
	overlay:SetAllPoints()
	overlay:SetTexCoord(.296875, .5703125, 0, .515625)

	button.overlay = overlay
	button.icon = icon
	button.count = count
	button.cd = cd
	return button
end

function addon:EnsureRaidDebuffsElement(frame)
	if not frame then
		return nil
	end
	if frame.RaidDebuffs then
		return frame.RaidDebuffs
	end

	local parent = frame.IndicatorFrame or frame
	local element = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	element:SetSize(18, 18)
	element:SetPoint("CENTER", frame.Health or frame, "CENTER", 0, 0)
	element:SetFrameLevel((parent:GetFrameLevel() or frame:GetFrameLevel() or 1) + 6)
	if element.SetBackdrop then
		element:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
	end
	element:SetBackdropBorderColor(0, 0, 0, 1)

	local icon = element:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	element.icon = icon

	local cd = CreateFrame("Cooldown", nil, element, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawBling(false)
	cd:SetDrawEdge(false)
	element.cd = cd

	local count = element:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	count:SetPoint("BOTTOMRIGHT", element, "BOTTOMRIGHT", -1, 1)
	element.count = count

	local time = element:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	time:SetPoint("TOP", element, "BOTTOM", 0, -1)
	element.time = time
	element.PostUpdate = function(widget, name, _, _, debuffType, _, _, spellID)
		if not name then
			StopRaidDebuffGlow(widget)
			return
		end
		local owner = widget.__owner
		if not owner or not owner.sufUnitType then
			StopRaidDebuffGlow(widget)
			return
		end
		local pluginCfg = addon:GetUnitPluginSettings(owner.sufUnitType)
		if pluginCfg and pluginCfg.raidDebuffs and pluginCfg.raidDebuffs.glow == false then
			StopRaidDebuffGlow(widget)
			return
		end
		local mode = pluginCfg and pluginCfg.raidDebuffs and pluginCfg.raidDebuffs.glowMode or "ALL"
		if mode == "DISPELLABLE" then
			if not IsDispellableDebuffType(debuffType) then
				StopRaidDebuffGlow(widget)
				return
			end
		elseif mode == "PRIORITY" then
			if not IsPriorityRaidDebuff(name, spellID) then
				StopRaidDebuffGlow(widget)
				return
			end
		end
		StartRaidDebuffGlow(widget)
	end
	element.__owner = frame

	frame.RaidDebuffs = element
	return element
end

function addon:EnsureAuraWatchElement(frame)
	if not frame then
		return nil
	end
	if frame.AuraWatch then
		return frame.AuraWatch
	end

	local parent = frame.IndicatorFrame or frame
	local element = CreateFrame("Frame", nil, parent)
	element:SetAllPoints(frame)
	element:SetFrameLevel((parent:GetFrameLevel() or frame:GetFrameLevel() or 1) + 4)
	element.CreateIcon = CreateAuraWatchIconElement
	element.watched = CopyTableDeep(DEFAULT_AURAWATCH_WATCHED)
	frame.AuraWatch = element
	return element
end

function addon:ApplyPluginElements(frame)
	if not frame or not frame.sufUnitType then
		return
	end

	local plugins = self:GetUnitPluginSettings(frame.sufUnitType)
	local isGroup = IsGroupUnitType(frame.sufUnitType)

	if frame.RaidDebuffs then
		frame.RaidDebuffs:SetShown(isGroup and plugins.raidDebuffs.enabled ~= false)
		if frame.RaidDebuffs:IsShown() then
			local size = math.max(12, math.min(36, tonumber(plugins.raidDebuffs.size) or 18))
			frame.RaidDebuffs:SetSize(size, size)
			frame.RaidDebuffs:ClearAllPoints()
			frame.RaidDebuffs:SetPoint("CENTER", frame.Health or frame, "CENTER", 0, 0)
		else
			StopRaidDebuffGlow(frame.RaidDebuffs)
		end
	end

	if frame.AuraWatch then
		frame.AuraWatch:SetShown(isGroup and plugins.auraWatch.enabled ~= false)
		local watched = self:BuildAuraWatchWatchedList(plugins.auraWatch.customSpells or plugins.auraWatch.customSpellList, plugins.auraWatch.replaceDefaults)
		if frame.AuraWatch.SetNewTable then
			frame.AuraWatch:SetNewTable(watched)
		else
			frame.AuraWatch.watched = watched
		end
		frame.AuraWatch.size = math.max(8, math.min(22, tonumber(plugins.auraWatch.size) or 10))
		frame.AuraWatch.numBuffs = math.max(0, math.min(8, tonumber(plugins.auraWatch.numBuffs) or 3))
		frame.AuraWatch.numDebuffs = math.max(0, math.min(8, tonumber(plugins.auraWatch.numDebuffs) or 3))
		frame.AuraWatch.showDebuffType = plugins.auraWatch.showDebuffType ~= false
		if frame.AuraWatch.ForceUpdate then
			frame.AuraWatch:ForceUpdate()
		end
	end

	if frame.Fader and frame.Fader.SetOption then
		local faderCfg = plugins.fader or defaults.profile.plugins.fader
		local enabled = faderCfg.enabled == true
		SafeSetFaderOption(frame.Fader, "MinAlpha", tonumber(faderCfg.minAlpha) or 0.45)
		SafeSetFaderOption(frame.Fader, "MaxAlpha", tonumber(faderCfg.maxAlpha) or 1)
		SafeSetFaderOption(frame.Fader, "Smooth", tonumber(faderCfg.smooth) or 0.2)
		SafeSetFaderOption(frame.Fader, "Hover", enabled and (faderCfg.hover ~= false) or false)
		SafeSetFaderOption(frame.Fader, "Combat", enabled and (faderCfg.combat ~= false) or false)
		SafeSetFaderOption(frame.Fader, "Casting", enabled and (faderCfg.casting == true) or false)
		SafeSetFaderOption(frame.Fader, "PlayerTarget", enabled and (faderCfg.playerTarget ~= false) or false)
		SafeSetFaderOption(frame.Fader, "ActionTarget", enabled and (faderCfg.actionTarget == true) or false)
		SafeSetFaderOption(frame.Fader, "UnitTarget", enabled and (faderCfg.unitTarget == true) or false)
		if frame.Fader.ForceUpdate then
			frame.Fader:ForceUpdate("SUF_FaderApply")
		end
	end
end

function addon:ApplyMedia(frame)
	local profileStart = debugprofilestop and debugprofilestop() or nil
	local texture = self:GetUnitStatusbarTexture(frame.sufUnitType)
	local bgCfg = self:GetUnitMainBarsBackgroundSettings(frame.sufUnitType)
	local hpCfgGlobal = self:GetUnitHealPredictionSettings(frame.sufUnitType)
	local incomingCfgGlobal = hpCfgGlobal and hpCfgGlobal.incoming or DEFAULT_HEAL_PREDICTION.incoming
	local font = self:GetFont()
	local sizes = self:GetUnitFontSizes(frame.sufUnitType)
	local castbarCfg = self.db.profile.castbar or {}
	local unitCastbarCfg = self:GetUnitCastbarSettings(frame.sufUnitType)
	local castbarColors = self:GetUnitCastbarColors(frame.sufUnitType)

	if frame.Health then
		frame.Health:SetStatusBarTexture(texture)
		local healthTex = frame.Health.GetStatusBarTexture and frame.Health:GetStatusBarTexture()
		if healthTex and healthTex.SetDrawLayer then
			healthTex:SetDrawLayer("ARTWORK", 1)
		end
	end

	if frame.Power then
		frame.Power:SetStatusBarTexture(texture)
	end

	if frame.PowerBG then
		frame.PowerBG:SetTexture(texture)
		frame.PowerBG:SetVertexColor(0, 0, 0, 0.6)
	end

	if frame.IncomingHealValue then
		local incomingFontSize = tonumber(incomingCfgGlobal and incomingCfgGlobal.valueFontSize) or math.max(8, (sizes and sizes.health or 11) - 1)
		frame.IncomingHealValue:SetFont(font, math.max(8, math.min(20, incomingFontSize)), "OUTLINE")
		local valueColor = incomingCfgGlobal and incomingCfgGlobal.valueColor or DEFAULT_HEAL_PREDICTION.incoming.valueColor
		frame.IncomingHealValue:SetTextColor(valueColor[1] or 0.35, valueColor[2] or 0.95, valueColor[3] or 0.45, 0.95)
	end

	if frame.MainBarsBackground then
		if bgCfg.enabled == false then
			frame.MainBarsBackground:Hide()
		else
			local bgTexture = DEFAULT_TEXTURE
			if LSM and bgCfg.texture then
				local lsmTexture = LSM:Fetch("statusbar", bgCfg.texture)
				if lsmTexture then
					bgTexture = lsmTexture
				end
			end
			frame.MainBarsBackground:SetTexture(bgTexture)
			local c = bgCfg.color or defaults.profile.mainBarsBackground.color
			frame.MainBarsBackground:SetVertexColor(c[1] or 0.05, c[2] or 0.05, c[3] or 0.05, bgCfg.alpha or 0.4)
			frame.MainBarsBackground:Show()
		end
	end

	local hpWidgets = GetHealthPredictionWidgets(frame)
	if hpWidgets then
		local hpCfg = hpCfgGlobal
		local incomingCfg = hpCfg.incoming
		local absorbCfg = hpCfg.absorbs
		local healAbsorbCfg = hpCfg.healAbsorbs
		local healthHeight = frame.Health:GetHeight() or 1
		local incomingInset = math.floor((healthHeight * (1 - math.max(0.3, math.min(1, incomingCfg.height or 1)))) * 0.5 + 0.5)
		local absorbInset = math.floor((healthHeight * (1 - math.max(0.3, math.min(1, absorbCfg.height or 1)))) * 0.5 + 0.5)
		local healAbsorbInset = math.floor((healthHeight * (1 - math.max(0.3, math.min(1, healAbsorbCfg.height or 1)))) * 0.5 + 0.5)
		local predictionLevel = (frame.Health:GetFrameLevel() or frame:GetFrameLevel() or 1) + 4
		local absorbLevel = (frame.Health:GetFrameLevel() or frame:GetFrameLevel() or 1) + 7
		local absorbOverlay = frame.Health and frame.Health.DamageAbsorbOverlay

		local function RaisePredictionBar(bar)
			if not bar then
				return
			end
			bar:SetFrameStrata(frame.Health:GetFrameStrata())
			bar:SetFrameLevel(predictionLevel)
			local texObj = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
			if texObj and texObj.SetDrawLayer then
				texObj:SetDrawLayer("ARTWORK", 7)
			end
		end

		local statusTex = frame.Health:GetStatusBarTexture()
		if statusTex and statusTex.SetDrawLayer then
			statusTex:SetDrawLayer("ARTWORK", 1)
		end
		if absorbOverlay then
			absorbOverlay:SetFrameStrata(frame.Health:GetFrameStrata())
			absorbOverlay:SetFrameLevel(absorbLevel - 1)
		end

		if hpWidgets.healingAll then
			hpWidgets.healingAll:SetStatusBarTexture(texture)
			RaisePredictionBar(hpWidgets.healingAll)
			local c = incomingCfg.colorAll
			hpWidgets.healingAll:SetStatusBarColor(c[1] or 0.35, c[2] or 0.95, c[3] or 0.45, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			hpWidgets.healingAll:ClearAllPoints()
			hpWidgets.healingAll:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			hpWidgets.healingAll:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			hpWidgets.healingAll:SetPoint("LEFT", statusTex, "RIGHT")
			local shownAll = (hpCfg.enabled ~= false) and (incomingCfg.enabled ~= false) and not incomingCfg.split
			hpWidgets.healingAll:SetShown(shownAll)
			UpdateBarTextureOutline(hpWidgets.healingAll, shownAll)
		end
		if hpWidgets.healingPlayer then
			hpWidgets.healingPlayer:SetStatusBarTexture(texture)
			RaisePredictionBar(hpWidgets.healingPlayer)
			local c = incomingCfg.colorPlayer
			hpWidgets.healingPlayer:SetStatusBarColor(c[1] or 0.35, c[2] or 0.95, c[3] or 0.45, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			hpWidgets.healingPlayer:ClearAllPoints()
			hpWidgets.healingPlayer:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			hpWidgets.healingPlayer:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			hpWidgets.healingPlayer:SetPoint("LEFT", statusTex, "RIGHT")
			local shownPlayer = (hpCfg.enabled ~= false) and (incomingCfg.enabled ~= false) and incomingCfg.split
			hpWidgets.healingPlayer:SetShown(shownPlayer)
			UpdateBarTextureOutline(hpWidgets.healingPlayer, shownPlayer)
		end
		if hpWidgets.healingOther then
			hpWidgets.healingOther:SetStatusBarTexture(texture)
			RaisePredictionBar(hpWidgets.healingOther)
			local c = incomingCfg.colorOther
			hpWidgets.healingOther:SetStatusBarColor(c[1] or 0.20, c[2] or 0.75, c[3] or 0.35, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			hpWidgets.healingOther:ClearAllPoints()
			hpWidgets.healingOther:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			hpWidgets.healingOther:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			local healAnchor = hpWidgets.healingPlayer and hpWidgets.healingPlayer:GetStatusBarTexture() or statusTex
			hpWidgets.healingOther:SetPoint("LEFT", healAnchor, "RIGHT")
			local shownOther = (hpCfg.enabled ~= false) and (incomingCfg.enabled ~= false) and incomingCfg.split
			hpWidgets.healingOther:SetShown(shownOther)
			UpdateBarTextureOutline(hpWidgets.healingOther, shownOther)
		end

		if frame.IncomingHealValue then
			frame.IncomingHealValue:ClearAllPoints()
			local incomingAnchor = statusTex
			local valueOffsetX = tonumber(incomingCfg.valueOffsetX) or 2
			local valueOffsetY = tonumber(incomingCfg.valueOffsetY) or 0
			if incomingCfg.split then
				if hpWidgets.healingOther and hpWidgets.healingOther.GetStatusBarTexture then
					incomingAnchor = hpWidgets.healingOther:GetStatusBarTexture() or incomingAnchor
				elseif hpWidgets.healingPlayer and hpWidgets.healingPlayer.GetStatusBarTexture then
					incomingAnchor = hpWidgets.healingPlayer:GetStatusBarTexture() or incomingAnchor
				end
			else
				if hpWidgets.healingAll and hpWidgets.healingAll.GetStatusBarTexture then
					incomingAnchor = hpWidgets.healingAll:GetStatusBarTexture() or incomingAnchor
				end
			end
			if not incomingAnchor then
				incomingAnchor = frame.Health
			end
			frame.IncomingHealValue:SetPoint("LEFT", incomingAnchor, "RIGHT", valueOffsetX, valueOffsetY)
			frame.IncomingHealValue:SetJustifyH("LEFT")
		end

		if hpWidgets.damageAbsorb then
			hpWidgets.damageAbsorb:SetStatusBarTexture(texture)
			RaisePredictionBar(hpWidgets.damageAbsorb)
			hpWidgets.damageAbsorb:SetFrameLevel(absorbLevel)
			local c = absorbCfg.color
			local r, g, b = c[1] or 1.00, c[2] or 0.95, c[3] or 0.20
			-- Compatibility: legacy cyan absorb color is hard to distinguish from SUF health colors.
			if math.abs(r - 0.25) < 0.08 and math.abs(g - 0.78) < 0.10 and math.abs(b - 0.92) < 0.10 then
				r, g, b = 1.00, 0.95, 0.20
			end
			hpWidgets.damageAbsorb:SetStatusBarColor(r, g, b, math.max(0.45, math.min(1, absorbCfg.opacity or 0.75)))
			local dtex = hpWidgets.damageAbsorb.GetStatusBarTexture and hpWidgets.damageAbsorb:GetStatusBarTexture()
			if dtex and dtex.SetDrawLayer then
				dtex:SetDrawLayer("OVERLAY", 5)
			end
			if dtex and dtex.SetBlendMode then
				dtex:SetBlendMode("ADD")
			end
			hpWidgets.damageAbsorb:ClearAllPoints()
			local absorbAnchor = statusTex
			if incomingCfg.split then
				if hpWidgets.healingOther and hpWidgets.healingOther.GetStatusBarTexture then
					absorbAnchor = hpWidgets.healingOther:GetStatusBarTexture() or absorbAnchor
				elseif hpWidgets.healingPlayer and hpWidgets.healingPlayer.GetStatusBarTexture then
					absorbAnchor = hpWidgets.healingPlayer:GetStatusBarTexture() or absorbAnchor
				end
			else
				if hpWidgets.healingAll and hpWidgets.healingAll.GetStatusBarTexture then
					absorbAnchor = hpWidgets.healingAll:GetStatusBarTexture() or absorbAnchor
				end
			end
			local absorbPosition = tostring(absorbCfg.position or "RIGHT")
			-- Force absorb segment to right side for consistent SUF behavior across all units.
			absorbPosition = "RIGHT"
			PositionPredictionBarUUF(
				hpWidgets.damageAbsorb,
				frame,
				absorbPosition,
				(frame.Health:GetHeight() or 1) - (absorbInset * 2),
				true,
				absorbAnchor or statusTex or frame.Health
			)
			local absorbShown = (hpCfg.enabled ~= false) and (absorbCfg.enabled ~= false)
			hpWidgets.damageAbsorb:SetShown(absorbShown)
			UpdateBarTextureOutline(hpWidgets.damageAbsorb, absorbShown)
			local absorbCap = frame.Health and frame.Health.AbsorbCap
			if absorbCap then
				absorbCap:ClearAllPoints()
				local dtex = hpWidgets.damageAbsorb.GetStatusBarTexture and hpWidgets.damageAbsorb:GetStatusBarTexture()
				if dtex then
					absorbCap:SetPoint("TOP", dtex, "TOP", 0, 0)
					absorbCap:SetPoint("BOTTOM", dtex, "BOTTOM", 0, 0)
					absorbCap:SetPoint("LEFT", dtex, "LEFT", 0, 0)
				else
					absorbCap:SetPoint("TOP", frame.Health, "TOP", 0, -absorbInset)
					absorbCap:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, absorbInset)
					absorbCap:SetPoint("RIGHT", frame.Health, "RIGHT", 0, 0)
				end
				absorbCap:SetWidth(2)
				absorbCap:SetDrawLayer("OVERLAY", 6)
				absorbCap:SetColorTexture(0.95, 1.00, 1.00, math.max(0.45, math.min(1, absorbCfg.opacity or 0.65)))
			end
		end
		if hpWidgets.healAbsorb then
			hpWidgets.healAbsorb:SetStatusBarTexture(texture)
			RaisePredictionBar(hpWidgets.healAbsorb)
			hpWidgets.healAbsorb:SetFrameLevel(absorbLevel)
			local c = healAbsorbCfg.color
			hpWidgets.healAbsorb:SetStatusBarColor(c[1] or 0.95, c[2] or 0.25, c[3] or 0.25, math.max(0.05, math.min(1, healAbsorbCfg.opacity or 0.55)))
			local htex = hpWidgets.healAbsorb.GetStatusBarTexture and hpWidgets.healAbsorb:GetStatusBarTexture()
			if htex and htex.SetDrawLayer then
				htex:SetDrawLayer("OVERLAY", 5)
			end
			hpWidgets.healAbsorb:ClearAllPoints()
			local healAbsorbAnchor = statusTex or frame.Health
			local healAbsorbPosition = tostring(healAbsorbCfg.position or "RIGHT")
			PositionPredictionBarUUF(
				hpWidgets.healAbsorb,
				frame,
				healAbsorbPosition,
				(frame.Health:GetHeight() or 1) - (healAbsorbInset * 2),
				true,
				healAbsorbAnchor
			)
			local healAbsorbShown = (hpCfg.enabled ~= false) and (healAbsorbCfg.enabled ~= false)
			hpWidgets.healAbsorb:SetShown(healAbsorbShown)
			UpdateBarTextureOutline(hpWidgets.healAbsorb, healAbsorbShown)
		end
		if hpWidgets.overDamageAbsorbIndicator then
			hpWidgets.overDamageAbsorbIndicator:SetDrawLayer("OVERLAY", 6)
			hpWidgets.overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
			hpWidgets.overDamageAbsorbIndicator:SetBlendMode("ADD")
			hpWidgets.overDamageAbsorbIndicator:SetVertexColor(1, 1, 1, math.max(0.25, math.min(1, absorbCfg.glowOpacity or 0.95)))
			hpWidgets.overDamageAbsorbIndicator:SetShown((hpCfg.enabled ~= false) and (absorbCfg.enabled ~= false) and absorbCfg.showGlow ~= false)
		end
		if hpWidgets.overHealAbsorbIndicator then
			hpWidgets.overHealAbsorbIndicator:SetDrawLayer("OVERLAY", 6)
			hpWidgets.overHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
			hpWidgets.overHealAbsorbIndicator:SetBlendMode("ADD")
			hpWidgets.overHealAbsorbIndicator:SetVertexColor(1, 1, 1, math.max(0.1, math.min(1, healAbsorbCfg.glowOpacity or 0.95)))
			hpWidgets.overHealAbsorbIndicator:SetShown((hpCfg.enabled ~= false) and (healAbsorbCfg.enabled ~= false) and healAbsorbCfg.showGlow ~= false)
		end

		self:UpdateAbsorbValue(frame)
		self:UpdateIncomingHealValue(frame)
		if frame.UpdateElement then
			pcall(frame.UpdateElement, frame, "Health")
		end
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
					StopCastbarNonInterruptGlow(castbar)
					return
				end

				if interruptible then
					local activeColor = castbar.channeling and (castbarColors.channeling or castbarColors.casting) or castbarColors.casting
					activeColor = activeColor or { 1, 0.7, 0 }
					castbar:SetStatusBarColor(activeColor[1] or 1, activeColor[2] or 0.7, activeColor[3] or 0)
					StopCastbarNonInterruptGlow(castbar)
					if castbar.Shield then
						castbar.Shield:SetShown(false)
					end
				else
					local niColor = castbarColors.nonInterruptible or { 0.75, 0.75, 0.75 }
					castbar:SetStatusBarColor(niColor[1] or 0.75, niColor[2] or 0.75, niColor[3] or 0.75)
					if self:GetEnhancementSettings().castbarNonInterruptibleGlow ~= false then
						StartCastbarNonInterruptGlow(castbar, { niColor[1] or 0.75, niColor[2] or 0.75, niColor[3] or 0.75, 0.90 })
					else
						StopCastbarNonInterruptGlow(castbar)
					end
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
				spellName = TruncateUTF8(spellName, maxChars)
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
				StopCastbarNonInterruptGlow(castbar)
				if castbar.Shield then
					castbar.Shield:SetShown(false)
				end
			end
			frame.Castbar.PostCastNotInterruptible = function(castbar)
				local color = castbarColors.nonInterruptible or { 0.75, 0.75, 0.75 }
				castbar:SetStatusBarColor(color[1] or 0.75, color[2] or 0.75, color[3] or 0.75)
				if self:GetEnhancementSettings().castbarNonInterruptibleGlow ~= false then
					StartCastbarNonInterruptGlow(castbar, { color[1] or 0.75, color[2] or 0.75, color[3] or 0.75, 0.90 })
				else
					StopCastbarNonInterruptGlow(castbar)
				end
				if castbar.Shield then
					castbar.Shield:SetShown(castbarCfg.showShield ~= false)
				end
			end
			frame.Castbar.PostCastFailed = function(castbar)
				local color = castbarColors.failed or { 1, 0.1, 0.1 }
				castbar:SetStatusBarColor(color[1] or 1, color[2] or 0.1, color[3] or 0.1)
				StopCastbarNonInterruptGlow(castbar)
			end
			frame.Castbar.PostCastInterrupted = frame.Castbar.PostCastFailed
			frame.Castbar.PostCastStop = function(castbar)
				local color = castbarColors.complete or { 0, 1, 0 }
				castbar:SetStatusBarColor(color[1] or 0, color[2] or 1, color[3] or 0)
				StopCastbarNonInterruptGlow(castbar)
			end
		else
			StopCastbarNonInterruptGlow(frame.Castbar)
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

	if frame.StatusIndicator then
		frame.StatusIndicator:SetFont(font, math.max(10, sizes.name), "OUTLINE")
	end

	self:ApplyPluginElements(frame)

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
		else
			frame.RestingIndicator:Hide()
		end
	end

	if frame.PvPIndicator then
		frame.PvPIndicator:SetSize(size, size)
		frame.PvPIndicator:ClearAllPoints()
		frame.PvPIndicator:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", offsetX, offsetY)
		if settings.showPvp then
			frame.PvPIndicator:Show()
		else
			frame.PvPIndicator:Hide()
		end
	end

	if frame.RoleIndicator then
		local roleSize = math.max(12, math.floor(size * 0.75))
		frame.RoleIndicator:SetSize(roleSize, roleSize)
		frame.RoleIndicator:ClearAllPoints()
		frame.RoleIndicator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, 2)
	end

	if frame.RaidMarkerIndicator then
		local markerSize = math.max(12, math.floor(size * 0.80))
		frame.RaidMarkerIndicator:SetSize(markerSize, markerSize)
		frame.RaidMarkerIndicator:ClearAllPoints()
		frame.RaidMarkerIndicator:SetPoint("TOP", frame, "TOP", -20, -2)
	end

	if frame.LeaderIndicator then
		local leaderSize = math.max(12, math.floor(size * 0.70))
		frame.LeaderIndicator:SetSize(leaderSize, leaderSize)
		frame.LeaderIndicator:ClearAllPoints()
		frame.LeaderIndicator:SetPoint("TOP", frame, "TOP", 0, 2)
	end

	self:UpdateUnitFrameStatusIndicators(frame)
end

function addon:UpdateUnitFrameStatusIndicators(frame)
	if not frame then
		return
	end

	local unit = frame.unit
	if type(unit) ~= "string" or unit == "" then
		if frame.RoleIndicator then frame.RoleIndicator:Hide() end
		if frame.RaidMarkerIndicator then frame.RaidMarkerIndicator:Hide() end
		if frame.LeaderIndicator then frame.LeaderIndicator:Hide() end
		if frame.StatusIndicator then frame.StatusIndicator:SetText("") end
		return
	end

	if frame.RoleIndicator then
		local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or "NONE"
		if role and role ~= "NONE" and role ~= "" then
			frame.RoleIndicator:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
			local l, r, t, b
			if type(GetTexCoordsForRoleSmall) == "function" then
				l, r, t, b = GetTexCoordsForRoleSmall(role)
			end
			if l and r and t and b then
				frame.RoleIndicator:SetTexCoord(l, r, t, b)
			elseif role == "TANK" then
				frame.RoleIndicator:SetTexCoord(0, 19 / 64, 22 / 64, 41 / 64)
			elseif role == "HEALER" then
				frame.RoleIndicator:SetTexCoord(20 / 64, 39 / 64, 1 / 64, 20 / 64)
			else
				frame.RoleIndicator:SetTexCoord(20 / 64, 39 / 64, 22 / 64, 41 / 64)
			end
			frame.RoleIndicator:Show()
		else
			frame.RoleIndicator:Hide()
		end
	end

	if frame.RaidMarkerIndicator then
		local markerIndex = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
		if markerIndex and markerIndex > 0 and type(SetRaidTargetIconTexture) == "function" then
			SetRaidTargetIconTexture(frame.RaidMarkerIndicator, markerIndex)
			frame.RaidMarkerIndicator:Show()
		else
			frame.RaidMarkerIndicator:Hide()
		end
	end

	if frame.LeaderIndicator then
		local isLeader = UnitIsGroupLeader and UnitIsGroupLeader(unit) or false
		if isLeader then
			frame.LeaderIndicator:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
			frame.LeaderIndicator:Show()
		else
			frame.LeaderIndicator:Hide()
		end
	end

	if frame.StatusIndicator then
		local text = ""
		local r, g, b = 1.0, 1.0, 1.0
		if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
			text = "DEAD"
			r, g, b = 1.0, 0.25, 0.25
		elseif UnitIsConnected and not UnitIsConnected(unit) then
			text = "OFFLINE"
			r, g, b = 0.70, 0.70, 0.70
		elseif UnitIsAFK and UnitIsAFK(unit) then
			text = "AFK"
			r, g, b = 1.0, 0.90, 0.35
		end
		frame.StatusIndicator:SetText(text)
		frame.StatusIndicator:SetTextColor(r, g, b, 1.0)
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

	local count = tonumber(frame.__sufClassPowerVisibleSlots) or 0
	if count <= 0 then
		for _, bar in ipairs(frame.ClassPower) do
			if bar and bar.IsShown and bar:IsShown() then
				count = count + 1
			end
		end
	end
	if count <= 0 then
		count = #frame.ClassPower
	end
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

	self:UpdateMainBarsBackgroundAnchors(frame)

	if profileStart then
		local profileEnd = debugprofilestop() or profileStart
		self:RecordProfilerEvent("suf:apply.size", profileEnd - profileStart)
	end
end

function addon:UpdateAllFrames()
	local totalStart = debugprofilestop and debugprofilestop() or nil
	for _, frame in ipairs(self.frames) do
		local frameStart = debugprofilestop and debugprofilestop() or nil
		self:UpdateSingleFrame(frame)
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

	if frame.RaidDebuffs then
		StopRaidDebuffGlow(frame.RaidDebuffs)
		frame.RaidDebuffs:Hide()
		frame.RaidDebuffs = nil
	end

	if frame.AuraWatch then
		frame.AuraWatch:Hide()
		frame.AuraWatch = nil
	end
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
	SetMousePassthrough(Castbar)
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
	SetMousePassthrough(anchor)

	for index = 1, 10 do
		local bar = CreateFrame("StatusBar", nil, anchor)
		bar:SetStatusBarTexture(DEFAULT_TEXTURE)
		bar:SetHeight(height)
		bar:SetPoint("TOPLEFT", anchor, "TOPLEFT", (index - 1) * 18, 0)
		bar:SetWidth(16)
		SetMousePassthrough(bar)
		ClassPower[index] = bar
	end

	self.ClassPower = ClassPower
	self.ClassPowerAnchor = anchor
end

local function CreateHealthPrediction(self)
	if not self.Health then
		return
	end
	local predictionLevel = (self.Health:GetFrameLevel() or 1) + 4
	local absorbOverlay = CreateFrame("Frame", nil, self.Health)
	absorbOverlay:SetAllPoints(self.Health)
	absorbOverlay:SetFrameStrata(self.Health:GetFrameStrata())
	absorbOverlay:SetFrameLevel((self.Health:GetFrameLevel() or 1) + 6)
	absorbOverlay:SetClipsChildren(false)
	SetMousePassthrough(absorbOverlay)

	local healingAll = CreateFrame("StatusBar", nil, self)
	healingAll:SetPoint("TOP")
	healingAll:SetPoint("BOTTOM")
	healingAll:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	healingAll:SetWidth(self.Health:GetWidth())
	healingAll:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingAll:SetStatusBarColor(0.35, 0.95, 0.45, 0.40)
	healingAll:SetFrameLevel(predictionLevel)
	SetMousePassthrough(healingAll)

	local healingPlayer = CreateFrame("StatusBar", nil, self)
	healingPlayer:SetPoint("TOP")
	healingPlayer:SetPoint("BOTTOM")
	healingPlayer:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	healingPlayer:SetWidth(self.Health:GetWidth())
	healingPlayer:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingPlayer:SetStatusBarColor(0.35, 0.95, 0.45, 0.40)
	healingPlayer:SetFrameLevel(predictionLevel)
	SetMousePassthrough(healingPlayer)

	local healingOther = CreateFrame("StatusBar", nil, self)
	healingOther:SetPoint("TOP")
	healingOther:SetPoint("BOTTOM")
	healingOther:SetPoint("LEFT", healingPlayer:GetStatusBarTexture(), "RIGHT")
	healingOther:SetWidth(self.Health:GetWidth())
	healingOther:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingOther:SetStatusBarColor(0.20, 0.75, 0.35, 0.40)
	healingOther:SetFrameLevel(predictionLevel)
	SetMousePassthrough(healingOther)

	local damageAbsorb = CreateFrame("StatusBar", nil, absorbOverlay)
	damageAbsorb:SetPoint("TOP", self.Health, "TOP")
	damageAbsorb:SetPoint("BOTTOM", self.Health, "BOTTOM")
	damageAbsorb:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	damageAbsorb:SetWidth(self.Health:GetWidth())
	damageAbsorb:SetReverseFill(false)
	damageAbsorb:SetStatusBarTexture(DEFAULT_TEXTURE)
	damageAbsorb:SetStatusBarColor(1.00, 0.95, 0.20, 0.80)
	damageAbsorb:SetFrameLevel((absorbOverlay:GetFrameLevel() or predictionLevel) + 1)
	SetMousePassthrough(damageAbsorb)
	do
		local tex = damageAbsorb:GetStatusBarTexture()
		if tex and tex.SetDrawLayer then
			tex:SetDrawLayer("OVERLAY", 5)
		end
		if tex and tex.SetBlendMode then
			tex:SetBlendMode("ADD")
		end
	end

	local absorbCap = absorbOverlay:CreateTexture(nil, "OVERLAY")
	absorbCap:SetPoint("TOP", damageAbsorb, "TOP", 0, 0)
	absorbCap:SetPoint("BOTTOM", damageAbsorb, "BOTTOM", 0, 0)
	absorbCap:SetPoint("LEFT", damageAbsorb:GetStatusBarTexture(), "LEFT", 0, 0)
	absorbCap:SetWidth(2)
	absorbCap:SetColorTexture(0.95, 1.00, 1.00, 0.95)
	absorbCap:Hide()

	local healAbsorb = CreateFrame("StatusBar", nil, absorbOverlay)
	healAbsorb:SetPoint("TOP")
	healAbsorb:SetPoint("BOTTOM")
	healAbsorb:SetPoint("RIGHT", self.Health:GetStatusBarTexture(), "RIGHT")
	healAbsorb:SetWidth(self.Health:GetWidth())
	healAbsorb:SetReverseFill(true)
	healAbsorb:SetStatusBarTexture(DEFAULT_TEXTURE)
	healAbsorb:SetStatusBarColor(0.95, 0.25, 0.25, 0.55)
	healAbsorb:SetFrameLevel((absorbOverlay:GetFrameLevel() or predictionLevel) + 1)
	SetMousePassthrough(healAbsorb)
	do
		local tex = healAbsorb:GetStatusBarTexture()
		if tex and tex.SetDrawLayer then
			tex:SetDrawLayer("OVERLAY", 5)
		end
	end

	local overDamageAbsorbIndicator = self:CreateTexture(nil, "OVERLAY")
	overDamageAbsorbIndicator:SetPoint("TOP")
	overDamageAbsorbIndicator:SetPoint("BOTTOM")
	overDamageAbsorbIndicator:SetPoint("RIGHT", self.Health, "RIGHT", 7, 0)
	overDamageAbsorbIndicator:SetWidth(12)
	overDamageAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	overDamageAbsorbIndicator:SetBlendMode("ADD")
	overDamageAbsorbIndicator:SetVertexColor(1, 1, 1, 0.95)

	local overHealAbsorbIndicator = self:CreateTexture(nil, "OVERLAY")
	overHealAbsorbIndicator:SetPoint("TOP")
	overHealAbsorbIndicator:SetPoint("BOTTOM")
	overHealAbsorbIndicator:SetPoint("LEFT", self.Health, "LEFT", -7, 0)
	overHealAbsorbIndicator:SetWidth(12)
	overHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
	overHealAbsorbIndicator:SetBlendMode("ADD")
	overHealAbsorbIndicator:SetVertexColor(1, 1, 1, 0.95)

	local function HookIncomingBar(bar)
		if not bar or bar._sufIncomingHooked then
			return
		end
		bar._sufIncomingHooked = true
		bar:HookScript("OnValueChanged", function()
			if addon and addon.UpdateIncomingHealValue then
				addon:UpdateIncomingHealValue(self, self.unit)
			end
		end)
	end
	HookIncomingBar(healingAll)
	HookIncomingBar(healingPlayer)
	HookIncomingBar(healingOther)

	self.Health.HealingAll = healingAll
	self.Health.HealingPlayer = healingPlayer
	self.Health.HealingOther = healingOther
	self.Health.DamageAbsorb = damageAbsorb
	self.Health.AbsorbCap = absorbCap
	self.Health.DamageAbsorbOverlay = absorbOverlay
	self.Health.HealAbsorb = healAbsorb
	self.Health.OverDamageAbsorbIndicator = overDamageAbsorbIndicator
	self.Health.OverHealAbsorbIndicator = overHealAbsorbIndicator
	-- Match UUF behavior so absorbs remain visible at full health and heal-absorb behavior is stable.
	self.Health.damageAbsorbClampMode = 2
	self.Health.healAbsorbClampMode = 1
	self.Health.healAbsorbMode = 1
	self.Health.incomingHealOverflow = 1.05
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
	SetMousePassthrough(Auras)
	Auras.CreateButton = function(element, position)
		local button = owner:AcquireRuntimeFrame("Button", element, "SUF_AuraButton")
		button:SetParent(element)
		button:SetID(position or 0)
		button:SetSize(element.size or 18, element.size or 18)
		button:Show()
		if button.EnableMouse then
			button:EnableMouse(true)
		end

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

function addon:SetupClassPowerCallbacks(frame)
	if not (frame and frame.ClassPower and not frame.__sufClassPowerCallbacks) then
		return
	end

	frame.__sufClassPowerCallbacks = true

	frame.ClassPower.PostUpdate = function(element, cur, max)
		local owner = element and element.__owner
		if not owner then
			return
		end
		local slots = tonumber(max) or 0
		if slots <= 0 then
			slots = #element
		end
		slots = math.max(1, math.min(#element, slots))
		if owner.__sufClassPowerVisibleSlots ~= slots then
			owner.__sufClassPowerVisibleSlots = slots
			addon:LayoutClassPower(owner)
		end
	end

	frame.ClassPower.PostVisibility = function(element, isVisible)
		local owner = element and element.__owner
		if not owner then
			return
		end
		if not isVisible then
			owner.__sufClassPowerVisibleSlots = nil
		end
		addon:LayoutClassPower(owner)
	end
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

function addon:GetEnhancementSettings()
	if not (self.db and self.db.profile) then
		return defaults.profile.enhancements
	end
	self.db.profile.enhancements = self.db.profile.enhancements or CopyTableDeep(defaults.profile.enhancements)
	return self.db.profile.enhancements
end

function addon:PlayWindowOpenAnimation(frame)
	if not frame then
		return
	end
	local cfg = self:GetEnhancementSettings()
	if cfg.uiOpenAnimation == false then
		return
	end
	if not CreateAnimationGroup then
		return
	end

	frame._sufOpenAnimGroup = frame._sufOpenAnimGroup or CreateAnimationGroup(frame)
	local group = frame._sufOpenAnimGroup
	if not group then
		return
	end

	local duration = math.max(0.05, math.min(0.60, tonumber(cfg.uiOpenAnimationDuration) or 0.18))
	local offsetY = math.max(-40, math.min(40, tonumber(cfg.uiOpenAnimationOffsetY) or 12))

	if not group._sufAlpha then
		local alpha = group:CreateAnimation("fade")
		alpha:SetDuration(duration)
		alpha:SetEasing("outquadratic")
		alpha:SetChange(1)
		group._sufAlpha = alpha
	end
	if not group._sufMove then
		local move = group:CreateAnimation("move")
		move:SetDuration(duration)
		move:SetEasing("outquadratic")
		move:SetOffset(0, 0)
		group._sufMove = move
	end

	if group._sufAlpha.SetDuration then
		group._sufAlpha:SetDuration(duration)
	end
	if group._sufMove.SetDuration then
		group._sufMove:SetDuration(duration)
	end
	if group._sufMove.SetOffset then
		group._sufMove:SetOffset(0, offsetY)
	end

	if frame._sufOpenAnimRestore then
		local restore = frame._sufOpenAnimRestore
		frame:ClearAllPoints()
		frame:SetPoint(restore[1], restore[2], restore[3], restore[4], restore[5])
		frame._sufOpenAnimRestore = nil
	end

	local a1, rel, a2, x, y = frame:GetPoint(1)
	if offsetY ~= 0 and a1 and rel and a2 then
		frame._sufOpenAnimRestore = { a1, rel, a2, x or 0, y or 0 }
		frame:ClearAllPoints()
		frame:SetPoint(a1, rel, a2, x or 0, (y or 0) - offsetY)
	end

	if group.IsPlaying and group:IsPlaying() then
		group:Stop()
	end
	frame:SetAlpha(0)
	group:Play()
end

function addon:IsStickyWindowsEnabled()
	local cfg = self:GetEnhancementSettings()
	return cfg and cfg.stickyWindows ~= false and LibSimpleSticky ~= nil
end

function addon:GetStickyDragTargets(sourceFrame)
	local targets = {}
	local seen = {}
	local function AddFrame(frame)
		if not frame or frame == sourceFrame then
			return
		end
		if seen[frame] then
			return
		end
		seen[frame] = true
		targets[#targets + 1] = frame
	end

	AddFrame(UIParent)

	if self.frames then
		for i = 1, #self.frames do
			AddFrame(self.frames[i])
		end
	end
	if self.headers then
		for _, header in pairs(self.headers) do
			AddFrame(header)
		end
	end

	AddFrame(self.optionsFrame)
	AddFrame(self.debugPanel)
	AddFrame(self.debugExportFrame)
	AddFrame(self.debugSettingsFrame)

	return targets
end

function addon:EnableMovableFrame(frame, allowSticky)
	if not frame then
		return
	end

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(movableFrame)
		if allowSticky and self:IsStickyWindowsEnabled() then
			local cfg = self:GetEnhancementSettings()
			local range = math.max(4, math.min(36, tonumber(cfg.stickyRange) or 15))
			LibSimpleSticky.rangeX = range
			LibSimpleSticky.rangeY = range
			LibSimpleSticky:StartMoving(movableFrame, self:GetStickyDragTargets(movableFrame), 0, 0, 0, 0)
		else
			movableFrame:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(movableFrame)
		if allowSticky and self:IsStickyWindowsEnabled() then
			local ok = pcall(LibSimpleSticky.StopMoving, LibSimpleSticky, movableFrame)
			if not ok then
				movableFrame:StopMovingOrSizing()
			end
		else
			movableFrame:StopMovingOrSizing()
		end
	end)
end

function addon:UpdateSingleFrame(frame)
	if not frame then
		return
	end

	self:ApplyTags(frame)
	self:ApplyMedia(frame)
	self:ApplySize(frame)
	self:ApplyIndicators(frame)
	self:ApplyPortrait(frame)
	frame:UpdateAllElements("SimpleUnitFrames_Update")
	self:UpdateAbsorbValue(frame)
	self:UpdateIncomingHealValue(frame)
	self:UpdateUnitFrameStatusIndicators(frame)
end

function addon:UpdateFramesByUnitType(unitType)
	if not unitType then
		self:UpdateAllFrames()
		return
	end

	local totalStart = debugprofilestop and debugprofilestop() or nil
	local updated = 0
	for _, frame in ipairs(self.frames or {}) do
		if frame and frame.sufUnitType == unitType then
			local frameStart = debugprofilestop and debugprofilestop() or nil
			self:UpdateSingleFrame(frame)
			updated = updated + 1
			if frameStart then
				local frameEnd = debugprofilestop() or frameStart
				self:RecordProfilerEvent("suf:update.frame", frameEnd - frameStart)
			end
		end
	end

	if totalStart then
		local totalEnd = debugprofilestop() or totalStart
		self:RecordProfilerEvent("suf:update.unit." .. tostring(unitType), totalEnd - totalStart)
	end
	return updated
end

function addon:ScheduleUpdateUnitType(unitType)
	if not unitType then
		self:ScheduleUpdateAll()
		return
	end
	if self.isBuildingOptions then
		return
	end

	self._unitUpdateTimers = self._unitUpdateTimers or {}
	if self._unitUpdateTimers[unitType] then
		return
	end

	self._unitUpdateTimers[unitType] = C_Timer.NewTimer(0.05, function()
		if self._unitUpdateTimers then
			self._unitUpdateTimers[unitType] = nil
		end
		self:UpdateFramesByUnitType(unitType)
	end)
end

function addon:FlushPendingPluginUpdates()
	if not self._pendingPluginUpdates then
		return true
	end
	if InCombatLockdown and InCombatLockdown() then
		return false
	end

	local pending = self._pendingPluginUpdates
	self._pendingPluginUpdates = nil
	if self:IsDebugEnabled() and self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.systems and self.db.profile.debug.systems.Events then
		local count = 0
		for key in pairs(pending) do
			if key ~= "__global" then
				count = count + 1
			end
		end
		self:DebugLog("Events", ("Flushing plugin updates (global=%s, units=%d)"):format(tostring(pending.__global == true), count), 3)
	end

	if pending.__global then
		self:ScheduleUpdateAll()
		return true
	end

	for unitType in pairs(pending) do
		if unitType ~= "__global" then
			self:ScheduleUpdateUnitType(unitType)
		end
	end
	return true
end

function addon:StartPluginUpdateTicker()
	if self._pluginUpdateTicker then
		return
	end
	self._pluginUpdateTicker = C_Timer.NewTicker(0.2, function()
		local flushed = self:FlushPendingPluginUpdates()
		if flushed and not self._pendingPluginUpdates and self._pluginUpdateTicker then
			self._pluginUpdateTicker:Cancel()
			self._pluginUpdateTicker = nil
		end
	end)
end

function addon:ReapplyPluginElements(unitType)
	for _, frame in ipairs(self.frames or {}) do
		if frame and frame.sufUnitType and (not unitType or frame.sufUnitType == unitType) then
			self:ApplyPluginElements(frame)
		end
	end
end

function addon:SchedulePluginUpdate(unitType)
	self._pendingPluginUpdates = self._pendingPluginUpdates or {}
	if unitType and IsGroupUnitType(unitType) then
		self._pendingPluginUpdates[unitType] = true
	else
		self._pendingPluginUpdates.__global = true
	end

	if InCombatLockdown and InCombatLockdown() then
		self:StartPluginUpdateTicker()
		return
	end
	self:StartPluginUpdateTicker()
end

function addon:Style(frame, unit)
	frame.sufUnitType = ResolveUnitType(unit)
	frame.__isSimpleUnitFrames = true
	local unitLayout = self:GetUnitLayoutSettings(frame.sufUnitType)
	frame:SetScale(1)
	frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	if frame.EnableMouse then
		frame:EnableMouse(true)
	end
	if frame.SetMouseClickEnabled then
		frame:SetMouseClickEnabled(true)
	end
	frame:SetAttribute("type2", "togglemenu")
	frame:SetAttribute("*type2", "togglemenu")
	if not frame.__sufLegacyMenu then
		frame.__sufLegacyMenu = frame.menu or UnitPopup_ShowMenu
	end
	frame.menu = function(widget)
		addon:OpenUnitContextMenu(widget)
	end
	frame:SetScript("OnEnter", UnitFrame_OnEnter)
	frame:SetScript("OnLeave", UnitFrame_OnLeave)

	local size = self.db.profile.sizes[frame.sufUnitType]
	frame:SetSize(size.width, size.height)

	local Health = CreateStatusBar(frame, size.height)
	Health:SetAllPoints(frame)
	Health.colorClass = true
	Health.colorReaction = true
	SetMousePassthrough(Health)
	frame.Health = Health
	HookRightClickProxy(Health, frame)
	CreateHealthPrediction(frame)
	if frame.Health then
		local originalPostUpdate = frame.Health.PostUpdate
		frame.Health.PostUpdate = function(element, unit)
			if originalPostUpdate then
				originalPostUpdate(element, unit)
			end
			addon:UpdateAbsorbValue(frame, unit)
			addon:UpdateIncomingHealValue(frame, unit)
		end
	end

	local Power = CreateStatusBar(frame, self.db.profile.powerHeight)
	Power:SetPoint("TOPLEFT", Health, "BOTTOMLEFT", 0, -2)
	Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, -2)
	Power.colorPower = true
	SetMousePassthrough(Power)
	frame.Power = Power
	HookRightClickProxy(Power, frame)

	local PowerBG = Power:CreateTexture(nil, "BACKGROUND")
	PowerBG:SetAllPoints(Power)
	PowerBG:SetColorTexture(0, 0, 0, 0.6)
	frame.PowerBG = PowerBG
	HookRightClickProxy(PowerBG, frame)

	local MainBarsBackground = frame:CreateTexture(nil, "BACKGROUND")
	MainBarsBackground:SetDrawLayer("BACKGROUND", -8)
	MainBarsBackground:SetColorTexture(0.05, 0.05, 0.05, 0.4)
	frame.MainBarsBackground = MainBarsBackground
	HookRightClickProxy(MainBarsBackground, frame)

	local TextOverlay = self:AcquireRuntimeFrame("Frame", frame, "SUF_TextOverlay")
	TextOverlay:Show()
	TextOverlay:SetAllPoints(frame)
	TextOverlay:SetFrameStrata(frame:GetFrameStrata())
	TextOverlay:SetFrameLevel((Health:GetFrameLevel() or frame:GetFrameLevel() or 1) + 8)
	SetMousePassthrough(TextOverlay)
	frame.TextOverlay = TextOverlay
	HookRightClickProxy(TextOverlay, frame)

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

	local IncomingHealValue = CreateFontString(TextOverlay, 10, "OUTLINE")
	IncomingHealValue:SetPoint("LEFT", Health, "RIGHT", 2, 0)
	IncomingHealValue:SetJustifyH("LEFT")
	IncomingHealValue:SetDrawLayer("OVERLAY", 7)
	frame.IncomingHealValue = IncomingHealValue

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
	SetMousePassthrough(IndicatorFrame)
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

	local RoleIndicator = IndicatorFrame.__sufRoleIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
	RoleIndicator:SetSize(18, 18)
	RoleIndicator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, 2)
	RoleIndicator:SetDrawLayer("OVERLAY", 6)
	IndicatorFrame.__sufRoleIndicator = RoleIndicator
	frame.RoleIndicator = RoleIndicator

	local RaidMarkerIndicator = IndicatorFrame.__sufRaidMarkerIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
	RaidMarkerIndicator:SetSize(18, 18)
	RaidMarkerIndicator:SetPoint("TOP", frame, "TOP", -20, -2)
	RaidMarkerIndicator:SetDrawLayer("OVERLAY", 6)
	IndicatorFrame.__sufRaidMarkerIndicator = RaidMarkerIndicator
	frame.RaidMarkerIndicator = RaidMarkerIndicator

	local LeaderIndicator = IndicatorFrame.__sufLeaderIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
	LeaderIndicator:SetSize(16, 16)
	LeaderIndicator:SetPoint("TOP", frame, "TOP", 0, 2)
	LeaderIndicator:SetDrawLayer("OVERLAY", 6)
	IndicatorFrame.__sufLeaderIndicator = LeaderIndicator
	frame.LeaderIndicator = LeaderIndicator

	local StatusIndicator = TextOverlay.__sufStatusIndicator or CreateFontString(TextOverlay, 13, "OUTLINE")
	StatusIndicator:SetPoint("CENTER", frame, "CENTER", 0, 0)
	StatusIndicator:SetJustifyH("CENTER")
	StatusIndicator:SetDrawLayer("OVERLAY", 7)
	StatusIndicator:SetText("")
	TextOverlay.__sufStatusIndicator = StatusIndicator
	frame.StatusIndicator = StatusIndicator

	frame.Fader = frame.Fader or {}
	if IsGroupUnitType(frame.sufUnitType) then
		self:EnsureRaidDebuffsElement(frame)
		self:EnsureAuraWatchElement(frame)
	end

	local Portrait2D = frame:CreateTexture(nil, "ARTWORK")
	Portrait2D:SetSize(32, 32)
	Portrait2D:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	SetMousePassthrough(Portrait2D)
	frame.Portrait2D = Portrait2D
	HookRightClickProxy(Portrait2D, frame)

	local Portrait3D = CreateFrame("PlayerModel", nil, frame)
	Portrait3D:SetSize(32, 32)
	Portrait3D:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	SetMousePassthrough(Portrait3D)
	frame.Portrait3D = Portrait3D
	HookRightClickProxy(Portrait3D, frame)

	if unit == "player" then
		CreateClassPower(frame, self.db.profile.classPowerHeight)
		self:SetupClassPowerCallbacks(frame)
		CreateAuras(frame)

		local secondaryGap = math.max(-6, math.min(24, math.floor((unitLayout.secondaryToFrame or 0) + 0.5)))
		local AdditionalPower = CreateStatusBar(frame, math.max(4, math.floor(self.db.profile.powerHeight * 0.7)))
		AdditionalPower:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 0, secondaryGap)
		AdditionalPower:SetPoint("BOTTOMRIGHT", Health, "TOPRIGHT", 0, secondaryGap)
		AdditionalPower.colorPower = true
		SetMousePassthrough(AdditionalPower)
		frame.AdditionalPower = AdditionalPower
		HookRightClickProxy(AdditionalPower, frame)

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
			SetMousePassthrough(frame.ClassPowerAnchor)
			HookRightClickProxy(frame.ClassPowerAnchor, frame)
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
	self:ApplyIndicators(frame)
	self:UpdateUnitFrameStatusIndicators(frame)
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
	C_Timer.After(0, function()
		if self and self.spawned then
			self:SchedulePluginUpdate()
		end
	end)
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
	C_Timer.After(0, function()
		if self and self.spawned then
			if needParty then
				self:SchedulePluginUpdate("party")
			end
			if needRaid then
				self:SchedulePluginUpdate("raid")
			end
		end
	end)
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

function addon:ValidateImportedProfileData(data)
	if type(data) ~= "table" then
		return nil, "Imported data is not a table."
	end

	local report = {
		ok = true,
		errors = {},
		warnings = {},
		keyCount = 0,
		unitCount = 0,
		tagCount = 0,
		pluginUnitCount = 0,
		reloadReasons = {},
	}
	for _ in pairs(data) do
		report.keyCount = report.keyCount + 1
	end
	if type(data.units) ~= "nil" and type(data.units) ~= "table" then
		report.errors[#report.errors + 1] = "units must be a table."
	end
	if type(data.tags) ~= "nil" and type(data.tags) ~= "table" then
		report.errors[#report.errors + 1] = "tags must be a table."
	end
	if type(data.plugins) ~= "nil" and type(data.plugins) ~= "table" then
		report.errors[#report.errors + 1] = "plugins must be a table."
	end
	if type(data.units) == "table" then
		for _ in pairs(data.units) do
			report.unitCount = report.unitCount + 1
		end
		report.reloadReasons[#report.reloadReasons + 1] = ("unit layouts (%d)"):format(report.unitCount)
	end
	if type(data.tags) == "table" then
		for _ in pairs(data.tags) do
			report.tagCount = report.tagCount + 1
		end
		report.reloadReasons[#report.reloadReasons + 1] = ("tag configs (%d)"):format(report.tagCount)
	end
	if type(data.plugins) == "table" then
		local pluginUnits = data.plugins.units
		if type(pluginUnits) == "table" then
			for _ in pairs(pluginUnits) do
				report.pluginUnitCount = report.pluginUnitCount + 1
			end
		end
		report.reloadReasons[#report.reloadReasons + 1] = "plugin behavior"
	end
	if data.media ~= nil then
		report.reloadReasons[#report.reloadReasons + 1] = "shared media/font bindings"
	end
	if data.optionsUI ~= nil then
		report.warnings[#report.warnings + 1] = "options UI state is included and will overwrite local panel preferences."
	end
	if report.keyCount == 0 then
		report.warnings[#report.warnings + 1] = "import payload is empty."
	end
	if #report.errors > 0 then
		report.ok = false
		return report, table.concat(report.errors, " ")
	end
	return report
end

function addon:BuildImportedProfilePreview(data, report)
	local preview = {
		summary = "",
		lines = {},
		reloadSummary = "",
	}
	if type(data) ~= "table" then
		preview.summary = "No validated payload."
		return preview
	end
	local validation = report or self:ValidateImportedProfileData(data)
	if not validation or validation.ok == false then
		preview.summary = "Validation failed."
		return preview
	end
	preview.lines[#preview.lines + 1] = ("Top-level keys: %d"):format(validation.keyCount or 0)
	preview.lines[#preview.lines + 1] = ("Units: %d | Tags: %d | Plugin Units: %d"):format(
		validation.unitCount or 0,
		validation.tagCount or 0,
		validation.pluginUnitCount or 0
	)
	if #(validation.warnings or {}) > 0 then
		for i = 1, #validation.warnings do
			preview.lines[#preview.lines + 1] = "Warning: " .. tostring(validation.warnings[i])
		end
	end
	local reasons = validation.reloadReasons or {}
	if #reasons > 0 then
		preview.reloadSummary = "Reload recommended for: " .. table.concat(reasons, ", ")
		preview.lines[#preview.lines + 1] = preview.reloadSummary
	else
		preview.reloadSummary = "No explicit reload reasons detected."
		preview.lines[#preview.lines + 1] = preview.reloadSummary
	end
	preview.summary = table.concat(preview.lines, "\n")
	return preview
end

function addon:BuildManualImportFallbackText(data, report)
	local validation = report or self:ValidateImportedProfileData(data)
	local lines = {
		"Manual Import Fallback",
		"1) Keep this import string for backup.",
		"2) Validate and preview before applying any manual edits.",
		"3) If auto-apply fails, switch profile then copy settings via unit/module copy tools.",
	}
	if validation and validation.reloadReasons and #validation.reloadReasons > 0 then
		lines[#lines + 1] = "Reload recommended for: " .. table.concat(validation.reloadReasons, ", ")
	end
	return table.concat(lines, "\n")
end

local function ReplaceTableContents(dst, src)
	if type(dst) ~= "table" or type(src) ~= "table" then
		return false
	end
	for key in pairs(dst) do
		if src[key] == nil then
			dst[key] = nil
		end
	end
	for key, value in pairs(src) do
		if type(value) == "table" then
			if type(dst[key]) ~= "table" then
				dst[key] = {}
			end
			ReplaceTableContents(dst[key], value)
		else
			dst[key] = value
		end
	end
	return true
end

function addon:BuildImportedProfileTarget(data)
	local profile = CopyTableDeep(defaults.profile)
	for key, value in pairs(data) do
		if type(value) == "table" then
			profile[key] = CopyTableDeep(value)
		else
			profile[key] = value
		end
	end
	MergeDefaults(profile, defaults.profile)
	return profile
end

function addon:PromptReloadAfterImport(summaryText)
	StaticPopupDialogs["SUF_IMPORT_RELOAD_CONFIRM"] = StaticPopupDialogs["SUF_IMPORT_RELOAD_CONFIRM"] or {
		text = "Import applied. Reload UI now?",
		button1 = "Reload",
		button2 = "Later",
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	local popup = StaticPopupDialogs["SUF_IMPORT_RELOAD_CONFIRM"]
	popup.text = tostring(summaryText or "Import applied. Reload UI now?")
	StaticPopup_Show("SUF_IMPORT_RELOAD_CONFIRM")
end

function addon:ApplyImportedProfile(data)
	local report, validationErr = self:ValidateImportedProfileData(data)
	if not report then
		return false, validationErr or "Invalid import payload."
	end
	if report.ok == false then
		return false, validationErr or "Import validation failed."
	end

	local targetProfile = self:BuildImportedProfileTarget(data)
	local previousProfile = CopyTableDeep(self.db.profile or defaults.profile)
	local adapterUsed = nil

	local adapters = {
		{
			id = "api_replace_in_place",
			run = function()
				if self.db and type(self.db.profile) == "table" then
					return ReplaceTableContents(self.db.profile, targetProfile)
				end
				return false
			end,
		},
		{
			id = "copy_fallback_swap",
			run = function()
				self.db.profile = CopyTableDeep(targetProfile)
				return true
			end,
		},
	}

	for i = 1, #adapters do
		local adapter = adapters[i]
		local ok, applied = pcall(adapter.run)
		if ok and applied then
			adapterUsed = adapter.id
			break
		end
	end
	if not adapterUsed then
		return false, "Unable to apply import with available adapters.", {
			manualFallback = true,
			manualText = self:BuildManualImportFallbackText(data, report),
		}
	end

	local postOk, postErr = pcall(function()
		self:NormalizePluginConfig()
		self:UpdateAllFrames()
		self:ApplyVisibilityRules()
	end)
	if not postOk then
		local rollbackOk = pcall(function()
			if self.db and type(self.db.profile) == "table" then
				ReplaceTableContents(self.db.profile, previousProfile)
			else
				self.db.profile = CopyTableDeep(previousProfile)
			end
			self:NormalizePluginConfig()
			self:UpdateAllFrames()
			self:ApplyVisibilityRules()
		end)
		if not rollbackOk then
			return false, "Import failed and rollback did not complete safely: " .. tostring(postErr)
		end
		return false, "Import failed and was rolled back: " .. tostring(postErr)
	end

	local preview = self:BuildImportedProfilePreview(data, report)
	return true, nil, {
		adapter = adapterUsed,
		report = report,
		preview = preview,
	}
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
	self._incomingHealthTrendByGUID = {}
	self:UpdateBlizzardFrames()
	self:TrySpawnFrames()
	self:ScheduleGroupHeaders(0.5)
end

function addon:OnClassResourceContextChanged()
	for _, frame in ipairs(self.frames or {}) do
		if frame and frame.sufUnitType == "player" then
			if frame.ClassPower and frame.ClassPower.ForceUpdate then
				pcall(frame.ClassPower.ForceUpdate, frame.ClassPower)
			elseif frame.ForceUpdate then
				pcall(frame.ForceUpdate, frame, frame.unit)
			end
			if frame.AdditionalPower and frame.AdditionalPower.ForceUpdate then
				pcall(frame.AdditionalPower.ForceUpdate, frame.AdditionalPower)
			end
			self:LayoutClassPower(frame)
			break
		end
	end
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
	local UI_STYLE = {
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
	frame:SetSize(1140, initialHeight)
	frame:SetPoint("CENTER")
	self:EnableMovableFrame(frame, true)
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
	if frame.SetBackdropColor then
		frame:SetBackdropColor(UI_STYLE.windowBg[1], UI_STYLE.windowBg[2], UI_STYLE.windowBg[3], UI_STYLE.windowBg[4])
	end
	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(UI_STYLE.windowBorder[1], UI_STYLE.windowBorder[2], UI_STYLE.windowBorder[3], UI_STYLE.windowBorder[4])
	end

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
	tabsHost:SetWidth(170)
	if tabsHost.SetBackdropColor then
		tabsHost:SetBackdropColor(UI_STYLE.panelBg[1], UI_STYLE.panelBg[2], UI_STYLE.panelBg[3], UI_STYLE.panelBg[4])
	end
	if tabsHost.SetBackdropBorderColor then
		tabsHost:SetBackdropBorderColor(UI_STYLE.panelBorder[1], UI_STYLE.panelBorder[2], UI_STYLE.panelBorder[3], UI_STYLE.panelBorder[4])
	end

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
	if contentHost.SetBackdropColor then
		contentHost:SetBackdropColor(UI_STYLE.panelBg[1], UI_STYLE.panelBg[2], UI_STYLE.panelBg[3], UI_STYLE.panelBg[4])
	end
	if contentHost.SetBackdropBorderColor then
		contentHost:SetBackdropBorderColor(UI_STYLE.panelBorder[1], UI_STYLE.panelBorder[2], UI_STYLE.panelBorder[3], UI_STYLE.panelBorder[4])
	end

	local searchLabel = contentHost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	searchLabel:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 12, -10)
	searchLabel:SetText("Search")
	searchLabel:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])

	local searchBox = CreateFrame("EditBox", nil, contentHost, "InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetSize(280, 22)
	searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
	if searchBox.SetBackdropColor then
		searchBox:SetBackdropColor(UI_STYLE.searchBg[1], UI_STYLE.searchBg[2], UI_STYLE.searchBg[3], UI_STYLE.searchBg[4])
	end
	if searchBox.SetBackdropBorderColor then
		searchBox:SetBackdropBorderColor(UI_STYLE.searchBorder[1], UI_STYLE.searchBorder[2], UI_STYLE.searchBorder[3], UI_STYLE.searchBorder[4])
	end
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
				fs:SetTextColor(1.0, 0.92, 0.3)
			elseif large then
				fs:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
			else
				fs:SetTextColor(0.92, 0.90, 0.84)
			end
			self.y = self.y - (large and 26 or 18)
		end

		function builder:Edit(label, getter, setter)
			RegisterOptionsSearchEntry(tabKey, label, "edit text input tag", "edit")
			if not self:Matches(label, "edit text input tag") then
				return
			end
			local x, y, width = self:Reserve(56, false)
			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			fs:SetText(label)
			if self:HasSearch() then
				fs:SetTextColor(1.0, 0.92, 0.3)
			end
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
					text:SetTextColor(1.0, 0.92, 0.3)
				end
			end
			if low then low:SetText(tostring(minv)) end
			if high then high:SetText(tostring(maxv)) end
			s:SetScript("OnValueChanged", function(_, v)
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
					c.Text:SetTextColor(1.0, 0.92, 0.3)
				end
			end
			c:SetChecked(getter() and true or false)
			c:SetEnabled(not disabled)
			c:SetScript("OnClick", function(w)
				setter(w:GetChecked() and true or false)
			end)
		end

		function builder:Button(label, onClick, span)
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
			b:SetScript("OnClick", function()
				if type(onClick) == "function" then
					onClick()
				end
			end)
			return b
		end

		function builder:Dropdown(label, options, getter, setter)
			RegisterOptionsSearchEntry(tabKey, label, "dropdown select profile preset mode texture font anchor", "dropdown")
			if not self:Matches(label, "dropdown select profile preset mode texture font anchor") then
				return
			end
			local x, y, width = self:Reserve(58, false)
			local fs = self.page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", x, y)
			fs:SetText(label)
			if self:HasSearch() then
				fs:SetTextColor(1.0, 0.92, 0.3)
			end
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
			RegisterOptionsSearchEntry(tabKey, label, "color picker red green blue", "color")
			if not self:Matches(label, "color picker red green blue") then
				return
			end
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
			if self:HasSearch() then
				fs:SetTextColor(1.0, 0.92, 0.3)
			end

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
			toggle:SetBackdropColor(0.10, 0.10, 0.12, 0.80)
			toggle:SetBackdropBorderColor(UI_STYLE.panelBorder[1], UI_STYLE.panelBorder[2], UI_STYLE.panelBorder[3], UI_STYLE.panelBorder[4])
			local txt = toggle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			txt:SetPoint("LEFT", toggle, "LEFT", 8, 0)
			txt:SetJustifyH("LEFT")
			txt:SetText((expanded and "[-] " or "[+] ") .. tostring(title or "Section"))
			txt:SetTextColor(UI_STYLE.accent[1], UI_STYLE.accent[2], UI_STYLE.accent[3])
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

	function frame.BuildTab(_, tabKey)
		frame.currentTab = tabKey
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
			local kind = tostring(option.type or "")
			if kind == "label" then
				uiBuilder:Label(option.text or "", option.large == true)
			elseif kind == "paragraph" then
				uiBuilder:Paragraph(option.text or "", option.small ~= false)
			elseif kind == "check" then
				uiBuilder:Check(option.label or "", option.get, option.set, IsOptionDisabled(option))
			elseif kind == "slider" then
				uiBuilder:Slider(option.label or "", option.min or 0, option.max or 1, option.step or 1, option.get, option.set)
			elseif kind == "dropdown" then
				uiBuilder:Dropdown(option.label or "", ResolveOptionValue(option.options) or {}, option.get, option.set)
			elseif kind == "edit" then
				uiBuilder:Edit(option.label or "", option.get, option.set)
			elseif kind == "color" then
				uiBuilder:Color(option.label or "", option.get, option.set)
			elseif kind == "button" then
				uiBuilder:Button(option.label or "", option.onClick, option.span == true)
			elseif kind == "dropdown_or_edit" then
				local opts = ResolveOptionValue(option.options) or {}
				if #opts > 0 then
					uiBuilder:Dropdown(option.label or "", opts, option.get, option.set)
				else
					uiBuilder:Edit(option.fallbackLabel or option.label or "", option.get, option.set)
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
					tokens[#tokens + 1] = (entry.remove and "-" or "") .. tostring(entry.id)
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
			addHint:SetText("Spell ID")
			local addBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			addBtn:SetPoint("LEFT", addBox, "RIGHT", 6, 0)
			addBtn:SetSize(80, 22)
			addBtn:SetText("Add")
			addBtn:SetScript("OnClick", function()
				local spellID = tonumber(TrimString(SafeText(addBox:GetText(), "")))
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
				local spellID = tonumber(TrimString(SafeText(addBox:GetText(), "")))
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
			clearBtn:SetPoint("LEFT", addRemoveBtn, "RIGHT", 6, 0)
			clearBtn:SetSize(100, 22)
			clearBtn:SetText("Clear List")
			clearBtn:SetScript("OnClick", function()
				auraEntries = {}
				SaveAuraWatchList()
			end)

			local sortAscBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			sortAscBtn:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 44)
			sortAscBtn:SetSize(96, 20)
			sortAscBtn:SetText("Sort Asc")
			sortAscBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return (a.remove and 1 or 0) < (b.remove and 1 or 0)
					end
					return (a.id or 0) < (b.id or 0)
				end)
				SaveAuraWatchList()
			end)
			local sortDescBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			sortDescBtn:SetPoint("LEFT", sortAscBtn, "RIGHT", 6, 0)
			sortDescBtn:SetSize(96, 20)
			sortDescBtn:SetText("Sort Desc")
			sortDescBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return (a.remove and 1 or 0) < (b.remove and 1 or 0)
					end
					return (a.id or 0) > (b.id or 0)
				end)
				SaveAuraWatchList()
			end)
			for i = 1, #AURAWATCH_PRESETS do
				local preset = AURAWATCH_PRESETS[i]
				local presetBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
				presetBtn:SetPoint("LEFT", (i == 1 and sortDescBtn or page.__sufPrevPresetBtn), (i == 1 and "RIGHT" or "RIGHT"), 6, 0)
				presetBtn:SetSize(118, 20)
				presetBtn:SetText(preset.label)
				presetBtn:SetScript("OnClick", function()
					for s = 1, #preset.spells do
						auraEntries[#auraEntries + 1] = { id = preset.spells[s], remove = false }
					end
					SaveAuraWatchList()
				end)
				page.__sufPrevPresetBtn = presetBtn
			end
			page.__sufPrevPresetBtn = nil

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
				if auraEntries[i].remove then
					specialCount = specialCount + 1
				else
					regularCount = regularCount + 1
				end
			end
			local grouping = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			grouping:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 72)
			grouping:SetText(("Priority Groups: Regular (+)=%d, Special Remove (-)=%d"):format(regularCount, specialCount))

			local dragFrom = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			dragFrom:SetAutoFocus(false)
			dragFrom:SetSize(46, 20)
			dragFrom:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 92)
			dragFrom:SetScript("OnEscapePressed", function(w) w:ClearFocus() end)
			local dragArrow = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
			dragArrow:SetPoint("LEFT", dragFrom, "RIGHT", 4, 0)
			dragArrow:SetText("->")
			local dragTo = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
			dragTo:SetAutoFocus(false)
			dragTo:SetSize(46, 20)
			dragTo:SetPoint("LEFT", dragArrow, "RIGHT", 4, 0)
			dragTo:SetScript("OnEscapePressed", function(w) w:ClearFocus() end)
			local dragBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			dragBtn:SetPoint("LEFT", dragTo, "RIGHT", 6, 0)
			dragBtn:SetSize(120, 20)
			dragBtn:SetText("Drag Move")
			dragBtn:SetScript("OnClick", function()
				if MoveAuraEntry(dragFrom:GetText(), dragTo:GetText()) then
					SaveAuraWatchList()
				else
					self:Print(addonName .. ": Invalid drag move indexes.")
				end
			end)
			local regularFirstBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			regularFirstBtn:SetPoint("LEFT", dragBtn, "RIGHT", 6, 0)
			regularFirstBtn:SetSize(104, 20)
			regularFirstBtn:SetText("Regular First")
			regularFirstBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return not a.remove
					end
					return (a.id or 0) < (b.id or 0)
				end)
				SaveAuraWatchList()
			end)
			local specialFirstBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			specialFirstBtn:SetPoint("LEFT", regularFirstBtn, "RIGHT", 6, 0)
			specialFirstBtn:SetSize(104, 20)
			specialFirstBtn:SetText("Special First")
			specialFirstBtn:SetScript("OnClick", function()
				table.sort(auraEntries, function(a, b)
					if a.remove ~= b.remove then
						return a.remove
					end
					return (a.id or 0) < (b.id or 0)
				end)
				SaveAuraWatchList()
			end)

			local listTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			listTitle:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 116)
			listTitle:SetText("Configured Entries (priority order)")
			local entries = auraEntries
			local maxRows = math.min(10, #entries)
			for row = 1, maxRows do
				local rowIndex = row
				local entry = entries[row]
				local rowY = ay - 138 - ((row - 1) * 22)
				local spellName = self:GetSpellNameForValidation(entry.id) or "Unknown Spell"
				local rowText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				rowText:SetPoint("TOPLEFT", page, "TOPLEFT", ax, rowY)
				rowText:SetWidth(awidth - 164)
				rowText:SetJustifyH("LEFT")
				rowText:SetText(("[%d] %s%s  %s"):format(rowIndex, (entry.remove and "- " or "+ "), tostring(entry.id), tostring(spellName)))
				if entry.remove then
					rowText:SetTextColor(1.00, 0.40, 0.40)
				else
					rowText:SetTextColor(0.40, 1.00, 0.40)
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
				extra:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 138 - (maxRows * 22))
				extra:SetText(("...and %d more entries"):format(#entries - maxRows))
			end
			local report = self:ValidateAuraWatchSpellList(auraWatchCfg.customSpellList or "")
			local hasWarn = (#(report.invalidIDs or {}) > 0 or #(report.invalidTokens or {}) > 0)
			local summary = ("Validation: add=%d remove=%d invalidIDs=%d invalidTokens=%d"):format(
				#(report.validAdds or {}),
				#(report.validRemoves or {}),
				#(report.invalidIDs or {}),
				#(report.invalidTokens or {})
			)
			local summaryText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			summaryText:SetPoint("TOPLEFT", page, "TOPLEFT", ax, ay - 142 - (maxRows * 22))
			summaryText:SetWidth(awidth)
			summaryText:SetJustifyH("LEFT")
			summaryText:SetText(summary)
			if hasWarn then
				summaryText:SetTextColor(1.00, 0.35, 0.35)
			else
				summaryText:SetTextColor(0.35, 1.00, 0.45)
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
							GameTooltip:SetOwner(widget, "ANCHOR_TOPLEFT")
							GameTooltip:AddLine(item.tabLabel, 1, 1, 1)
							GameTooltip:AddLine(details, 0.7, 0.85, 1, true)
							GameTooltip:Show()
						end)
						btn:SetScript("OnLeave", function()
							GameTooltip:Hide()
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
				{ type = "slider", label = "Spell Name Max Chars", min = 6, max = 40, step = 1, get = function() return castbarCfg.spellMaxChars end, set = function(v) castbarCfg.spellMaxChars = v; self:ScheduleUpdateAll() end },
				{ type = "slider", label = "Cast Time Decimals", min = 0, max = 2, step = 1, get = function() return castbarCfg.timeDecimals end, set = function(v) castbarCfg.timeDecimals = v; self:ScheduleUpdateAll() end },
				{ type = "check", label = "Show Cast Delay", get = function() return castbarCfg.showDelay ~= false end, set = function(v) castbarCfg.showDelay = v; self:ScheduleUpdateAll() end },
				{ type = "label", text = "Library Enhancements" },
				{ type = "check", label = "Sticky Window Drag (LibSimpleSticky)", get = function() return enhancementCfg.stickyWindows ~= false end, set = function(v) enhancementCfg.stickyWindows = v and true or false end, disabled = function() return not LibSimpleSticky end },
				{ type = "slider", label = "Sticky Snap Range", min = 4, max = 36, step = 1, get = function() return enhancementCfg.stickyRange or 15 end, set = function(v) enhancementCfg.stickyRange = v end },
				{ type = "check", label = "Transliterate Names (LibTranslit)", get = function() return enhancementCfg.translitNames == true end, set = function(v) enhancementCfg.translitNames = v and true or false; self:ScheduleUpdateAll() end, disabled = function() return not LibTranslit end },
				{ type = "edit", label = "Translit Marker Prefix", get = function() return enhancementCfg.translitMarker or "" end, set = function(v) enhancementCfg.translitMarker = SafeText(v, ""); self:ScheduleUpdateAll() end },
				{ type = "check", label = "Non-Interruptible Castbar Glow (LibCustomGlow)", get = function() return enhancementCfg.castbarNonInterruptibleGlow ~= false end, set = function(v) enhancementCfg.castbarNonInterruptibleGlow = v and true or false; self:ScheduleUpdateAll() end, disabled = function() return not LibCustomGlow end },
				{ type = "check", label = "Window Open Animation (LibAnim)", get = function() return enhancementCfg.uiOpenAnimation ~= false end, set = function(v) enhancementCfg.uiOpenAnimation = v and true or false end, disabled = function() return not CreateAnimationGroup end },
				{ type = "slider", label = "Window Animation Duration", min = 0.05, max = 0.60, step = 0.01, get = function() return tonumber(enhancementCfg.uiOpenAnimationDuration) or 0.18 end, set = function(v) enhancementCfg.uiOpenAnimationDuration = v end },
				{ type = "slider", label = "Window Animation Offset Y", min = -40, max = 40, step = 1, get = function() return tonumber(enhancementCfg.uiOpenAnimationOffsetY) or 12 end, set = function(v) enhancementCfg.uiOpenAnimationOffsetY = v end },
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
			local function BuildSUFStatusReport()
				local plugins = self:GetPluginSettings() or {}
				local raidDebuffsEnabled = plugins.raidDebuffs and plugins.raidDebuffs.enabled ~= false
				local auraWatchEnabled = plugins.auraWatch and plugins.auraWatch.enabled ~= false
				local faderEnabled = plugins.fader and plugins.fader.enabled == true
				local inCombat = InCombatLockdown and InCombatLockdown() or false
				local inEditMode = self:IsEditModeActive()
				local isPerfEnabled = self:IsPerformanceIntegrationEnabled()
				local pendingPlugins = self._pendingPluginUpdates and true or false
				local queueAccepted = tonumber(self._perfQueueAccepted or 0) or 0
				local queueFallback = tonumber(self._perfQueueFallback or 0) or 0
				local headerCount = 0
				for _ in pairs(self.headers or {}) do
					headerCount = headerCount + 1
				end
				return ("Runtime: combat=%s editMode=%s perf=%s\nFrames: active=%d headers=%d\nPlugins: raidDebuffs=%s auraWatch=%s fader=%s pendingPluginFlush=%s\nQueue: accepted=%d fallback=%d"):format(
					tostring(inCombat),
					tostring(inEditMode),
					tostring(isPerfEnabled),
					#(self.frames or {}),
					headerCount,
					tostring(raidDebuffsEnabled),
					tostring(auraWatchEnabled),
					tostring(faderEnabled),
					tostring(pendingPlugins),
					queueAccepted,
					queueFallback
				)
			end
			ui:Paragraph(BuildSUFStatusReport(), true)

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
					wizardStatus:SetTextColor(1.00, 0.35, 0.35)
				else
					wizardStatus:SetTextColor(0.35, 1.00, 0.45)
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
			ui:Paragraph("Libraries Used\nAce3 (AceAddon/AceDB/AceGUI/AceSerializer), oUF, oUF_Plugins, LibSharedMedia-3.0, LibDualSpec-1.0, LibSerialize, LibDeflate, LibDataBroker-1.1, LibDBIcon-1.0, LibAnim, LibCustomGlow-1.0, LibActionButton-1.0, LibSimpleSticky, LibTranslit-1.0, UTF8, LibDispel-1.0, CallbackHandler-1.0, LibStub, TaintLess.", true)
			ui:Paragraph("Special Thanks\nBlizzard UI Source and WoW addon ecosystem maintainers.", true)
		else
			local unitSettings = self:GetUnitSettings(tabKey)
			local tags = self.db.profile.tags[tabKey]
			local size = self.db.profile.sizes[tabKey]
			local plugins = self:GetPluginSettings()
			local unitPluginProfile = nil
			if IsGroupUnitType(tabKey) then
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
			if ui:Section("General", "unit.general", true) then
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
			if ui:Section("Bars", "unit.bars", true) then
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
			end
			if ui:Section("Castbar", "unit.castbar", true) then
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
			if ui:Section("Plugins", "unit.plugins", true) then
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
			if ui:Section("Auras", "unit.auras", true) then
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
			end
			if ui:Section("Advanced", "unit.advanced", false) then
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
				if IsGroupUnitType(tabKey) then
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
				if moduleState.module == "fader" and IsGroupUnitType(sourceUnit) then
					local sourcePlugins = self:GetPluginSettings()
					return sourcePlugins and sourcePlugins.units and sourcePlugins.units[sourceUnit] and sourcePlugins.units[sourceUnit].fader
				end
				if moduleState.module == "aurawatch" and IsGroupUnitType(sourceUnit) then
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
		button:SetBackdropColor(UI_STYLE.navDefault[1], UI_STYLE.navDefault[2], UI_STYLE.navDefault[3], UI_STYLE.navDefault[4])
		button:SetBackdropBorderColor(UI_STYLE.navDefaultBorder[1], UI_STYLE.navDefaultBorder[2], UI_STYLE.navDefaultBorder[3], UI_STYLE.navDefaultBorder[4])
		local fs = button:CreateFontString(nil, "OVERLAY", isChild and "GameFontHighlightSmall" or "GameFontNormal")
		fs:SetPoint("LEFT", button, "LEFT", isChild and 12 or 8, 0)
		fs:SetJustifyH("LEFT")
		button._sufText = fs
		button._sufSelected = false
		button._sufMatchSearch = false
		button:SetScript("OnEnter", function(selfButton)
			if selfButton._sufSelected then
				return
			end
			selfButton:SetBackdropColor(UI_STYLE.navHover[1], UI_STYLE.navHover[2], UI_STYLE.navHover[3], UI_STYLE.navHover[4])
			selfButton:SetBackdropBorderColor(UI_STYLE.navHoverBorder[1], UI_STYLE.navHoverBorder[2], UI_STYLE.navHoverBorder[3], UI_STYLE.navHoverBorder[4])
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
				selfButton:SetBackdropColor(UI_STYLE.navSelected[1], UI_STYLE.navSelected[2], UI_STYLE.navSelected[3], UI_STYLE.navSelected[4])
				selfButton:SetBackdropBorderColor(UI_STYLE.navSelectedBorder[1], UI_STYLE.navSelectedBorder[2], UI_STYLE.navSelectedBorder[3], UI_STYLE.navSelectedBorder[4])
				if selfButton._sufText then
					selfButton._sufText:SetTextColor(1.00, 0.96, 0.86)
				end
			else
				if matchSearch then
					selfButton:SetBackdropColor(UI_STYLE.navSearch[1], UI_STYLE.navSearch[2], UI_STYLE.navSearch[3], UI_STYLE.navSearch[4])
					selfButton:SetBackdropBorderColor(UI_STYLE.navSearchBorder[1], UI_STYLE.navSearchBorder[2], UI_STYLE.navSearchBorder[3], UI_STYLE.navSearchBorder[4])
					if selfButton._sufText then
						selfButton._sufText:SetTextColor(0.88, 0.96, 0.72)
					end
				else
					selfButton:SetBackdropColor(UI_STYLE.navDefault[1], UI_STYLE.navDefault[2], UI_STYLE.navDefault[3], UI_STYLE.navDefault[4])
					selfButton:SetBackdropBorderColor(UI_STYLE.navDefaultBorder[1], UI_STYLE.navDefaultBorder[2], UI_STYLE.navDefaultBorder[3], UI_STYLE.navDefaultBorder[4])
					if selfButton._sufText then
						selfButton._sufText:SetTextColor(0.90, 0.90, 0.90)
					end
				end
			end
		end
	end

	local menuScroll = CreateFrame("ScrollFrame", nil, tabsHost)
	menuScroll:SetPoint("TOPLEFT", tabsHost, "TOPLEFT", 8, -(iconSize + 24))
	menuScroll:SetPoint("BOTTOMRIGHT", tabsHost, "BOTTOMRIGHT", -8, 8)
	local menuContent = CreateFrame("Frame", nil, menuScroll)
	menuContent:SetSize(150, 1)
	menuScroll:SetScrollChild(menuContent)

	local navButtons = {}
	local function RebuildSidebar()
		for i = 1, #navButtons do
			navButtons[i]:Hide()
			navButtons[i]:SetParent(nil)
			navButtons[i] = nil
		end
		wipe(tabButtons)

		local y = -2
		local width = 150
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
						childBtn._sufText:SetText(tab.label)
						childBtn:SetScript("OnClick", function()
							frame:BuildTab(tab.key)
						end)
						tabButtons[tab.key] = childBtn
						navButtons[#navButtons + 1] = childBtn
						y = y - 24
					end
				end
			end
		end
		menuContent:SetHeight(math.max(1, -y + 6))
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

	frame:Show()
	self:PlayWindowOpenAnimation(frame)
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
	if not self.db.profile.optionsUI then
		self.db.profile.optionsUI = CopyTableDeep(defaults.profile.optionsUI)
	else
		MergeDefaults(self.db.profile.optionsUI, defaults.profile.optionsUI)
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
	if not self.db.profile.enhancements then
		self.db.profile.enhancements = CopyTableDeep(defaults.profile.enhancements)
	else
		for key, value in pairs(defaults.profile.enhancements) do
			if self.db.profile.enhancements[key] == nil then
				self.db.profile.enhancements[key] = value
			end
		end
	end
	if not self.db.profile.plugins then
		self.db.profile.plugins = CopyTableDeep(defaults.profile.plugins)
	else
		MergeDefaults(self.db.profile.plugins, defaults.profile.plugins)
	end
	self:NormalizePluginConfig()
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
	self:RegisterIncomingEstimateFrame()

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
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "OnClassResourceContextChanged")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnClassResourceContextChanged")
	self:RegisterEvent("SPELLS_CHANGED", "OnClassResourceContextChanged")
	self:RegisterEvent("TRAIT_CONFIG_UPDATED", "OnClassResourceContextChanged")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupRosterUpdate")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnGroupRosterUpdate")

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

function addon:SetTestModeForUnitType(unitType)
	if not unitType then
		self:SetTestMode(true)
		return
	end
	if InCombatLockdown() then
		return
	end
	self:SetTestMode(true)
	for _, frame in ipairs(self.frames or {}) do
		if frame then
			frame:SetShown(frame.sufUnitType == unitType)
		end
	end
	for key, header in pairs(self.headers or {}) do
		if header then
			header:SetShown(key == unitType)
		end
	end
end

function addon:OnDisable()
	if self._pluginUpdateTicker then
		self._pluginUpdateTicker:Cancel()
		self._pluginUpdateTicker = nil
	end
	self._pendingPluginUpdates = nil
	if self._unitUpdateTimers then
		for unitType, timer in pairs(self._unitUpdateTimers) do
			if timer and timer.Cancel then
				timer:Cancel()
			end
			self._unitUpdateTimers[unitType] = nil
		end
	end

	self:UnregisterIncomingEstimateFrame()
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

