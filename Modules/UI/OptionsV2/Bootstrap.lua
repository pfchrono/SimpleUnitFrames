local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

function addon:ShowOptionsV2()
	local cfg = self:EnsureOptionsV2Config()
	local frame = self:CreateOptionsV2Window()
	if self.PrepareWindowForDisplay then
		self:PrepareWindowForDisplay(frame)
	end
	frame:Show()
	if self.PlayWindowOpenAnimation then
		self:PlayWindowOpenAnimation(frame)
	end
	frame:SetPage(cfg.lastPage or "global")
end

