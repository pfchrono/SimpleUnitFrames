---Focus unit frame spawner and initialization
---@class FocusUnitBuilder
---Unit builder for focus unit frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register focus unit frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
registry.focus = function(self)
	local oUF = self.oUF
	---@type Frame Focus unit frame reference
	local focus = oUF:Spawn("focus", "SUF_Focus")
	self:HookAnchor(focus, "FocusFrame")

	-- Phase 3.4: Apply reusable mixins for fading, dragging, theming
	if focus and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("focus")
		if unitSettings then
			Mixin(focus, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if focus.InitFader and unitSettings.fader then
				focus:InitFader(unitSettings.fader)
			end
			if focus.InitDraggable and unitSettings.draggable then
				focus:InitDraggable(db, "Frame_focus", unitSettings.draggable)
			end
			if focus.InitTheme and unitSettings.theme then
				focus:InitTheme(unitSettings.theme)
			end
		end
	end
end
