local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.player = function(self)
	local oUF = self.oUF
	local player = oUF:Spawn("player", "SUF_Player")
	self:HookAnchor(player, "PlayerFrame")
end
