local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.target = function(self)
	local oUF = self.oUF
	local target = oUF:Spawn("target", "SUF_Target")
	self:HookAnchor(target, "TargetFrame")
end
