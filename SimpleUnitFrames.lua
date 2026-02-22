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
			showPlayerWhenSolo = false,
		},
		performance = {
			enabled = true,
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

local GROUP_UNIT_TYPES = {
	party = true,
	raid = true,
}

local PERF_EVENT_PRIORITY = {
	UNIT_HEALTH = 1,
	UNIT_POWER_UPDATE = 1,
	UNIT_MAXHEALTH = 2,
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
	UNIT_HEALTH = { delay = 0.10, priority = 2 },
	UNIT_POWER_UPDATE = { delay = 0.09, priority = 2 },
	UNIT_MAXHEALTH = { delay = 0.10, priority = 2 },
	UNIT_MAXPOWER = { delay = 0.10, priority = 2 },
	UNIT_DISPLAYPOWER = { delay = 0.10, priority = 2 },
	UNIT_AURA = { delay = 0.08, priority = 2 },
	UNIT_THREAT_SITUATION_UPDATE = { delay = 0.10, priority = 3 },
	UNIT_THREAT_LIST_UPDATE = { delay = 0.10, priority = 3 },
	PLAYER_TOTEM_UPDATE = { delay = 0.05, priority = 3 },
	RUNE_POWER_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_SPELLCAST_CHANNEL_UPDATE = { delay = 0.05, priority = 3 },
	UNIT_PORTRAIT_UPDATE = { delay = 0.20, priority = 4 },
	UNIT_MODEL_CHANGED = { delay = 0.20, priority = 4 },
}

local NON_UNIT_EVENT_TARGETS = {
	PLAYER_TOTEM_UPDATE = { "player" },
	RUNE_POWER_UPDATE = { "player" },
}

local UNIT_SCOPED_EVENTS = {
	UNIT_HEALTH = true,
	UNIT_POWER_UPDATE = true,
	UNIT_MAXHEALTH = true,
	UNIT_MAXPOWER = true,
	UNIT_DISPLAYPOWER = true,
	UNIT_AURA = true,
	UNIT_THREAT_SITUATION_UPDATE = true,
	UNIT_THREAT_LIST_UPDATE = true,
	UNIT_SPELLCAST_CHANNEL_UPDATE = true,
	UNIT_PORTRAIT_UPDATE = true,
	UNIT_MODEL_CHANGED = true,
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

	if self.performanceLib.SetPreset and self.performanceLib.db and (not self.performanceLib.db.presets or self.performanceLib.db.presets == "") then
		pcall(self.performanceLib.SetPreset, self.performanceLib, "High")
	end

	local optimizer = self.performanceLib.MLOptimizer
	if optimizer and optimizer.RegisterSequence then
		optimizer:RegisterSequence("UNIT_HEALTH", "UNIT_POWER_UPDATE", 0.75)
		optimizer:RegisterSequence("UNIT_POWER_UPDATE", "UNIT_DISPLAYPOWER", 0.65)
		optimizer:RegisterSequence("UNIT_MAXHEALTH", "UNIT_HEALTH", 0.60)
	end
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

function addon:MarkFrameDirty(frame, eventName)
	if not frame then
		return
	end

	local priority = self:GetDirtyPriorityForEvent(eventName, frame)
	local dirtyManager = self.performanceLib and self.performanceLib.DirtyFlagManager
	if dirtyManager and dirtyManager.MarkDirty then
		dirtyManager:MarkDirty(frame, priority)
	else
		frame:UpdateAllElements("SimpleUnitFrames_PerfFallback")
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

	local eventConfig = EVENT_COALESCE_CONFIG[eventName]
	local priority = (eventConfig and eventConfig.priority) or PERF_EVENT_PRIORITY[eventName] or 3
	self:DebugLog("Events", "Queued event: " .. tostring(eventName), 3)

	if self.performanceLib and self.performanceLib.QueueEvent then
		self.performanceLib:QueueEvent(eventName, priority, ...)
	else
		self:HandleCoalescedEvent(eventName, ...)
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
				self:DispatchSUFEvent("COALESCED_EVENT", eventName, ...)
			end
			self.performanceHandlers[eventName] = callback
			coalescer:CoalesceEvent(eventName, config.delay, callback, config.priority)
			if coalescer.SetEventDelay then
				coalescer:SetEventDelay(eventName, config.delay)
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
	else
		if self.performanceLib.EventCoalescer and self.performanceLib.EventCoalescer.Flush then
			self.performanceLib.EventCoalescer:Flush()
		end
		self:UnregisterPerformanceEventFrame()
		self:UnregisterPerformanceCoalescedHandlers()
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

		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -8)
		title:SetText("SUF Debug Export")

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

		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -8)
		title:SetText("SUF Debug Settings")

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

		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -8)
		title:SetText("|cFF00B0F7SUF Debug Console|r")

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
		settingsBtn:SetSize(80, 24)
		settingsBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
		settingsBtn:SetText("Settings")
		settingsBtn:SetScript("OnClick", function()
			self:ShowDebugSettings()
		end)

		self.debugPanel = frame
	end

	if self.debugPanel.toggleBtn then
		self.debugPanel.toggleBtn:SetText(self:IsDebugEnabled() and "Enabled" or "Disabled")
	end
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

	local inRaid = IsInRaid and IsInRaid() or false
	local inGroup = IsInGroup and IsInGroup() or false
	if not inRaid and not inGroup then
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
end

