--[[
    SUF ActionBars - Layout: empty slots, button lock, page arrows, usability/range.
    Ported from QUI ActionBars (QUI/modules/frames/actionbars.lua).
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

local DRAG_PREVIEW_ALPHA = 0.3
local RANGE_CHECK_INTERVAL_NORMAL = 0.25
local RANGE_CHECK_INTERVAL_FAST   = 0.05

local function GetAB()
	return addon.ActionBars
end

---------------------------------------------------------------------------
-- SAFE API WRAPPERS (Midnight secret-value protection)
---------------------------------------------------------------------------

-- Midnight (WoW 12.0.0+) detection
-- Per API verification workflow against wow-ui-source:
--   * GetBuildInfo() 4th return value is the numeric build number
--   * Build >= 120000 corresponds to 12.0.0 ("Midnight") on all branches
-- If Blizzard changes build numbering in the future, update this threshold
-- and cross-check against Blizzard_*/ reference UI code.
local MIDNIGHT_BUILD_THRESHOLD = 120000

local function IsMidnightClient()
	local ok, _, _, build = pcall(GetBuildInfo)
	if not ok or not build then
		return false
	end
	local numericBuild = tonumber(build)
	if not numericBuild then
		return false
	end
	return numericBuild >= MIDNIGHT_BUILD_THRESHOLD
end

local IS_MIDNIGHT = IsMidnightClient()
local function SafeIsActionInRange(action)
	if IS_MIDNIGHT then
		local ok, result = pcall(function()
			local inRange = IsActionInRange(action)
			if inRange == false then return false end
			if inRange == true  then return true  end
			return nil
		end)
		if not ok then return nil end
		return result
	end
	return IsActionInRange(action)
end

local function SafeIsUsableAction(action)
	if IS_MIDNIGHT then
		local ok, isUsable, notEnoughMana = pcall(function()
			local usable, noMana = IsUsableAction(action)
			local boolUsable = usable  and true or false
			local boolNoMana = noMana  and true or false
			return boolUsable, boolNoMana
		end)
		if not ok then return true, false end
		return isUsable, notEnoughMana
	end
	return IsUsableAction(action)
end

---------------------------------------------------------------------------
-- EMPTY SLOT VISIBILITY
---------------------------------------------------------------------------

local function UpdateEmptySlotVisibility(button, settings)
	if not settings then return end
	local ab = GetAB()
	if not ab then return end
	local state = ab.GetFrameState(button)

	local barKey = ab.GetBarKeyFromButton(button)
	local fadeState = barKey and ab.fadeState and ab.fadeState[barKey]
	local targetAlpha = fadeState and fadeState.currentAlpha or 1

	if not settings.hideEmptySlots then
		if state.hiddenEmpty then
			button:SetAlpha(targetAlpha)
			state.hiddenEmpty = nil
		end
		return
	end

	if button.action then
		local hasAction = ab.SafeHasAction(button.action)
		if hasAction then
			button:SetAlpha(targetAlpha)
			state.hiddenEmpty = nil
		else
			if ab.dragPreviewActive then
				button:SetAlpha(DRAG_PREVIEW_ALPHA * targetAlpha)
			else
				button:SetAlpha(0)
			end
			state.hiddenEmpty = true
		end
	end
end

---------------------------------------------------------------------------
-- BUTTON LOCK
---------------------------------------------------------------------------

local function ApplyButtonLock()
	-- Read from Blizzard's CVar; SUF never overwrites it.
	local locked = GetCVar and GetCVar("lockActionBars") == "1"
	LOCK_ACTIONBAR = locked and "1" or "0"
end

---------------------------------------------------------------------------
-- USABILITY & RANGE INDICATORS
---------------------------------------------------------------------------

local usabilityCheckFrame = nil

local function GetUpdateInterval()
	local ab = GetAB()
	local settings = ab and ab.GetGlobalSettings()
	if settings and settings.fastUsabilityUpdates then
		return RANGE_CHECK_INTERVAL_FAST
	end
	return RANGE_CHECK_INTERVAL_NORMAL
end

local function UpdateButtonUsability(button, settings)
	if not settings then return end
	if not button.action then return end
	local ab = GetAB()
	if not ab then return end
	local state = ab.GetFrameState(button)
	local icon = button.icon or button.Icon
	if not icon then return end

	if not settings.rangeIndicator and not settings.usabilityIndicator then
		if state.tinted then
			icon:SetVertexColor(1, 1, 1, 1)
			icon:SetDesaturated(false)
			state.tinted = nil
		end
		return
	end

	-- Priority 1: out-of-range
	if settings.rangeIndicator then
		local inRange = SafeIsActionInRange(button.action)
		if inRange == false then
			local c = settings.rangeColor
			icon:SetVertexColor(c and c[1] or 0.8, c and c[2] or 0.1, c and c[3] or 0.1, c and c[4] or 1)
			icon:SetDesaturated(false)
			state.tinted = "range"
			return
		end
	end

	-- Priority 2: usability
	if settings.usabilityIndicator then
		local isUsable, notEnoughMana = SafeIsUsableAction(button.action)
		if notEnoughMana then
			local c = settings.manaColor
			icon:SetVertexColor(c and c[1] or 0.5, c and c[2] or 0.5, c and c[3] or 1.0, c and c[4] or 1)
			icon:SetDesaturated(false)
			state.tinted = "mana"
			return
		elseif not isUsable then
			if settings.usabilityDesaturate then
				icon:SetDesaturated(true)
				icon:SetVertexColor(0.6, 0.6, 0.6, 1)
			else
				local c = settings.usabilityColor
				icon:SetVertexColor(c and c[1] or 0.4, c and c[2] or 0.4, c and c[3] or 0.4, c and c[4] or 1)
				icon:SetDesaturated(false)
			end
			state.tinted = "unusable"
			return
		end
	end

	-- Normal state
	if state.tinted then
		icon:SetVertexColor(1, 1, 1, 1)
		icon:SetDesaturated(false)
		state.tinted = nil
	end
end

local function UpdateAllButtonUsability()
	local ab = GetAB()
	if not ab then return end
	local globalSettings = ab.GetGlobalSettings()
	if not globalSettings then return end
	if not globalSettings.rangeIndicator and not globalSettings.usabilityIndicator then return end
	for i = 1, 8 do
		local barKey = "bar" .. i
		local buttons = ab.GetBarButtons(barKey)
		for _, button in ipairs(buttons) do
			if button:IsVisible() then
				UpdateButtonUsability(button, globalSettings)
			end
		end
	end
end

local function ResetAllButtonTints()
	local ab = GetAB()
	if not ab then return end
	for i = 1, 8 do
		local barKey = "bar" .. i
		local buttons = ab.GetBarButtons(barKey)
		for _, button in ipairs(buttons) do
			local state = ab.GetFrameState(button)
			local icon = button.icon or button.Icon
			if icon and state.tinted then
				icon:SetVertexColor(1, 1, 1, 1)
				icon:SetDesaturated(false)
				state.tinted = nil
			end
		end
	end
end

local usabilityUpdatePending = false
local function ScheduleUsabilityUpdate()
	if usabilityUpdatePending then return end
	usabilityUpdatePending = true
	C_Timer.After(0.05, function()
		usabilityUpdatePending = false
		UpdateAllButtonUsability()
	end)
end

local function UpdateUsabilityPolling()
	local ab = GetAB()
	if not ab then return end
	local settings = ab.GetGlobalSettings()
	local usabilityEnabled = settings and settings.usabilityIndicator
	local rangeEnabled     = settings and settings.rangeIndicator

	if not usabilityCheckFrame then
		usabilityCheckFrame = CreateFrame("Frame")
		usabilityCheckFrame.elapsed = 0
	end

	if usabilityEnabled or rangeEnabled then
		usabilityCheckFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
		usabilityCheckFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		usabilityCheckFrame:RegisterEvent("SPELL_UPDATE_USABLE")
		usabilityCheckFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
		usabilityCheckFrame:RegisterEvent("UNIT_POWER_UPDATE")
		usabilityCheckFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
		usabilityCheckFrame:SetScript("OnEvent", function()
			ScheduleUsabilityUpdate()
		end)
		ScheduleUsabilityUpdate()
	else
		usabilityCheckFrame:UnregisterAllEvents()
		usabilityCheckFrame:SetScript("OnEvent", nil)
	end

	if rangeEnabled then
		usabilityCheckFrame:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed < GetUpdateInterval() then return end
			self.elapsed = 0
			UpdateAllButtonUsability()
		end)
		usabilityCheckFrame:Show()
	else
		usabilityCheckFrame:SetScript("OnUpdate", nil)
		usabilityCheckFrame.elapsed = 0
		if not usabilityEnabled then
			usabilityCheckFrame:Hide()
			ResetAllButtonTints()
		end
	end
end

---------------------------------------------------------------------------
-- PAGE ARROW VISIBILITY
---------------------------------------------------------------------------

local pageArrowShowHooked = false

local function ApplyPageArrowVisibility(hide)
	local pageNum = MainActionBar and MainActionBar.ActionBarPageNumber
	if not pageNum then return end
	if hide then
		pageNum:Hide()
		if not pageArrowShowHooked then
			pageArrowShowHooked = true
			hooksecurefunc(pageNum, "Show", function(self)
				local ab = GetAB()
				local db = ab and ab.GetDB()
				if db and db.bars and db.bars.bar1 and db.bars.bar1.hidePageArrow then
					self:Hide()
				end
			end)
		end
	else
		pageNum:Show()
	end
end

---------------------------------------------------------------------------
-- APPLY ALL LAYOUT SETTINGS
---------------------------------------------------------------------------

local function ApplyBarLayoutSettings()
	ApplyButtonLock()
	UpdateUsabilityPolling()

	local ab = GetAB()
	if not ab then return end
	local settings = ab.GetGlobalSettings()
	if settings then
		for barKey in pairs(ab.BUTTON_PATTERNS) do
			local buttons = ab.GetBarButtons(barKey)
			for _, button in ipairs(buttons) do
				UpdateEmptySlotVisibility(button, settings)
			end
		end
	end
end

---------------------------------------------------------------------------
-- EXPOSE ON ADDON
---------------------------------------------------------------------------

addon.ActionBarsLayout = {
	UpdateEmptySlotVisibility  = UpdateEmptySlotVisibility,
	ApplyButtonLock            = ApplyButtonLock,
	UpdateButtonUsability      = UpdateButtonUsability,
	UpdateUsabilityPolling     = UpdateUsabilityPolling,
	ApplyPageArrowVisibility   = ApplyPageArrowVisibility,
	ApplyBarLayoutSettings     = ApplyBarLayoutSettings,
	ResetAllButtonTints        = ResetAllButtonTints,
}
