---@class SimpleUnitFrames : AceAddon
---@field db AceDB Database instance (AceDB-3.0)
---@field frames table<integer, Frame> Array of spawned unit frames
---@field isBuildingOptions boolean Flag for options window state
---@field performanceLib table|nil Optional PerformanceLib integration
---@field sufEventBus table|nil Optional event bus for internal addon events

local addonName = "SUF"
local addonId = "SimpleUnitFrames"

---Get oUF library reference
---@return table oUF library instance
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
local LibTranslit = LibStub("LibTranslit-1.0", true)
local LibCustomGlow = LibStub("LibCustomGlow-1.0", true)
local LibRangeCheck = LibStub("LibRangeCheck-3.0", true)

---@type SimpleUnitFrames
local addon = AceAddon:NewAddon("SimpleUnitFrames", "AceEvent-3.0", "AceConsole-3.0")

---@type string
local DEFAULT_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
---@type string
local DEFAULT_FONT = STANDARD_TEXT_FONT
local ICON_PATH = "Interface\\AddOns\\SimpleUnitFrames\\Media\\AddonIcon"
local DATATEXT_SLOT_ORDER = { "left", "center", "right" }

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
			globalStatusbarOverride = true,
			globalFontOverride = true,
		},
		optionsUI = {
			sectionState = {},
			unitSubTabs = {},
			searchShowCounts = true,
			searchKeyboardHints = true,
			tutorialSeen = false,
			installFlowSeen = false,
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
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = true,
				showPvp = true,
				portrait = { mode = "none", size = 36, showClass = false, motion = false, position = "LEFT" },
			},
			target = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 36, showClass = false, motion = false, position = "LEFT" },
			},
			tot = {
				fontSizes = { name = 11, level = 9, health = 10, power = 9, cast = 9 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 28, showClass = false, motion = false, position = "LEFT" },
			},
			focus = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = false,
				showPvp = true,
				portrait = { mode = "none", size = 32, showClass = false, motion = false, position = "LEFT" },
			},
			pet = {
				fontSizes = { name = 11, level = 9, health = 10, power = 9, cast = 9 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = false,
				showPvp = false,
				portrait = { mode = "none", size = 28, showClass = false, motion = false, position = "LEFT" },
			},
			party = {
				fontSizes = { name = 11, level = 9, health = 10, power = 9, cast = 9 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = false,
				showPvp = true,
				auraSize = 22,
				auras = {
					enabled = true,
					numBuffs = 6,
					numDebuffs = 0,
					spacingX = 4,
					spacingY = 4,
					maxCols = 6,
					initialAnchor = "BOTTOMLEFT",
					growthX = "RIGHT",
					growthY = "UP",
					sortMethod = "DEFAULT",
					sortDirection = "ASC",
					onlyShowPlayer = false,
					showStealableBuffs = true,
				},
				portrait = { mode = "none", size = 26, showClass = false, motion = false, position = "LEFT" },
			},
			raid = {
				fontSizes = { name = 10, level = 8, health = 9, power = 8, cast = 8 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
				showResting = false,
				showPvp = false,
				portrait = { mode = "none", size = 22, showClass = false, motion = false, position = "LEFT" },
			},
			boss = {
				fontSizes = { name = 12, level = 10, health = 11, power = 10, cast = 10 },
				media = { statusbar = "Blizzard", font = "Friz Quadrata TT" },
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
			showDirectionIndicator = false,
			showChannelTicks = false,
			channelTickWidth = 2,
			showEmpowerPips = true,
			showLatencyText = false,
			latencyWarnMs = 120,
			latencyHighMs = 220,
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
			pixelSnapWindows = true,
		},
		blizzardFrames = {
			player = true,
			pet = true,
			target = true,
			tot = true,
			focus = true,
			party = true,
			raid = true,
			boss = true,
		},
		blizzardSkin = {
			enabled = false,
			intensity = "subtle",
			labMode = false,
			aggressiveRecursive = false,
			aggressiveReassertHooks = false,
			character = true,
			spellbook = true,
			collections = true,
			questlog = true,
			lfg = true,
			map = true,
			calendar = true,
			professions = true,
			dressup = true,
			gossip = true,
			merchant = true,
			mail = true,
			economy = true,
			friends = true,
			guild = true,
			housing = true,
			achievement = true,
			encounter = true,
		},
		movers = {},
		databars = {
			enabled = true,
			positionMode = "ANCHOR",
			anchor = "TOP",
			offsetX = 0,
			offsetY = -2,
			width = 520,
			height = 10,
			showText = true,
			showXP = true,
			showReputation = true,
			showPetXP = true,
			showRestedOverlay = true,
			showQuestXPOverlay = true,
			xpFade = {
				enabled = false,
				showOnHover = true,
				showInCombat = true,
				fadeInDuration = 0.2,
				fadeOutDuration = 0.3,
				fadeOutAlpha = 0.0,
				fadeOutDelay = 0.5,
			},
		},
		datatext = {
			enabled = true,
			refreshRate = 1.0,
			positionMode = "ANCHOR",
			panel = {
				width = 520,
				height = 20,
				anchor = "TOP",
				offsetX = 0,
				offsetY = -14,
				backdrop = true,
				mouseover = false,
			},
			slots = {
				left = "FPS",
				center = "Time",
				right = "Memory",
			},
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
		customTrackers = {
			bars = {},
			autoLearn = {
				enabled = false,
				learnSpells = true,
				learnItems = true,
				targetBarID = "",
			},
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
				AbsorbEvents = false,
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

local DEFAULT_UNIT_TARGET_GLOW = {
	enabled = false,
	color = { 0.95, 0.85, 0.25, 0.92 },
	inset = 3,
}

local DEFAULT_UNIT_POWER_PREDICTION = {
	enabled = false,
	height = 3,
	opacity = 0.70,
	color = { 1.00, 0.90, 0.25 },
}

local DEFAULT_UNIT_AURA_LAYOUT = {
	enabled = true,
	numBuffs = 8,
	numDebuffs = 8,
	spacingX = 4,
	spacingY = 4,
	maxCols = 8,
	initialAnchor = "BOTTOMLEFT",
	growthX = "RIGHT",
	growthY = "UP",
	sortMethod = "DEFAULT",
	sortDirection = "ASC",
	onlyShowPlayer = false,
	showStealableBuffs = true,
}

local DEFAULT_PARTY_AURA_LAYOUT = {
	enabled = true,
	numBuffs = 6,
	numDebuffs = 0,
	spacingX = 4,
	spacingY = 4,
	maxCols = 6,
	initialAnchor = "BOTTOMLEFT",
	growthX = "RIGHT",
	growthY = "UP",
	sortMethod = "DEFAULT",
	sortDirection = "ASC",
	onlyShowPlayer = false,
	showStealableBuffs = true,
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

local ELVUI_IMPORTED_AURA_FILTERS = {
	IMPORTANTCC = {
		label = "ImportantCC",
		desc = "ElvUI-inspired important crowd control auras.",
		spells = {
			118, 3355, 33786, 51514, 853, 408, 5246, 8122, 217832, 179057, 5211, 20066, 6789, 30283, 119381, 31661,
		},
	},
	CLASSDEBUFFS = {
		label = "ClassDebuffs",
		desc = "ElvUI-inspired class priority debuffs.",
		spells = {
			55078, 194310, 204598, 207771, 164812, 164815, 155722, 1079, 217200, 210824, 123725, 228287, 343527, 335467, 34914, 589,
			703, 1943, 188389, 316099, 980, 146739, 157736, 388539, 262115,
		},
	},
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
	UNIT_HEALTH = { delay = 0.18, priority = 3 },
	UNIT_HEAL_PREDICTION = { delay = 0.14, priority = 3 },
	UNIT_ABSORB_AMOUNT_CHANGED = { delay = 0.12, priority = 3 },
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = { delay = 0.12, priority = 3 },
	UNIT_POWER_UPDATE = { delay = 0.20, priority = 4 },
	UNIT_MAXHEALTH = { delay = 0.12, priority = 2 },
	UNIT_MAXPOWER = { delay = 0.12, priority = 2 },
	UNIT_DISPLAYPOWER = { delay = 0.12, priority = 3 },
	UNIT_THREAT_SITUATION_UPDATE = { delay = 0.14, priority = 3 },
	UNIT_THREAT_LIST_UPDATE = { delay = 0.16, priority = 4 },
	PLAYER_TOTEM_UPDATE = { delay = 0.05, priority = 3 },
	RUNE_POWER_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_SPELLCAST_CHANNEL_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_PORTRAIT_UPDATE = { delay = 0.20, priority = 4 },
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
	PLAYER_FLAGS_CHANGED = { "player" },
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
	local tex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	local layer, subLevel
	if tex and tex.GetDrawLayer then
		layer, subLevel = tex:GetDrawLayer()
	end
	bar:SetStatusBarTexture(DEFAULT_TEXTURE)
	if layer then
		local newTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
		if newTex and newTex.SetDrawLayer then
			subLevel = math.max(-8, math.min(7, tonumber(subLevel) or 0))
			newTex:SetDrawLayer(layer, subLevel)
		end
	end
	return bar
end

local function SetStatusBarTexturePreserveLayer(statusBar, texture)
	if not (statusBar and statusBar.SetStatusBarTexture) then
		return
	end
	local tex = statusBar.GetStatusBarTexture and statusBar:GetStatusBarTexture()
	local layer, subLevel
	if tex and tex.GetDrawLayer then
		layer, subLevel = tex:GetDrawLayer()
	end
	statusBar:SetStatusBarTexture(texture)
	if layer then
		local newTex = statusBar.GetStatusBarTexture and statusBar:GetStatusBarTexture()
		if newTex and newTex.SetDrawLayer then
			subLevel = math.max(-8, math.min(7, tonumber(subLevel) or 0))
			newTex:SetDrawLayer(layer, subLevel)
		end
	end
end

local function CopyColor(color, fallback)
	local c = color or fallback or { 1, 1, 1, 1 }
	return {
		tonumber(c[1]) or 1,
		tonumber(c[2]) or 1,
		tonumber(c[3]) or 1,
		tonumber(c[4]) or 1,
	}
end

local function GetWatchedFactionInfoCompat()
	if type(GetWatchedFactionInfo) == "function" then
		return GetWatchedFactionInfo()
	end
	if C_Reputation and C_Reputation.GetWatchedFactionData then
		local ok, data = pcall(C_Reputation.GetWatchedFactionData)
		if ok and type(data) == "table" and data.name then
			local function SafeNumeric(value, fallback)
				if type(issecretvalue) == "function" and issecretvalue(value) then
					return fallback
				end
				local n = tonumber(value)
				if n == nil then
					return fallback
				end
				return n
			end
			local minRep = SafeNumeric(data.currentReactionThreshold, 0) or 0
			local maxRep = SafeNumeric(data.nextReactionThreshold, minRep + 1) or (minRep + 1)
			local curRep = SafeNumeric(data.currentStanding, minRep) or minRep
			return data.name, data.reaction, minRep, maxRep, curRep
		end
	end
	return nil
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

---Format numeric value as compact notation (e.g., 1.5m for millions, 3.2k for thousands)
---@param value number|string Numeric value to format
---@return string Formatted compact value ("1.5m", "3.2k", or raw number)
local function FormatCompactValue(value)
	value = tonumber(value) or 0
	if value >= 1000000 then
		return string.format("%.1fm", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.1fk", value / 1000)
	end
	return tostring(math.floor(value + 0.5))
end

---Round numeric value to specified decimal places
---@param value number|string Numeric value to round
---@param decimals integer Number of decimal places
---@return number Rounded numeric value
local function RoundNumber(value, decimals)
	local n = tonumber(value) or 0
	local places = tonumber(decimals) or 0
	local mult = 10 ^ places
	return math.floor((n * mult) + 0.5) / mult
end

---Check if a value is marked as secret (WoW 12.0.0+ instance restriction)
---@param value any Potentially-secret value from WoW API
---@return boolean True if value is secret, false otherwise
local function IsSecretValue(value)
	return type(issecretvalue) == "function" and issecretvalue(value) or false
end

---Safely extract numeric value from potentially-secret WoW API return
---@param value any Potentially-secret value from WoW API
---@param fallback number Default value if input is secret or invalid
---@return number Safe numeric value (fallback if secret)
local function SafeNumber(value, fallback)
	if IsSecretValue(value) then
		return fallback
	end
	local num = tonumber(value)
	if not num then
		return fallback
	end
	if IsSecretValue(num) then
		return fallback
	end
	return num
end

---Safely extract boolean value from potentially-secret WoW API return
---@param value any Potentially-secret value from WoW API
---@param fallback boolean Default value if input is secret or invalid
---@return boolean Safe boolean value (fallback if secret)
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

	local debugAbsorb = addon.db and addon.db.profile and addon.db.profile.debug and addon.db.profile.debug.systems and addon.db.profile.debug.systems.AbsorbEvents
	
	-- PRIORITY 1: Try healthValues.GetDamageAbsorbs() first (WoW 12.0.0+ secret-safe method)
	if healthValues and healthValues.GetDamageAbsorbs then
		local damageAbsorbAmount, damageAbsorbClamped = Call(healthValues.GetDamageAbsorbs, healthValues)
		local value = SafeNumber(damageAbsorbAmount, nil)
		if debugAbsorb then
			addon:DebugLog("AbsorbEvents", ("HealthPrediction.values:GetDamageAbsorbs(%s): damageAbsorbAmount=%s clamped=%s value=%s"):format(
				tostring(unit),
				tostring(damageAbsorbAmount),
				tostring(damageAbsorbClamped),
				tostring(value)
			), 2)
		end
		if value ~= nil then
			return value, unit
		end
	end

	-- PRIORITY 2: Fallback to UnitGetTotalAbsorbs (may return secret values in instances/PvP)
	local function GetAbsorbFromUnit(token)
		if type(UnitGetTotalAbsorbs) ~= "function" then
			return nil
		end
		local result, success = Call(UnitGetTotalAbsorbs, token)
		
		if debugAbsorb then
			addon:DebugLog("AbsorbEvents", ("UnitGetTotalAbsorbs(%s): rawResult=%s success=%s isSecret=%s"):format(
				tostring(token), 
				tostring(result), 
				tostring(success),
				tostring(IsSecretValue(result))
			), 2)
		end
		
		return SafeNumber(result, nil)
	end

	local value = GetAbsorbFromUnit(unit)
	if value ~= nil then
		return value, unit
	end

	if type(UnitIsUnit) == "function" and type(UnitExists) == "function" then
		for i = 1, #ABSORB_FALLBACK_UNITS do
			local token = ABSORB_FALLBACK_UNITS[i]
			if token ~= unit and UnitExists(token) then
				local isSameUnit = Call(UnitIsUnit, unit, token)
				local sameUnit = SafeBoolean(isSameUnit, false)
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

---Safely extract text from potentially-secret WoW API return
---@param value any Potentially-secret value from WoW API
---@param fallback string Default value if input is secret or invalid
---@return string Safe text value (fallback if secret)
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

---Safely call a WoW API function that may return secret values
---@param fn function Function to call safely
---@param ... any Arguments to pass to function
---@return any Result from function call, or nil if secret/error
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

---Deep copy a table recursively (includes nested tables)
---@param source table Source table to copy
---@return table Deep copy of source table
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

---Merge default values into target table (only fills in nil values)
---@param target table Target table to merge defaults into
---@param defaultsTable table Table of default values
---@return void
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

addon._core = addon._core or {}
addon._core.defaults = defaults
addon._core.RoundNumber = RoundNumber
addon._core.SafeNumber = SafeNumber
addon._core.CopyTableDeep = CopyTableDeep
addon._core.MergeDefaults = MergeDefaults
addon._core.addonName = addonName
addon._core.ICON_PATH = ICON_PATH
addon._core.DEFAULT_TEXTURE = DEFAULT_TEXTURE
addon._core.DATATEXT_SLOT_ORDER = DATATEXT_SLOT_ORDER
addon._core.SetStatusBarTexturePreserveLayer = SetStatusBarTexturePreserveLayer
addon._core.FormatCompactValue = FormatCompactValue
addon._core.GetWatchedFactionInfoCompat = GetWatchedFactionInfoCompat
addon._core.UNIT_TYPE_ORDER = UNIT_TYPE_ORDER
addon._core.UNIT_LABELS = UNIT_LABELS
addon._core.DEFAULT_UNIT_CASTBAR = DEFAULT_UNIT_CASTBAR
addon._core.DEFAULT_UNIT_LAYOUT = DEFAULT_UNIT_LAYOUT
addon._core.DEFAULT_UNIT_MAIN_BARS_BACKGROUND = DEFAULT_UNIT_MAIN_BARS_BACKGROUND
addon._core.DEFAULT_HEAL_PREDICTION = DEFAULT_HEAL_PREDICTION

-- Expose safe value helpers on addon table for modules to use
addon.IsSecretValue = IsSecretValue
addon.SafeNumber = SafeNumber
addon.SafeText = SafeText
addon.SafeAPICall = SafeAPICall

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

---Get media statusbar texture (global setting or fallback)
---@return string Path to statusbar texture
function addon:GetStatusbarTexture()
	if LSM then
		local texture = LSM:Fetch("statusbar", self.db.profile.media.statusbar)
		if texture then
			return texture
		end
	end

	return DEFAULT_TEXTURE
end

---Get media font (global setting or fallback)
---@return string Path to font file
function addon:GetFont()
	if LSM then
		local font = LSM:Fetch("font", self.db.profile.media.font)
		if font then
			return font
		end
	end

	return DEFAULT_FONT
end

function addon:IsGlobalStatusbarOverrideEnabled()
	local media = self.db and self.db.profile and self.db.profile.media or nil
	if not media then
		return true
	end
	return media.globalStatusbarOverride ~= false
end

function addon:IsGlobalFontOverrideEnabled()
	local media = self.db and self.db.profile and self.db.profile.media or nil
	if not media then
		return true
	end
	return media.globalFontOverride ~= false
end

---Get unit-specific settings from current profile
---@param unitType string Unit type identifier ("player", "target", "party1", "raid1", etc.)
---@return table Configuration table for unit (or empty table if not found)
function addon:GetUnitSettings(unitType)
	return self.db.profile.units[unitType] or {}
end

---Get unit font sizes (unit-specific or global fallback)
---@param unitType string Unit type identifier
---@return table Font size configuration {name, level, health, power, cast}
function addon:GetUnitFontSizes(unitType)
	local unit = self:GetUnitSettings(unitType)
	if unit.fontSizes then
		return unit.fontSizes
	end

	return self.db.profile.fontSizes
end

---Get unit statusbar texture (unit-specific override or global setting)
---@param unitType string Unit type identifier
---@return string Path to statusbar texture
function addon:GetUnitStatusbarTexture(unitType)
	if self:IsGlobalStatusbarOverrideEnabled() then
		return self:GetStatusbarTexture()
	end
	local unit = self:GetUnitSettings(unitType)
	if LSM and unit.media and unit.media.statusbar then
		local texture = LSM:Fetch("statusbar", unit.media.statusbar)
		if texture then
			return texture
		end
	end

	return self:GetStatusbarTexture()
end

---Get unit font (unit-specific override or global setting)
---@param unitType string Unit type identifier
---@return string Path to font file
function addon:GetUnitFont(unitType)
	if self:IsGlobalFontOverrideEnabled() then
		return self:GetFont()
	end
	local unit = self:GetUnitSettings(unitType)
	if LSM and unit.media and unit.media.font then
		local font = LSM:Fetch("font", unit.media.font)
		if font then
			return font
		end
	end
	return self:GetFont()
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

---Get unit castbar settings (with defaults applied)
---@param unitType string Unit type identifier
---@return table Castbar configuration table
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

function addon:GetUnitTargetGlowSettings(unitType)
	local unit = self:GetUnitSettings(unitType)
	if not unit then
		return DEFAULT_UNIT_TARGET_GLOW
	end

	if unit.targetGlow == nil then
		unit.targetGlow = CopyTableDeep(DEFAULT_UNIT_TARGET_GLOW)
	else
		MergeDefaults(unit.targetGlow, DEFAULT_UNIT_TARGET_GLOW)
	end

	return unit.targetGlow
end

function addon:GetUnitPowerPredictionSettings(unitType)
	local unit = self:GetUnitSettings(unitType)
	if not unit then
		return DEFAULT_UNIT_POWER_PREDICTION
	end

	if unit.powerPrediction == nil then
		unit.powerPrediction = CopyTableDeep(DEFAULT_UNIT_POWER_PREDICTION)
	else
		MergeDefaults(unit.powerPrediction, DEFAULT_UNIT_POWER_PREDICTION)
	end

	return unit.powerPrediction
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

---Get plugin settings (with safe initialization)
---@return table All plugin configurations
function addon:GetPluginSettings()
	self.db.profile.plugins = self.db.profile.plugins or CopyTableDeep(defaults.profile.plugins)
	MergeDefaults(self.db.profile.plugins, defaults.profile.plugins)
	return self.db.profile.plugins
end

---Check if unit type is a group unit (party or raid)
---@param unitType string Unit type identifier
---@return boolean True if unitType is "party" or "raid"
function addon:IsGroupUnitType(unitType)
	return unitType == "party" or unitType == "raid"
end

---Trim whitespace from start and end of string
---@param value any Input value (coerced to string)
---@return string Trimmed string (empty if not a string)
local function TrimString(value)
	if type(value) ~= "string" then
		return ""
	end
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Truncate string to maximum character length with ellipsis
---@param text string Text to truncate (UTF-8 safe if available)
---@param maxChars integer Maximum characters to display
---@return string Truncated text with "..." suffix if over limit
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

---Get unit-specific plugin settings (with global fallback for group units)
---@param unitType string Unit type identifier ("player", "party1", "raid1", etc.)
---@return table Merged plugin configuration with unit overrides
function addon:GetUnitPluginSettings(unitType)
	local plugins = self:GetPluginSettings()
	if not self:IsGroupUnitType(unitType) then
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
	if not self:IsGroupUnitType(unitType) then
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
		if self:IsGroupUnitType(unitType) then
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
		return self:IsGroupUnitType(unitKey)
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
	if moduleKey == "fader" and self:IsGroupUnitType(unitKey) then
		local plugins = self:GetPluginSettings()
		local unitPlugins = plugins and plugins.units
		local unitCfg = unitPlugins and unitPlugins[unitKey]
		return unitCfg and unitCfg.fader
	end
	if moduleKey == "aurawatch" and self:IsGroupUnitType(unitKey) then
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
	if moduleKey == "fader" and self:IsGroupUnitType(unitKey) then
		return defaults.profile.plugins.units[unitKey] and defaults.profile.plugins.units[unitKey].fader
	end
	if moduleKey == "aurawatch" and self:IsGroupUnitType(unitKey) then
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
	elseif moduleKey == "fader" and self:IsGroupUnitType(dstUnitKey) then
		MergeDefaults(targetPayload, defaults.profile.plugins.units[dstUnitKey].fader)
	elseif moduleKey == "aurawatch" and self:IsGroupUnitType(dstUnitKey) then
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

function addon:EnsurePopupDialog(dialogKey, definition)
	if not dialogKey or type(definition) ~= "table" then
		return nil
	end
	StaticPopupDialogs[dialogKey] = StaticPopupDialogs[dialogKey] or {}
	local dialog = StaticPopupDialogs[dialogKey]
	for key, value in pairs(definition) do
		dialog[key] = value
	end
	return dialog
end

function addon:ShowPopup(dialogKey, textArg1, textArg2, data)
	if not dialogKey then
		return nil
	end
	return StaticPopup_Show(dialogKey, textArg1, textArg2, data)
end

function addon:RunWithOptionalModuleApplyConfirmation(confirmEnabled, title, details, onAccept)
	if not onAccept then
		return false
	end
	if not confirmEnabled then
		onAccept()
		return true
	end

	self:EnsurePopupDialog("SUF_MODULE_APPLY_CONFIRM", {
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
	})

	self._pendingModuleApplyCallback = onAccept
	local popupText = tostring(title or "Confirm Apply")
	if details and details ~= "" then
		popupText = popupText .. "\n\n" .. tostring(details)
	end
	self:ShowPopup("SUF_MODULE_APPLY_CONFIRM", popupText)
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
	if moduleKey == "fader" and self:IsGroupUnitType(dstUnitKey) then
		local plugins = self:GetPluginSettings()
		plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
		plugins.units[dstUnitKey] = plugins.units[dstUnitKey] or CopyTableDeep(defaults.profile.plugins.units[dstUnitKey])
		plugins.units[dstUnitKey].fader = CopyTableDeep(payload)
		MergeDefaults(plugins.units[dstUnitKey].fader, defaults.profile.plugins.units[dstUnitKey].fader)
		plugins.units[dstUnitKey].useGlobal = false
		self:SchedulePluginUpdate(dstUnitKey)
		return true
	end
	if moduleKey == "aurawatch" and self:IsGroupUnitType(dstUnitKey) then
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
	if moduleKey == "fader" and self:IsGroupUnitType(unitKey) then
		local plugins = self:GetPluginSettings()
		plugins.units = plugins.units or CopyTableDeep(defaults.profile.plugins.units)
		plugins.units[unitKey] = plugins.units[unitKey] or CopyTableDeep(defaults.profile.plugins.units[unitKey])
		plugins.units[unitKey].fader = CopyTableDeep(defaults.profile.plugins.units[unitKey].fader)
		plugins.units[unitKey].useGlobal = false
		self:SchedulePluginUpdate(unitKey)
		return true
	end
	if moduleKey == "aurawatch" and self:IsGroupUnitType(unitKey) then
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
	for i = 1, #parsed.removeFilters do
		local setData = self:GetImportedAuraFilterSet(parsed.removeFilters[i])
		if setData and setData.spells then
			for s = 1, #setData.spells do
				watched[setData.spells[s]] = nil
			end
		end
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
	for i = 1, #parsed.addFilters do
		local setData = self:GetImportedAuraFilterSet(parsed.addFilters[i])
		if setData and setData.spells then
			for s = 1, #setData.spells do
				local spellID = setData.spells[s]
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
		end
	end

	return watched
end

function addon:GetImportedAuraFilterSet(setName)
	local key = string.upper(TrimString(SafeText(setName, "")))
	key = key:gsub("%s+", "")
	if key == "" then
		return nil
	end
	return ELVUI_IMPORTED_AURA_FILTERS[key]
end

function addon:ParseAuraWatchSpellTokens(customValue)
	local result = {
		adds = {},
		removes = {},
		addFilters = {},
		removeFilters = {},
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
		if value:sub(1, 1) == "@" then
			local filterName = value:sub(2)
			local setData = self:GetImportedAuraFilterSet(filterName)
			if setData then
				local key = string.upper(TrimString(SafeText(filterName, ""))):gsub("%s+", "")
				if isRemove then
					result.removeFilters[#result.removeFilters + 1] = key
				else
					result.addFilters[#result.addFilters + 1] = key
				end
			else
				result.invalid[#result.invalid + 1] = token
			end
		else
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
	local validAddFilters, validRemoveFilters = {}, {}

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
	for i = 1, #parsed.addFilters do
		validAddFilters[#validAddFilters + 1] = parsed.addFilters[i]
	end
	for i = 1, #parsed.removeFilters do
		validRemoveFilters[#validRemoveFilters + 1] = parsed.removeFilters[i]
	end

	return {
		validAdds = validAdds,
		validRemoves = validRemoves,
		validAddFilters = validAddFilters,
		validRemoveFilters = validRemoveFilters,
		invalidIDs = invalidIDs,
		invalidTokens = parsed.invalid,
	}
end

function addon:GetAbsorbTextForUnit(unit, useAbbrev)
	local debugTags = self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.absorbTags
	
	if debugTags then
		if not self._absorbTagCallCount then
			self._absorbTagCallCount = {}
		end
		self._absorbTagCallCount[unit or "nil"] = (self._absorbTagCallCount[unit or "nil"] or 0) + 1
		
		self:DebugLog("AbsorbTags", ("GetAbsorbTextForUnit CALLED: unit=%s useAbbrev=%s (call#%d)"):format(
			tostring(unit),
			tostring(useAbbrev),
			self._absorbTagCallCount[unit or "nil"]
		), 2)
	end
	
	if not unit or not UnitExists or not UnitExists(unit) then
		if debugTags then
			self:DebugLog("AbsorbTags", ("Early return: unit=%s exists=%s"):format(
				tostring(unit),
				UnitExists and tostring(UnitExists(unit)) or "no_api"
			), 2)
		end
		return ""
	end
	if type(UnitGetTotalAbsorbs) ~= "function" then
		if debugTags then
			self:DebugLog("AbsorbTags", "Early return: UnitGetTotalAbsorbs not available", 2)
		end
		return ""
	end

	-- Try to get cached absorb value from frame's Health element first (more reliable timing)
	local rawAbsorbValue = nil
	
	-- Find the frame for this unit by checking oUF global registry
	local ouf = oUF or (self.oUF)
	if ouf then
		for _, f in pairs(ouf.objects or {}) do
			if f.unit == unit and f.Health and f.Health.values then
				-- Get absorb from Health element's cached values (same source as Health Override uses)
				local absorbAmount = f.Health.values:GetDamageAbsorbs()
				rawAbsorbValue = absorbAmount
				if debugTags then
					self:DebugLog("AbsorbTags", ("Using cached absorb from frame %s: rawValue=%s"):format(
						f:GetName() or "Unknown",
						rawAbsorbValue and "exists" or "nil"
					), 2)
				end
				break
			end
		end
	end
	
	-- Fallback to direct API call if frame not found
	if not rawAbsorbValue then
		rawAbsorbValue = SafeAPICall(UnitGetTotalAbsorbs, unit)
		if debugTags then
			self:DebugLog("AbsorbTags", ("Using direct API call: rawValue=%s"):format(
				rawAbsorbValue and "exists" or "nil"
			), 2)
		end
	end
	
	local isSecret = rawAbsorbValue and IsSecretValue(rawAbsorbValue)
	
	if debugTags then
		self:DebugLog("AbsorbTags", ("GetAbsorbTextForUnit: unit=%s useAbbrev=%s rawValue=%s isSecret=%s"):format(
			tostring(unit),
			tostring(useAbbrev),
			rawAbsorbValue and "exists" or "nil",
			tostring(isSecret)
		), 2)
	end
	
	-- If value is secret, show placeholder (absorb bar would still be visible)
	if isSecret then
		if debugTags then
			self:DebugLog("AbsorbTags", ("Returning placeholder '~' for unit %s"):format(tostring(unit)), 2)
		end
		return "~"
	end
	
	-- Try to convert to number
	local absorbValue = SafeNumber(rawAbsorbValue, nil)
	
	if debugTags then
		self:DebugLog("AbsorbTags", ("Converted value for unit %s: absorbValue=%s"):format(
			tostring(unit),
			tostring(absorbValue)
		), 2)
	end
	
	if not absorbValue or absorbValue <= 0 then
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

function addon:GetMissingHealthTextForUnit(unit, useAbbrev)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end
	local maxHealth = SafeNumber(UnitHealthMax and UnitHealthMax(unit), 0)
	local curHealth = SafeNumber(UnitHealth and UnitHealth(unit), 0)
	local missing = math.max(0, maxHealth - curHealth)
	if missing <= 0 then
		return ""
	end
	if useAbbrev then
		return FormatCompactValue(missing)
	end
	return tostring(math.floor(missing + 0.5))
end

function addon:GetMissingPowerTextForUnit(unit, useAbbrev)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end
	local powerType = UnitPowerType and UnitPowerType(unit) or nil
	local maxPower = SafeNumber(UnitPowerMax and UnitPowerMax(unit, powerType), 0)
	local curPower = SafeNumber(UnitPower and UnitPower(unit, powerType), 0)
	local missing = math.max(0, maxPower - curPower)
	if missing <= 0 then
		return ""
	end
	if useAbbrev then
		return FormatCompactValue(missing)
	end
	return tostring(math.floor(missing + 0.5))
end

function addon:GetStatusTextForUnit(unit)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end
	if UnitIsDead and UnitIsDead(unit) then
		return "Dead"
	end
	if UnitIsGhost and UnitIsGhost(unit) then
		return "Ghost"
	end
	if UnitIsConnected and not UnitIsConnected(unit) then
		return "Offline"
	end
	if UnitIsAFK and UnitIsAFK(unit) then
		return "AFK"
	end
	if UnitIsDND and UnitIsDND(unit) then
		return "DND"
	end
	return ""
end

function addon:GetHealthPercentWithAbsorbsTextForUnit(unit)
	if not unit or not UnitExists or not UnitExists(unit) then
		return ""
	end
	local status = self:GetStatusTextForUnit(unit)
	if status ~= "" then
		return status
	end
	local maxHealth = SafeNumber(UnitHealthMax and UnitHealthMax(unit), 0)
	if maxHealth <= 0 then
		return ""
	end
	local curHealth = SafeNumber(UnitHealth and UnitHealth(unit), 0)
	local absorbs = SafeNumber(UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit), 0)
	local effective = math.max(0, curHealth + absorbs)
	local pct = (effective / maxHealth) * 100
	return string.format("%d%%", math.floor(pct + 0.5))
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

	local rawName = nil
	if UnitName then
		local ok, value = pcall(UnitName, unit)
		if ok then
			rawName = value
		end
	end
	if rawName == nil then
		return ""
	end

	-- Some units can return "secret" string values. We should still display them,
	-- but avoid transformations/comparisons that can taint or error on those values.
	if IsSecretValue(rawName) then
		return rawName
	end

	local unitName = SafeText(rawName, "")
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
		if addon._absorbTagCallCount then
			addon._absorbTagCallCount["TAG_suf:absorbs"] = (addon._absorbTagCallCount["TAG_suf:absorbs"] or 0) + 1
		end
		return addon:GetAbsorbTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:absorbs:abbr"] = function(unit)
		if addon._absorbTagCallCount then
			addon._absorbTagCallCount["TAG_suf:absorbs:abbr"] = (addon._absorbTagCallCount["TAG_suf:absorbs:abbr"] or 0) + 1
		end
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
	ouf.Tags.Methods["suf:missinghp"] = function(unit)
		return addon:GetMissingHealthTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:missinghp:abbr"] = function(unit)
		return addon:GetMissingHealthTextForUnit(unit, true)
	end
	ouf.Tags.Methods["suf:missingpp"] = function(unit)
		return addon:GetMissingPowerTextForUnit(unit, false)
	end
	ouf.Tags.Methods["suf:missingpp:abbr"] = function(unit)
		return addon:GetMissingPowerTextForUnit(unit, true)
	end
	ouf.Tags.Methods["suf:status"] = function(unit)
		return addon:GetStatusTextForUnit(unit)
	end
	ouf.Tags.Methods["suf:health:percent-with-absorbs"] = function(unit)
		return addon:GetHealthPercentWithAbsorbsTextForUnit(unit)
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
	ouf.Tags.Events["suf:missinghp"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:missinghp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:missingpp"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:missingpp:abbr"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:status"] = "UNIT_CONNECTION UNIT_HEALTH PLAYER_FLAGS_CHANGED PLAYER_ENTERING_WORLD"
	ouf.Tags.Events["suf:health:percent-with-absorbs"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED UNIT_CONNECTION PLAYER_FLAGS_CHANGED PLAYER_ENTERING_WORLD"
	-- Include direct target/focus switches so hostile/neutral target names refresh immediately.
	ouf.Tags.Events["suf:name"] = "UNIT_NAME_UPDATE PLAYER_ENTERING_WORLD GROUP_ROSTER_UPDATE UNIT_TARGET PLAYER_TARGET_CHANGED PLAYER_FOCUS_CHANGED"

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

function addon:GetUnitAuraLayoutSettings(unitType)
	local unit = self:GetUnitSettings(unitType)
	local auraDefaults = unitType == "party" and DEFAULT_PARTY_AURA_LAYOUT or DEFAULT_UNIT_AURA_LAYOUT
	if not unit then
		return auraDefaults
	end
	if unit.auras == nil then
		unit.auras = CopyTableDeep(auraDefaults)
	else
		MergeDefaults(unit.auras, auraDefaults)
	end
	return unit.auras
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

	self.sufEventBus:Register("LOCAL_WORK", "queue-local-work", function(workType, unitType)
		self:QueueLocalWork(workType, unitType)
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

local function GetStatusBarAnchor(statusBar)
	if not statusBar then
		return nil
	end
	if statusBar.GetStatusBarTexture then
		local tex = statusBar:GetStatusBarTexture()
		if tex then
			return tex
		end
	end
	return statusBar
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
	-- For header-spawned frames (party/raid), try secure attribute if frame.unit is not set
	if not unit and frame.GetAttribute then
		unit = frame:GetAttribute('unit') or frame:GetAttribute('oUF-guessUnit')
	end
	
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
		if dropdown.IsForbidden and dropdown:IsForbidden() then
			return false
		end
		if CloseDropDownMenus then
			CloseDropDownMenus()
		end
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
	elseif eventName == "UNIT_PORTRAIT_UPDATE" or eventName == "UNIT_NAME_UPDATE" or eventName == "UNIT_FACTION" then
		local settings = self:GetUnitSettings(frame.sufUnitType)
		return settings and settings.portrait and settings.portrait.mode and settings.portrait.mode ~= "none"
	end

	return true
end

function addon:HasRelevantFrameForUnitEvent(eventName, unitToken)
	if type(unitToken) ~= "string" or unitToken == "" then
		return false
	end

	local index = self:EnsureFrameEventIndex()
	local unitType = ResolveUnitType(unitToken)
	local direct = index and index.byUnit and index.byUnit[unitToken]
	if direct then
		for i = 1, #direct do
			if self:IsFrameEventRelevant(direct[i], eventName) then
				return true
			end
		end
	end

	local typed = index and index.byType and index.byType[unitType]
	if typed then
		for i = 1, #typed do
			if self:IsFrameEventRelevant(typed[i], eventName) then
				return true
			end
		end
	end

	if unitToken == "target" then
		local tot = index and index.byType and index.byType["tot"]
		if tot then
			for i = 1, #tot do
				if self:IsFrameEventRelevant(tot[i], eventName) then
					return true
				end
			end
		end
	end

	return false
end

function addon:UpdateFrameFromDirtyEvents(frame, dirtyEvents)
	if not frame then
		return
	end
	local profileStart = debugprofilestop and debugprofilestop() or nil

	if type(dirtyEvents) ~= "table" then
		return
	end

	local eventCount = 0
	local auraOnly = true
	for eventName in pairs(dirtyEvents) do
		eventCount = eventCount + 1
		if eventName ~= "UNIT_AURA" then
			auraOnly = false
		end
	end

	-- Fast path: aura spam should not force full frame/status refresh work.
	if auraOnly and eventCount > 0 then
		SafeUpdateElement(frame, "Auras", "UNIT_AURA")
		if profileStart then
			local profileEnd = debugprofilestop() or profileStart
			self:RecordProfilerEvent("suf:dirty.update", profileEnd - profileStart)
		end
		return
	end

	local touched = false
	local needsHealthDerivedTextUpdate = false
	for eventName in pairs(dirtyEvents) do
		if eventName == "UNIT_HEALTH" or eventName == "UNIT_MAXHEALTH" or eventName == "UNIT_THREAT_SITUATION_UPDATE" or eventName == "UNIT_THREAT_LIST_UPDATE" or eventName == "UNIT_HEAL_PREDICTION" or eventName == "UNIT_ABSORB_AMOUNT_CHANGED" or eventName == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
			touched = SafeUpdateElement(frame, "Health", eventName) or touched
			needsHealthDerivedTextUpdate = true
		elseif eventName == "UNIT_POWER_UPDATE" or eventName == "UNIT_MAXPOWER" or eventName == "UNIT_DISPLAYPOWER" or eventName == "RUNE_POWER_UPDATE" or eventName == "PLAYER_TOTEM_UPDATE" then
			touched = SafeUpdateElement(frame, "Power", eventName) or touched
			touched = SafeUpdateElement(frame, "AdditionalPower", eventName) or touched
			touched = SafeUpdateElement(frame, "ClassPower", eventName) or touched
		elseif eventName == "UNIT_AURA" then
			touched = SafeUpdateElement(frame, "Auras", eventName) or touched
		elseif eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
			touched = SafeUpdateElement(frame, "Castbar", eventName) or touched
		elseif eventName == "UNIT_PORTRAIT_UPDATE" or eventName == "UNIT_NAME_UPDATE" or eventName == "UNIT_FACTION" then
			touched = self:RefreshPortraitFrame(frame) or touched
		elseif eventName == "UNIT_FLAGS" or eventName == "UNIT_CONNECTION" or eventName == "PLAYER_FLAGS_CHANGED" or eventName == "RAID_TARGET_UPDATE" or eventName == "GROUP_ROSTER_UPDATE" or eventName == "PLAYER_ROLES_ASSIGNED" or eventName == "PARTY_LEADER_CHANGED" then
			touched = true
			self:UpdateUnitFrameStatusIndicators(frame)
		else
			-- Keep dirty-path incremental; avoid full frame refresh fallback
			-- here because it causes visible churn under event storms.
			touched = true
		end
	end

	if needsHealthDerivedTextUpdate then
		self:UpdateAbsorbValue(frame)
		self:UpdateIncomingHealValue(frame)
	end

	if not touched then
		return
	end
	self:UpdateUnitFrameStatusIndicators(frame)

	if profileStart then
		local profileEnd = debugprofilestop() or profileStart
		self:RecordProfilerEvent("suf:dirty.update", profileEnd - profileStart)
	end
end

function addon:ShouldBypassPerformanceDirty(frame, eventName)
	if not frame then
		return false
	end
	if not self:IsPerformanceIntegrationEnabled() then
		return false
	end
	local unitType = frame.sufUnitType
	if unitType == "player" or unitType == "target" or unitType == "tot" then
		if eventName == "UNIT_HEALTH" or eventName == "UNIT_MAXHEALTH"
			or eventName == "UNIT_POWER_UPDATE" or eventName == "UNIT_MAXPOWER"
			or eventName == "UNIT_DISPLAYPOWER" then
			return true
		end
	end
	return false
end

function addon:MarkFrameDirty(frame, eventName)
	if not frame then
		return
	end
	if not self:IsFrameEventRelevant(frame, eventName) then
		return
	end
	if self:ShouldBypassPerformanceDirty(frame, eventName) then
		return
	end

	-- Keep UNIT_AURA isolated from full dirty-frame processing to avoid
	-- unnecessary frame-wide updates (and fader/portrait alpha churn).
	if eventName == "UNIT_AURA" then
		if frame.__sufAuraDirtyQueued then
			return
		end
		frame.__sufAuraDirtyQueued = true
		C_Timer.After(0, function()
			frame.__sufAuraDirtyQueued = nil
			if not frame then
				return
			end
			SafeUpdateElement(frame, "Auras", "UNIT_AURA")
		end)
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

	local traceAbsorb = (eventName == "UNIT_ABSORB_AMOUNT_CHANGED" or eventName == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
		and (unit == "target" or unit == "tot" or unit == "targettarget")
	local tracedHits = 0

	local index = self:EnsureFrameEventIndex()
	local seen = {}
	local hasDirectMatch = false

	local direct = index and index.byUnit and index.byUnit[unit]
	if direct then
		for i = 1, #direct do
			local frame = direct[i]
			if frame and not seen[frame] then
				seen[frame] = true
				hasDirectMatch = true
				tracedHits = tracedHits + 1
				self:MarkFrameDirty(frame, eventName)
			end
		end
	end

	if not hasDirectMatch then
		local unitType = ResolveUnitType(unit)
		local typed = index and index.byType and index.byType[unitType]
		if typed then
			for i = 1, #typed do
				local frame = typed[i]
				if frame and not seen[frame] then
					seen[frame] = true
					tracedHits = tracedHits + 1
					self:MarkFrameDirty(frame, eventName)
				end
			end
		end

		-- Fall back to UnitIsUnit matching for tokens that don't have a direct
		-- byUnit or byType match (e.g. nameplate units that share a GUID with
		-- the current target).
		local all = index and index.all
		if all then
			for i = 1, #all do
				local frame = all[i]
				local isSameUnit = frame and frame.unit and SafeAPICall(UnitIsUnit, unit, frame.unit)
				if frame and not seen[frame] and isSameUnit then
					seen[frame] = true
					tracedHits = tracedHits + 1
					self:MarkFrameDirty(frame, eventName)
				end
			end
		end
	end

	if unit == "target" then
		local tot = index and index.byType and index.byType["tot"]
		if tot then
			for i = 1, #tot do
				local frame = tot[i]
				if frame and not seen[frame] then
					seen[frame] = true
					tracedHits = tracedHits + 1
					self:MarkFrameDirty(frame, eventName)
				end
			end
		end
	end

	if traceAbsorb and self:IsAbsorbEventsDebugEnabled() then
		self:DebugLog("AbsorbEvents", ("Coalesced %s unit=%s dirtyHits=%d directMatch=%s"):format(tostring(eventName), tostring(unit), tracedHits, tostring(hasDirectMatch)), 2)
	end

	-- For absorb events, immediately update the absorb bar on affected frames
	-- (don't wait for batch dirty processing which may be throttled)
	if (eventName == "UNIT_ABSORB_AMOUNT_CHANGED" or eventName == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") then
		for frame in pairs(seen) do
			if frame and frame.AbsorbValue then
				self:UpdateAbsorbValue(frame, nil)
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

function addon:RegisterDebugSystem(system, defaultEnabled)
	self:EnsureDebugConfig()
	if type(system) ~= "string" or system == "" then
		return
	end
	local dbg = self.db.profile.debug
	dbg.systems = dbg.systems or {}
	if dbg.systems[system] == nil then
		dbg.systems[system] = (defaultEnabled ~= false)
	end
end

function addon:IsDebugEnabled()
	return self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.enabled
end

function addon:IsIncomingTextDebugEnabled()
	self:EnsureDebugConfig()
	return self:IsDebugEnabled() and self.db.profile.debug and self.db.profile.debug.systems and self.db.profile.debug.systems.IncomingText
end

function addon:IsAbsorbEventsDebugEnabled()
	self:EnsureDebugConfig()
	return self:IsDebugEnabled() and self.db.profile.debug and self.db.profile.debug.systems and self.db.profile.debug.systems.AbsorbEvents
end

function addon:DebugLog(system, message, tier)
	self:EnsureDebugConfig()
	self.debugMessages = self.debugMessages or {}
	system = system or "General"
	tier = tier or 3 -- 1=critical,2=info,3=debug
	self:RegisterDebugSystem(system, true)

	local dbg = self.db.profile.debug
	local enabledForSystem = (dbg.systems and dbg.systems[system] ~= false)
	if tier > 1 and (not dbg.enabled or not enabledForSystem) then
		return
	end

	local timestamp = dbg.timestamp and date("%H:%M:%S") or ""
	local prefix = timestamp ~= "" and ("[" .. timestamp .. "] ") or ""
	
	-- Sanitize message to prevent secret value errors in debug panel
	local safeMessage = tostring(message)
	if IsSecretValue(safeMessage) then
		safeMessage = "<secret value>"
	end
	local line = prefix .. system .. ": " .. safeMessage

	table.insert(self.debugMessages, line)
	if #self.debugMessages > dbg.maxMessages then
		table.remove(self.debugMessages, 1)
	end

	if self.debugPanel and self.debugPanel:IsShown() then
		self:RefreshDebugPanel()
	end
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

function addon:BuildStatusReportText()
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
	local protectedQueueSize = #(self._protectedOperationQueue or {})
	local headerCount = 0
	for _ in pairs(self.headers or {}) do
		headerCount = headerCount + 1
	end
	return ("Runtime: combat=%s editMode=%s perf=%s\nFrames: active=%d headers=%d\nPlugins: raidDebuffs=%s auraWatch=%s fader=%s pendingPluginFlush=%s\nQueue: accepted=%d fallback=%d protectedOps=%d"):format(
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
		queueFallback,
		protectedQueueSize
	)
end

function addon:RegisterMediaCallbacks()
	if not (LSM and LSM.RegisterCallback) then
		return
	end
	if self._lsmCallbacksRegistered then
		return
	end
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnSharedMediaRegistered")
	self._lsmCallbacksRegistered = true
end

function addon:UnregisterMediaCallbacks()
	if not (LSM and LSM.UnregisterCallback and self._lsmCallbacksRegistered) then
		return
	end
	pcall(LSM.UnregisterCallback, LSM, self, "LibSharedMedia_Registered")
	self._lsmCallbacksRegistered = nil
end

function addon:OnSharedMediaRegistered(_, mediaType)
	if mediaType ~= "font" and mediaType ~= "statusbar" then
		return
	end
	self:ScheduleUpdateAll()
	self:UpdateDataBars()
	self:UpdateDataTextPanel()
end

function addon:PrintStatusReport()
	local text = self:BuildStatusReportText()
	for line in tostring(text):gmatch("[^\n]+") do
		self:Print(addonName .. ": " .. line)
	end
end
---Check if Blizzard Edit Mode is currently active
---@return boolean True if Edit Mode UI is shown
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

---Schedule all unit frames for update (safe queueing during combat)
---@return void
function addon:ScheduleUpdateAll()
	if self.isBuildingOptions then
		return
	end

	if self.sufEventBus and self.sufEventBus.Dispatch then
		self:DispatchSUFEvent("LOCAL_WORK", "update_all")
	else
		self:QueueLocalWork("update_all")
	end
end

---Get optimal work delay with ML optimization support
---@return number Delay in seconds (0.01 to 0.20 range)
function addon:GetLocalWorkDelay()
	local delay = 0.05
	if self:IsPerformanceIntegrationEnabled() then
		local optimizer = self.performanceLib and self.performanceLib.MLOptimizer
		if optimizer and optimizer.GetOptimalDelay then
			local ok, learned = pcall(optimizer.GetOptimalDelay, optimizer, "SUF_LOCAL_WORK")
			if ok and type(learned) == "number" then
				delay = learned
			end
		end
	end
	return math.max(0.01, math.min(0.20, tonumber(delay) or 0.05))
end

---Queue frame work for deferred update processing
---@param workType string Work type identifier ("update_all", "update_unit", "visibility")
---@param unitType? string Optional unit type for "update_unit" work
---@return void
function addon:QueueLocalWork(workType, unitType)
	if self.isBuildingOptions then
		return
	end

	self._localWork = self._localWork or {
		updateAll = false,
		applyVisibility = false,
		unitTypes = {},
	}

	local work = self._localWork
	if workType == "visibility" then
		work.applyVisibility = true
	elseif workType == "update_unit" and unitType then
		work.unitTypes[unitType] = true
	else
		work.updateAll = true
		work.unitTypes = {}
	end

	local optimizer = self.performanceLib and self.performanceLib.MLOptimizer
	if optimizer and optimizer.TrackPattern then
		pcall(optimizer.TrackPattern, optimizer, "SUF_LOCAL_WORK", tostring(workType))
	end

	if self._localWorkTimer then
		return
	end

	local delay = self:GetLocalWorkDelay()
	self._localWorkTimer = C_Timer.NewTimer(delay, function()
		self._localWorkTimer = nil
		local started = debugprofilestop and debugprofilestop() or nil
		local state = self._localWork or {}
		self._localWork = {
			updateAll = false,
			applyVisibility = false,
			unitTypes = {},
		}

		if state.applyVisibility then
			self:ApplyVisibilityRules()
		end
		if state.updateAll then
			self:UpdateAllFrames()
		else
			for queuedUnitType in pairs(state.unitTypes or {}) do
				self:UpdateFramesByUnitType(queuedUnitType)
			end
		end

		if started then
			local elapsed = (debugprofilestop() or started) - started
			local opt = self.performanceLib and self.performanceLib.MLOptimizer
			if opt and opt.LearnDelay then
				pcall(opt.LearnDelay, opt, "SUF_LOCAL_WORK", delay, elapsed <= 10)
			end
			self:RecordProfilerEvent("suf:localwork.flush", elapsed)
		end
	end)
end

function addon:ScheduleApplyVisibility()
	if self.isBuildingOptions then
		return
	end
	if self.sufEventBus and self.sufEventBus.Dispatch then
		self:DispatchSUFEvent("LOCAL_WORK", "visibility")
	else
		self:QueueLocalWork("visibility")
	end
end

function addon:ScheduleUpdateUnitType(unitType)
	if not unitType then
		self:ScheduleUpdateAll()
		return
	end
	if self.isBuildingOptions then
		return
	end
	if self.sufEventBus and self.sufEventBus.Dispatch then
		self:DispatchSUFEvent("LOCAL_WORK", "update_unit", unitType)
	else
		self:QueueLocalWork("update_unit", unitType)
	end
end

function addon:FlushLocalWorkNow()
	if self._localWorkTimer and self._localWorkTimer.Cancel then
		self._localWorkTimer:Cancel()
		self._localWorkTimer = nil
	end
	if self._localWork then
		local pending = self._localWork
		self._localWork = nil
		if pending.applyVisibility then
			self:ApplyVisibilityRules()
		end
		if pending.updateAll then
			self:UpdateAllFrames()
		else
			for unitType in pairs(pending.unitTypes or {}) do
				self:UpdateFramesByUnitType(unitType)
			end
		end
	end
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
		local debugTags = self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.absorbTags
		
		frame:Untag(frame.AbsorbValue)
		local absorbTag = self.db and self.db.profile and self.db.profile.absorbValueTag or "[suf:absorbs:abbr]"
		
		local frameName = frame:GetName() or "Unknown"
		local unit = frame.unit or "nil"
		if debugTags then
			self:DebugLog("AbsorbTags", ("Applying tag to frame %s (unit=%s): tag='%s'"):format(
				frameName,
				tostring(unit),
				tostring(absorbTag)
			), 2)
		end
		
		if absorbTag and absorbTag ~= "" then
			local ok, err = pcall(frame.Tag, frame, frame.AbsorbValue, absorbTag)
			if ok then
				frame.AbsorbValue.__isSUFTaggedAbsorb = true
				if debugTags then
					self:DebugLog("AbsorbTags", ("Tag applied successfully to %s"):format(frame:GetName() or "Unknown"), 2)
				end
			else
				frame.AbsorbValue:SetText("")
				frame.AbsorbValue.__isSUFTaggedAbsorb = false
				if debugTags then
					self:DebugLog("AbsorbTags", ("Tag application FAILED for %s: %s"):format(frame:GetName() or "Unknown", tostring(err)), 2)
				end
			end
		else
			frame.AbsorbValue:SetText("")
			frame.AbsorbValue.__isSUFTaggedAbsorb = false
			if debugTags then
				self:DebugLog("AbsorbTags", ("No tag configured for %s"):format(frame:GetName() or "Unknown"), 2)
			end
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

	local anchorFrame = anchorTexture or GetStatusBarAnchor(frame.Health) or frame.Health
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
		local healthTexture = anchorTexture or GetStatusBarAnchor(frame.Health) or frame.Health
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

local function GetCastbarRemainingDuration(castbar, durationObject)
	local remaining = durationObject and SafeNumber(SafeAPICall(durationObject.GetRemainingDuration, durationObject), nil)
	if remaining ~= nil then
		return math.max(0, remaining)
	end

	local maxValue = SafeNumber(castbar and castbar.max, nil) or SafeNumber(castbar and castbar.maxValue, nil)
	local value = SafeNumber(castbar and castbar.value, nil)
	local duration = SafeNumber(castbar and castbar.duration, nil)

	if maxValue and duration then
		return math.max(0, maxValue - duration)
	end
	if maxValue and value then
		if castbar and castbar.channeling then
			return math.max(0, value)
		end
		return math.max(0, maxValue - value)
	end

	return nil
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

	-- Throttle debug logging to prevent spam (max once per second per frame)
	local debugAbsorb = self.db and self.db.profile and self.db.profile.debug and self.db.profile.debug.systems and self.db.profile.debug.systems.AbsorbEvents
	local now = GetTime and GetTime() or 0
	local lastLog = frame.__sufAbsorbLastDebugLog or 0
	local shouldLog = debugAbsorb and (now - lastLog) >= 1.0
	
	if shouldLog then
		frame.__sufAbsorbLastDebugLog = now
		local unit = unitToken or frame.unit or "unknown"
		local unitType = (frame and frame.sufUnitType) or "unknown"
		self:DebugLog("AbsorbEvents", ("UpdateAbsorbValue called: frame=%s unit=%s unitType=%s"):format(frame:GetName() or "unnamed", unit, unitType), 2)
	end

	local hpCfg = self:GetUnitHealPredictionSettings(frame.sufUnitType)
	if not (hpCfg and hpCfg.enabled and hpCfg.absorbs and hpCfg.absorbs.enabled) then
		if shouldLog then
			self:DebugLog("AbsorbEvents", ("Early return: absorbs disabled or config missing. hpCfg=%s enabled=%s absorbs=%s"):format(hpCfg and "yes" or "nil", hpCfg and hpCfg.enabled or "N/A", hpCfg and hpCfg.absorbs and hpCfg.absorbs.enabled or "N/A"), 2)
		end
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
	-- For header-spawned frames (party/raid), try secure attribute if frame.unit is not set
	if not unit and frame.GetAttribute then
		unit = frame:GetAttribute('unit') or frame:GetAttribute('oUF-guessUnit')
	end
	
	if not unit then
		if shouldLog then
			self:DebugLog("AbsorbEvents", ("Early return: no unit token. unit=%s"):format(tostring(unit)), 2)
		end
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
	
	-- Note: Don't use UnitExists() check here - it can be unreliable for target/tot tokens
	-- Just proceed with the API calls which will handle missing units gracefully

	if type(UnitGetTotalAbsorbs) ~= "function" then
		if shouldLog then
			self:DebugLog("AbsorbEvents", "Early return: UnitGetTotalAbsorbs not available", 2)
		end
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

	local hpWidgets = GetHealthPredictionWidgets(frame)
	if not hpWidgets or not hpWidgets.damageAbsorb then
		if shouldLog then
			self:DebugLog("AbsorbEvents", ("GetHealthPredictionWidgets returned nil or no damageAbsorb. widgets=%s damageAbsorb=%s"):format(hpWidgets and "yes" or "nil", hpWidgets and hpWidgets.damageAbsorb and "yes" or "nil"), 2)
		end
		frame.AbsorbValue:SetText("")
		return
	end

	-- Health Override already sets the bar correctly via normal oUF events
	-- No need to force update here (causes lag spikes)
	
	local absorbBar = hpWidgets.damageAbsorb
	
	-- Health Override already sets the bar correctly (handles secret values).
	-- We only need to update the text display.
	-- Try to read the bar's current value for text display
	local absorbValue = nil
	local absorbBarValue = absorbBar.GetValue and absorbBar:GetValue()
	
	-- Check if bar is showing (Health Override set it) but value is secret
	local barIsShown = absorbBar.IsShown and absorbBar:IsShown()
	local valueIsSecret = absorbBarValue and IsSecretValue(absorbBarValue)
	
	if shouldLog then
		self:DebugLog("AbsorbEvents", ("Absorb bar state: shown=%s barValue=%s isSecret=%s"):format(
			tostring(barIsShown),
			absorbBarValue and "exists" or "nil",
			tostring(valueIsSecret)
		), 2)
	end
	
	-- Try to convert to number for text display
	if absorbBarValue and not valueIsSecret then
		absorbValue = SafeNumber(absorbBarValue, nil)
	end
	
	local maxHealth = SafeNumber(SafeAPICall(UnitHealthMax, unit), nil)

	if shouldLog then
		self:DebugLog("AbsorbEvents", ("State: maxHealth=%s absorbValue=%s barShown=%s"):format(
			tostring(maxHealth), 
			tostring(absorbValue),
			tostring(barIsShown)
		), 2)
	end

	-- Health Override already set the bar correctly - we only update auxiliary elements here
	
	-- Update AbsorbCap indicator position (white line at absorb edge)
	if frame.Health and frame.Health.AbsorbCap and barIsShown then
		local cap = frame.Health.AbsorbCap
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
		cap:SetWidth(2)
		cap:SetShown(true)
	elseif frame.Health and frame.Health.AbsorbCap then
		frame.Health.AbsorbCap:Hide()
	end

	-- Update text display
	if frame.AbsorbValue.__isSUFTaggedAbsorb then
		local now = (GetTime and GetTime()) or 0
		local isSecretDisplay = barIsShown and valueIsSecret
		local valueBucket = isSecretDisplay and "secret" or (absorbValue and tostring(math.floor(absorbValue + 0.5)) or "none")
		local shouldForceTagUpdate = false

		if frame.__sufLastAbsorbTagBucket ~= valueBucket then
			shouldForceTagUpdate = true
		else
			local lastTagUpdate = tonumber(frame.__sufLastAbsorbTagUpdateAt) or 0
			if now - lastTagUpdate >= 0.20 then
				shouldForceTagUpdate = true
			end
		end

		if shouldLog then
			local hasUpdateTag = frame.AbsorbValue and frame.AbsorbValue.UpdateTag ~= nil
			local hasUpdateTags = frame.UpdateTags ~= nil
			self:DebugLog("AbsorbEvents", ("Text managed by oUF tag system (frame=%s), update=%s bucket=%s HasUpdateTag=%s HasUpdateTags=%s"):format(
				frame:GetName() or "Unknown",
				tostring(shouldForceTagUpdate),
				tostring(valueBucket),
				tostring(hasUpdateTag),
				tostring(hasUpdateTags)
			), 2)
		end

		if not shouldForceTagUpdate then
			return
		end

		-- Force oUF to update the absorb tag specifically
		if frame.AbsorbValue and frame.AbsorbValue.UpdateTag then
			local ok, err = pcall(frame.AbsorbValue.UpdateTag, frame.AbsorbValue)
			if shouldLog and not ok then
				self:DebugLog("AbsorbEvents", ("UpdateTag failed: %s"):format(tostring(err)), 2)
			end
			if ok then
				frame.__sufLastAbsorbTagUpdateAt = now
				frame.__sufLastAbsorbTagBucket = valueBucket
			end
		elseif frame.UpdateTags then
			local ok, err = pcall(frame.UpdateTags, frame)
			if shouldLog and not ok then
				self:DebugLog("AbsorbEvents", ("UpdateTags failed: %s"):format(tostring(err)), 2)
			end
			if ok then
				frame.__sufLastAbsorbTagUpdateAt = now
				frame.__sufLastAbsorbTagBucket = valueBucket
			end
		end
		return
	end
	
	if shouldLog then
		self:DebugLog("AbsorbEvents", ("Text NOT managed by tag, __isSUFTaggedAbsorb=%s"):format(
			tostring(frame.AbsorbValue.__isSUFTaggedAbsorb)
		), 2)
	end

	-- If bar is shown but value is secret, show placeholder
	if barIsShown and valueIsSecret then
		frame.AbsorbValue:SetText("~")
		return
	end

	-- If no readable value, clear text
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

local CHANNEL_TICK_COUNT_BY_SPELL_ID = {
	[15407] = 5, -- Mind Flay
	[48045] = 5, -- Mind Sear
	[198590] = 5, -- Drain Soul
	[234153] = 6, -- Drain Life
	[5143] = 5, -- Arcane Missiles
}

local function HideCastbarDirectionIndicator(castbar)
	if castbar and castbar._sufDirectionIndicator then
		castbar._sufDirectionIndicator:Hide()
	end
end

local function UpdateCastbarDirectionIndicator(castbar, cfg)
	if not castbar then
		return
	end
	if cfg.showDirectionIndicator ~= true then
		HideCastbarDirectionIndicator(castbar)
		return
	end
	if not (castbar.casting or castbar.channeling) then
		HideCastbarDirectionIndicator(castbar)
		return
	end
	if not castbar._sufDirectionIndicator then
		local fs = castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetPoint("BOTTOM", castbar, "TOP", 0, 1)
		castbar._sufDirectionIndicator = fs
	end
	castbar._sufDirectionIndicator:SetText(castbar:GetReverseFill() and "<" or ">")
	castbar._sufDirectionIndicator:Show()
end

local function HideCastbarChannelTicks(castbar)
	if not castbar or not castbar._sufChannelTicks then
		return
	end
	for i = 1, #castbar._sufChannelTicks do
		local tick = castbar._sufChannelTicks[i]
		if tick then
			tick:Hide()
		end
	end
end

local function UpdateCastbarChannelTicks(castbar, cfg)
	if not castbar then
		return
	end
	if cfg.showChannelTicks ~= true or not castbar.channeling then
		HideCastbarChannelTicks(castbar)
		return
	end
	local spellID = tonumber(castbar.spellID) or 0
	local tickCount = CHANNEL_TICK_COUNT_BY_SPELL_ID[spellID]
	if not tickCount or tickCount <= 0 then
		HideCastbarChannelTicks(castbar)
		return
	end

	castbar._sufChannelTicks = castbar._sufChannelTicks or {}
	local width = castbar:GetWidth() or 0
	local height = castbar:GetHeight() or 0
	if width <= 0 or height <= 0 then
		HideCastbarChannelTicks(castbar)
		return
	end
	local tickWidth = math.max(1, tonumber(cfg.channelTickWidth) or 2)
	for i = 1, tickCount do
		local tick = castbar._sufChannelTicks[i]
		if not tick then
			tick = castbar:CreateTexture(nil, "OVERLAY")
			castbar._sufChannelTicks[i] = tick
		end
		local pct = i / (tickCount + 1)
		local offset = width * pct
		tick:ClearAllPoints()
		if castbar:GetReverseFill() then
			tick:SetPoint("TOP", castbar, "TOPRIGHT", -offset, 0)
			tick:SetPoint("BOTTOM", castbar, "BOTTOMRIGHT", -offset, 0)
		else
			tick:SetPoint("TOP", castbar, "TOPLEFT", offset, 0)
			tick:SetPoint("BOTTOM", castbar, "BOTTOMLEFT", offset, 0)
		end
		tick:SetWidth(tickWidth)
		tick:SetColorTexture(1, 1, 1, 0.65)
		tick:Show()
	end
	for i = tickCount + 1, #castbar._sufChannelTicks do
		local tick = castbar._sufChannelTicks[i]
		if tick then
			tick:Hide()
		end
	end
end

local function UpdateCastbarEmpowerPips(castbar, cfg)
	if not castbar or not castbar.Pips then
		return
	end
	if cfg.showEmpowerPips == false then
		for _, pip in pairs(castbar.Pips) do
			if pip then
				pip:Hide()
			end
		end
		return
	end
	for _, pip in pairs(castbar.Pips) do
		if pip then
			pip:SetAlpha(0.95)
		end
	end
end

local function HideCastbarLatencyIndicator(castbar)
	if castbar and castbar._sufLatencyIndicator then
		castbar._sufLatencyIndicator:Hide()
	end
end

local function UpdateCastbarLatencyIndicator(castbar, cfg)
	if not castbar then
		return
	end
	if cfg.showLatencyText ~= true then
		HideCastbarLatencyIndicator(castbar)
		return
	end
	if not (castbar.casting or castbar.channeling) then
		HideCastbarLatencyIndicator(castbar)
		return
	end
	local owner = castbar.__owner
	local unit = owner and owner.unit
	if unit ~= "player" then
		HideCastbarLatencyIndicator(castbar)
		return
	end
	if not GetNetStats then
		HideCastbarLatencyIndicator(castbar)
		return
	end
	local _, _, home, world = GetNetStats()
	local latency = math.max(tonumber(home) or 0, tonumber(world) or 0)
	if not castbar._sufLatencyIndicator then
		local fs = castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		fs:SetPoint("TOPRIGHT", castbar, "BOTTOMRIGHT", 0, -1)
		fs:SetJustifyH("RIGHT")
		castbar._sufLatencyIndicator = fs
	end
	local warnMs = math.max(1, tonumber(cfg.latencyWarnMs) or 120)
	local highMs = math.max(warnMs, tonumber(cfg.latencyHighMs) or 220)
	local r, g, b = 0.35, 1.0, 0.35
	if latency >= highMs then
		r, g, b = 1.0, 0.25, 0.25
	elseif latency >= warnMs then
		r, g, b = 1.0, 0.85, 0.30
	end
	castbar._sufLatencyIndicator:SetFormattedText("%dms", latency)
	castbar._sufLatencyIndicator:SetTextColor(r, g, b, 0.95)
	castbar._sufLatencyIndicator:Show()
end

local function UpdateCastbarEnhancementWidgets(castbar, cfg)
	UpdateCastbarDirectionIndicator(castbar, cfg)
	UpdateCastbarChannelTicks(castbar, cfg)
	UpdateCastbarEmpowerPips(castbar, cfg)
	UpdateCastbarLatencyIndicator(castbar, cfg)
end

local function HideCastbarEnhancementWidgets(castbar)
	HideCastbarDirectionIndicator(castbar)
	HideCastbarChannelTicks(castbar)
	HideCastbarLatencyIndicator(castbar)
	if castbar and castbar.Pips then
		for _, pip in pairs(castbar.Pips) do
			if pip then
				pip:Hide()
			end
		end
	end
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
	local isGroup = self:IsGroupUnitType(frame.sufUnitType)

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
		local hasElementApi = frame.EnableElement and frame.DisableElement and frame.IsElementEnabled
		if hasElementApi then
			if enabled and not frame:IsElementEnabled("Fader") then
				pcall(frame.EnableElement, frame, "Fader")
			elseif (not enabled) and frame:IsElementEnabled("Fader") then
				pcall(frame.DisableElement, frame, "Fader")
			end
		end
		local minAlpha = math.max(0.05, math.min(1, tonumber(faderCfg.minAlpha) or 0.45))
		local maxAlpha = math.max(0.05, math.min(1, tonumber(faderCfg.maxAlpha) or 1))
		if minAlpha > maxAlpha then
			minAlpha = maxAlpha
		end
		local smooth = math.max(0, math.min(1, tonumber(faderCfg.smooth) or 0.2))
		SafeSetFaderOption(frame.Fader, "MinAlpha", minAlpha)
		SafeSetFaderOption(frame.Fader, "MaxAlpha", maxAlpha)
		SafeSetFaderOption(frame.Fader, "Smooth", smooth)
		SafeSetFaderOption(frame.Fader, "Hover", enabled and (faderCfg.hover ~= false) or false)
		SafeSetFaderOption(frame.Fader, "Combat", enabled and (faderCfg.combat ~= false) or false)
		SafeSetFaderOption(frame.Fader, "Casting", enabled and (faderCfg.casting == true) or false)
		SafeSetFaderOption(frame.Fader, "PlayerTarget", enabled and (faderCfg.playerTarget ~= false) or false)
		SafeSetFaderOption(frame.Fader, "ActionTarget", enabled and (faderCfg.actionTarget == true) or false)
		SafeSetFaderOption(frame.Fader, "UnitTarget", enabled and (faderCfg.unitTarget == true) or false)
		if enabled and frame.Fader.ForceUpdate then
			frame.Fader:ForceUpdate("SUF_FaderApply")
		elseif not enabled and frame.SetAlpha then
			if frame.Fader.ClearTimers then
				frame.Fader:ClearTimers()
			end
			frame.Fader.count = 0
			frame.Fader.TargetHooked = 0
			frame.Fader.HoverHooked = 0
			frame.Fader.__fadingTo = nil
			frame.Fader.__lastTargetAlpha = nil
			frame:SetAlpha(1)
			if self.UpdateAbsorbValue then
				self:UpdateAbsorbValue(frame, frame.unit)
			end
		end
	end
end

function addon:ApplyMedia(frame)
	local profileStart = debugprofilestop and debugprofilestop() or nil
	local texture = self:GetUnitStatusbarTexture(frame.sufUnitType)
	local bgCfg = self:GetUnitMainBarsBackgroundSettings(frame.sufUnitType)
	local hpCfgGlobal = self:GetUnitHealPredictionSettings(frame.sufUnitType)
	local incomingCfgGlobal = hpCfgGlobal and hpCfgGlobal.incoming or DEFAULT_HEAL_PREDICTION.incoming
	local font = self:GetUnitFont(frame.sufUnitType)
	local sizes = self:GetUnitFontSizes(frame.sufUnitType)
	local castbarCfg = self.db.profile.castbar or {}
	local unitCastbarCfg = self:GetUnitCastbarSettings(frame.sufUnitType)
	local castbarColors = self:GetUnitCastbarColors(frame.sufUnitType)

	if frame.Health then
		SetStatusBarTexturePreserveLayer(frame.Health, texture)
		local healthTex = frame.Health.GetStatusBarTexture and frame.Health:GetStatusBarTexture()
		if healthTex and healthTex.SetDrawLayer then
			healthTex:SetDrawLayer("ARTWORK", 1)
		end
	end

	if frame.Power then
		SetStatusBarTexturePreserveLayer(frame.Power, texture)
	end

	if frame.Auras then
		local auraCfg = self:GetUnitAuraLayoutSettings(frame.sufUnitType)
		local spacingX = tonumber(auraCfg.spacingX) or 4
		local spacingY = tonumber(auraCfg.spacingY) or 4
		local maxCols = math.max(1, tonumber(auraCfg.maxCols) or 8)
		local initialAnchor = tostring(auraCfg.initialAnchor or "BOTTOMLEFT")
		local growthX = tostring(auraCfg.growthX or "RIGHT")
		local growthY = tostring(auraCfg.growthY or "UP")
		local sortMethod = tostring(auraCfg.sortMethod or "DEFAULT")
		local sortDirection = tostring(auraCfg.sortDirection or "ASC")
		local onlyShowPlayer = auraCfg.onlyShowPlayer == true
		local showStealableBuffs = auraCfg.showStealableBuffs ~= false
		local numBuffs = math.max(0, tonumber(auraCfg.numBuffs) or 8)
		local numDebuffs = math.max(0, tonumber(auraCfg.numDebuffs) or 8)
		local enabled = auraCfg.enabled ~= false
		local layoutSig = table.concat({
			spacingX, spacingY, maxCols, initialAnchor, growthX, growthY,
			sortMethod, sortDirection, tostring(onlyShowPlayer), tostring(showStealableBuffs),
			numBuffs, numDebuffs
		}, "|")

		frame.Auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"
		frame.Auras.tooltipOffsetX = 0
		frame.Auras.tooltipOffsetY = 0
		frame.Auras.reanchorIfVisibleChanged = false

		if frame.__sufAuraLayoutSig ~= layoutSig then
			frame.Auras.spacingX = spacingX
			frame.Auras.spacingY = spacingY
			frame.Auras.maxCols = maxCols
			frame.Auras.initialAnchor = initialAnchor
			frame.Auras.growthX = growthX
			frame.Auras.growthY = growthY
			frame.Auras.sortMethod = sortMethod
			frame.Auras.sortDirection = sortDirection
			frame.Auras.onlyShowPlayer = onlyShowPlayer
			frame.Auras.showStealableBuffs = showStealableBuffs
			frame.Auras.numBuffs = numBuffs
			frame.Auras.numDebuffs = numDebuffs
			frame.Auras.needFullUpdate = true
			frame.__sufAuraLayoutSig = layoutSig
		end

		if frame.__sufAuraEnabled ~= enabled then
			frame.Auras:SetShown(enabled)
			frame.__sufAuraEnabled = enabled
		end
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

		local statusTex = GetStatusBarAnchor(frame.Health)
		if statusTex and statusTex.SetDrawLayer then
			statusTex:SetDrawLayer("ARTWORK", 1)
		end
		if absorbOverlay then
			absorbOverlay:SetFrameStrata(frame.Health:GetFrameStrata())
			absorbOverlay:SetFrameLevel(absorbLevel - 1)
		end

		if hpWidgets.healingAll then
			SetStatusBarTexturePreserveLayer(hpWidgets.healingAll, texture)
			RaisePredictionBar(hpWidgets.healingAll)
			local c = incomingCfg.colorAll
			hpWidgets.healingAll:SetStatusBarColor(c[1] or 0.35, c[2] or 0.95, c[3] or 0.45, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			hpWidgets.healingAll:ClearAllPoints()
			hpWidgets.healingAll:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			hpWidgets.healingAll:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			hpWidgets.healingAll:SetPoint("LEFT", statusTex or frame.Health, "RIGHT")
			local shownAll = (hpCfg.enabled ~= false) and (incomingCfg.enabled ~= false) and not incomingCfg.split
			hpWidgets.healingAll:SetShown(shownAll)
			UpdateBarTextureOutline(hpWidgets.healingAll, shownAll)
		end
		if hpWidgets.healingPlayer then
			SetStatusBarTexturePreserveLayer(hpWidgets.healingPlayer, texture)
			RaisePredictionBar(hpWidgets.healingPlayer)
			local c = incomingCfg.colorPlayer
			hpWidgets.healingPlayer:SetStatusBarColor(c[1] or 0.35, c[2] or 0.95, c[3] or 0.45, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			hpWidgets.healingPlayer:ClearAllPoints()
			hpWidgets.healingPlayer:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			hpWidgets.healingPlayer:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			hpWidgets.healingPlayer:SetPoint("LEFT", statusTex or frame.Health, "RIGHT")
			local shownPlayer = (hpCfg.enabled ~= false) and (incomingCfg.enabled ~= false) and incomingCfg.split
			hpWidgets.healingPlayer:SetShown(shownPlayer)
			UpdateBarTextureOutline(hpWidgets.healingPlayer, shownPlayer)
		end
		if hpWidgets.healingOther then
			SetStatusBarTexturePreserveLayer(hpWidgets.healingOther, texture)
			RaisePredictionBar(hpWidgets.healingOther)
			local c = incomingCfg.colorOther
			hpWidgets.healingOther:SetStatusBarColor(c[1] or 0.20, c[2] or 0.75, c[3] or 0.35, math.max(0.05, math.min(1, incomingCfg.opacity or 0.4)))
			hpWidgets.healingOther:ClearAllPoints()
			hpWidgets.healingOther:SetPoint("TOP", frame.Health, "TOP", 0, -incomingInset)
			hpWidgets.healingOther:SetPoint("BOTTOM", frame.Health, "BOTTOM", 0, incomingInset)
			local healAnchor = hpWidgets.healingPlayer and GetStatusBarAnchor(hpWidgets.healingPlayer) or statusTex
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
					incomingAnchor = GetStatusBarAnchor(hpWidgets.healingOther) or incomingAnchor
				elseif hpWidgets.healingPlayer and hpWidgets.healingPlayer.GetStatusBarTexture then
					incomingAnchor = GetStatusBarAnchor(hpWidgets.healingPlayer) or incomingAnchor
				end
			else
				if hpWidgets.healingAll and hpWidgets.healingAll.GetStatusBarTexture then
					incomingAnchor = GetStatusBarAnchor(hpWidgets.healingAll) or incomingAnchor
				end
			end
			if not incomingAnchor then
				incomingAnchor = frame.Health
			end
			frame.IncomingHealValue:SetPoint("LEFT", incomingAnchor, "RIGHT", valueOffsetX, valueOffsetY)
			frame.IncomingHealValue:SetJustifyH("LEFT")
		end

		if hpWidgets.damageAbsorb then
			SetStatusBarTexturePreserveLayer(hpWidgets.damageAbsorb, texture)
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
					absorbAnchor = GetStatusBarAnchor(hpWidgets.healingOther) or absorbAnchor
				elseif hpWidgets.healingPlayer and hpWidgets.healingPlayer.GetStatusBarTexture then
					absorbAnchor = GetStatusBarAnchor(hpWidgets.healingPlayer) or absorbAnchor
				end
			else
				if hpWidgets.healingAll and hpWidgets.healingAll.GetStatusBarTexture then
					absorbAnchor = GetStatusBarAnchor(hpWidgets.healingAll) or absorbAnchor
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
				local dtex = GetStatusBarAnchor(hpWidgets.damageAbsorb)
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
			SetStatusBarTexturePreserveLayer(hpWidgets.healAbsorb, texture)
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
		SetStatusBarTexturePreserveLayer(frame.AdditionalPower, texture)
	end

	if frame.AdditionalPowerBG then
		frame.AdditionalPowerBG:SetTexture(texture)
		frame.AdditionalPowerBG:SetVertexColor(0, 0, 0, 0.6)
	end

	self:UpdateUnitPowerPrediction(frame, texture)

	if frame.Castbar then
		local castbarEnabled = unitCastbarCfg.enabled ~= false
		frame.Castbar:SetShown(castbarEnabled)
		if castbarEnabled then
			frame.Castbar:SetReverseFill(unitCastbarCfg.reverseFill == true)
			SetStatusBarTexturePreserveLayer(frame.Castbar, texture)
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
			UpdateCastbarEnhancementWidgets(frame.Castbar, castbarCfg)

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
				local remaining = GetCastbarRemainingDuration(castbar, durationObject)
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
				local remaining = GetCastbarRemainingDuration(castbar, durationObject)
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
				UpdateCastbarEnhancementWidgets(castbar, castbarCfg)
			end
			frame.Castbar.PostChannelStart = function(castbar)
				local color = castbarColors.channeling or castbarColors.casting or { 0.2, 0.6, 1 }
				castbar:SetStatusBarColor(color[1] or 0.2, color[2] or 0.6, color[3] or 1)
				UpdateInterruptVisual(castbar)
				UpdateCastbarEnhancementWidgets(castbar, castbarCfg)
			end
			frame.Castbar.PostCastInterruptible = function(castbar)
				local color = castbar.channeling and (castbarColors.channeling or castbarColors.casting) or castbarColors.casting
				color = color or { 1, 0.7, 0 }
				castbar:SetStatusBarColor(color[1] or 1, color[2] or 0.7, color[3] or 0)
				StopCastbarNonInterruptGlow(castbar)
				if castbar.Shield then
					castbar.Shield:SetShown(false)
				end
				UpdateCastbarEnhancementWidgets(castbar, castbarCfg)
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
				UpdateCastbarEnhancementWidgets(castbar, castbarCfg)
			end
			frame.Castbar.PostCastFailed = function(castbar)
				local color = castbarColors.failed or { 1, 0.1, 0.1 }
				castbar:SetStatusBarColor(color[1] or 1, color[2] or 0.1, color[3] or 0.1)
				StopCastbarNonInterruptGlow(castbar)
				HideCastbarEnhancementWidgets(castbar)
			end
			frame.Castbar.PostCastInterrupted = frame.Castbar.PostCastFailed
			frame.Castbar.PostCastUpdate = function(castbar)
				UpdateInterruptVisual(castbar)
				UpdateCastbarEnhancementWidgets(castbar, castbarCfg)
			end
			frame.Castbar.PostChannelUpdate = frame.Castbar.PostCastUpdate
			frame.Castbar.PostCastStop = function(castbar)
				local color = castbarColors.complete or { 0, 1, 0 }
				castbar:SetStatusBarColor(color[1] or 0, color[2] or 1, color[3] or 0)
				StopCastbarNonInterruptGlow(castbar)
				HideCastbarEnhancementWidgets(castbar)
			end
		else
			StopCastbarNonInterruptGlow(frame.Castbar)
			HideCastbarEnhancementWidgets(frame.Castbar)
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
			SetStatusBarTexturePreserveLayer(bar, texture)
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

function addon:UpdateUnitPowerPrediction(frame, texture)
	if not (frame and frame.Power and frame.PowerPrediction) then
		return
	end

	local cfg = self:GetUnitPowerPredictionSettings(frame.sufUnitType)
	local enabled = cfg and cfg.enabled == true
	local predictionBar = frame.PowerPrediction
	if enabled then
		SetStatusBarTexturePreserveLayer(predictionBar, texture or DEFAULT_TEXTURE)
		local color = cfg.color or DEFAULT_UNIT_POWER_PREDICTION.color
		local alpha = math.max(0.05, math.min(1, tonumber(cfg.opacity) or DEFAULT_UNIT_POWER_PREDICTION.opacity or 0.70))
		predictionBar:SetStatusBarColor(color[1] or 1.0, color[2] or 0.9, color[3] or 0.25, alpha)
		predictionBar:SetReverseFill(frame.Power:GetReverseFill() == true)
		local predictionHeight = math.max(1, math.min(16, tonumber(cfg.height) or DEFAULT_UNIT_POWER_PREDICTION.height or 3))
		predictionBar:SetHeight(predictionHeight)
		predictionBar:ClearAllPoints()
		predictionBar:SetPoint("TOP", frame.Power, "TOP", 0, 0)
		predictionBar:SetPoint("BOTTOM", frame.Power, "BOTTOM", 0, 0)
		local statusAnchor = frame.Power.GetStatusBarTexture and frame.Power:GetStatusBarTexture() or nil
		if statusAnchor then
			predictionBar:SetPoint("RIGHT", statusAnchor, "RIGHT", 0, 0)
		else
			predictionBar:SetPoint("RIGHT", frame.Power, "RIGHT", 0, 0)
		end
		predictionBar:SetWidth(frame.Power:GetWidth() or 1)
		frame.Power.CostPrediction = predictionBar
		predictionBar:Show()
	else
		frame.Power.CostPrediction = nil
		predictionBar:Hide()
	end

	if frame.__sufPowerPredictionEnabled ~= enabled then
		frame.__sufPowerPredictionEnabled = enabled
		if frame.Power and frame.Power.ForceUpdate then
			pcall(frame.Power.ForceUpdate, frame.Power)
		elseif frame.UpdateElement then
			pcall(frame.UpdateElement, frame, "Power")
		end
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

	if frame.ThreatIndicator then
		local threatSize = math.max(12, math.floor(size * 0.6))
		frame.ThreatIndicator:SetSize(threatSize, threatSize)
		frame.ThreatIndicator:ClearAllPoints()
		frame.ThreatIndicator:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
	end

	if frame.QuestIndicator then
		-- Fixed size 30x30, positioned outside frame at top right corner
		frame.QuestIndicator:SetSize(30, 30)
		frame.QuestIndicator:ClearAllPoints()
		frame.QuestIndicator:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT", 2, -2)
	end

	if frame.PvPClassificationIndicator then
		local classSize = math.max(12, math.floor(size * 0.6))
		frame.PvPClassificationIndicator:SetSize(classSize, classSize)
		frame.PvPClassificationIndicator:ClearAllPoints()
		frame.PvPClassificationIndicator:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
	end

	if frame.ClassificationIndicator then
		-- Elite/Rare/Boss badges positioned at top-right
		local classificationSize = math.max(18, math.floor(size * 0.6)) -- Keep at 18x18 for consistent display
		frame.ClassificationIndicator:SetSize(classificationSize, classificationSize)
		frame.ClassificationIndicator:ClearAllPoints()
		frame.ClassificationIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 8, 8)
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

	if frame.TargetIndicator then
		local glowCfg = self:GetUnitTargetGlowSettings(frame.sufUnitType)
		local inset = math.max(0, math.min(12, tonumber(glowCfg.inset) or 3))
		frame.TargetIndicator:ClearAllPoints()
		frame.TargetIndicator:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
		frame.TargetIndicator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
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
		if frame.ThreatIndicator then frame.ThreatIndicator:Hide() end
		if frame.TargetIndicator then frame.TargetIndicator:Hide() end
		if frame.StatusIndicator then frame.StatusIndicator:SetText("") end
		return
	end
	if UnitExists and not UnitExists(unit) then
		if frame.RoleIndicator then frame.RoleIndicator:Hide() end
		if frame.RaidMarkerIndicator then frame.RaidMarkerIndicator:Hide() end
		if frame.LeaderIndicator then frame.LeaderIndicator:Hide() end
		if frame.ThreatIndicator then frame.ThreatIndicator:Hide() end
		if frame.TargetIndicator then frame.TargetIndicator:Hide() end
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
		markerIndex = SafeNumber(markerIndex, 0)  -- Guard against secret values in WoW 12.0.0+
		if markerIndex > 0 and type(SetRaidTargetIconTexture) == "function" then
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

	if frame.TargetIndicator then
		local glowCfg = self:GetUnitTargetGlowSettings(frame.sufUnitType)
		local enabled = glowCfg and glowCfg.enabled == true
		local isTarget = false
		if enabled and UnitExists and UnitExists("target") and UnitExists(unit) then
			if UnitIsUnit and UnitIsUnit("target", unit) then
				isTarget = true
			elseif UnitGUID then
				-- Use SafeAPICall to handle secret values in WoW 12.0.0+
				local targetGUID = SafeAPICall(UnitGUID, "target")
				local unitGUID = SafeAPICall(UnitGUID, unit)
				-- Only compare if both GUIDs are accessible (not secret)
				isTarget = (targetGUID and unitGUID and targetGUID == unitGUID) and true or false
			end
		end
		if isTarget then
			local color = glowCfg.color or DEFAULT_UNIT_TARGET_GLOW.color
			local alpha = color[4] or 0.92
			frame.TargetIndicator:SetBackdropBorderColor(color[1] or 0.95, color[2] or 0.85, color[3] or 0.25, alpha)
			frame.TargetIndicator:SetAlpha(alpha)
			frame.TargetIndicator:Show()
		else
			frame.TargetIndicator:Hide()
		end
	end

	if frame.StatusIndicator then
		local text = ""
		local r, g, b = 1.0, 1.0, 1.0
		local isPlayerUnit = UnitIsPlayer and UnitIsPlayer(unit) or false
		if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
			text = "DEAD"
			r, g, b = 1.0, 0.25, 0.25
		elseif isPlayerUnit and UnitIsConnected and not UnitIsConnected(unit) then
			text = "OFFLINE"
			r, g, b = 0.70, 0.70, 0.70
		elseif isPlayerUnit and UnitIsAFK and UnitIsAFK(unit) then
			text = "AFK"
			r, g, b = 1.0, 0.90, 0.35
		elseif isPlayerUnit and UnitIsDND and UnitIsDND(unit) then
			text = "DND"
			r, g, b = 1.0, 0.25, 0.25
		end
		frame.StatusIndicator:SetText(text)
		frame.StatusIndicator:SetTextColor(r, g, b, 1.0)
	end

	-- Update ClassificationIndicator (Elite/Rare/Boss badges)
	if frame.ClassificationIndicator then
		local classification = UnitClassification and UnitClassification(unit)
		if classification == "elite" then
			frame.ClassificationIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite")
			-- Elite texture is 64x16; crop center 16 pixels to create square dragon head
			-- (24 to 40 pixels out of 64 = 0.375 to 0.625)
			frame.ClassificationIndicator:SetTexCoord(0.375, 0.625, 0, 1)
			frame.ClassificationIndicator:Show()
		elseif classification == "rare" then
			-- Reset texture coordinates before SetAtlas to ensure clean slate
			frame.ClassificationIndicator:SetTexCoord(0, 1, 0, 1)
			-- SetAtlas with useAtlasSize=false means we control size, but atlas manages its own texture coords
			frame.ClassificationIndicator:SetAtlas("VignetteKill", false)
			frame.ClassificationIndicator:Show()
		elseif classification == "rareelite" then
			-- Reset texture coordinates before SetAtlas to ensure clean slate
			frame.ClassificationIndicator:SetTexCoord(0, 1, 0, 1)
			-- SetAtlas with useAtlasSize=false means we control size, but atlas manages its own texture coords
			frame.ClassificationIndicator:SetAtlas("VignetteKillElite", false)
			frame.ClassificationIndicator:Show()
		elseif classification == "worldboss" then
			frame.ClassificationIndicator:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
			frame.ClassificationIndicator:SetTexCoord(0, 1, 0, 1)  -- Full texture for skull
			frame.ClassificationIndicator:Show()
		else
			frame.ClassificationIndicator:Hide()
		end
	end
end

function addon:RefreshPortraitFrame(frame)
	if not frame then
		return false
	end
	local unit = frame.unit
	if type(unit) ~= "string" or unit == "" then
		return false
	end
	local widget = frame.Portrait
	if not widget then
		return false
	end
	if widget == frame.Portrait2D then
		if type(SetPortraitTexture) == "function" then
			local ok = pcall(SetPortraitTexture, widget, unit)
			return ok
		end
		return false
	end
	if widget == frame.Portrait3D then
		if widget.SetUnit then
			local guid = SafeAPICall(UnitGUID, unit)
			if guid and frame.__sufPortrait3DGuid == guid then
				return true
			end
			local ok = pcall(widget.SetUnit, widget, unit)
			if ok then
				frame.__sufPortrait3DGuid = guid
				-- Zoom in for closer portrait view (1 = head/shoulders, 0 = full body)
				if widget.SetPortraitZoom then
					pcall(widget.SetPortraitZoom, widget, 1)
				end
			end
			return ok
		end
		return false
	end
	return false
end

function addon:RefreshAllTargetGlowIndicators()
	for _, frame in ipairs(self.frames or {}) do
		if frame and frame.TargetIndicator then
			self:UpdateUnitFrameStatusIndicators(frame)
		end
	end
end

function addon:OnPlayerTargetChanged()
	self:ScheduleUpdateDataTextPanel()
	self:RefreshAllTargetGlowIndicators()
	if self.frames then
		for _, frame in ipairs(self.frames) do
			if frame and (frame.sufUnitType == "target" or frame.sufUnitType == "tot") then
				self:UpdateFrameFromDirtyEvents(frame, {
					PLAYER_TARGET_CHANGED = true,
					UNIT_HEALTH = true,
					UNIT_MAXHEALTH = true,
					UNIT_POWER_UPDATE = true,
					UNIT_MAXPOWER = true,
					UNIT_NAME_UPDATE = true,
					UNIT_PORTRAIT_UPDATE = true,
					UNIT_AURA = true,
					UNIT_THREAT_SITUATION_UPDATE = true,
					UNIT_THREAT_LIST_UPDATE = true,
					UNIT_CLASSIFICATION_CHANGED = true,
					UNIT_RANGE = true,
					UNIT_ABSORB_AMOUNT_CHANGED = true,
					UNIT_HEAL_ABSORB_AMOUNT_CHANGED = true,
				})
				if frame.UpdateTags then
					pcall(frame.UpdateTags, frame)
				end
				if frame.HealthValue and frame.HealthValue.UpdateTag then
					pcall(frame.HealthValue.UpdateTag, frame.HealthValue)
				end
				-- Force update oUF elements that respond to threat/classification changes
				if frame.ThreatIndicator and frame.ThreatIndicator.ForceUpdate then
					pcall(frame.ThreatIndicator.ForceUpdate, frame.ThreatIndicator)
				end
				if frame.QuestIndicator and frame.QuestIndicator.ForceUpdate then
					pcall(frame.QuestIndicator.ForceUpdate, frame.QuestIndicator)
				end
				if frame.Range and frame.Range.ForceUpdate then
					pcall(frame.Range.ForceUpdate, frame.Range)
				end
				-- Force update absorb bar on target change
				if frame.AbsorbValue then
					self:UpdateAbsorbValue(frame)
				end
				self:RefreshPortraitFrame(frame)
			end
		end
	end
end

function addon:OnPlayerFlagsChanged()
	-- Mark player frame dirty to update status indicators (AFK/DND/DC)
	if self.frames then
		for _, frame in ipairs(self.frames) do
			if frame and frame.sufUnitType == "player" then
				self:MarkFrameDirty(frame, "PLAYER_FLAGS_CHANGED")
			end
		end
	end
end

function addon:ApplyPortrait(frame)
	local settings = self:GetUnitSettings(frame.sufUnitType)
	local portrait = settings.portrait or { mode = "none", size = 0, position = "LEFT", showClass = false, motion = false }
	local portraitMode = portrait.mode or "none"
	local portraitSize = tonumber(portrait.size) or 0
	local portraitPosition = portrait.position or "LEFT"
	local portraitShowClass = portrait.showClass == true

	if frame.__sufPortraitMode == portraitMode
		and frame.__sufPortraitSize == portraitSize
		and frame.__sufPortraitPosition == portraitPosition
		and frame.__sufPortraitShowClass == portraitShowClass
	then
		return
	end

	if frame.Portrait2D then
		frame.Portrait2D:Hide()
	end
	if frame.Portrait3D then
		frame.Portrait3D:Hide()
		frame.Portrait3D:SetScript("OnUpdate", nil)
	end

	if portraitMode == "none" then
		if frame.DisableElement then
			frame:DisableElement("Portrait")
		end
		frame.Portrait = nil
		frame.__sufPortrait3DGuid = nil
		frame.__sufPortraitMode = portraitMode
		frame.__sufPortraitSize = portraitSize
		frame.__sufPortraitPosition = portraitPosition
		frame.__sufPortraitShowClass = portraitShowClass
		return
	end

	local widget
	if portraitMode == "2D" then
		widget = frame.Portrait2D
	elseif portraitMode == "3D" or portraitMode == "3DMotion" then
		widget = frame.Portrait3D
	end

	if not widget then
		return
	end

	widget:ClearAllPoints()
	if portraitPosition == "RIGHT" then
		widget:SetPoint("LEFT", frame, "RIGHT", 4, 0)
	else
		widget:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	end
	widget:SetSize(portraitSize, portraitSize)
	widget.showClass = portraitShowClass
	widget:Show()

	frame.Portrait = widget
	-- Keep 3D portraits on a GUID-gated manual update path to avoid
	-- frequent model clear/rebind flicker from full portrait event churn.
	if frame.DisableElement then
		pcall(frame.DisableElement, frame, "Portrait")
	end
	frame.__sufPortrait3DGuid = nil
	self:RefreshPortraitFrame(frame)

	if portraitMode == "3DMotion" and widget.SetFacing then
		local facing = 0
		widget:SetScript("OnUpdate", function(_, elapsed)
			facing = facing + elapsed * 0.5
			widget:SetFacing(facing)
		end)
	end

	frame.__sufPortraitMode = portraitMode
	frame.__sufPortraitSize = portraitSize
	frame.__sufPortraitPosition = portraitPosition
	frame.__sufPortraitShowClass = portraitShowClass
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

	if frame.Runes then
		local count = #frame.Runes
		local spacing = self.db.profile.classPowerSpacing
		local totalWidth = frame:GetWidth()
		local barWidth = math.floor((totalWidth - spacing * (count - 1)) / count)
		if barWidth < 4 then
			barWidth = 4
		end
		local runeHeight = math.max(4, math.floor(self.db.profile.classPowerHeight * 0.85))
		local anchor = frame.ClassPowerAnchor or frame
		for index, bar in ipairs(frame.Runes) do
			bar:SetHeight(runeHeight)
			bar:ClearAllPoints()
			if index == 1 then
				bar:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
			else
				bar:SetPoint("LEFT", frame.Runes[index - 1], "RIGHT", spacing, 0)
			end
			bar:SetWidth(barWidth)
		end
	end

	if frame.Stagger then
		local staggerHeight = math.max(4, math.floor(self.db.profile.classPowerHeight * 0.8))
		local anchor = frame.ClassPowerAnchor or frame
		frame.Stagger:SetHeight(staggerHeight)
		frame.Stagger:ClearAllPoints()
		frame.Stagger:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
		frame.Stagger:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
	end

	if frame.Auras then
		local auraSize = self:GetUnitAuraSize(frame.sufUnitType)
		local topAnchor = frame
		if frame.AdditionalPower and frame.AdditionalPower.IsShown and frame.AdditionalPower:IsShown() then
			topAnchor = frame.AdditionalPower
		end
		if frame.ClassPowerAnchor and HasVisibleClassPower(frame) then
			topAnchor = frame.ClassPowerAnchor
		end
		local anchorSig = tostring(topAnchor) .. "|" .. tostring(auraSize)
		if frame.__sufAuraAnchorSig ~= anchorSig then
			frame.Auras.size = auraSize
			frame.Auras.width = auraSize
			frame.Auras.height = auraSize
			frame.Auras:SetHeight(auraSize + 2)
			frame.Auras:ClearAllPoints()
			frame.Auras:SetPoint("BOTTOMLEFT", topAnchor, "TOPLEFT", 0, 4)
			frame.Auras:SetPoint("BOTTOMRIGHT", topAnchor, "TOPRIGHT", 0, 4)
			frame.Auras.needFullUpdate = true
			frame.__sufAuraAnchorSig = anchorSig
		end
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
	Castbar.__owner = self
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

	local healthAnchor = GetStatusBarAnchor(self.Health) or self.Health
	local healingAll = CreateFrame("StatusBar", nil, self)
	healingAll:SetPoint("TOP")
	healingAll:SetPoint("BOTTOM")
	healingAll:SetPoint("LEFT", healthAnchor, "RIGHT")
	healingAll:SetWidth(self.Health:GetWidth())
	healingAll:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingAll:SetStatusBarColor(0.35, 0.95, 0.45, 0.40)
	healingAll:SetFrameLevel(predictionLevel)
	SetMousePassthrough(healingAll)

	local healingPlayer = CreateFrame("StatusBar", nil, self)
	healingPlayer:SetPoint("TOP")
	healingPlayer:SetPoint("BOTTOM")
	healingPlayer:SetPoint("LEFT", healthAnchor, "RIGHT")
	healingPlayer:SetWidth(self.Health:GetWidth())
	healingPlayer:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingPlayer:SetStatusBarColor(0.35, 0.95, 0.45, 0.40)
	healingPlayer:SetFrameLevel(predictionLevel)
	SetMousePassthrough(healingPlayer)

	local healingOther = CreateFrame("StatusBar", nil, self)
	healingOther:SetPoint("TOP")
	healingOther:SetPoint("BOTTOM")
	healingOther:SetPoint("LEFT", GetStatusBarAnchor(healingPlayer) or healthAnchor, "RIGHT")
	healingOther:SetWidth(self.Health:GetWidth())
	healingOther:SetStatusBarTexture(DEFAULT_TEXTURE)
	healingOther:SetStatusBarColor(0.20, 0.75, 0.35, 0.40)
	healingOther:SetFrameLevel(predictionLevel)
	SetMousePassthrough(healingOther)

	local damageAbsorb = CreateFrame("StatusBar", nil, absorbOverlay)
	damageAbsorb:SetPoint("TOP", self.Health, "TOP")
	damageAbsorb:SetPoint("BOTTOM", self.Health, "BOTTOM")
	damageAbsorb:SetPoint("LEFT", healthAnchor, "RIGHT")
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
	absorbCap:SetPoint("LEFT", GetStatusBarAnchor(damageAbsorb) or damageAbsorb, "LEFT", 0, 0)
	absorbCap:SetWidth(2)
	absorbCap:SetColorTexture(0.95, 1.00, 1.00, 0.95)
	absorbCap:Hide()

	local healAbsorb = CreateFrame("StatusBar", nil, absorbOverlay)
	healAbsorb:SetPoint("TOP")
	healAbsorb:SetPoint("BOTTOM")
	healAbsorb:SetPoint("RIGHT", healthAnchor, "RIGHT")
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

local function AttachAuraTooltipScripts(button)
	button.UpdateTooltip = function(widget)
		if GameTooltip and widget.auraInstanceID and widget:GetParent() and widget:GetParent().__owner and widget:GetParent().__owner.unit then
			if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then
				return
			end
			GameTooltip:SetUnitAuraByAuraInstanceID(widget:GetParent().__owner.unit, widget.auraInstanceID)
		end
	end
	button:SetScript("OnEnter", function(widget)
		if GameTooltip and widget:IsVisible() then
			if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then
				return
			end
			local parent = widget:GetParent()
			local anchorType = (parent and parent.tooltipAnchor) or "ANCHOR_BOTTOMRIGHT"
			local offsetX = (parent and parent.tooltipOffsetX) or 0
			local offsetY = (parent and parent.tooltipOffsetY) or 0
			GameTooltip:SetOwner(widget, anchorType, offsetX, offsetY)
			widget:UpdateTooltip()
		end
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:Hide()
		end
	end)
end

local function CreateAuras(self)
	local owner = addon
	local Auras = owner:AcquireRuntimeFrame("Frame", self, "SUF_AuraContainer")
	local auraSize = owner:GetUnitAuraSize(self.sufUnitType)
	local auraCfg = owner:GetUnitAuraLayoutSettings(self.sufUnitType)
	Auras:Show()
	Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
	Auras:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 4)
	Auras:SetHeight(auraSize + 2)
	Auras.size = auraSize
	Auras.width = auraSize
	Auras.height = auraSize
	Auras.spacingX = tonumber(auraCfg.spacingX) or 4
	Auras.spacingY = tonumber(auraCfg.spacingY) or 4
	Auras.maxCols = math.max(1, tonumber(auraCfg.maxCols) or 8)
	Auras.initialAnchor = tostring(auraCfg.initialAnchor or "BOTTOMLEFT")
	Auras.growthX = tostring(auraCfg.growthX or "RIGHT")
	Auras.growthY = tostring(auraCfg.growthY or "UP")
	Auras.sortMethod = tostring(auraCfg.sortMethod or "DEFAULT")
	Auras.sortDirection = tostring(auraCfg.sortDirection or "ASC")
	Auras.onlyShowPlayer = auraCfg.onlyShowPlayer == true
	Auras.showStealableBuffs = auraCfg.showStealableBuffs ~= false
	Auras.reanchorIfVisibleChanged = false
	Auras.numBuffs = math.max(0, tonumber(auraCfg.numBuffs) or 8)
	Auras.numDebuffs = math.max(0, tonumber(auraCfg.numDebuffs) or 8)
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

		AttachAuraTooltipScripts(button)

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

function addon:RegisterSharedMediaAssets()
	if not LSM or not LSM.Register then
		return
	end
	local entries = {
		{ kind = "font", name = "SUF Expressway", path = "Interface\\AddOns\\SimpleUnitFrames\\Media\\Fonts\\Expressway.ttf" },
		{ kind = "font", name = "SUF Avante", path = "Interface\\AddOns\\SimpleUnitFrames\\Media\\Fonts\\Avante.ttf" },
		{ kind = "statusbar", name = "SUF ThinStripes", path = "Interface\\AddOns\\SimpleUnitFrames\\Media\\Textures\\ThinStripes.png" },
		{ kind = "statusbar", name = "SUF Stripes", path = "Interface\\AddOns\\SimpleUnitFrames\\Media\\Textures\\Stripes.png" },
	}
	for i = 1, #entries do
		local entry = entries[i]
		pcall(LSM.Register, LSM, entry.kind, entry.name, entry.path)
	end
end

function addon:SetupToolkitAPI()
	self.API = self.API or {}
	self.API.Clamp = function(value, minimum, maximum, fallback)
		local n = tonumber(value)
		if not n then
			return fallback
		end
		if minimum and n < minimum then
			n = minimum
		end
		if maximum and n > maximum then
			n = maximum
		end
		return n
	end
	self.API.Round = RoundNumber
	self.API.ShortValue = FormatCompactValue
	self.API.RegisterAnyClicks = function(frame)
		if frame and frame.RegisterForClicks then
			frame:RegisterForClicks("AnyUp")
		end
	end
	self.API.GetStatusReportText = function()
		return addon:BuildStatusReportText()
	end
end

function addon:PlayWindowOpenAnimation(frame)
	if not frame then
		return
	end
	local cfg = self:GetEnhancementSettings()
	if cfg.uiOpenAnimation == false then
		return
	end
	if not frame.CreateAnimationGroup then
		return
	end

	frame._sufOpenAnimGroup = frame._sufOpenAnimGroup or frame:CreateAnimationGroup()
	local group = frame._sufOpenAnimGroup
	if not group then
		return
	end
	if not group._sufHooksInstalled then
		local function FinalizeOpenAnimation()
			if not frame or not frame.SetAlpha then
				return
			end
			frame:SetAlpha(1)
			if frame._sufOpenAnimRestore then
				local restore = frame._sufOpenAnimRestore
				frame:ClearAllPoints()
				frame:SetPoint(restore[1], restore[2], restore[3], restore[4], restore[5])
				frame._sufOpenAnimRestore = nil
			end
		end
		group:SetScript("OnFinished", FinalizeOpenAnimation)
		group:SetScript("OnStop", FinalizeOpenAnimation)
		group._sufHooksInstalled = true
	end

	local duration = math.max(0.05, math.min(0.60, tonumber(cfg.uiOpenAnimationDuration) or 0.18))
	local offsetY = math.max(-40, math.min(40, tonumber(cfg.uiOpenAnimationOffsetY) or 12))

	if not group._sufAlpha then
		local alpha = group:CreateAnimation("Alpha")
		alpha:SetDuration(duration)
		if alpha.SetSmoothing then
			alpha:SetSmoothing("OUT")
		elseif alpha.SetEasing then
			alpha:SetEasing("outquadratic")
		end
		if alpha.SetFromAlpha and alpha.SetToAlpha then
			alpha:SetFromAlpha(0)
			alpha:SetToAlpha(1)
		elseif alpha.SetChange then
			alpha:SetChange(1)
		end
		group._sufAlpha = alpha
	end
	if not group._sufMove then
		local move = group:CreateAnimation("Translation")
		move:SetDuration(duration)
		if move.SetSmoothing then
			move:SetSmoothing("OUT")
		elseif move.SetEasing then
			move:SetEasing("outquadratic")
		end
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
	frame:SetAlpha(1)
	if offsetY ~= 0 then
		frame:SetAlpha(0)
	end
	group:Play()
end

function addon:PrepareWindowForDisplay(frame)
	if not frame then
		return
	end
	if frame._sufOpenAnimGroup and frame._sufOpenAnimGroup.IsPlaying and frame._sufOpenAnimGroup:IsPlaying() then
		frame._sufOpenAnimGroup:Stop()
	end
	if frame._sufOpenAnimRestore then
		local restore = frame._sufOpenAnimRestore
		frame:ClearAllPoints()
		frame:SetPoint(restore[1], restore[2], restore[3], restore[4], restore[5])
		frame._sufOpenAnimRestore = nil
	end
	if frame.SetAlpha then
		frame:SetAlpha(1)
	end
	if frame.SetScale then
		local scale = tonumber(frame:GetScale()) or 1
		if scale <= 0 then
			frame:SetScale(1)
		end
	end
	if frame.GetParent and frame:GetParent() ~= UIParent and frame.SetParent then
		frame:SetParent(UIParent)
	end
	if self.ApplySUFControlSkinsInFrame then
		self:ApplySUFControlSkinsInFrame(frame)
	elseif self.ApplySUFButtonSkinsInFrame then
		self:ApplySUFButtonSkinsInFrame(frame)
	end
end

function addon:UpdateSingleFrame(frame)
	if not frame then
		return
	end
	local unitType = frame.sufUnitType
	if unitType == "player" or unitType == "target" or unitType == "tot" then
		local optionsOpen = self.optionsFrame and self.optionsFrame.IsShown and self.optionsFrame:IsShown()
		if not optionsOpen then
			local now = (GetTime and GetTime()) or 0
			local last = tonumber(frame.__sufLastFullRefreshAt) or 0
			if now - last < 1.0 then
				return
			end
			frame.__sufLastFullRefreshAt = now
		end
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
	self:UpdateUnitFrameUnlockHandle(frame)
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

local function GetUnitSelectionTypeSafe(unit, considerSelectionInCombatHostile)
	local ouf = addon and addon.oUF
	local private = ouf and ouf.Private
	local fn = private and private.unitSelectionType
	if type(fn) == "function" then
		return fn(unit, considerSelectionInCombatHostile)
	end
	if type(UnitSelectionType) == "function" then
		return UnitSelectionType(unit)
	end
	return nil
end

function addon:ConfigureHealthElementOverrides(frame)
	local element = frame and frame.Health
	if not element then
		return
	end

	local function SetBarMinMax(bar, maxValue)
		if not bar then
			return
		end
		if maxValue ~= nil then
			bar:SetMinMaxValues(0, maxValue)
		end
	end

	local function SetBarValue(bar, value, smoothing)
		if not bar then
			return
		end
		if value == nil then
			value = 0
		end
		bar:SetValue(value, smoothing)
	end

	local function SetPredictionBarValue(bar, rawValue, maxValue)
		if not bar then
			return
		end
		SetBarMinMax(bar, maxValue)
		SetBarValue(bar, rawValue)
	end

	local function ResolveColorRGB(color)
		if not color then
			return nil, nil, nil
		end
		local r, g, b
		if color.GetRGB then
			local ok, rr, gg, bb = pcall(color.GetRGB, color)
			if ok then
				r, g, b = rr, gg, bb
			end
		elseif type(color) == "table" then
			r = color.r or color[1]
			g = color.g or color[2]
			b = color.b or color[3]
		end

		if r == nil or g == nil or b == nil then
			return nil, nil, nil
		end

		r = SafeNumber(r, nil)
		g = SafeNumber(g, nil)
		b = SafeNumber(b, nil)
		if r == nil or g == nil or b == nil then
			return nil, nil, nil
		end
		return r, g, b
	end

	element.UpdateColor = function(owner, eventName, unit)
		if not unit or owner.unit ~= unit then
			return
		end

		local color
		if element.colorDisconnected and UnitIsPlayer(unit) and not UnitIsConnected(unit) then
			color = owner.colors.disconnected
		elseif element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
			color = owner.colors.tapped
		elseif element.colorThreat and not UnitPlayerControlled(unit) then
			local threatStatus = SafeNumber(SafeAPICall(UnitThreatSituation, "player", unit), nil)
			if threatStatus and owner.colors and owner.colors.threat then
				color = owner.colors.threat[threatStatus]
			end
		elseif (element.colorClass and (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
			or (element.colorClassNPC and not (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
			or (element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
			local classToken
			if UnitClass then
				local ok, _, token = pcall(UnitClass, unit)
				if ok then
					classToken = SafeText(token, nil)
				end
			end
			if classToken and owner.colors and owner.colors.class then
				color = owner.colors.class[classToken]
			end
		elseif element.colorSelection then
			local selectionType = SafeNumber(GetUnitSelectionTypeSafe(unit, element.considerSelectionInCombatHostile), nil)
			if selectionType and owner.colors and owner.colors.selection then
				color = owner.colors.selection[selectionType]
			end
		elseif element.colorReaction then
			local reaction = SafeNumber(SafeAPICall(UnitReaction, unit, "player"), nil)
			if reaction and owner.colors and owner.colors.reaction then
				color = owner.colors.reaction[reaction]
			end
		elseif element.colorSmooth and owner.colors and owner.colors.health and owner.colors.health.GetCurve and element.values and element.values.EvaluateCurrentHealthPercent then
			local curve = owner.colors.health:GetCurve()
			if curve then
				color = element.values:EvaluateCurrentHealthPercent(curve)
			end
		elseif element.colorHealth then
			color = owner.colors.health
		end

		if color then
			local r, g, b = ResolveColorRGB(color)
			if r ~= nil and g ~= nil and b ~= nil then
				element:SetStatusBarColor(r, g, b)
			end
		end
		if element.PostUpdateColor then
			element:PostUpdateColor(unit, color)
		end
	end

	element.Override = function(owner, eventName, unit)
		if not unit or owner.unit ~= unit then
			return
		end

		if element.PreUpdate then
			element:PreUpdate(unit)
		end

		if UnitGetDetailedHealPrediction and element.values then
			UnitGetDetailedHealPrediction(unit, "player", element.values)
		end

		local max = element.values and element.values.GetMaximumHealth and element.values:GetMaximumHealth() or nil
		if max == nil and UnitHealthMax then
			max = UnitHealthMax(unit)
		end
		if max == nil then
			max = element.max or 1
		end
		SetBarMinMax(element, max)

		local cur = element.values and element.values.GetCurrentHealth and element.values:GetCurrentHealth() or nil
		if cur == nil and UnitHealth then
			cur = UnitHealth(unit)
		end
		if cur == nil then
			cur = element.cur
		end
		if cur == nil then
			cur = 0
		end

		local isPlayerUnit = UnitIsPlayer(unit)
		local isConnected = UnitIsConnected(unit)
		if isPlayerUnit and (isConnected == false) then
			SetBarValue(element, max, element.smoothing)
		else
			SetBarValue(element, cur, element.smoothing)
		end

		element.cur = cur
		element.max = max

		if element.values and (element.HealingAll or element.HealingPlayer or element.HealingOther or element.OverHealIndicator) then
			local allHeal, playerHeal, otherHeal, healClamped = element.values:GetIncomingHeals()
			if element.HealingAll then
				SetPredictionBarValue(element.HealingAll, allHeal, max)
			end
			if element.HealingPlayer then
				SetPredictionBarValue(element.HealingPlayer, playerHeal, max)
			end
			if element.HealingOther then
				SetPredictionBarValue(element.HealingOther, otherHeal, max)
			end
			if element.OverHealIndicator then
				element.OverHealIndicator:SetAlphaFromBoolean(healClamped, 1, 0)
			end
		end

		if element.values and (element.DamageAbsorb or element.OverDamageAbsorbIndicator) then
			local damageAbsorbAmount, damageAbsorbClamped = element.values:GetDamageAbsorbs()
			if element.DamageAbsorb then
				SetPredictionBarValue(element.DamageAbsorb, damageAbsorbAmount, max)
			end
			if element.OverDamageAbsorbIndicator then
				element.OverDamageAbsorbIndicator:SetAlphaFromBoolean(damageAbsorbClamped, 1, 0)
			end
		end

		if element.values and (element.HealAbsorb or element.OverHealAbsorbIndicator) then
			local healAbsorbAmount, healAbsorbClamped = element.values:GetHealAbsorbs()
			if element.HealAbsorb then
				SetPredictionBarValue(element.HealAbsorb, healAbsorbAmount, max)
			end
			if element.OverHealAbsorbIndicator then
				element.OverHealAbsorbIndicator:SetAlphaFromBoolean(healAbsorbClamped, 1, 0)
			end
		end

		local lossPerc = 0
		if element.TempLoss then
			lossPerc = GetUnitTotalModifiedMaxHealthPercent and GetUnitTotalModifiedMaxHealthPercent(unit) or 0
			SetBarValue(element.TempLoss, lossPerc, element.smoothing)
		end

		if element.PostUpdate then
			element:PostUpdate(unit, cur, max, lossPerc)
		end
	end
end

function addon:SchedulePluginUpdate(unitType)
	self._pendingPluginUpdates = self._pendingPluginUpdates or {}
	if unitType and self:IsGroupUnitType(unitType) then
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

-- Custom tooltip handler for header-spawned frames that intelligently determines the unit
local function SUF_UpdateTooltip(frame)
	-- Try to get a valid unit token
	local unitToken = frame.unit
	
	-- Fallback: try secure attribute
	if not unitToken or (unitToken == 'party' or unitToken:match('^party%d+$')) and UnitExists(unitToken) == false then
		unitToken = frame:GetAttribute('unit') or frame:GetAttribute('oUF-guessUnit')
	end
	
	-- If unit is still invalid, try to guess based on frame name for party frames
	if not unitToken or not UnitExists(unitToken) then
		local frameName = frame:GetName() or ''
		if frameName:match('Party') then
			-- This is a party frame, might be showing player solo - try player unit
			if UnitExists('player') then
				unitToken = 'player'
			else
				unitToken = nil
			end
		end
	end
	
	-- Now try to show the tooltip
	GameTooltip_SetDefaultAnchor(GameTooltip, frame)
	if unitToken and GameTooltip:SetUnit(unitToken, frame.hideStatusOnTooltip) then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK)
		GameTooltip:Show()
		frame.UpdateTooltip = SUF_UpdateTooltip
	else
		frame.UpdateTooltip = nil
	end
end

local function SUF_OnEnter(frame)
	SUF_UpdateTooltip(frame)
end

local function SUF_OnLeave(frame)
	frame.UpdateTooltip = nil
	GameTooltip:FadeOut()
end

local function HookTooltipHoverProxy(widget, ownerFrame)
	if not widget or not ownerFrame or widget.__sufTooltipHoverProxy then
		return
	end
	if widget.EnableMouse then
		widget:EnableMouse(true)
	end
	if widget.SetMouseClickEnabled then
		widget:SetMouseClickEnabled(false)
	end
	if widget.SetMouseMotionEnabled then
		widget:SetMouseMotionEnabled(true)
	end
	if widget.SetPropagateMouseClicks then
		widget:SetPropagateMouseClicks(true)
	end
	if widget.SetPropagateMouseMotion then
		widget:SetPropagateMouseMotion(true)
	end
	if widget.HookScript then
		widget:HookScript("OnEnter", function()
			SUF_OnEnter(ownerFrame)
		end)
		widget:HookScript("OnLeave", function()
			SUF_OnLeave(ownerFrame)
		end)
		widget.__sufTooltipHoverProxy = true
	end
end

function addon:Style(frame, unit)
	-- Ensure frame.unit is set for tooltip handlers (especially important for header-spawned frames like solo party)
	if not frame.unit then
		frame.unit = unit or frame:GetAttribute('unit') or 'player'
	end
	
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
	self:QueueOrRun(function()
		frame:SetAttribute("type2", "togglemenu")
		frame:SetAttribute("*type2", "togglemenu")
	end, "frame-menu-" .. tostring(frame:GetName() or frame.sufUnitType or frame.unit or "unknown"))
	if not frame.__sufLegacyMenu then
		frame.__sufLegacyMenu = frame.menu or UnitPopup_ShowMenu
	end
	frame.menu = function(widget)
		addon:OpenUnitContextMenu(widget)
	end
	-- Use custom tooltip handlers that work better with header-spawned frames
	frame:SetScript("OnEnter", SUF_OnEnter)
	frame:SetScript("OnLeave", SUF_OnLeave)

	local size = self.db.profile.sizes[frame.sufUnitType]
	frame:SetSize(size.width, size.height)
	if frame.unlockHandle then
		frame.unlockHandle:SetAllPoints(frame)
	end

	local Health = CreateStatusBar(frame, size.height)
	Health:SetAllPoints(frame)
	Health.colorClass = true
	Health.colorReaction = true
	SetMousePassthrough(Health)
	frame.Health = Health
	HookRightClickProxy(Health, frame)
	HookTooltipHoverProxy(Health, frame)
	CreateHealthPrediction(frame)
	self:ConfigureHealthElementOverrides(frame)
	if frame.Health then
		local originalPostUpdate = frame.Health.PostUpdate
		frame.Health.PostUpdate = function(element, unit, cur, max, lossPerc)
			if originalPostUpdate then
				originalPostUpdate(element, unit, cur, max, lossPerc)
			end
			if unit and UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
				element:SetValue(0, element.smoothing)
			elseif unit and UnitIsPlayer(unit) and UnitIsConnected and UnitIsConnected(unit) == false then
				element:SetValue(max or element.max or 1, element.smoothing)
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
	HookTooltipHoverProxy(Power, frame)

	local PowerBG = Power:CreateTexture(nil, "BACKGROUND")
	PowerBG:SetAllPoints(Power)
	PowerBG:SetColorTexture(0, 0, 0, 0.6)
	frame.PowerBG = PowerBG
	HookRightClickProxy(PowerBG, frame)

	local PowerPrediction = CreateFrame("StatusBar", nil, Power)
	PowerPrediction:SetPoint("TOP", Power, "TOP", 0, 0)
	PowerPrediction:SetPoint("BOTTOM", Power, "BOTTOM", 0, 0)
	PowerPrediction:SetPoint("RIGHT", Power, "RIGHT", 0, 0)
	PowerPrediction:SetWidth(Power:GetWidth() or 1)
	PowerPrediction:SetStatusBarTexture(DEFAULT_TEXTURE)
	PowerPrediction:SetStatusBarColor(1, 0.9, 0.25, 0.70)
	PowerPrediction:SetReverseFill(true)
	PowerPrediction:Hide()
	SetMousePassthrough(PowerPrediction)
	frame.PowerPrediction = PowerPrediction

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
	HookTooltipHoverProxy(TextOverlay, frame)

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
	IndicatorFrame:SetClipsChildren(false)
	IndicatorFrame:SetFrameStrata("HIGH")
	IndicatorFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
	SetMousePassthrough(IndicatorFrame)
	frame.IndicatorFrame = IndicatorFrame
	HookTooltipHoverProxy(IndicatorFrame, frame)

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

	-- ThreatIndicator: Only for units that can have threat (not player/pet)
	if frame.sufUnitType ~= "player" and frame.sufUnitType ~= "pet" then
		local ThreatIndicator = IndicatorFrame.__sufThreatIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
		ThreatIndicator:SetDrawLayer("OVERLAY", 6)
		if frame.sufUnitType == "party" or frame.sufUnitType == "raid" then
			ThreatIndicator.feedbackUnit = "target"
		else
			ThreatIndicator.feedbackUnit = nil
		end
		ThreatIndicator.PostUpdate = function(element, _, status)
			if status ~= 3 then
				element:Hide()
			end
		end
		IndicatorFrame.__sufThreatIndicator = ThreatIndicator
		frame.ThreatIndicator = ThreatIndicator
	else
		frame.ThreatIndicator = nil
	end

	-- QuestIndicator: Only for NPC units (not player/pet/party/raid)
	if frame.sufUnitType ~= "player" and frame.sufUnitType ~= "pet" and 
	   frame.sufUnitType ~= "party" and frame.sufUnitType ~= "raid" then
		local QuestIndicator = IndicatorFrame.__sufQuestIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
		QuestIndicator:SetDrawLayer("OVERLAY", 6)
		IndicatorFrame.__sufQuestIndicator = QuestIndicator
		frame.QuestIndicator = QuestIndicator
	else
		frame.QuestIndicator = nil
	end

	local PvPClassificationIndicator = IndicatorFrame.__sufPvPClassificationIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
	PvPClassificationIndicator.useAtlasSize = true
	PvPClassificationIndicator:SetDrawLayer("OVERLAY", 6)
	IndicatorFrame.__sufPvPClassificationIndicator = PvPClassificationIndicator
	frame.PvPClassificationIndicator = PvPClassificationIndicator

	-- ClassificationIndicator: Shows Elite/Rare/Boss badges on NPCs
	if frame.sufUnitType ~= "player" and frame.sufUnitType ~= "pet" and
	   frame.sufUnitType ~= "party" and frame.sufUnitType ~= "raid" then
		local ClassificationIndicator = IndicatorFrame.__sufClassificationIndicator or IndicatorFrame:CreateTexture(nil, "OVERLAY")
		ClassificationIndicator:SetSize(18, 18)
		ClassificationIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 8, 8)
		ClassificationIndicator:SetDrawLayer("OVERLAY", 7)
		ClassificationIndicator.useAtlasSize = false  -- We'll manage size ourselves for consistency
		IndicatorFrame.__sufClassificationIndicator = ClassificationIndicator
		frame.ClassificationIndicator = ClassificationIndicator
	else
		frame.ClassificationIndicator = nil
	end

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

	local TargetIndicator = IndicatorFrame.__sufTargetIndicator or CreateFrame("Frame", nil, frame, "BackdropTemplate")
	TargetIndicator:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3)
	TargetIndicator:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
	TargetIndicator:SetFrameStrata(frame:GetFrameStrata() or "MEDIUM")
	TargetIndicator:SetFrameLevel((frame:GetFrameLevel() or 1) + 1)
	TargetIndicator:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 2,
	})
	TargetIndicator:SetBackdropColor(0, 0, 0, 0)
	TargetIndicator:SetBackdropBorderColor(0.95, 0.85, 0.25, 0.92)
	TargetIndicator:Hide()
	IndicatorFrame.__sufTargetIndicator = TargetIndicator
	frame.TargetIndicator = TargetIndicator

	local StatusIndicator = TextOverlay.__sufStatusIndicator or CreateFontString(TextOverlay, 13, "OUTLINE")
	StatusIndicator:SetPoint("CENTER", frame, "CENTER", 0, 0)
	StatusIndicator:SetJustifyH("CENTER")
	StatusIndicator:SetDrawLayer("OVERLAY", 7)
	StatusIndicator:SetText("")
	TextOverlay.__sufStatusIndicator = StatusIndicator
	frame.StatusIndicator = StatusIndicator

	-- Add SetAlphaFromBoolean method for Range element
	if not frame.SetAlphaFromBoolean then
		frame.SetAlphaFromBoolean = function(self, condition, trueAlpha, falseAlpha)
			self:SetAlpha(condition and trueAlpha or falseAlpha)
		end
	end

	frame.Fader = frame.Fader or {}
	-- Only apply Range element to unit types that can go out of range
	-- (tot, focus, boss; party/raid are handled by oUF directly)
	if frame.sufUnitType == "tot" or frame.sufUnitType == "focus" or frame.sufUnitType == "boss" then
		if not frame.Range then
			frame.Range = {
				insideAlpha = 1,
				outsideAlpha = 0.55,
			}
		elseif type(frame.Range) == "table" then
			frame.Range.insideAlpha = frame.Range.insideAlpha or 1
			frame.Range.outsideAlpha = frame.Range.outsideAlpha or 0.55
		end
		
		-- Override Range element for non-party frames to work with target/tot/focus/boss
		frame.Range.Override = function(self, event)
			local element = self.Range
			local unit = self.unit
			
			if element.PreUpdate then
				element:PreUpdate()
			end
			
			local inRange
			-- For non-party frames, check if unit exists and is connected
			if UnitExists(unit) and UnitIsConnected(unit) then
				inRange = UnitInRange(unit)
				if inRange == nil then
					-- UnitInRange returns nil for invalid units or units that don't support range
					-- Default to in-range (full alpha) for these cases
					inRange = true
				end
				self:SetAlphaFromBoolean(inRange, element.insideAlpha, element.outsideAlpha)
			else
				-- Unit doesn't exist or is offline, use full alpha
				self:SetAlpha(element.insideAlpha)
			end
			
			if element.PostUpdate then
				return element:PostUpdate(self, inRange, UnitExists(unit) and UnitIsConnected(unit))
			end
		end
	end
	if self:IsGroupUnitType(frame.sufUnitType) then
		self:EnsureRaidDebuffsElement(frame)
		self:EnsureAuraWatchElement(frame)
	end

	local Portrait2D = frame:CreateTexture(nil, "ARTWORK")
	Portrait2D:SetSize(32, 32)
	Portrait2D:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	SetMousePassthrough(Portrait2D)
	frame.Portrait2D = Portrait2D
	HookRightClickProxy(Portrait2D, frame)
		HookTooltipHoverProxy(Portrait2D, frame)

	local Portrait3D = CreateFrame("PlayerModel", nil, frame)
	Portrait3D:SetSize(32, 32)
	Portrait3D:SetPoint("RIGHT", frame, "LEFT", -4, 0)
	SetMousePassthrough(Portrait3D)
	frame.Portrait3D = Portrait3D
	HookRightClickProxy(Portrait3D, frame)
		HookTooltipHoverProxy(Portrait3D, frame)

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
		HookTooltipHoverProxy(AdditionalPower, frame)

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
			HookTooltipHoverProxy(frame.ClassPowerAnchor, frame)
		end

		local playerClass = UnitClassBase and UnitClassBase("player") or select(2, UnitClass("player"))
		if playerClass == "DEATHKNIGHT" and not frame.Runes then
			-- Per Blizzard_UnitFrame/Mainline/RuneFrame.lua line 5: DK runes are gated by UnitClass("player").
			local Runes = {}
			local runeHeight = math.max(4, math.floor(self.db.profile.classPowerHeight * 0.85))
			local runeAnchor = frame.ClassPowerAnchor or frame
			for index = 1, 6 do
				local bar = CreateStatusBar(frame, runeHeight)
				bar:SetPoint("TOPLEFT", runeAnchor, "TOPLEFT", 0, 0)
				bar:SetWidth(12)
				SetMousePassthrough(bar)
				Runes[index] = bar
			end
			frame.Runes = Runes
		end
		if playerClass == "MONK" and not frame.Stagger then
			-- Per Blizzard_UnitFrame/Mainline/MonkStaggerBar.lua line 69-74: Stagger uses UnitStagger/UnitHealthMax.
			local Stagger = CreateStatusBar(frame, math.max(4, math.floor(self.db.profile.classPowerHeight * 0.8)))
			local anchor = frame.ClassPowerAnchor or frame
			Stagger:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
			Stagger:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
			Stagger.smoothing = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or nil
			SetMousePassthrough(Stagger)
			frame.Stagger = Stagger
		end
	end

	if unit == "player" or unit == "target" or (unit and unit:match("^boss%d*$")) then
		local anchor = frame.ClassPowerAnchor
		CreateCastbar(frame, self.db.profile.castbarHeight, anchor)
	end

	if frame.sufUnitType == "player" or frame.sufUnitType == "target" or frame.sufUnitType == "focus" or frame.sufUnitType == "pet" or frame.sufUnitType == "tot" or frame.sufUnitType == "party" or frame.sufUnitType == "raid" or frame.sufUnitType == "boss" then
		if not frame.Auras then
			CreateAuras(frame)
		end
	end

	self:ApplyTags(frame)
	self:ApplyMedia(frame)
	self:ApplySize(frame)
	self:ApplyIndicators(frame)
	self:EnableUnitFrameEditModeDrag(frame)
	self:UpdateUnitFrameUnlockHandle(frame)
	self:UpdateUnitFrameStatusIndicators(frame)
	local function FlushQueuedDirtyEvents(widget)
		local events = widget.__sufDirtyEvents
		widget.__sufDirtyQueued = false
		widget.__sufDirtyEvents = {}
		addon:UpdateFrameFromDirtyEvents(widget, events)
		ClearTableInPlace(events)
	end
	local function ShouldAllowFullRefreshPassthrough(eventName)
		if type(eventName) ~= "string" then
			return false
		end
		if eventName == "SimpleUnitFrames_Update" then
			return true
		end
		if eventName == "RefreshUnit" then
			return true
		end
		if eventName == "ForceUpdate" then
			return true
		end
		return false
	end
	local function ShouldApplyAntiFlickerGuards(unitType)
		return type(unitType) == "string" and unitType ~= ""
	end
	local function TryIncrementalEventUpdate(widget, eventName, statKey)
		if type(eventName) ~= "string" or eventName == "" then
			return false
		end
		if eventName == "OnShow" then
			return true
		end
		addon:UpdateFrameFromDirtyEvents(widget, { [eventName] = true })
		return true
	end
	if frame.UpdateAll and not frame.__sufOriginalUpdateAll then
		frame.__sufOriginalUpdateAll = frame.UpdateAll
		frame.UpdateAll = function(widget, ...)
			local eventName = select(1, ...)
			local unitType = widget and widget.sufUnitType
			if ShouldApplyAntiFlickerGuards(unitType) and eventName == "OnUpdate" then
				return
			end
			local events = widget.__sufDirtyEvents
			if widget.__sufDirtyQueued and type(events) == "table" and next(events) ~= nil then
				FlushQueuedDirtyEvents(widget)
				return
			end
			if ShouldApplyAntiFlickerGuards(unitType) then
				if not ShouldAllowFullRefreshPassthrough(eventName) then
					if TryIncrementalEventUpdate(widget, eventName, "WrappedUpdateAllIncremental") then
						return
					end
					return
				end
			end
			return widget:__sufOriginalUpdateAll(...)
		end
	end
	if frame.UpdateAllElements and not frame.__sufOriginalUpdateAllElements then
		frame.__sufOriginalUpdateAllElements = frame.UpdateAllElements
		frame.UpdateAllElements = function(widget, ...)
			local eventName = select(1, ...)
			local unitType = widget and widget.sufUnitType
			if ShouldApplyAntiFlickerGuards(unitType) and eventName == "OnUpdate" then
				return
			end
			local events = widget.__sufDirtyEvents
			if widget.__sufDirtyQueued and type(events) == "table" and next(events) ~= nil then
				FlushQueuedDirtyEvents(widget)
				return
			end
			if ShouldApplyAntiFlickerGuards(unitType) then
				if not ShouldAllowFullRefreshPassthrough(eventName) then
					if TryIncrementalEventUpdate(widget, eventName, "WrappedUpdateAllElementsIncremental") then
						return
					end
					return
				end
			end
			return widget:__sufOriginalUpdateAllElements(...)
		end
	end
	if not frame.__sufOriginalUpdate then
		frame.__sufOriginalUpdate = frame.Update
		frame.Update = function(widget, ...)
			local events = widget.__sufDirtyEvents
			if widget.__sufDirtyQueued and type(events) == "table" and next(events) ~= nil then
				FlushQueuedDirtyEvents(widget)
				return
			end
			if widget.__sufOriginalUpdate then
				return widget:__sufOriginalUpdate(...)
			end
		end
	end
	table.insert(self.frames, frame)
	self:InvalidateFrameEventIndex()
	-- Initialize status indicators for the player frame (AFK/DND/DC status)
	if frame.sufUnitType == "player" then
		self:UpdateUnitFrameStatusIndicators(frame)
	end
	-- Schedule ApplyMedia immediately after frame creation for all frames
	-- This ensures absorb bar and all media elements are initialized on login/creation
	-- Must run before the throttled UpdateSingleFrame to show all UI elements immediately
	self:QueueOrRun(function()
		self:ApplyMedia(frame)
	end, {
		key = "InitMedia_" .. tostring(frame:GetName() or frame.sufUnitType or "unknown"),
		type = "FRAME_MEDIA_INIT",
		priority = "HIGH",
	})
end

function addon:HookAnchor(frame, anchorName)
	local anchor = _G[anchorName]
	frame:ClearAllPoints()
	if anchor then
		frame:SetPoint("CENTER", anchor, "CENTER")
	else
		frame:SetPoint("CENTER", UIParent, "CENTER")
	end
	if frame and frame.__sufEditMoverKey then
		self:ApplyStoredMoverPosition(frame, frame.__sufEditMoverKey, { "CENTER", anchorName, "CENTER", 0, 0 })
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
	self:InvalidateFrameEventIndex()
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
		-- Expose addon globally AFTER spawning completes (safe from oUF lookup)
		_G.SimpleUnitFrames = self
		print("SpawnFrames: Exposed _G.SimpleUnitFrames, IndicatorPoolManager exists: " .. tostring(self.IndicatorPoolManager ~= nil))
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
	self:UpdateBlizzardFrames()
	self:TrySpawnGroupHeaders()
	self:UpdateDataTextPanel()
end

function addon:GetPartyHeaderYOffset()
	local partyCfg = (self.db and self.db.profile and self.db.profile.party) or {}
	local spacing = math.max(0, math.min(40, tonumber(partyCfg.spacing) or 10))
	local powerHeight = tonumber(self.db and self.db.profile and self.db.profile.powerHeight) or 8
	local size = self.db and self.db.profile and self.db.profile.sizes and self.db.profile.sizes.party
	local frameHeight = tonumber(size and size.height) or 26
	-- Party header initial config starts at 26px; account for extra frame height plus the lower power row.
	local extraHeight = math.max(0, frameHeight - 26)
	local auraExtraHeight = 0
	local partyUnitCfg = self:GetUnitSettings("party")
	local auraCfg = partyUnitCfg and partyUnitCfg.auras
	if auraCfg and auraCfg.enabled ~= false then
		local maxCols = math.max(1, tonumber(auraCfg.maxCols) or 1)
		local numBuffs = math.max(0, tonumber(auraCfg.numBuffs) or 0)
		local numDebuffs = math.max(0, tonumber(auraCfg.numDebuffs) or 0)
		local maxVisibleAuras = math.max(numBuffs, numDebuffs)
		if maxVisibleAuras > 0 then
			local auraRows = math.max(1, math.ceil(maxVisibleAuras / maxCols))
			local auraSize = tonumber(partyUnitCfg and partyUnitCfg.auraSize) or self:GetUnitAuraSize("party") or 18
			local spacingY = math.max(0, tonumber(auraCfg.spacingY) or 4)
			auraExtraHeight = 8 + (auraRows * auraSize) + ((auraRows - 1) * spacingY)
		end
	end
	local effectiveSpacing = spacing + extraHeight + powerHeight + 3 + auraExtraHeight
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

	self:QueueOrRun(function()
		header:SetAttribute("showPlayer", showPlayer)
		header:SetAttribute("showSolo", showSolo)
		header:SetAttribute("yOffset", yOffset)
	end, "party-header-attrs")
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
			local unitType = frame.sufUnitType or "frame"
			self:QueueOrRun(function()
				UnregisterStateDriver(frame, "visibility")
			end, "visibility-driver-skip-" .. tostring(frame:GetName() or unitType))
		end
	end

	for _, header in pairs(self.headers or {}) do
		if header then
			if header.__sufVisibilityDriver == driver then
			else
				header.__sufVisibilityDriver = driver
				local headerName = tostring(header:GetName() or "header")
				self:QueueOrRun(function()
					UnregisterStateDriver(header, "visibility")
					RegisterStateDriver(header, "visibility", driver)
				end, "visibility-driver-header-" .. headerName)
			end
		end
	end
end

function addon:SerializeProfile()
	if not (LibSerialize and LibDeflate) then
		return nil, "LibSerialize or LibDeflate is missing."
	end

	local function WrapEncodedForDisplay(encoded, lineLen)
		local text = tostring(encoded or "")
		local width = tonumber(lineLen) or 120
		if text == "" or width < 16 then
			return text
		end
		local out, i = {}, 1
		local n = #text
		while i <= n do
			out[#out + 1] = text:sub(i, math.min(i + width - 1, n))
			i = i + width
		end
		return table.concat(out, "\n")
	end

	local payload = {
		__sufExportType = "profile_bundle",
		__sufExportVersion = 2,
		profile = CopyTableDeep(self.db.profile or defaults.profile or {}),
		global = CopyTableDeep((self.db and self.db.global) or {}),
		customTrackers = CopyTableDeep(((self.db and self.db.profile and self.db.profile.customTrackers) or {})),
	}

	local serialized = LibSerialize:Serialize(payload)
	local compressed = LibDeflate:CompressDeflate(serialized)
	local encoded = LibDeflate:EncodeForPrint(compressed)
	return WrapEncodedForDisplay(encoded, 120)
end

function addon:DeserializeProfile(input)
	if not (LibSerialize and LibDeflate) then
		return nil, "LibSerialize or LibDeflate is missing."
	end

	local compactInput = tostring(input or ""):gsub("%s+", "")
	local decoded = LibDeflate:DecodeForPrint(compactInput)
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

local function UnwrapImportedPayload(data)
	if type(data) ~= "table" then
		return nil, nil
	end
	if data.__sufExportType == "profile_bundle" and type(data.profile) == "table" then
		local profile = CopyTableDeep(data.profile)
		if type(data.customTrackers) == "table" then
			profile.customTrackers = CopyTableDeep(data.customTrackers)
		end
		local envelope = {
			version = tonumber(data.__sufExportVersion) or 1,
			global = type(data.global) == "table" and CopyTableDeep(data.global) or nil,
			hasCustomTrackers = type(data.customTrackers) == "table",
		}
		return profile, envelope
	end
	return data, nil
end

function addon:ValidateImportedProfileData(data)
	local profileData, envelope = UnwrapImportedPayload(data)
	if type(profileData) ~= "table" then
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
		envelopeVersion = envelope and envelope.version or nil,
		includesGlobal = envelope and envelope.global ~= nil or false,
		includesCustomTrackers = envelope and envelope.hasCustomTrackers == true or (type(profileData.customTrackers) == "table"),
	}
	for _ in pairs(profileData) do
		report.keyCount = report.keyCount + 1
	end
	if type(profileData.units) ~= "nil" and type(profileData.units) ~= "table" then
		report.errors[#report.errors + 1] = "units must be a table."
	end
	if type(profileData.tags) ~= "nil" and type(profileData.tags) ~= "table" then
		report.errors[#report.errors + 1] = "tags must be a table."
	end
	if type(profileData.plugins) ~= "nil" and type(profileData.plugins) ~= "table" then
		report.errors[#report.errors + 1] = "plugins must be a table."
	end
	if type(profileData.units) == "table" then
		for _ in pairs(profileData.units) do
			report.unitCount = report.unitCount + 1
		end
		report.reloadReasons[#report.reloadReasons + 1] = ("unit layouts (%d)"):format(report.unitCount)
	end
	if type(profileData.tags) == "table" then
		for _ in pairs(profileData.tags) do
			report.tagCount = report.tagCount + 1
		end
		report.reloadReasons[#report.reloadReasons + 1] = ("tag configs (%d)"):format(report.tagCount)
	end
	if type(profileData.plugins) == "table" then
		local pluginUnits = profileData.plugins.units
		if type(pluginUnits) == "table" then
			for _ in pairs(pluginUnits) do
				report.pluginUnitCount = report.pluginUnitCount + 1
			end
		end
		report.reloadReasons[#report.reloadReasons + 1] = "plugin behavior"
	end
	if profileData.media ~= nil then
		report.reloadReasons[#report.reloadReasons + 1] = "shared media/font bindings"
	end
	if profileData.optionsUI ~= nil then
		report.warnings[#report.warnings + 1] = "options UI state is included and will overwrite local panel preferences."
	end
	if type(profileData.customTrackers) == "table" then
		report.reloadReasons[#report.reloadReasons + 1] = "custom tracker bars/settings"
	end
	if envelope and envelope.global then
		report.reloadReasons[#report.reloadReasons + 1] = "global addon settings"
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
	preview.lines[#preview.lines + 1] = ("Includes Global: %s | Includes Custom Trackers: %s"):format(
		(validation.includesGlobal and "Yes" or "No"),
		(validation.includesCustomTrackers and "Yes" or "No")
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

--- Protected Operations system has been moved to Core/ProtectedOperations.lua
--- Backward compatibility aliases are registered in OnEnable() via ProtectedOperations:RegisterAddonAliases()

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
	self:EnsurePopupDialog("SUF_IMPORT_RELOAD_CONFIRM", {
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
	})
	local popup = StaticPopupDialogs["SUF_IMPORT_RELOAD_CONFIRM"]
	popup.text = tostring(summaryText or "Import applied. Reload UI now?")
	self:ShowPopup("SUF_IMPORT_RELOAD_CONFIRM")
end

function addon:PromptReloadUI(message)
	self:EnsurePopupDialog("SUF_CONFIG_RELOAD", {
		text = "Some changes require ReloadUI.",
		button1 = "Reload",
		button2 = "Later",
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	})
	local popup = StaticPopupDialogs["SUF_CONFIG_RELOAD"]
	if popup then
		popup.text = tostring(message or "Some changes require ReloadUI.")
	end
	self:ShowPopup("SUF_CONFIG_RELOAD")
end

function addon:ApplyImportedProfile(data)
	local report, validationErr = self:ValidateImportedProfileData(data)
	if not report then
		return false, validationErr or "Invalid import payload."
	end
	if report.ok == false then
		return false, validationErr or "Import validation failed."
	end

	local profileData, envelope = UnwrapImportedPayload(data)
	local targetProfile = self:BuildImportedProfileTarget(profileData)
	local previousProfile = CopyTableDeep(self.db.profile or defaults.profile)
	local previousGlobal = CopyTableDeep((self.db and self.db.global) or {})
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
		if envelope and type(envelope.global) == "table" and self.db and type(self.db.global) == "table" then
			ReplaceTableContents(self.db.global, envelope.global)
		end
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
			if self.db and type(self.db.global) == "table" then
				ReplaceTableContents(self.db.global, previousGlobal)
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
	self:UpdateDataBars()
	self:UpdateDataTextPanel()
	-- Bootstrap target/tot visuals and text on initial login/reload.
	C_Timer.After(0, function()
		self:OnPlayerTargetChanged()
	end)
	C_Timer.After(0.25, function()
		self:OnPlayerTargetChanged()
	end)
	C_Timer.After(0.75, function()
		self:OnPlayerTargetChanged()
		-- Also update player frame status indicators (AFK/DND/DC) on login
		if self.frames then
			for _, frame in ipairs(self.frames) do
				if frame and frame.sufUnitType == "player" then
					self:UpdateUnitFrameStatusIndicators(frame)
					-- Force update Power bar to prevent visual glitches on login (e.g., Shadow Priest Insanity overflow)
					if frame.Power and frame.Power.ForceUpdate then
						pcall(frame.Power.ForceUpdate, frame.Power)
					end
				end
			end
		end
	end)
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

function addon:OnEditModeStateChanged()
	self:UpdateBlizzardFrames()
	self:UpdateDataBars()
	self:UpdateDataTextPanel()
	self:UpdateAllUnitFrameUnlockHandles()
end

function addon:SetFramesVisible(isEditMode)
	local blizzardCfg = (self.db and self.db.profile and self.db.profile.blizzardFrames) or defaults.profile.blizzardFrames or {}
	local isGrouped = (IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid())
	local function ResolveAlpha(key)
		return blizzardCfg[key] == false and 1 or 0
	end

	local playerAlpha = ResolveAlpha("player")
	if _G.PlayerFrame then _G.PlayerFrame:SetAlpha(playerAlpha) end
	if _G.CastingBarFrame then _G.CastingBarFrame:SetAlpha(playerAlpha) end

	local petAlpha = ResolveAlpha("pet")
	if _G.PetFrame then _G.PetFrame:SetAlpha(petAlpha) end

	local targetAlpha = ResolveAlpha("target")
	if _G.TargetFrame then _G.TargetFrame:SetAlpha(targetAlpha) end
	if _G.TargetFrameSpellBar then _G.TargetFrameSpellBar:SetAlpha(targetAlpha) end

	local totAlpha = ResolveAlpha("tot")
	if _G.TargetFrameToT then _G.TargetFrameToT:SetAlpha(totAlpha) end

	local focusAlpha = ResolveAlpha("focus")
	if _G.FocusFrame then _G.FocusFrame:SetAlpha(focusAlpha) end

	local partyAlpha = ResolveAlpha("party")
	if _G.PartyFrame then _G.PartyFrame:SetAlpha(partyAlpha) end
	if _G.CompactPartyFrame then _G.CompactPartyFrame:SetAlpha(partyAlpha) end

	local raidAlpha = ResolveAlpha("raid")
	if _G.CompactRaidFrameContainer then _G.CompactRaidFrameContainer:SetAlpha(raidAlpha) end
	if _G.CompactRaidFrameManager then _G.CompactRaidFrameManager:SetAlpha(isGrouped and 1 or raidAlpha) end

	local bossAlpha = ResolveAlpha("boss")
	if _G.BossTargetFrameContainer then _G.BossTargetFrameContainer:SetAlpha(bossAlpha) end

	if isEditMode then
		for _, frame in ipairs(self.frames or {}) do
			UnregisterStateDriver(frame, "visibility")
			if frame._sufWasUnitWatchInEditMode == nil then
				frame._sufWasUnitWatchInEditMode = UnitWatchRegistered(frame)
			end
			if frame._sufWasUnitWatchInEditMode then
				UnregisterUnitWatch(frame)
			end
			frame:Show()
		end
		for _, header in pairs(self.headers or {}) do
			if header then
				UnregisterStateDriver(header, "visibility")
				header:Show()
			end
		end
	else
		for _, frame in ipairs(self.frames or {}) do
			if frame._sufWasUnitWatchInEditMode ~= nil then
				if frame._sufWasUnitWatchInEditMode then
					RegisterUnitWatch(frame)
				end
				frame._sufWasUnitWatchInEditMode = nil
			end
		end
		self:ApplyVisibilityRules()
	end
	self:UpdateAllUnitFrameUnlockHandles()
	if _G.CompactRaidFrameManager and isGrouped then
		if _G.CompactRaidFrameManager_SetSetting then
			pcall(_G.CompactRaidFrameManager_SetSetting, "IsShown", "1")
		end
		if _G.CompactRaidFrameManager_UpdateShown then
			pcall(_G.CompactRaidFrameManager_UpdateShown)
		end
		if _G.CompactRaidFrameManager.Show then
			pcall(_G.CompactRaidFrameManager.Show, _G.CompactRaidFrameManager)
		end
		if _G.CompactRaidFrameManagerDisplayFrame and _G.CompactRaidFrameManagerDisplayFrame.Show then
			pcall(_G.CompactRaidFrameManagerDisplayFrame.Show, _G.CompactRaidFrameManagerDisplayFrame)
		end
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


function addon:OnInitialize()
	ChatMsg(addonName .. ": OnInitialize")
	self.allowGroupHeaders = false
	self:RegisterSharedMediaAssets()
	self:SetupToolkitAPI()
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
	if not self.db.profile.blizzardFrames then
		self.db.profile.blizzardFrames = CopyTableDeep(defaults.profile.blizzardFrames)
	else
		MergeDefaults(self.db.profile.blizzardFrames, defaults.profile.blizzardFrames)
	end
	if not self.db.profile.blizzardSkin then
		self.db.profile.blizzardSkin = CopyTableDeep(defaults.profile.blizzardSkin)
	else
		MergeDefaults(self.db.profile.blizzardSkin, defaults.profile.blizzardSkin)
	end
	if not self.db.profile.movers then
		self.db.profile.movers = CopyTableDeep(defaults.profile.movers)
	end
	if not self.db.profile.databars then
		self.db.profile.databars = CopyTableDeep(defaults.profile.databars)
	else
		MergeDefaults(self.db.profile.databars, defaults.profile.databars)
	end
	do
		local mode = tostring(self.db.profile.databars.positionMode or "ANCHOR")
		if mode == "EDITMODE" or mode == "EDIT" then
			self.db.profile.databars.positionMode = "EDIT_MODE"
		end
	end
	if not self.db.profile.datatext then
		self.db.profile.datatext = CopyTableDeep(defaults.profile.datatext)
	else
		MergeDefaults(self.db.profile.datatext, defaults.profile.datatext)
	end
	do
		local mode = tostring(self.db.profile.datatext.positionMode or "ANCHOR")
		if mode == "EDITMODE" or mode == "EDIT" then
			self.db.profile.datatext.positionMode = "EDIT_MODE"
		end
	end
	if not self.db.profile.customTrackers then
		self.db.profile.customTrackers = CopyTableDeep(defaults.profile.customTrackers)
	else
		if not self.db.profile.customTrackers.bars then
			self.db.profile.customTrackers.bars = {}
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
			local auraDefaults = (unitType == "party") and DEFAULT_PARTY_AURA_LAYOUT or DEFAULT_UNIT_AURA_LAYOUT
			self.db.profile.units[unitType].auras = CopyTableDeep(auraDefaults)
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
			if not self.db.profile.units[unitType].targetGlow then
				self.db.profile.units[unitType].targetGlow = CopyTableDeep(DEFAULT_UNIT_TARGET_GLOW)
			else
				MergeDefaults(self.db.profile.units[unitType].targetGlow, DEFAULT_UNIT_TARGET_GLOW)
			end
			if not self.db.profile.units[unitType].powerPrediction then
				self.db.profile.units[unitType].powerPrediction = CopyTableDeep(DEFAULT_UNIT_POWER_PREDICTION)
			else
				MergeDefaults(self.db.profile.units[unitType].powerPrediction, DEFAULT_UNIT_POWER_PREDICTION)
			end
			local auraDefaults = (unitType == "party") and DEFAULT_PARTY_AURA_LAYOUT or DEFAULT_UNIT_AURA_LAYOUT
			if not self.db.profile.units[unitType].auras then
				self.db.profile.units[unitType].auras = CopyTableDeep(auraDefaults)
			else
				MergeDefaults(self.db.profile.units[unitType].auras, auraDefaults)
			end
			if unitType == "party" then
				local partyAuras = self.db.profile.units[unitType].auras
				local usesLegacyDefaults = (tonumber(partyAuras.numBuffs) or 8) == 8
					and (tonumber(partyAuras.numDebuffs) or 8) == 8
					and (tonumber(partyAuras.maxCols) or 8) == 8
					and tostring(partyAuras.initialAnchor or "BOTTOMLEFT") == "BOTTOMLEFT"
					and tostring(partyAuras.growthX or "RIGHT") == "RIGHT"
					and tostring(partyAuras.growthY or "UP") == "UP"
				if usesLegacyDefaults then
					partyAuras.enabled = true
					partyAuras.numBuffs = DEFAULT_PARTY_AURA_LAYOUT.numBuffs
					partyAuras.numDebuffs = DEFAULT_PARTY_AURA_LAYOUT.numDebuffs
					partyAuras.maxCols = DEFAULT_PARTY_AURA_LAYOUT.maxCols
				end
				if self.db.profile.units[unitType].auraSize == nil then
					self.db.profile.units[unitType].auraSize = 22
				end
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
	self:RegisterChatCommand("sufabsorbdebug", "HandleAbsorbDebugSlash")
	self:RegisterChatCommand("sufperf", function()
		self:TogglePerformanceDashboard()
	end)
	self:RegisterChatCommand("libperf", function()
		self:Print(addonName .. ": /libperf is aliased to /sufperf.")
		self:TogglePerformanceDashboard()
	end)
	self:RegisterChatCommand("sufstatus", function() self:PrintStatusReport() end)
	self:RegisterChatCommand("sufinstall", function() self:StartInstallFlow() end)
	self:RegisterChatCommand("suftutorial", function() self:ShowTutorialOverview(true) end)
	self:RegisterChatCommand("sufprotected", "HandleProtectedOpsSlash")
	self:RegisterChatCommand("sufskinreport", function()
		if self.PrintBlizzardSkinCoverageReport then
			self:PrintBlizzardSkinCoverageReport()
		elseif self.PrintBlizzardSkinReport then
			self:PrintBlizzardSkinReport()
		else
			self:Print(addonName .. ": Blizzard skin report is unavailable.")
		end
	end)
	self:RegisterChatCommand("sufskincoverage", function()
		if self.PrintBlizzardSkinCoverageReport then
			self:PrintBlizzardSkinCoverageReport()
		elseif self.PrintBlizzardSkinReport then
			self:PrintBlizzardSkinReport()
		else
			self:Print(addonName .. ": Blizzard skin report is unavailable.")
		end
	end)
end

function addon:RegisterUnitScopedDataEvents()
	if not self._unitScopedDataEventFrame then
		local frame = CreateFrame("Frame")
		frame:SetScript("OnEvent", function(_, event, unit)
			if event == "UNIT_PET_EXPERIENCE" and unit ~= "pet" then
				return
			end
			if event == "UNIT_PET" and unit ~= "player" then
				return
			end
			if event == "UNIT_INVENTORY_CHANGED" then
				if unit == "player" and addon.ScheduleUpdateDataTextPanel then
					addon:ScheduleUpdateDataTextPanel()
				end
				return
			end
			if addon.ScheduleUpdateDataBars then
				addon:ScheduleUpdateDataBars()
			end
		end)
		self._unitScopedDataEventFrame = frame
	end

	local frame = self._unitScopedDataEventFrame
	frame:UnregisterAllEvents()
	if frame.RegisterUnitEvent then
		frame:RegisterUnitEvent("UNIT_PET_EXPERIENCE", "pet")
		frame:RegisterUnitEvent("UNIT_PET", "player")
		frame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
	else
		frame:RegisterEvent("UNIT_PET_EXPERIENCE")
		frame:RegisterEvent("UNIT_PET")
		frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	end
end

function addon:UnregisterUnitScopedDataEvents()
	if self._unitScopedDataEventFrame then
		self._unitScopedDataEventFrame:UnregisterAllEvents()
	end
end

function addon:OnEnable()
	ChatMsg(addonName .. ": OnEnable")
	self:DebugLog("General", "Addon enabled.", 2)
	if self.SyncThemeFromOptionsV2 then
		self:SyncThemeFromOptionsV2()
	end
	self:RegisterMediaCallbacks()
	self:InitializeLauncher()
	if not self.performanceLib then
		self:SetupPerformanceLib()
	end
	
	--- Initialize protected operations system (combat-lockdown-safe queueing) ---
	if self.ProtectedOperations then
		self.ProtectedOperations:Init()
		self.ProtectedOperations:RegisterAddonAliases()
	end
	
	--- Initialize indicator pool manager (GC reduction for visual effects) ---
	if self.IndicatorPoolManager then
		self.IndicatorPoolManager:Initialize(self)  -- Pass addon reference for debug logging
		self:DebugLog("IndicatorPoolManager", "Initialized successfully", 2)
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
		local ok = pcall(self.RegisterEvent, self, eventName, "OnEditModeStateChanged")
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
	self:RegisterEvent("PLAYER_XP_UPDATE", "ScheduleUpdateDataBars")
	self:RegisterEvent("UPDATE_EXHAUSTION", "ScheduleUpdateDataBars")
	self:RegisterEvent("UPDATE_FACTION", "ScheduleUpdateDataBars")
	self:RegisterEvent("QUEST_LOG_UPDATE", "ScheduleUpdateDataBars")
	self:RegisterEvent("PET_BAR_UPDATE", "ScheduleUpdateDataBars")
	self:RegisterUnitScopedDataEvents()
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("PLAYER_MONEY", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("BAG_UPDATE_DELAYED", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("ZONE_CHANGED", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnPlayerTargetChanged")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "OnPlayerFlagsChanged")
	self:RegisterEvent("QUEST_ACCEPTED", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("QUEST_REMOVED", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("QUEST_TURNED_IN", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("MAIL_INBOX_UPDATE", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("UPDATE_PENDING_MAIL", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("MAIL_CLOSED", "ScheduleUpdateDataTextPanel")
	self:RegisterEvent("MAIL_SHOW", "ScheduleUpdateDataTextPanel")
	self:InitializeDataSystems()

	-- Initialize Custom Trackers
	if self.CustomTrackers and self.CustomTrackers.Init then
		self.CustomTrackers:Init()
	end
	if self.SetupBlizzardSkinning then
		self:SetupBlizzardSkinning()
	end
	if self.ApplyBlizzardSkinningNow then
		self:ApplyBlizzardSkinningNow()
	end

	C_Timer.After(1.0, function()
		if addon and addon.db and addon.db.profile and addon.db.profile.optionsUI and addon.db.profile.optionsUI.tutorialSeen ~= true then
			addon:ShowTutorialOverview(false)
		end
	end)

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
	self:UnregisterUnitScopedDataEvents()
	self:UnregisterMediaCallbacks()
	if self._pluginUpdateTicker then
		self._pluginUpdateTicker:Cancel()
		self._pluginUpdateTicker = nil
	end
	self._pendingPluginUpdates = nil
	if self._localWorkTimer and self._localWorkTimer.Cancel then
		self._localWorkTimer:Cancel()
		self._localWorkTimer = nil
	end
	if self._protectedOperationTicker and self._protectedOperationTicker.Cancel then
		self._protectedOperationTicker:Cancel()
		self._protectedOperationTicker = nil
	end
	self._protectedOperationQueue = nil
	self._protectedOperationIndex = nil
	if self.spawnTicker and self.spawnTicker.Cancel then
		self.spawnTicker:Cancel()
		self.spawnTicker = nil
	end
	if self.groupHeaderTimer and self.groupHeaderTimer.Cancel then
		self.groupHeaderTimer:Cancel()
		self.groupHeaderTimer = nil
	end
	if self.optionsFrame and self.optionsFrame.performanceSnapshotTicker and self.optionsFrame.performanceSnapshotTicker.Cancel then
		self.optionsFrame.performanceSnapshotTicker:Cancel()
		self.optionsFrame.performanceSnapshotTicker = nil
	end
	self._localWork = nil

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
	if self._dataTextTicker and self._dataTextTicker.Cancel then
		self._dataTextTicker:Cancel()
		self._dataTextTicker = nil
	end
	if self._dataTextRefreshTimer and self._dataTextRefreshTimer.Cancel then
		self._dataTextRefreshTimer:Cancel()
		self._dataTextRefreshTimer = nil
	end
	if self._dataBarsRefreshTimer and self._dataBarsRefreshTimer.Cancel then
		self._dataBarsRefreshTimer:Cancel()
		self._dataBarsRefreshTimer = nil
	end
	if self.dataTextPanel then
		self.dataTextPanel:Hide()
	end
	if self.dataBarsFrame then
		self.dataBarsFrame:Hide()
	end
	self:ReleaseAllPooledResources()
end


