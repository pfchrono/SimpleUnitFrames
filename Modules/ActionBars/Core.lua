--[[
    SUF ActionBars - Core lifecycle, DB accessor, and refresh orchestration.
    Ported from QUI ActionBars (QUI/modules/frames/actionbars.lua) with all
    QUI-specific dependencies replaced by SUF/AceAddon equivalents.
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

---------------------------------------------------------------------------
-- MIDNIGHT (12.0+) DETECTION
---------------------------------------------------------------------------

local IS_MIDNIGHT = select(4, GetBuildInfo()) >= 120000

---------------------------------------------------------------------------
-- CONSTANTS (shared across ActionBars sub-modules via addon.ActionBars)
---------------------------------------------------------------------------

local TEXTURE_PATH = [[Interface\AddOns\SimpleUnitFrames\Media\iconskin\]]

local TEXTURES = {
	normal    = TEXTURE_PATH .. "Normal",
	gloss     = TEXTURE_PATH .. "Gloss",
	highlight = TEXTURE_PATH .. "Highlight",
	pushed    = TEXTURE_PATH .. "Pushed",
	checked   = TEXTURE_PATH .. "Checked",
	flash     = TEXTURE_PATH .. "Flash",
}

-- Bar frame name mappings (Midnight 12.0+ renames MainMenuBar -> MainActionBar)
local BAR_FRAMES = {
	bar1              = "MainActionBar",
	bar2              = "MultiBarBottomLeft",
	bar3              = "MultiBarBottomRight",
	bar4              = "MultiBarRight",
	bar5              = "MultiBarLeft",
	bar6              = "MultiBar5",
	bar7              = "MultiBar6",
	bar8              = "MultiBar7",
	pet               = "PetActionBar",
	stance            = "StanceBar",
	microbar          = "MicroMenuContainer",
	bags              = "BagsBar",
	extraActionButton = "ExtraActionBarFrame",
	zoneAbility       = "ZoneAbilityFrame",
}

-- Button name format strings per bar
local BUTTON_PATTERNS = {
	bar1    = "ActionButton%d",
	bar2    = "MultiBarBottomLeftButton%d",
	bar3    = "MultiBarBottomRightButton%d",
	bar4    = "MultiBarRightButton%d",
	bar5    = "MultiBarLeftButton%d",
	bar6    = "MultiBar5Button%d",
	bar7    = "MultiBar6Button%d",
	bar8    = "MultiBar7Button%d",
	pet     = "PetActionButton%d",
	stance  = "StanceButton%d",
}

-- Number of buttons per bar
local BUTTON_COUNTS = {
	bar1 = 12, bar2 = 12, bar3 = 12, bar4 = 12,
	bar5 = 12, bar6 = 12, bar7 = 12, bar8 = 12,
	pet = 10, stance = 10,
}

-- Binding command prefixes for LibKeyBound
local BINDING_COMMANDS = {
	bar1   = "ACTIONBUTTON",
	bar2   = "MULTIACTIONBAR1BUTTON",
	bar3   = "MULTIACTIONBAR2BUTTON",
	bar4   = "MULTIACTIONBAR3BUTTON",
	bar5   = "MULTIACTIONBAR4BUTTON",
	bar6   = "MULTIACTIONBAR5BUTTON",
	bar7   = "MULTIACTIONBAR6BUTTON",
	bar8   = "MULTIACTIONBAR7BUTTON",
	pet    = "BONUSACTIONBUTTON",
	stance = "SHAPESHIFTBUTTON",
}

---------------------------------------------------------------------------
-- MODULE STATE
---------------------------------------------------------------------------

local ActionBars = {
	initialized             = false,
	skinnedButtons          = {},
	fadeState               = {},
	fadeFrame               = nil,
	levelSuppressionActive  = nil,
	dragPreviewActive       = false,  -- Track active drag preview state
	-- shared constants
	IS_MIDNIGHT       = IS_MIDNIGHT,
	TEXTURES          = TEXTURES,
	BAR_FRAMES        = BAR_FRAMES,
	BUTTON_PATTERNS   = BUTTON_PATTERNS,
	BUTTON_COUNTS     = BUTTON_COUNTS,
	BINDING_COMMANDS  = BINDING_COMMANDS,
}

addon.ActionBars = addon.ActionBars or ActionBars

-- External weak-key table for per-button state (avoids tainting secure frames)
local frameState = setmetatable({}, { __mode = "k" })

local function GetFrameState(frame)
	local state = frameState[frame]
	if not state then
		state = {}
		frameState[frame] = state
	end
	return state
end

ActionBars.frameState    = frameState
ActionBars.GetFrameState = GetFrameState

---------------------------------------------------------------------------
-- DB ACCESSORS
---------------------------------------------------------------------------

local DEFAULT_ACTIONBARS = {
	enabled = false,
	global  = {
		skinEnabled         = true,
		iconZoom            = 0.07,
		showBackdrop        = true,
		backdropAlpha       = 0.8,
		showBorders         = true,
		showGloss           = false,
		glossAlpha          = 0.6,
		showKeybinds        = true,
		hideEmptyKeybinds   = false,
		keybindFontSize     = 11,
		keybindColor        = { 1, 1, 1, 1 },
		keybindAnchor       = "TOPRIGHT",
		keybindOffsetX      = 0,
		keybindOffsetY      = 0,
		showMacroNames      = true,
		macroNameFontSize   = 10,
		macroNameColor      = { 1, 1, 1, 1 },
		macroNameAnchor     = "BOTTOM",
		macroNameOffsetX    = 0,
		macroNameOffsetY    = 0,
		showCounts          = true,
		countFontSize       = 14,
		countColor          = { 1, 1, 1, 1 },
		countAnchor         = "BOTTOMRIGHT",
		countOffsetX        = 0,
		countOffsetY        = 0,
		hideEmptySlots      = false,
		rangeIndicator      = true,
		rangeColor          = { 0.8, 0.1, 0.1, 1 },
		usabilityIndicator  = true,
		usabilityColor      = { 0.4, 0.4, 0.4, 1 },
		manaColor           = { 0.5, 0.5, 1.0, 1 },
		usabilityDesaturate = false,
		fastUsabilityUpdates = false,
		showTooltips        = true,
	},
	fade = {
		enabled            = false,
		fadeInDuration     = 0.2,
		fadeOutDuration    = 0.3,
		fadeOutAlpha       = 0,
		fadeOutDelay       = 0.5,
		alwaysShowInCombat = true,
		linkBars1to8       = false,
		disableBelowMaxLevel = true,
	},
	blizzardXP = {
		enabled            = false,
		fadeInDuration     = 0.2,
		fadeOutDuration    = 0.3,
		fadeOutAlpha       = 0,
		fadeOutDelay       = 0.5,
		maxAlpha           = 1,
		alwaysShowInCombat = true,
	},
	bars = {
		bar1    = { enabled = true,  overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil, hidePageArrow = false, hideArtwork = false },
		bar2    = { enabled = true,  overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		bar3    = { enabled = true,  overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		bar4    = { enabled = true,  overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		bar5    = { enabled = true,  overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		bar6    = { enabled = false, overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		bar7    = { enabled = false, overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		bar8    = { enabled = false, overrideEnabled = false, alwaysShow = false, fadeEnabled = nil, fadeOutAlpha = nil },
		pet     = { enabled = true,  alwaysShow = true,  fadeEnabled = nil, fadeOutAlpha = nil, hideArtwork = false },
		stance  = { enabled = true,  alwaysShow = true,  fadeEnabled = nil, fadeOutAlpha = nil, hideArtwork = false },
		-- NOTE: microbar and bags visibility not yet implemented (controlled by Edit Mode)
		microbar = { enabled = true,  alwaysShow = true },
		bags     = { enabled = true,  alwaysShow = true },
		extraActionButton = { enabled = true, scale = 1.0, hideArtwork = false, fadeEnabled = false, position = nil, offsetX = 0, offsetY = 0 },
		zoneAbility       = { enabled = true, scale = 1.0, hideArtwork = false, fadeEnabled = false, position = nil, offsetX = 0, offsetY = 0 },
	},
}

function addon:GetActionBarsSettings()
	if not (self.db and self.db.profile) then
		return DEFAULT_ACTIONBARS
	end
	if not self.db.profile.actionBars then
		self.db.profile.actionBars = {}
	end
	local cfg = self.db.profile.actionBars
	if cfg.enabled == nil then
		cfg.enabled = DEFAULT_ACTIONBARS.enabled
	end
	if not cfg.global then
		cfg.global = {}
	end
	if not cfg.fade then
		cfg.fade = {}
	end
	if not cfg.blizzardXP then
		cfg.blizzardXP = {}
	end
	if not cfg.bars then
		cfg.bars = {}
	end
	-- Ensure every bar key exists with its defaults
	local MergeDefaults = addon._core and addon._core.MergeDefaults
	if MergeDefaults then
		MergeDefaults(cfg.global, DEFAULT_ACTIONBARS.global)
		MergeDefaults(cfg.fade, DEFAULT_ACTIONBARS.fade)
		MergeDefaults(cfg.blizzardXP, DEFAULT_ACTIONBARS.blizzardXP)
		for barKey, barDefaults in pairs(DEFAULT_ACTIONBARS.bars) do
			if not cfg.bars[barKey] then
				cfg.bars[barKey] = {}
			end
			MergeDefaults(cfg.bars[barKey], barDefaults)
		end
	end
	return cfg
end

local function GetDB()
	return addon:GetActionBarsSettings()
end

local function GetGlobalSettings()
	local db = GetDB()
	return db and db.global
end

local function GetBarSettings(barKey)
	local db = GetDB()
	return db and db.bars and db.bars[barKey]
end

local function GetFadeSettings()
	local db = GetDB()
	return db and db.fade
end

local function GetBlizzardXPSettings()
	local db = GetDB()
	return db and db.blizzardXP
end

-- Expose on the module table so sub-modules can call them
ActionBars.GetDB             = GetDB
ActionBars.GetGlobalSettings = GetGlobalSettings
ActionBars.GetBarSettings    = GetBarSettings
ActionBars.GetFadeSettings   = GetFadeSettings


---------------------------------------------------------------------------
-- SHARED HELPERS
---------------------------------------------------------------------------

local function IsPlayerBelowMaxLevel()
	local level = UnitLevel("player")
	if not level or level <= 0 then return false end
	local maxLevel = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion()
		or MAX_PLAYER_LEVEL or 80
	if not maxLevel or maxLevel <= 0 then return false end
	return level < maxLevel
end

local function ShouldSuppressMouseoverHideForLevel()
	local fadeSettings = GetFadeSettings()
	return fadeSettings and fadeSettings.disableBelowMaxLevel and IsPlayerBelowMaxLevel()
end

local function UpdateLevelSuppressionState()
	local suppress = ShouldSuppressMouseoverHideForLevel()
	if ActionBars.levelSuppressionActive == suppress then return false end
	ActionBars.levelSuppressionActive = suppress
	return true
end

ActionBars.IsPlayerBelowMaxLevel           = IsPlayerBelowMaxLevel
ActionBars.ShouldSuppressMouseoverHideForLevel = ShouldSuppressMouseoverHideForLevel
ActionBars.UpdateLevelSuppressionState     = UpdateLevelSuppressionState

-- Font helper: uses SUF media settings via LibSharedMedia
local function GetFontSettings()
	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	local fontPath = "Fonts\\FRIZQT__.TTF"
	local outline = "OUTLINE"
	if addon.db and addon.db.profile then
		local media = addon.db.profile.media
		if media and media.font and LSM then
			fontPath = LSM:Fetch("font", media.font) or fontPath
		end
	end
	return fontPath, outline
end

ActionBars.GetFontSettings = GetFontSettings

-- Safe HasAction wrapper (Midnight secret-value protection)
local function SafeHasAction(action)
	if IS_MIDNIGHT then
		local ok, result = pcall(function()
			local has = HasAction(action)
			if has then return true end
			return false
		end)
		if not ok then return true end
		return result
	end
	return HasAction(action)
end

ActionBars.SafeHasAction = SafeHasAction

-- Determine bar key from button name
local function GetBarKeyFromButton(button)
	local name = button and button:GetName()
	if not name then return nil end
	if name:match("^ActionButton%d+$")              then return "bar1" end
	if name:match("^MultiBarBottomLeftButton%d+$")  then return "bar2" end
	if name:match("^MultiBarBottomRightButton%d+$") then return "bar3" end
	if name:match("^MultiBarRightButton%d+$")       then return "bar4" end
	if name:match("^MultiBarLeftButton%d+$")        then return "bar5" end
	if name:match("^MultiBar5Button%d+$")           then return "bar6" end
	if name:match("^MultiBar6Button%d+$")           then return "bar7" end
	if name:match("^MultiBar7Button%d+$")           then return "bar8" end
	if name:match("^PetActionButton%d+$")           then return "pet" end
	if name:match("^StanceButton%d+$")              then return "stance" end
	return nil
end

local function GetButtonIndex(button)
	local name = button and button:GetName()
	if not name then return nil end
	return tonumber(name:match("%d+$"))
end

ActionBars.GetBarKeyFromButton = GetBarKeyFromButton
ActionBars.GetButtonIndex      = GetButtonIndex

-- Get all buttons for a given bar key
local function GetBarButtons(barKey)
	local buttons = {}
	if barKey == "microbar" then
		if MicroMenu then
			for _, child in ipairs({ MicroMenu:GetChildren() }) do
				if child.IsObjectType and child:IsObjectType("Button") then
					buttons[#buttons + 1] = child
				end
			end
		end
		return buttons
	elseif barKey == "bags" then
		if MainMenuBarBackpackButton then
			buttons[#buttons + 1] = MainMenuBarBackpackButton
		end
		for i = 0, 3 do
			local slot = _G["CharacterBag" .. i .. "Slot"]
			if slot then buttons[#buttons + 1] = slot end
		end
		if CharacterReagentBag0Slot then
			buttons[#buttons + 1] = CharacterReagentBag0Slot
		end
		return buttons
	elseif barKey == "extraActionButton" then
		if ExtraActionBarFrame and ExtraActionBarFrame.button then
			buttons[#buttons + 1] = ExtraActionBarFrame.button
		end
		return buttons
	elseif barKey == "zoneAbility" then
		if ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer then
			for button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
				buttons[#buttons + 1] = button
			end
		end
		return buttons
	end
	local pattern = BUTTON_PATTERNS[barKey]
	local count   = BUTTON_COUNTS[barKey] or 12
	if not pattern then return buttons end
	for i = 1, count do
		local button = _G[string.format(pattern, i)]
		if button then buttons[#buttons + 1] = button end
	end
	return buttons
end

local function GetBarFrame(barKey)
	local frameName = BAR_FRAMES[barKey]
	local frame = frameName and _G[frameName]
	if not frame and barKey == "bar1" then
		frame = _G["MainMenuBar"]
	end
	return frame
end

ActionBars.GetBarButtons = GetBarButtons
ActionBars.GetBarFrame   = GetBarFrame

-- Get effective settings (global merged with per-bar overrides)
local OVERRIDE_KEYS = {
	"iconZoom", "showBackdrop", "backdropAlpha", "showGloss", "glossAlpha",
	"showKeybinds", "hideEmptyKeybinds", "keybindFontSize", "keybindColor",
	"keybindAnchor", "keybindOffsetX", "keybindOffsetY",
	"showMacroNames", "macroNameFontSize", "macroNameColor",
	"macroNameAnchor", "macroNameOffsetX", "macroNameOffsetY",
	"showCounts", "countFontSize", "countColor",
	"countAnchor", "countOffsetX", "countOffsetY",
}

local function GetEffectiveSettings(barKey)
	local global = GetGlobalSettings()
	if not global then return nil end
	local barSettings = GetBarSettings(barKey)
	if not barSettings or not barSettings.overrideEnabled then
		return global
	end
	local effective = {}
	for key, value in pairs(global) do
		effective[key] = value
	end
	for _, key in ipairs(OVERRIDE_KEYS) do
		if barSettings[key] ~= nil then
			effective[key] = barSettings[key]
		end
	end
	return effective
end

ActionBars.GetEffectiveSettings = GetEffectiveSettings

---------------------------------------------------------------------------
-- BAR VISIBILITY MANAGEMENT
---------------------------------------------------------------------------

local function ApplyBarVisibility()
	local db = GetDB()
	if not db or not db.bars then return end
	
	if addon.DebugLog then
		addon:DebugLog("ActionBars", "ApplyBarVisibility() called", 3)
	end
	
	-- Control individual bar visibility using WoW Settings system (12.0+)
	-- Bar 1 (MainActionBar) is always shown - it's the primary bar
	-- Bars 2-8 can be toggled via Settings
	local settingsMap = {
		bar2 = "PROXY_SHOW_ACTIONBAR_2",  -- MultiBarBottomLeft
		bar3 = "PROXY_SHOW_ACTIONBAR_3",  -- MultiBarBottomRight
		bar4 = "PROXY_SHOW_ACTIONBAR_4",  -- MultiBarRight
		bar5 = "PROXY_SHOW_ACTIONBAR_5",  -- MultiBarLeft
		bar6 = "PROXY_SHOW_ACTIONBAR_6",  -- MultiBar5
		bar7 = "PROXY_SHOW_ACTIONBAR_7",  -- MultiBar6
		bar8 = "PROXY_SHOW_ACTIONBAR_8",  -- MultiBar7
	}
	
	-- Apply settings if Settings API is available
	if Settings and Settings.SetValue then
		for barKey, settingName in pairs(settingsMap) do
			local barCfg = db.bars[barKey]
			local enabled = barCfg and barCfg.enabled ~= false
			-- Get the setting and set its value
			local setting = Settings.GetSetting(settingName)
			if setting then
				Settings.SetValue(settingName, enabled)
				if addon.DebugLog then
					addon:DebugLog("ActionBars", string.format("Set %s (%s) to %s", barKey, settingName, tostring(enabled)), 3)
				end
			else
				if addon.DebugLog then
					addon:DebugLog("ActionBars", string.format("Setting %s not found for %s", settingName, barKey), 3)
				end
			end
		end
	else
		if addon.DebugLog then
			addon:DebugLog("ActionBars", "Settings API not available", 2)
		end
	end
	
	-- Pet bar visibility
	local petCfg = db.bars.pet
	if petCfg and petCfg.enabled == false and PetActionBarFrame then
		PetActionBarFrame:Hide()
	elseif PetActionBarFrame and UnitExists("pet") then
		PetActionBarFrame:Show()
	end
	
	-- Stance bar visibility
	local stanceCfg = db.bars.stance
	if stanceCfg and stanceCfg.enabled == false and StanceBar then
		StanceBar:Hide()
	elseif StanceBar and GetNumShapeshiftForms() > 0 then
		StanceBar:Show()
	end
	
	-- Main action bar (bar1) artwork hiding
	local bar1Cfg = db.bars.bar1
	if bar1Cfg and MainActionBar then
		local hideArtwork = bar1Cfg.hideArtwork == true
		if MainActionBar.BorderArt then
			MainActionBar.BorderArt:SetShown(not hideArtwork)
		end
		if MainActionBar.EndCaps then
			MainActionBar.EndCaps:SetShown(not hideArtwork)
			if MainActionBar.UpdateEndCaps then
				MainActionBar:UpdateEndCaps(hideArtwork)
			end
		end
		if MainActionBar.hideBarArt ~= hideArtwork then
			MainActionBar.hideBarArt = hideArtwork
			if MainActionBar.UpdateDividers then
				MainActionBar:UpdateDividers()
			end
		end
		if hideArtwork then
			if MainActionBar.QuickKeybindBottomShadow then MainActionBar.QuickKeybindBottomShadow:Hide() end
			if MainActionBar.QuickKeybindRightShadow then MainActionBar.QuickKeybindRightShadow:Hide() end
			if MainActionBar.QuickKeybindGlowLarge then MainActionBar.QuickKeybindGlowLarge:Hide() end
			if MainActionBar.QuickKeybindGlowSmall then MainActionBar.QuickKeybindGlowSmall:Hide() end
			if addon.DebugLog then
				addon:DebugLog("ActionBars", "Hidden main action bar artwork", 3)
			end
		end
	end
	
	-- Hide artwork for pet/stance bars if requested
	if petCfg and petCfg.hideArtwork and PetActionBarFrame then
		for i = 1, PetActionBarFrame:GetNumChildren() do
			local child = select(i, PetActionBarFrame:GetChildren())
			if child and child:IsObjectType("Texture") then
				child:Hide()
			end
		end
		if addon.DebugLog then
			addon:DebugLog("ActionBars", "Hidden pet bar artwork", 3)
		end
	elseif petCfg and not petCfg.hideArtwork and PetActionBarFrame then
		for i = 1, PetActionBarFrame:GetNumChildren() do
			local child = select(i, PetActionBarFrame:GetChildren())
			if child and child:IsObjectType("Texture") then
				child:Show()
			end
		end
	end
	
	if stanceCfg and stanceCfg.hideArtwork and StanceBar then
		for i = 1, StanceBar:GetNumChildren() do
			local child = select(i, StanceBar:GetChildren())
			if child and child:IsObjectType("Texture") then
				child:Hide()
			end
		end
		if addon.DebugLog then
			addon:DebugLog("ActionBars", "Hidden stance bar artwork", 3)
		end
	elseif stanceCfg and not stanceCfg.hideArtwork and StanceBar then
		for i = 1, StanceBar:GetNumChildren() do
			local child = select(i, StanceBar:GetChildren())
			if child and child:IsObjectType("Texture") then
				child:Show()
			end
		end
	end
end

---------------------------------------------------------------------------
-- INITIALIZE / REFRESH
---------------------------------------------------------------------------

function ActionBars:Refresh()
	if not self.initialized then return end
	-- Clear skin cache and ghost textures so all buttons re-skin cleanly
	for button in pairs(self.skinnedButtons) do
		GetFrameState(button).skinKey = nil
		-- Clear any ghost textures from previous bar states
		if addon.ActionBarsSkinning then
			addon.ActionBarsSkinning.ClearButtonSkinningState(button)
		end
	end
	-- Apply bar visibility first
	ApplyBarVisibility()
	if addon.ActionBarsSkinning then
		addon.ActionBarsSkinning.SkinAllBars()
	end
	if addon.ActionBarsLayout then
		addon.ActionBarsLayout.ApplyBarLayoutSettings()
	end
	-- Page arrow
	local db = GetDB()
	if db and db.bars and db.bars.bar1 then
		if addon.ActionBarsLayout then
			addon.ActionBarsLayout.ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
		end
	end
end

function ActionBars:Initialize()
	if self.initialized then return end
	if InCombatLockdown() then
		self.pendingInitialize = true
		return
	end
	local db = GetDB()
	if not db or not db.enabled then
		if addon.DebugLog then
			addon:DebugLog("ActionBars", "Initialize() aborted: enabled = " .. tostring(db and db.enabled or "nil"), 2)
		end
		return
	end

	if addon.DebugLog then
		addon:DebugLog("ActionBars", "Initializing Action Bars system...", 2)
	end

	self.initialized = true
	self.levelSuppressionActive = ShouldSuppressMouseoverHideForLevel()

	-- Patch LibKeyBound for Midnight before anything touches buttons
	if addon.ActionBarsBindings then
		addon.ActionBarsBindings.PatchLibKeyBoundForMidnight()
	end

	-- Tooltip suppression hook
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
		local global = GetGlobalSettings()
		if not global or global.showTooltips ~= false then return end
		local name = parent and parent.GetName and parent:GetName()
		if name and (
			name:match("^ActionButton")     or
			name:match("^MultiBar")         or
			name:match("^PetActionButton")  or
			name:match("^StanceButton")     or
			name:match("^OverrideActionBar") or
			name:match("^ExtraActionButton")
		) then
			tooltip:Hide()
			tooltip:SetOwner(UIParent, "ANCHOR_NONE")
			tooltip:ClearLines()
		end
	end)

	-- Apply bar visibility
	ApplyBarVisibility()
	if addon.ActionBarsSkinning then
		addon.ActionBarsSkinning.SkinAllBars()
	end
	if addon.ActionBarsLayout then
		addon.ActionBarsLayout.ApplyBarLayoutSettings()
		if db.bars and db.bars.bar1 then
			addon.ActionBarsLayout.ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
		end
	end
	if addon.ActionBarsExtras then
		addon.ActionBarsExtras.InitializeExtraButtons()
		addon.ActionBarsExtras.SetupEditModeHooks()
	end
	
	if addon.DebugLog then
		addon:DebugLog("ActionBars", "Action Bars initialization complete.", 2)
	end
end

---------------------------------------------------------------------------
-- SUF INTEGRATION ENTRY POINTS
---------------------------------------------------------------------------

function addon:InitializeActionBars()
	self.ActionBars = ActionBars
	-- Register sub-module namespaces so Initialize can call them
	-- (populated by the sub-module files as they load)
	C_Timer.After(0.5, function()
		ActionBars:Initialize()
	end)
end

function addon:RefreshActionBars()
	--- Queue refresh for deferred execution if in combat lockdown ---
	addon:QueueOrRun(function()
		ActionBars:Refresh()
	end, {
		key = "ActionBars_Refresh",
		type = "ACTIONBARS_REFRESH",
		priority = "NORMAL",
	})
end

---------------------------------------------------------------------------
-- EVENT FRAME
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("CURSOR_CHANGED")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ACTIONBAR_SLOT_CHANGED" then
		--- Defer slot changed updates to ProtectedOperations queue ---
		addon:QueueOrRun(function()
			C_Timer.After(0.1, function()
				for barKey in pairs(BUTTON_PATTERNS) do
					local effectiveSettings = GetEffectiveSettings(barKey)
					if effectiveSettings then
						local buttons = GetBarButtons(barKey)
						for _, button in ipairs(buttons) do
							if addon.ActionBarsSkinning then
								addon.ActionBarsSkinning.UpdateButtonText(button, effectiveSettings)
							end
							if addon.ActionBarsLayout then
								addon.ActionBarsLayout.UpdateEmptySlotVisibility(button, effectiveSettings)
							end
						end
					end
				end
			end)
		end, {
			key = "ActionBars_SlotChanged",
			type = "ACTIONBAR_SLOT_CHANGED",
			priority = "HIGH",
		})

	elseif event == "CURSOR_CHANGED" then
		--- Handle drag preview immediately (not protected) ---
		local globalSettings = GetGlobalSettings()
		if globalSettings and globalSettings.hideEmptySlots then
			local cursorType = GetCursorInfo and GetCursorInfo()
			local shouldPreview = cursorType == "spell" or cursorType == "item"
				or cursorType == "macro" or cursorType == "petaction"
				or cursorType == "mount" or cursorType == "flyout"
			if shouldPreview ~= (ActionBars.dragPreviewActive or false) then
				ActionBars.dragPreviewActive = shouldPreview or nil
				if addon.ActionBarsLayout then
					for barKey in pairs(BUTTON_PATTERNS) do
						local effectiveSettings = GetEffectiveSettings(barKey)
						if effectiveSettings then
							local buttons = GetBarButtons(barKey)
							for _, button in ipairs(buttons) do
								local state = GetFrameState(button)
								if state.hiddenEmpty then
									local fadeState = ActionBars.fadeState and ActionBars.fadeState[barKey]
									local targetAlpha = fadeState and fadeState.currentAlpha or 1
									local DRAG_PREVIEW_ALPHA = 0.3
									button:SetAlpha(shouldPreview and (DRAG_PREVIEW_ALPHA * targetAlpha) or 0)
								end
							end
						end
					end
				end
			end
		end

	elseif event == "UPDATE_BINDINGS" then
		--- Defer binding text updates to ProtectedOperations queue ---
		addon:QueueOrRun(function()
			C_Timer.After(0.1, function()
				for barKey in pairs(BUTTON_PATTERNS) do
					local effectiveSettings = GetEffectiveSettings(barKey)
					if effectiveSettings and addon.ActionBarsSkinning then
						local buttons = GetBarButtons(barKey)
						for _, button in ipairs(buttons) do
							addon.ActionBarsSkinning.UpdateKeybindText(button, effectiveSettings)
						end
					end
				end
			end)
		end, {
			key = "ActionBars_UpdateBindings",
			type = "UPDATE_BINDINGS",
			priority = "NORMAL",
		})

	elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" then
		if UpdateLevelSuppressionState() then
			addon:RefreshActionBars()
		end
	end
end)
