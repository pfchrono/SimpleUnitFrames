local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.pet = function(self)
	local oUF = self.oUF
	local pet = oUF:Spawn("pet", "SUF_Pet")
	self:HookAnchor(pet, "PetFrame")
end
