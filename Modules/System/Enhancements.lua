local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local function CopyTableDeep(source)
	local core = addon._core
	if core and core.CopyTableDeep then
		return core.CopyTableDeep(source)
	end
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = (type(value) == "table") and CopyTableDeep(value) or value
	end
	return copy
end

local function RoundNumber(value)
	local core = addon._core
	if core and core.RoundNumber then
		return core.RoundNumber(value, 0)
	end
	local number = tonumber(value) or 0
	return (number >= 0) and math.floor(number + 0.5) or math.ceil(number - 0.5)
end

function addon:GetEnhancementSettings()
	local core = self._core
	local defaults = core and core.defaults
	local fallback = defaults and defaults.profile and defaults.profile.enhancements or {}
	if not (self.db and self.db.profile) then
		return fallback
	end
	self.db.profile.enhancements = self.db.profile.enhancements or CopyTableDeep(fallback)
	return self.db.profile.enhancements
end

function addon:SnapFrameToPixelGrid(frame)
	if not frame or not frame.GetPoint then
		return
	end
	local cfg = self:GetEnhancementSettings()
	if not cfg or cfg.pixelSnapWindows == false then
		return
	end
	local p, rel, rp, x, y = frame:GetPoint(1)
	if not (p and rel and rp) then
		return
	end
	x = RoundNumber(tonumber(x) or 0)
	y = RoundNumber(tonumber(y) or 0)
	frame:ClearAllPoints()
	frame:SetPoint(p, rel, rp, x, y)
end