function addon:ApplyMedia(frame)
	local texture = self:GetUnitStatusbarTexture(frame.sufUnitType)
	local font = self:GetFont()
	local sizes = self:GetUnitFontSizes(frame.sufUnitType)

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

	if frame.AdditionalPower then
		frame.AdditionalPower:SetStatusBarTexture(texture)
	end

	if frame.AdditionalPowerBG then
		frame.AdditionalPowerBG:SetTexture(texture)
		frame.AdditionalPowerBG:SetVertexColor(0, 0, 0, 0.6)
	end

	if frame.Castbar then
		frame.Castbar:SetStatusBarTexture(texture)
		if frame.Castbar.Text then
			frame.Castbar.Text:SetFont(font, sizes.cast, "OUTLINE")
		end
		if frame.Castbar.Time then
			frame.Castbar.Time:SetFont(font, sizes.cast, "OUTLINE")
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

	if frame.PowerValue then
		frame.PowerValue:SetFont(font, sizes.power, "OUTLINE")
	end

	if frame.AdditionalPowerValue then
		frame.AdditionalPowerValue:SetFont(font, math.max(8, sizes.power - 1), "OUTLINE")
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
	local unitType = frame.sufUnitType
	local size = self.db.profile.sizes[unitType]
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
	end

	if frame.Castbar then
		frame.Castbar:SetHeight(self.db.profile.castbarHeight)
	end

	if frame.ClassPowerAnchor and frame.ClassPower then
		frame.ClassPowerAnchor:SetHeight(self.db.profile.classPowerHeight)
		for _, bar in ipairs(frame.ClassPower) do
			bar:SetHeight(self.db.profile.classPowerHeight)
		end
		self:LayoutClassPower(frame)
	end
end

function addon:UpdateAllFrames()
	for _, frame in ipairs(self.frames) do
		self:ApplyTags(frame)
		self:ApplyMedia(frame)
		self:ApplySize(frame)
		self:ApplyIndicators(frame)
		self:ApplyPortrait(frame)
		frame:UpdateAllElements("SimpleUnitFrames_Update")
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

	if frame.Auras and frame.Auras.__sufPooledFrame and self.performanceLib and self.performanceLib.ReleaseFrame then
		pcall(self.performanceLib.ReleaseFrame, self.performanceLib, frame.Auras)
	end
	frame.Auras = nil
end

function addon:ReleaseAllPooledResources()
	for _, frame in ipairs(self.frames or {}) do
		self:ReleaseFramePooledResources(frame)
	end
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

	Castbar.Text = Text
	Castbar.Time = Time
	self.Castbar = Castbar
end

