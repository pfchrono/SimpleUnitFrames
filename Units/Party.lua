local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.party = function(self)
	local oUF = self.oUF
	if not self.allowGroupHeaders then
		return
	end
	if InCombatLockdown() or (self.IsEditModeActive and self:IsEditModeActive()) then
		return
	end
	if self.headers and self.headers.party then
		return
	end
	local showPlayerSolo = false
	local party = oUF:SpawnHeader("SUF_Party", nil, "party",
		"showParty", true,
		"showRaid", false,
		"showPlayer", showPlayerSolo,
		"showSolo", showPlayerSolo,
		"xOffset", 0,
		"yOffset", -8,
		"point", "TOP",
		"oUF-initialConfigFunction", [[
			self:SetWidth(160)
			self:SetHeight(26)
		]]
	)
	self:HookAnchor(party, "PartyFrame")
	self.headers.party = party
end
