---Raid header frames spawner and initialization
---@class RaidUnitBuilder
---Unit builder for raid group header frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register raid header frame builder
---@param self SimpleUnitFrames Addon instance
---@return void
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
	local raid = oUF:SpawnHeader("SUF_Raid", nil,
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

	-- Phase 3.4: Apply reusable mixins to raid header frame
	if raid and self.GetUnitSettings then
		local unitSettings = self:GetUnitSettings("raid")
		if unitSettings then
			Mixin(raid, FrameFaderMixin, DraggableMixin, ThemeMixin)
			local db = self.db and self.db.profile and self.db.profile.positions or {}
			if raid.InitFader and unitSettings.fader then
				raid:InitFader(unitSettings.fader)
			end
			if raid.InitDraggable and unitSettings.draggable then
				raid:InitDraggable(db, "Frame_raid", unitSettings.draggable)
			end
			if raid.InitTheme and unitSettings.theme then
				raid:InitTheme(unitSettings.theme)
			end
		end
	end
end
