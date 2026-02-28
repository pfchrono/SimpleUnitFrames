---Boss unit frames spawner and initialization
---@class BossUnitBuilder
---Unit builder for boss encounter unit frame spawning and anchoring

local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

---Register boss encounter frames builder
---@param self SimpleUnitFrames Addon instance
---@return void
registry.boss = function(self)
	local oUF = self.oUF
	local bossFrames = {}
	for index = 1, 5 do
		local boss = oUF:Spawn("boss" .. index, "SUF_Boss" .. index)
		bossFrames[index] = boss

		-- Phase 3.4: Apply reusable mixins to each boss frame
		if boss and self.GetUnitSettings then
			local unitSettings = self:GetUnitSettings("boss")
			if unitSettings then
				Mixin(boss, FrameFaderMixin, DraggableMixin, ThemeMixin)
				local db = self.db and self.db.profile and self.db.profile.positions or {}
				if boss.InitFader and unitSettings.fader then
					boss:InitFader(unitSettings.fader)
				end
				if boss.InitDraggable and unitSettings.draggable then
					boss:InitDraggable(db, "Frame_boss" .. index, unitSettings.draggable)
				end
				if boss.InitTheme and unitSettings.theme then
					boss:InitTheme(unitSettings.theme)
				end
			end
		end
	end

	if _G.BossTargetFrameContainer then
		bossFrames[1]:ClearAllPoints()
		bossFrames[1]:SetPoint("TOPLEFT", _G.BossTargetFrameContainer, "TOPLEFT")
		for index = 2, #bossFrames do
			bossFrames[index]:SetPoint("TOPLEFT", bossFrames[index - 1], "BOTTOMLEFT", 0, -8)
		end
	else
		bossFrames[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 800, -300)
		for index = 2, #bossFrames do
			bossFrames[index]:SetPoint("TOPLEFT", bossFrames[index - 1], "BOTTOMLEFT", 0, -8)
		end
	end
end