local function CreateClassPower(self, height)
	local ClassPower = {}
	local anchor = CreateFrame("Frame", nil, self)
	anchor:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
	anchor:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -4)
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

local function CreateAuras(self)
	local owner = addon
	local Auras = owner:AcquireRuntimeFrame("Frame", self, "SUF_AuraContainer")
	Auras:Show()
	Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 6)
	Auras:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 6)
	Auras:SetHeight(20)
	Auras.size = 18
	Auras.spacing = 4
	Auras.numBuffs = 8
	Auras.numDebuffs = 8
	Auras.disableCooldown = false
	self.Auras = Auras
end

function addon:Style(frame, unit)
	frame.sufUnitType = ResolveUnitType(unit)
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

	local Power = CreateStatusBar(frame, self.db.profile.powerHeight)
	Power:SetPoint("TOPLEFT", Health, "BOTTOMLEFT", 0, -2)
	Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, -2)
	Power.colorPower = true
	frame.Power = Power

	local PowerBG = Power:CreateTexture(nil, "BACKGROUND")
	PowerBG:SetAllPoints(Power)
	PowerBG:SetColorTexture(0, 0, 0, 0.6)
	frame.PowerBG = PowerBG

	local NameText = CreateFontString(Health, 12, "OUTLINE")
	NameText:SetPoint("TOPLEFT", Health, "TOPLEFT", 4, -2)
	frame.NameText = NameText

	local LevelText = CreateFontString(Health, 10, "OUTLINE")
	LevelText:SetPoint("TOPRIGHT", Health, "TOPRIGHT", -4, -2)
	LevelText:SetJustifyH("RIGHT")
	frame.LevelText = LevelText

	local HealthValue = CreateFontString(Health, 11, "OUTLINE")
	HealthValue:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT", 4, 2)
	frame.HealthValue = HealthValue

	local PowerValue = CreateFontString(Power, 10, "OUTLINE")
	PowerValue:SetPoint("CENTER", Power, "CENTER", 0, 0)
	PowerValue:SetJustifyH("CENTER")
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

		local AdditionalPower = CreateStatusBar(frame, math.max(4, math.floor(self.db.profile.powerHeight * 0.7)))
		AdditionalPower:SetPoint("TOPLEFT", frame.Power, "BOTTOMLEFT", 0, -2)
		AdditionalPower:SetPoint("TOPRIGHT", frame.Power, "BOTTOMRIGHT", 0, -2)
		AdditionalPower.colorPower = true
		frame.AdditionalPower = AdditionalPower

		local AdditionalPowerBG = AdditionalPower:CreateTexture(nil, "BACKGROUND")
		AdditionalPowerBG:SetAllPoints(AdditionalPower)
		AdditionalPowerBG:SetColorTexture(0, 0, 0, 0.6)
		frame.AdditionalPowerBG = AdditionalPowerBG

		local AdditionalPowerValue = CreateFontString(AdditionalPower, 9, "OUTLINE")
		AdditionalPowerValue:SetPoint("CENTER", AdditionalPower, "CENTER", 0, 0)
		AdditionalPowerValue:SetJustifyH("CENTER")
		frame.AdditionalPowerValue = AdditionalPowerValue
	end

	if unit == "player" or unit == "target" then
		local anchor = frame.ClassPowerAnchor
		CreateCastbar(frame, self.db.profile.castbarHeight, anchor)
		if not frame.Auras then
			CreateAuras(frame)
		end
	end

	self:ApplyTags(frame)
	self:ApplyMedia(frame)
	self:ApplySize(frame)
	if not frame.Update then
		frame.Update = function(widget)
			widget:UpdateAllElements("SimpleUnitFrames_PerfDirty")
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

	local inRaid = IsInRaid and IsInRaid() or false
	local inGroup = IsInGroup and IsInGroup() or false
	if not inRaid and not inGroup then
		return
	end

	self.oUF = oUF
	self.headers = self.headers or {}

	local needParty = inGroup and not inRaid and not self.headers.party
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

	self:ApplyVisibilityRules()
end

