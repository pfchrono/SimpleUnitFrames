---Frame positioning and mover system
---@class MoverSystem
---Manages frame positions, save/load, and drag-and-drop positioning

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

---Round numeric value to specified decimal places (local utility)
---@param value number|string Numeric value to round
---@param decimals? integer Number of decimal places (default: 0)
---@return number Rounded numeric value
local function RoundNumber(value, decimals)
	local n = tonumber(value) or 0
	local places = tonumber(decimals) or 0
	local mult = 10 ^ places
	return math.floor((n * mult) + 0.5) / mult
end

---Get mover position storage table
---@return table<string, table> Stored mover positions
function addon:GetMoverStore()
	if not (self.db and self.db.profile) then
		return {}
	end
	self.db.profile.movers = self.db.profile.movers or {}
	return self.db.profile.movers
end

---Apply saved mover position to a frame
---@param frame Frame Frame to position
---@param moverKey string Key for mover storage
---@param defaultPoint? table Default position {point, relativeTo, relativePoint, offsetX, offsetY}
---@return void
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

---Save current frame position to storage
---@param frame Frame Frame to save position from
---@param moverKey string Key for mover storage
---@return void
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
