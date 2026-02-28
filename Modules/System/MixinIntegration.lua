---MixinIntegration: Integration helpers for applying reusable mixins to unit frames
---Provides utilities for composing unit frames with FrameFaderMixin, DraggableMixin, ThemeMixin
---@class MixinIntegration

local function ApplyUnitFrameMixins(frame, unitType, db, settings)
	if not frame then
		return
	end

	-- Apply FrameFaderMixin for combat/hover alpha behavior
	if settings and settings.fader and settings.fader.enabled then
		Mixin(frame, FrameFaderMixin)
		local faderSettings = settings.fader
		frame:InitFader(faderSettings)
		
		-- Wire fader events into frame's event handler
		if frame:GetScript("OnEvent") then
			local originalHandler = frame:GetScript("OnEvent")
			frame:SetScript("OnEvent", function(self, event, ...)
				if event:match("^PLAYER_REGEN") or event:match("^UNIT_SPELLCAST") then
					self:OnFaderEvent(event, ...)
				end
				originalHandler(self, event, ...)
			end)
		end
	end

	-- Apply DraggableMixin for frame movement and position persistence
	if settings and settings.draggable and settings.draggable.enabled then
		Mixin(frame, DraggableMixin)
		local storageKey = "Frame_" .. (unitType or "unknown")
		frame:InitDraggable(db, storageKey, settings.draggable)
	end

	-- Apply ThemeMixin for color/font/texture theming
	if settings and settings.theme then
		Mixin(frame, ThemeMixin)
		frame:InitTheme(settings.theme)
	end
end

--- Register unit frame for mixin integration and event routing
---@param addon any SimpleUnitFrames addon instance
---@param frame any Unit frame to integrate
---@param unitType string Unit type (e.g., "player", "target", "party1")
function RegisterUnitFrameMixins(addon, frame, unitType)
	if not (addon and frame and unitType) then
		return
	end

	local db = addon.db and addon.db.profile and addon.db.profile.positions or {}
	local unitSettings = addon:GetUnitSettings(unitType) or {}

	ApplyUnitFrameMixins(frame, unitType, db, unitSettings)

	-- Register for settings update callbacks
	if addon.EventBus and addon.EventBus.RegisterCallback then
		addon.EventBus:RegisterCallback("UnitSettingsChanged", function(_, changedUnitType)
			if changedUnitType == unitType then
				ApplyUnitFrameMixins(frame, unitType, db, addon:GetUnitSettings(unitType))
			end
		end)
	end
end

--- Update mixins when settings change (called from OptionsWindow or addon settings)
---@param addon any SimpleUnitFrames addon instance
---@param frame any Unit frame to update
---@param unitType string Unit type
function UpdateUnitFrameMixins(addon, frame, unitType)
	if not (addon and frame and unitType) then
		return
	end

	local unitSettings = addon:GetUnitSettings(unitType) or {}

	-- Update FrameFaderMixin settings
	if frame.UpdateFaderSettings then
		frame:UpdateFaderSettings(unitSettings.fader)
	end

	-- Update DraggableMixin settings
	if frame.UpdateDraggableSettings then
		frame:UpdateDraggableSettings(unitSettings.draggable)
	end

	-- Update ThemeMixin
	if frame.ApplyTheme and unitSettings.theme then
		frame:InitTheme(unitSettings.theme)
		frame:ApplyTheme()
	end
end

--- Remove all mixins from a frame (reset to base frame behavior)
---@param frame any Unit frame to clean
function RemoveUnitFrameMixins(frame)
	if not frame then
		return
	end

	-- Remove fader timers
	if frame.ResetFader then
		frame:ResetFader()
	end

	-- Remove draggable handlers
	if frame.SetDraggingEnabled then
		frame:SetDraggingEnabled(false)
	end

	-- Reset frame to default alpha
	frame:SetAlpha(1.0)
end

return {
	ApplyUnitFrameMixins = ApplyUnitFrameMixins,
	RegisterUnitFrameMixins = RegisterUnitFrameMixins,
	UpdateUnitFrameMixins = UpdateUnitFrameMixins,
	RemoveUnitFrameMixins = RemoveUnitFrameMixins,
}
