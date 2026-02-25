--[[
    SUF ActionBars - Mouseover fade engine, linked bars, and combat visibility.
    Ported from QUI ActionBars (QUI/modules/frames/actionbars.lua).
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

local function GetAB()
	return addon.ActionBars
end

---------------------------------------------------------------------------
-- LINKED BARS (1-8)
---------------------------------------------------------------------------

local LINKED_BAR_KEYS = { "bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "bar7", "bar8" }
local COMBAT_FADE_BARS = {
	bar1 = true, bar2 = true, bar3 = true, bar4 = true,
	bar5 = true, bar6 = true, bar7 = true, bar8 = true,
}



local function IsLinkedBar(barKey)
	for _, key in ipairs(LINKED_BAR_KEYS) do
		if key == barKey then return true end
	end
	return false
end

---------------------------------------------------------------------------
-- FADE STATE
---------------------------------------------------------------------------

local function GetBarFadeState(barKey)
	local ab = GetAB()
	if not ab then return {} end
	if not ab.fadeState[barKey] then
		ab.fadeState[barKey] = {
			isFading       = false,
			currentAlpha   = 1,
			targetAlpha    = 1,
			fadeStart      = 0,
			fadeStartAlpha = 1,
			fadeDuration   = 0.3,
			isMouseOver    = false,
			delayTimer     = nil,
			leaveCheckTimer = nil,
		}
	end
	return ab.fadeState[barKey]
end

---------------------------------------------------------------------------
-- SET BAR ALPHA
---------------------------------------------------------------------------

local function SetBarAlpha(barKey, alpha)
	local ab = GetAB()
	if not ab then return end

	local buttons = ab.GetBarButtons(barKey)
	local settings = ab.GetGlobalSettings()
	local hideEmptyEnabled = settings and settings.hideEmptySlots

	for _, button in ipairs(buttons) do
		local state = ab.GetFrameState(button)
		if hideEmptyEnabled and state.hiddenEmpty then
			local DRAG_PREVIEW_ALPHA = 0.3
			button:SetAlpha(ab.dragPreviewActive and (DRAG_PREVIEW_ALPHA * alpha) or 0)
		else
			button:SetAlpha(alpha)
		end
	end

	local barFrame = ab.GetBarFrame(barKey)
	if barFrame then
		barFrame:SetAlpha(alpha)
	end

	GetBarFadeState(barKey).currentAlpha = alpha
end

---------------------------------------------------------------------------
-- START BAR FADE (smooth easing OnUpdate)
---------------------------------------------------------------------------

local function StartBarFade(barKey, targetAlpha)
	local ab = GetAB()
	if not ab then return end

	local state        = GetBarFadeState(barKey)
	local fadeSettings = ab.GetFadeSettings()

	local duration = targetAlpha > state.currentAlpha
		and (fadeSettings and fadeSettings.fadeInDuration  or 0.2)
		or  (fadeSettings and fadeSettings.fadeOutDuration or 0.3)

	if math.abs(state.currentAlpha - targetAlpha) < 0.01 then
		state.isFading = false
		return
	end

	state.isFading       = true
	state.targetAlpha    = targetAlpha
	state.fadeStart      = GetTime()
	state.fadeStartAlpha = state.currentAlpha
	state.fadeDuration   = duration

	if not ab.fadeFrame then
		ab.fadeFrame = CreateFrame("Frame")
	end

	ab.fadeFrame:SetScript("OnUpdate", function(self, elapsed)
		local now      = GetTime()
		local anyFading = false

		for bKey, bState in pairs(ab.fadeState) do
			if bState.isFading then
				anyFading = true
				local elapsedTime = now - bState.fadeStart
				local progress    = math.min(elapsedTime / bState.fadeDuration, 1)
				local easedProgress = progress * (2 - progress)
				local alpha = bState.fadeStartAlpha +
					(bState.targetAlpha - bState.fadeStartAlpha) * easedProgress

				SetBarAlpha(bKey, alpha)

				if progress >= 1 then
					bState.isFading = false
					SetBarAlpha(bKey, bState.targetAlpha)
				end
			end
		end

		if not anyFading then
			self:SetScript("OnUpdate", nil)
			self:Hide()
		end
	end)
	ab.fadeFrame:Show()
end

---------------------------------------------------------------------------
-- MOUSE-OVER DETECTION HELPERS
---------------------------------------------------------------------------

local function IsMouseOverBar(barKey)
	local ab = GetAB()
	if not ab then return false end
	local barFrame = ab.GetBarFrame(barKey)
	if barFrame and barFrame:IsMouseOver() then return true end
	local buttons = ab.GetBarButtons(barKey)
	for _, button in ipairs(buttons) do
		if button:IsMouseOver() then return true end
	end
	return false
end

local function IsMouseOverAnyLinkedBar()
	for _, barKey in ipairs(LINKED_BAR_KEYS) do
		if IsMouseOverBar(barKey) then return true end
	end
	return false
end

---------------------------------------------------------------------------
-- LINKED BAR DIRECT HELPERS (called from enter/leave handlers)
---------------------------------------------------------------------------

local function ShowLinkedBarDirect(barKey)
	local ab = GetAB()
	if not ab then return end
	local barSettings  = ab.GetBarSettings(barKey)
	local fadeSettings = ab.GetFadeSettings()
	if not barSettings then return end
	if ab.ShouldSuppressMouseoverHideForLevel() then
		SetBarAlpha(barKey, 1)
		return
	end
	if barSettings.alwaysShow then return end
	local fadeEnabled = barSettings.fadeEnabled
	if fadeEnabled == nil then fadeEnabled = fadeSettings and fadeSettings.enabled end
	if not fadeEnabled then return end

	local state = GetBarFadeState(barKey)
	if state.delayTimer    then state.delayTimer:Cancel()    ; state.delayTimer    = nil end
	if state.leaveCheckTimer then state.leaveCheckTimer:Cancel() ; state.leaveCheckTimer = nil end
	StartBarFade(barKey, 1)
end

local function FadeLinkedBarDirect(barKey)
	local ab = GetAB()
	if not ab then return end
	local barSettings  = ab.GetBarSettings(barKey)
	local fadeSettings = ab.GetFadeSettings()
	if not barSettings then return end
	if ab.ShouldSuppressMouseoverHideForLevel() then
		SetBarAlpha(barKey, 1)
		return
	end
	if barSettings.alwaysShow then return end
	local fadeEnabled = barSettings.fadeEnabled
	if fadeEnabled == nil then fadeEnabled = fadeSettings and fadeSettings.enabled end
	if not fadeEnabled then return end

	local state = GetBarFadeState(barKey)
	state.isMouseOver = false

	local fadeOutAlpha = barSettings.fadeOutAlpha
	if fadeOutAlpha == nil then fadeOutAlpha = fadeSettings and fadeSettings.fadeOutAlpha or 0 end
	local delay = fadeSettings and fadeSettings.fadeOutDelay or 0.5

	if state.delayTimer then state.delayTimer:Cancel() end
	state.delayTimer = C_Timer.NewTimer(delay, function()
		state.delayTimer = nil
		if not IsMouseOverAnyLinkedBar() then
			StartBarFade(barKey, fadeOutAlpha)
		end
	end)
end

---------------------------------------------------------------------------
-- MOUSE ENTER / LEAVE
---------------------------------------------------------------------------

local function OnBarMouseEnter(barKey)
	local ab = GetAB()
	if not ab then return end
	local state        = GetBarFadeState(barKey)
	local fadeSettings = ab.GetFadeSettings()
	local barSettings  = ab.GetBarSettings(barKey)

	if ab.ShouldSuppressMouseoverHideForLevel() then
		SetBarAlpha(barKey, 1)
		return
	end
	if barSettings and barSettings.alwaysShow then return end

	local fadeEnabled = barSettings and barSettings.fadeEnabled
	if fadeEnabled == nil then fadeEnabled = fadeSettings and fadeSettings.enabled end
	if not fadeEnabled then return end

	state.isMouseOver = true

	if fadeSettings and fadeSettings.linkBars1to8 and IsLinkedBar(barKey) then
		for _, linkedKey in ipairs(LINKED_BAR_KEYS) do
			if linkedKey ~= barKey then
				ShowLinkedBarDirect(linkedKey)
			end
		end
	end

	if state.delayTimer    then state.delayTimer:Cancel()    ; state.delayTimer    = nil end
	if state.leaveCheckTimer then state.leaveCheckTimer:Cancel() ; state.leaveCheckTimer = nil end
	StartBarFade(barKey, 1)
end

local function OnBarMouseLeave(barKey)
	local ab = GetAB()
	if not ab then return end
	local state        = GetBarFadeState(barKey)
	local fadeSettings = ab.GetFadeSettings()
	local barSettings  = ab.GetBarSettings(barKey)



	if ab.ShouldSuppressMouseoverHideForLevel() then
		SetBarAlpha(barKey, 1)
		return
	end
	if barSettings and barSettings.alwaysShow then return end

	-- "Always show in combat" suppresses fade-out on main bars
	local isMainBar = barKey and barKey:match("^bar%d$")
	if isMainBar and InCombatLockdown() and fadeSettings and fadeSettings.alwaysShowInCombat then
		return
	end

	local fadeEnabled = barSettings and barSettings.fadeEnabled
	if fadeEnabled == nil then fadeEnabled = fadeSettings and fadeSettings.enabled end
	if not fadeEnabled then return end

	if state.leaveCheckTimer then state.leaveCheckTimer:Cancel() end

	state.leaveCheckTimer = C_Timer.NewTimer(0.066, function()
		state.leaveCheckTimer = nil
		if IsMouseOverBar(barKey) then return end

		if fadeSettings and fadeSettings.linkBars1to8 and IsLinkedBar(barKey) then
			if IsMouseOverAnyLinkedBar() then return end
			for _, linkedKey in ipairs(LINKED_BAR_KEYS) do
				FadeLinkedBarDirect(linkedKey)
			end
			return
		end

		state.isMouseOver = false

		local fadeOutAlpha = barSettings and barSettings.fadeOutAlpha
		if fadeOutAlpha == nil then fadeOutAlpha = fadeSettings and fadeSettings.fadeOutAlpha or 0 end
		local delay = fadeSettings and fadeSettings.fadeOutDelay or 0.5

		if state.delayTimer then state.delayTimer:Cancel() end
		state.delayTimer = C_Timer.NewTimer(delay, function()
			if not state.isMouseOver then
				local freshBarSettings  = ab.GetBarSettings(barKey)
				local freshFadeSettings = ab.GetFadeSettings()
				local freshAlpha = freshBarSettings and freshBarSettings.fadeOutAlpha
				if freshAlpha == nil then freshAlpha = freshFadeSettings and freshFadeSettings.fadeOutAlpha or 0 end
				StartBarFade(barKey, freshAlpha)
			end
			state.delayTimer = nil
		end)
	end)
end

---------------------------------------------------------------------------
-- HOOK FRAME FOR MOUSEOVER
---------------------------------------------------------------------------

local function HookFrameForMouseover(frame, barKey)
	if not frame then return end
	local ab = GetAB()
	if not ab then return end
	local state = ab.GetFrameState(frame)
	if state.mouseoverHooked then return end
	state.mouseoverHooked = true

	frame:HookScript("OnEnter", function() OnBarMouseEnter(barKey) end)
	frame:HookScript("OnLeave", function() OnBarMouseLeave(barKey) end)
end

---------------------------------------------------------------------------
-- SETUP BAR MOUSEOVER
---------------------------------------------------------------------------

local function SetupBarMouseover(barKey)
	local ab = GetAB()
	if not ab then return end
	local db = ab.GetDB()
	if not db or not db.enabled then return end

	local barSettings  = ab.GetBarSettings(barKey)
	local fadeSettings = ab.GetFadeSettings()

	-- Extra bars only fade if explicitly enabled
	if barKey == "extraActionButton" or barKey == "zoneAbility" then
		if not barSettings or barSettings.fadeEnabled ~= true then return end
	end

	local state = GetBarFadeState(barKey)

	if ab.ShouldSuppressMouseoverHideForLevel() then
		state.isFading = false
		if state.delayTimer    then state.delayTimer:Cancel()    ; state.delayTimer    = nil end
		if state.leaveCheckTimer then state.leaveCheckTimer:Cancel() ; state.leaveCheckTimer = nil end
		SetBarAlpha(barKey, 1)
		return
	end

	if barSettings and barSettings.alwaysShow then
		SetBarAlpha(barKey, 1)
		return
	end

	local fadeEnabled = barSettings and barSettings.fadeEnabled
	if fadeEnabled == nil then fadeEnabled = fadeSettings and fadeSettings.enabled end

	if not fadeEnabled then
		SetBarAlpha(barKey, 1)
		return
	end

	local fadeOutAlpha = barSettings and barSettings.fadeOutAlpha
	if fadeOutAlpha == nil then fadeOutAlpha = fadeSettings and fadeSettings.fadeOutAlpha or 0 end

	local barFrame = ab.GetBarFrame(barKey)
	if barFrame then HookFrameForMouseover(barFrame, barKey) end

	local buttons = ab.GetBarButtons(barKey)
	for _, button in ipairs(buttons) do
		HookFrameForMouseover(button, barKey)
	end

	state.targetAlpha = fadeOutAlpha
	state.isFading    = false
	if state.delayTimer    then state.delayTimer:Cancel()    ; state.delayTimer    = nil end
	if state.leaveCheckTimer then state.leaveCheckTimer:Cancel() ; state.leaveCheckTimer = nil end

	if not IsMouseOverBar(barKey) then
		SetBarAlpha(barKey, fadeOutAlpha)
	end
end

---------------------------------------------------------------------------
-- COMBAT FADE HANDLER
---------------------------------------------------------------------------

local combatFadeFrame = CreateFrame("Frame")
combatFadeFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFadeFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

combatFadeFrame:SetScript("OnEvent", function(self, event)
	local ab = GetAB()
	if not ab then return end
	local fadeSettings = ab.GetFadeSettings()
	if fadeSettings and fadeSettings.enabled and fadeSettings.alwaysShowInCombat and not ab.ShouldSuppressMouseoverHideForLevel() then
		if event == "PLAYER_REGEN_DISABLED" then
			for barKey in pairs(COMBAT_FADE_BARS) do
				local state = GetBarFadeState(barKey)
				if state.delayTimer    then state.delayTimer:Cancel()    ; state.delayTimer    = nil end
				if state.leaveCheckTimer then state.leaveCheckTimer:Cancel() ; state.leaveCheckTimer = nil end
				StartBarFade(barKey, 1)
			end
		else
			for barKey in pairs(COMBAT_FADE_BARS) do
				SetupBarMouseover(barKey)
			end
		end
	end

end)

---------------------------------------------------------------------------
-- EXPOSE ON ADDON
---------------------------------------------------------------------------

addon.ActionBarsFade = {
	SetupBarMouseover   = SetupBarMouseover,
	StartBarFade        = StartBarFade,
	SetBarAlpha         = SetBarAlpha,
	GetBarFadeState     = GetBarFadeState,
	OnBarMouseEnter     = OnBarMouseEnter,
	OnBarMouseLeave     = OnBarMouseLeave,
}
