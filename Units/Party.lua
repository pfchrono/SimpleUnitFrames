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
	local partyCfg = (self.db and self.db.profile and self.db.profile.party) or {}
	local showPlayerSolo = partyCfg.showPlayerWhenSolo == true
	local showPlayerInParty = partyCfg.showPlayerInParty ~= false
	local showPlayer = showPlayerInParty or showPlayerSolo
	local yOffset = (self.GetPartyHeaderYOffset and self:GetPartyHeaderYOffset()) or -16
	local party = oUF:SpawnHeader("SUF_Party", nil,
		"showParty", true,
		"showRaid", false,
		"showPlayer", showPlayer,
		"showSolo", showPlayerSolo,
		"xOffset", 0,
		"yOffset", yOffset,
		"point", "TOP",
		"oUF-initialConfigFunction", [[
			self:SetWidth(160)
			self:SetHeight(26)
		]]
	)
	self:HookAnchor(party, "PartyFrame")
	self.headers.party = party
end
