local registry = _G.SimpleUnitFrames_UnitBuilders or {}
_G.SimpleUnitFrames_UnitBuilders = registry

registry.boss = function(self)
	local oUF = self.oUF
	local bossFrames = {}
	for index = 1, 5 do
		local boss = oUF:Spawn("boss" .. index, "SUF_Boss" .. index)
		bossFrames[index] = boss
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
