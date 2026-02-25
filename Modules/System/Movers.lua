local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local function RoundNumber(value)
	local core = addon._core
	if core and core.RoundNumber then
		return core.RoundNumber(value, 0)
	end
	local number = tonumber(value) or 0
	return (number >= 0) and math.floor(number + 0.5) or math.ceil(number - 0.5)
end

function addon:GetMoverStore()
	if not (self.db and self.db.profile) then
		return {}
	end
	self.db.profile.movers = self.db.profile.movers or {}
	return self.db.profile.movers
end

function addon:ApplyStoredMoverPosition(frame, moverKey, defaultPoint)
	if not (frame and moverKey) then
		return
	end

	local store = self:GetMoverStore()
	local saved = store[moverKey]
	frame:ClearAllPoints()
	if type(saved) == "table" and saved[1] and saved[3] then
		local rel = saved[2] and _G[saved[2]] or UIParent
		frame:SetPoint(saved[1], rel, saved[3], tonumber(saved[4]) or 0, tonumber(saved[5]) or 0)
		return
	end

	if type(defaultPoint) == "table" and defaultPoint[1] then
		local rel = defaultPoint[2] and _G[defaultPoint[2]] or defaultPoint[2] or UIParent
		frame:SetPoint(defaultPoint[1], rel, defaultPoint[3] or defaultPoint[1], tonumber(defaultPoint[4]) or 0, tonumber(defaultPoint[5]) or 0)
	else
		frame:SetPoint("CENTER")
	end
end

function addon:SaveMoverPosition(frame, moverKey)
	if not (frame and moverKey) then
		return
	end
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	if not point then
		return
	end
	local relativeName = (relativeTo and relativeTo.GetName and relativeTo:GetName()) or "UIParent"
	self:GetMoverStore()[moverKey] = {
		point,
		relativeName,
		relativePoint or point,
		RoundNumber(x or 0),
		RoundNumber(y or 0),
	}
end
