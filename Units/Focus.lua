local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.focus = function(self)
	local oUF = self.oUF
	local focus = oUF:Spawn("focus", "SUF_Focus")
	self:HookAnchor(focus, "FocusFrame")
end
