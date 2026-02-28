---Party header frames spawner and initialization
---@class PartyUnitBuilder
---Unit builder for party group header frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register party header frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
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

	-- Phase 3.4: Apply reusable mixins to party header frame
	if party and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("party")
		if unitSettings then
			Mixin(party, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if party.InitFader and unitSettings.fader then
				party:InitFader(unitSettings.fader)
			end
			if party.InitDraggable and unitSettings.draggable then
				party:InitDraggable(db, "Frame_party", unitSettings.draggable)
			end
			if party.InitTheme and unitSettings.theme then
				party:InitTheme(unitSettings.theme)
			end
		end
	end
end
