---FrameFaderMixin: Reusable component for frame alpha fading (combat, hover, targeting states)
---Enables configurable alpha transitions based on gameplay context (in-combat, mouseover, target focus)
---@class FrameFaderMixin
FrameFaderMixin = {}

--- Initialize fader on a frame with settings and event listeners
---@param self any Frame to apply fader to (inherits mixin via CreateFromMixins)
---@param settings FaderSettings Configuration table with alpha/smoothing/state flags
function FrameFaderMixin:InitFader(settings)
	if not settings then
		return
	end

	self.faderSettings = {
		enabled = settings.enabled == true,
		minAlpha = math.max(0.05, math.min(1.0, tonumber(settings.minAlpha) or 0.45)),
		maxAlpha = math.max(0.05, math.min(1.0, tonumber(settings.maxAlpha) or 1.0)),
		smooth = math.max(0, math.min(1, tonumber(settings.smooth) or 0.2)),
		combat = settings.combat ~= false,
		hover = settings.hover ~= false,
		playerTarget = settings.playerTarget ~= false,
		actionTarget = settings.actionTarget == true,
		unitTarget = settings.unitTarget == true,
		casting = settings.casting == true,
	}

	-- Clamp min to max relationship
	if self.faderSettings.minAlpha > self.faderSettings.maxAlpha then
		self.faderSettings.minAlpha = self.faderSettings.maxAlpha
	end

	-- Initialize tracking state
	self.__fadingTo = nil
	self.__targetAlpha = self.faderSettings.maxAlpha
	self.__isHovering = false
	self.__isCasting = false
	self.__inCombat = InCombatLockdown and InCombatLockdown() or false

	-- Register combat and hover events
	if not self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	if not self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
	end

	-- Register mouseover events if hover is enabled
	if self.faderSettings.hover then
		self:SetScript("OnEnter", function(frame)
			frame.__isHovering = true
			frame:UpdateFaderAlpha()
		end)
		self:SetScript("OnLeave", function(frame)
			frame.__isHovering = false
			frame:UpdateFaderAlpha()
		end)
	end

	-- Initialize casting event listener if casting alpha is enabled
	if self.faderSettings.casting and self.unit then
		if not self:IsEventRegistered("UNIT_SPELLCAST_START") then
			self:RegisterEvent("UNIT_SPELLCAST_START")
		end
		if not self:IsEventRegistered("UNIT_SPELLCAST_STOP") then
			self:RegisterEvent("UNIT_SPELLCAST_STOP")
		end
		if not self:IsEventRegistered("UNIT_SPELLCAST_FAILED") then
			self:RegisterEvent("UNIT_SPELLCAST_FAILED")
		end
		if not self:IsEventRegistered("UNIT_SPELLCAST_INTERRUPTED") then
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		end
	end

	-- Initialize target watching
	self.__targetUnit = nil
	self:UpdateFaderAlpha()
end

