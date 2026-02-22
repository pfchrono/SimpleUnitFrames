local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.tot = function(self)
	local oUF = self.oUF
	local tot = oUF:Spawn("targettarget", "SUF_ToT")
	self:HookAnchor(tot, "TargetFrameToT")
end
