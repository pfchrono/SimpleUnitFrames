---Target unit frame spawner and initialization
---@class TargetUnitBuilder
---Unit builder for target unit frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register target unit frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
registry.target = function(self)
	local oUF = self.oUF
	---@type Frame Target unit frame reference
	local target = oUF:Spawn("target", "SUF_Target")
	self:HookAnchor(target, "TargetFrame")

	-- Phase 3.4: Apply reusable mixins for fading, dragging, theming
	if target and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("target")
		if unitSettings then
			Mixin(target, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if target.InitFader and unitSettings.fader then
				target:InitFader(unitSettings.fader)
			end
			if target.InitDraggable and unitSettings.draggable then
				target:InitDraggable(db, "Frame_target", unitSettings.draggable)
			end
			if target.InitTheme and unitSettings.theme then
				target:InitTheme(unitSettings.theme)
			end
		end
	end
end
