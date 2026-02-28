---Pet unit frame spawner and initialization
---@class PetUnitBuilder
---Unit builder for pet unit frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register pet unit frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
registry.pet = function(self)
	local oUF = self.oUF
	---@type Frame Pet unit frame reference
	local pet = oUF:Spawn("pet", "SUF_Pet")
	self:HookAnchor(pet, "PetFrame")

	-- Phase 3.4: Apply reusable mixins for fading, dragging, theming
	if pet and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("pet")
		if unitSettings then
			Mixin(pet, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if pet.InitFader and unitSettings.fader then
				pet:InitFader(unitSettings.fader)
			end
			if pet.InitDraggable and unitSettings.draggable then
				pet:InitDraggable(db, "Frame_pet", unitSettings.draggable)
			end
			if pet.InitTheme and unitSettings.theme then
				pet:InitTheme(unitSettings.theme)
			end
		end
	end
end
