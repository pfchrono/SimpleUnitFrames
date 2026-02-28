---Target of target unit frame spawner and initialization
---@class TotUnitBuilder
---Unit builder for targettarget unit frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register target-of-target unit frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
registry.tot = function(self)
	local oUF = self.oUF
	---@type Frame Target-of-target unit frame reference
	local tot = oUF:Spawn("targettarget", "SUF_ToT")
	self:HookAnchor(tot, "TargetFrameToT")
	-- Phase 3.4: Apply reusable mixins for fading, dragging, theming
	if tot and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("tot")
		if unitSettings then
			Mixin(tot, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if tot.InitFader and unitSettings.fader then
				tot:InitFader(unitSettings.fader)
			end
			if tot.InitDraggable and unitSettings.draggable then
				tot:InitDraggable(db, "Frame_tot", unitSettings.draggable)
			end
			if tot.InitTheme and unitSettings.theme then
				tot:InitTheme(unitSettings.theme)
			end
		end
	end
end
