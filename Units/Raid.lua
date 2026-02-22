local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.raid = function(self)
	local oUF = self.oUF
	if not self.allowGroupHeaders then
		return
	end
	if InCombatLockdown() or (self.IsEditModeActive and self:IsEditModeActive()) then
		return
	end
	if self.headers and self.headers.raid then
		return
	end
	local raid = oUF:SpawnHeader("SUF_Raid", nil, "raid",
		"showRaid", true,
		"showParty", false,
		"showPlayer", false,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"maxColumns", 5,
		"unitsPerColumn", 5,
		"columnSpacing", 6,
		"columnAnchorPoint", "LEFT",
		"xOffset", 0,
		"yOffset", -6,
		"point", "TOP",
		"oUF-initialConfigFunction", [[
			self:SetWidth(120)
			self:SetHeight(22)
		]]
	)
	self:HookAnchor(raid, "CompactRaidFrameContainer")
	self.headers.raid = raid
end