--- Calculate target alpha based on current state (combat, hover, target)
---@param self any Frame with fader settings
---@return number Target alpha value (0.0-1.0)
function FrameFaderMixin:CalculateTargetAlpha()
	local settings = self.faderSettings
	local inCombat = InCombatLockdown and InCombatLockdown() or false

	-- Start with max alpha (fully visible)
	local targetAlpha = settings.maxAlpha

	-- Reduce to min alpha if conditions are met
	local shouldFade = false

	-- Combat state fade
	if settings.combat and not inCombat then
		shouldFade = true
	end

	-- Hover fade (reduce if NOT hovering)
	if settings.hover and not self.__isHovering then
		shouldFade = true
	end

	-- Player target fade
	if settings.playerTarget and self.unit and UnitIsUnit(self.unit, "player") then
		shouldFade = false -- Always show player frame
	end

	-- Unit target fade (show when unit is player's target)
	if settings.unitTarget and self.unit and UnitIsUnit(self.unit, "target") then
		shouldFade = false
	end

	-- Action target fade (show when unit has active casting/action)
	if settings.actionTarget and self.unit and self.__isCasting then
		shouldFade = false
	end

	if shouldFade then
		targetAlpha = settings.minAlpha
	end

	return targetAlpha
end

--- Update frame alpha with smooth interpolation toward target
---@param self any Frame to update
function FrameFaderMixin:UpdateFaderAlpha()
	if not self.faderSettings or not self.faderSettings.enabled then
		return
	end

	local targetAlpha = self:CalculateTargetAlpha()
	self.__targetAlpha = targetAlpha

	if not self.__fadeAnimation then
		local anim = self:CreateAnimationGroup()
		self.__fadeAnimation = anim
	end

	local anim = self.__fadeAnimation
	anim:Stop()
	anim:Clear()

	local startAlpha = self:GetAlpha()
	local duration = self.faderSettings.smooth

	if duration > 0 then
		-- Smooth fade animation
		local alpha = anim:CreateAnimation("Alpha")
		alpha:SetFromAlpha(startAlpha)
		alpha:SetToAlpha(targetAlpha)
		alpha:SetDuration(duration)
		anim:Play()
	else
		-- Immediate alpha change
		self:SetAlpha(targetAlpha)
	end
end

--- Handle event dispatch (combat, casting, etc)
---@param self any Frame receiving event
---@param event string Event name (PLAYER_REGEN_*, UNIT_SPELLCAST_*, etc)
---@param unit? string Unit ID for unit-specific events
function FrameFaderMixin:OnFaderEvent(event, unit)
	if not self.faderSettings or not self.faderSettings.enabled then
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		self.__inCombat = false
		self:UpdateFaderAlpha()
	elseif event == "PLAYER_REGEN_DISABLED" then
		self.__inCombat = true
		self:UpdateFaderAlpha()
	elseif event == "UNIT_SPELLCAST_START" then
		if unit and unit == self.unit then
			self.__isCasting = true
			self:UpdateFaderAlpha()
		end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if unit and unit == self.unit then
			self.__isCasting = false
			self:UpdateFaderAlpha()
		end
	end
end

--- Clear fader timers and reset alpha
---@param self any Frame to reset
function FrameFaderMixin:ResetFader()
	if self.__fadeAnimation then
		self.__fadeAnimation:Stop()
		self.__fadeAnimation:Clear()
	end
	self:SetAlpha(1.0)
	self.__fadingTo = nil
	self.__targetAlpha = 1.0
	self.__isHovering = false
	self.__isCasting = false
	self:UnregisterAllEvents()
end

--- Update fader settings (called when configuration changes)
---@param self any Frame with fader
---@param newSettings FaderSettings Updated settings table
function FrameFaderMixin:UpdateFaderSettings(newSettings)
	if not newSettings then
		return
	end

	self.faderSettings = {
		enabled = newSettings.enabled == true,
		minAlpha = math.max(0.05, math.min(1.0, tonumber(newSettings.minAlpha) or 0.45)),
		maxAlpha = math.max(0.05, math.min(1.0, tonumber(newSettings.maxAlpha) or 1.0)),
		smooth = math.max(0, math.min(1, tonumber(newSettings.smooth) or 0.2)),
		combat = newSettings.combat ~= false,
		hover = newSettings.hover ~= false,
		playerTarget = newSettings.playerTarget ~= false,
		actionTarget = newSettings.actionTarget == true,
		unitTarget = newSettings.unitTarget == true,
		casting = newSettings.casting == true,
	}

	if self.faderSettings.minAlpha > self.faderSettings.maxAlpha then
		self.faderSettings.minAlpha = self.faderSettings.maxAlpha
	end

	if self.faderSettings.enabled then
		self:UpdateFaderAlpha()
	else
		self:ResetFader()
	end
end

---@type FaderSettings
---@field enabled boolean Enable/disable fader
---@field minAlpha number Minimum alpha (0.05-1.0, default 0.45)
---@field maxAlpha number Maximum alpha (0.05-1.0, default 1.0)
---@field smooth number Fade duration in seconds (0-1, default 0.2)
---@field combat boolean Fade when out of combat (default true)
---@field hover boolean Fade when not hovering (default true)
---@field playerTarget boolean Always show player frame (default true)
---@field actionTarget boolean Show when casting (default false)
---@field unitTarget boolean Show when unit is target (default false)
---@field casting boolean Fade based on casting state (default false)