function addon:OnGroupRosterUpdate()
	self:TrySpawnGroupHeaders()
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
			if showBlizzard then
				if frame.Show then
					frame:Show()
				end
			else
				if frame.Hide then
					frame:Hide()
				end
			end
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
	if self.optionsFrame then
		self.optionsFrame:Show()
		if self.optionsFrame.BuildTab then
			self.optionsFrame:BuildTab(self.optionsFrame.currentTab or "global")
		end
		return
	end

	local frame = CreateFrame("Frame", "SUFOptionsWindow", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(920, 680)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(760, 520, UIParent:GetWidth() - 40, UIParent:GetHeight() - 40)
	else
		if frame.SetMinResize then
			frame:SetMinResize(760, 520)
		end
		if frame.SetMaxResize then
			frame:SetMaxResize(UIParent:GetWidth() - 40, UIParent:GetHeight() - 40)
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

	local contentHost = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	contentHost:SetPoint("TOPLEFT", tabsHost, "TOPRIGHT", 8, 0)
	contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 14)

	local scroll = CreateFrame("ScrollFrame", nil, contentHost, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -28, 8)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(660, 200)
	scroll:SetScrollChild(content)

	local tabs = {
		{ key = "global", label = "Global" },
		{ key = "importexport", label = "Import / Export" },
		{ key = "player", label = "Player" },
		{ key = "target", label = "Target" },
		{ key = "tot", label = "TargetOfTarget" },
		{ key = "focus", label = "Focus" },
		{ key = "pet", label = "Pet" },
		{ key = "party", label = "Party" },
		{ key = "raid", label = "Raid" },
		{ key = "boss", label = "Boss" },
	}

	local tabButtons = {}
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
			width = math.max(420, contentHost:GetWidth() - 72),
		}

		function builder:Label(text, large)
			local fs = self.page:CreateFontString(nil, "OVERLAY", large and "GameFontNormalLarge" or "GameFontNormal")
			fs:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			fs:SetText(text)
			self.y = self.y - (large and 26 or 18)
		end

		function builder:Edit(label, getter, setter)
			self:Label(label, false)
			local eb = CreateFrame("EditBox", nil, self.page, "InputBoxTemplate")
			eb:SetAutoFocus(false)
			eb:SetSize(self.width, 22)
			eb:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			eb:SetText(tostring(getter() or ""))
			eb:SetScript("OnEnterPressed", function(w)
				setter(w:GetText())
				w:ClearFocus()
			end)
			eb:SetScript("OnEscapePressed", function(w)
				w:ClearFocus()
			end)
			self.y = self.y - 34
		end

		function builder:Slider(label, minv, maxv, step, getter, setter)
			addon._optSliderId = (addon._optSliderId or 0) + 1
			local name = "SUF_OptSlider_" .. tabKey .. "_" .. addon._optSliderId
			local s = CreateFrame("Slider", name, self.page, "OptionsSliderTemplate")
			s:SetPoint("TOPLEFT", self.page, "TOPLEFT", 12, self.y)
			s:SetWidth(self.width)
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
			self.y = self.y - 44
		end

		function builder:Check(label, getter, setter, disabled)
			local c = CreateFrame("CheckButton", nil, self.page, "UICheckButtonTemplate")
			c:SetPoint("TOPLEFT", self.page, "TOPLEFT", 10, self.y)
			if c.Text then c.Text:SetText(label) end
			c:SetChecked(getter() and true or false)
			c:SetEnabled(not disabled)
			c:SetScript("OnClick", function(w)
				setter(w:GetChecked() and true or false)
			end)
			self.y = self.y - 26
		end

		function builder:Dropdown(label, options, getter, setter)
			self:Label(label, false)
			addon._optDropdownId = (addon._optDropdownId or 0) + 1
			local name = "SUF_OptDropdown_" .. tabKey .. "_" .. addon._optDropdownId
			local dd = CreateFrame("Frame", name, self.page, "UIDropDownMenuTemplate")
			dd:SetPoint("TOPLEFT", self.page, "TOPLEFT", -4, self.y + 8)
			UIDropDownMenu_SetWidth(dd, math.max(220, self.width - 42))
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
				UIDropDownMenu_SetText(dd, tostring(current))
			end

			self.y = self.y - 50
		end

		function builder:GetHeight()
			return math.abs(self.y) + 20
		end

		return builder
	end

	function frame.BuildTab(_, tabKey)
		frame.currentTab = tabKey
		for key, button in pairs(tabButtons) do
			button:SetEnabled(key ~= tabKey)
		end
		self.isBuildingOptions = true
		ClearContent()

		local page = CreateFrame("Frame", nil, content)
		page:SetPoint("TOPLEFT", content, "TOPLEFT")
		page:SetWidth(math.max(560, contentHost:GetWidth() - 44))
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
			ui:Check("Hide in Vehicle", function() return self.db.profile.visibility.hideVehicle end, function(v) self.db.profile.visibility.hideVehicle = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide in Pet Battles", function() return self.db.profile.visibility.hidePetBattle end, function(v) self.db.profile.visibility.hidePetBattle = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide with Override Bar", function() return self.db.profile.visibility.hideOverride end, function(v) self.db.profile.visibility.hideOverride = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide with Possess Bar", function() return self.db.profile.visibility.hidePossess end, function(v) self.db.profile.visibility.hidePossess = v; self:ScheduleApplyVisibility() end)
			ui:Check("Hide with Extra Bar", function() return self.db.profile.visibility.hideExtra end, function(v) self.db.profile.visibility.hideExtra = v; self:ScheduleApplyVisibility() end)
			ui:Check("Test Mode (Show All Frames)", function() return self.testMode end, function(v) self:SetTestMode(v) end)
			ui:Check("Enable PerformanceLib Integration", function() return self.db.profile.performance and self.db.profile.performance.enabled end, function(v) self:SetPerformanceIntegrationEnabled(v) end, not self.performanceLib)
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
		else
			local unitSettings = self:GetUnitSettings(tabKey)
			local tags = self.db.profile.tags[tabKey]
			local size = self.db.profile.sizes[tabKey]
			unitSettings.fontSizes = unitSettings.fontSizes or CopyTableDeep(self.db.profile.fontSizes)
			unitSettings.portrait = unitSettings.portrait or { mode = "none", size = 32, showClass = false, position = "LEFT" }
			unitSettings.media = unitSettings.media or { statusbar = self.db.profile.media.statusbar }
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
		local preferredHeight = wanted + 120
		if preferredHeight > frame:GetHeight() then
			frame:SetHeight(math.min(UIParent:GetHeight() - 40, preferredHeight))
		end
		self.isBuildingOptions = false
	end

	for i, tab in ipairs(tabs) do
		local button = CreateFrame("Button", nil, tabsHost, "UIPanelButtonTemplate")
		button:SetSize(150, 24)
		button:SetPoint("TOPLEFT", tabsHost, "TOPLEFT", 10, -10 - ((i - 1) * 28))
		button:SetText(tab.label)
		button:SetScript("OnClick", function()
			frame:BuildTab(tab.key)
		end)
		tabButtons[tab.key] = button
	end

	frame:SetScript("OnSizeChanged", function()
		if frame.currentTab and frame:IsShown() then
			C_Timer.After(0, function()
				if frame:IsShown() and frame.currentTab then
					frame:BuildTab(frame.currentTab)
				end
			end)
		end
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
	end
	if not self.db.profile.performance then
		self.db.profile.performance = CopyTableDeep(defaults.profile.performance)
	end
	if self.db.profile.performance.enabled == nil then
		self.db.profile.performance.enabled = defaults.profile.performance.enabled
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
		end
	end

	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, "SimpleUnitFrames")
	end

	self:RegisterChatCommand("suf", "ShowOptions")
	self:RegisterChatCommand("sufdebug", "HandleDebugSlash")
end

function addon:OnEnable()
	ChatMsg(addonName .. ": OnEnable")
	self:DebugLog("General", "Addon enabled.", 2)
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
	self:ReleaseAllPooledResources()
end
