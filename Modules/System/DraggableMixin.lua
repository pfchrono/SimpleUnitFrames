---DraggableMixin: Reusable component for draggable frames with position persistence
---Enables frame dragging and automatic save/restore of position to database
---@class DraggableMixin

local function RoundNumber(value, decimals)
	local n = tonumber(value) or 0
	local places = tonumber(decimals) or 0
	local mult = 10 ^ places
	return math.floor((n * mult) + 0.5) / mult
end

DraggableMixin = {}

--- Initialize draggable behavior on a frame with persistent position storage
---@param self any Frame to make draggable (inherits mixin via CreateFromMixins)
---@param db table Database table for storing frame positions (should be saved via AceDB)
---@param frameName string Key name used in database for position storage
---@param settings? DraggableSettings Optional configuration (inset, clampToScreen, etc)
function DraggableMixin:InitDraggable(db, frameName, settings)
	if not db or not frameName then
		return
	end

	settings = settings or {}

	self.draggableDb = db
	self.draggableFrameName = frameName
	self.draggableSettings = {
		enabled = settings.enabled ~= false,
		clampToScreen = settings.clampToScreen ~= false,
		inset = tonumber(settings.inset) or 10,
		constraints = settings.constraints or nil, -- Optional parent frame for constraining
	}

	-- Apply draggable properties to frame
	self:SetMovable(true)
	self:SetClampedToScreen(self.draggableSettings.clampToScreen)
	self:RegisterForDrag("LeftButton")

	-- Set up drag handlers
	self:SetScript("OnDragStart", function(frame)
		if frame.draggableSettings.enabled then
			frame:StartMoving()
		end
	end)

	self:SetScript("OnDragStop", function(frame)
		frame:StopMovingOrSizing()
		frame:SavePosition()
	end)

	-- Load previously saved position
	self:LoadPosition()
end

--- Load frame position from database and apply to frame
---@param self any Draggable frame to restore
function DraggableMixin:LoadPosition()
	if not self.draggableDb or not self.draggableFrameName then
		return
	end

	self.draggableDb[self.draggableFrameName] = self.draggableDb[self.draggableFrameName] or {}
	local posData = self.draggableDb[self.draggableFrameName]

	-- Load position if data exists
	if posData.point and posData.relativePoint then
		local x = tonumber(posData.x) or 0
		local y = tonumber(posData.y) or 0

		self:ClearAllPoints()
		self:SetPoint(posData.point, UIParent, posData.relativePoint, x, y)
	else
		-- Initialize default position
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		self:SavePosition()
	end
end

--- Save current frame position to database
---@param self any Draggable frame to save
function DraggableMixin:SavePosition()
	if not self.draggableDb or not self.draggableFrameName then
		return
	end

	self.draggableDb[self.draggableFrameName] = self.draggableDb[self.draggableFrameName] or {}
	local posData = self.draggableDb[self.draggableFrameName]

	-- Get frame position
	local point, relativeTo, relativePoint, x, y = self:GetPoint(1)

	if point then
		posData.point = point
		posData.relativePoint = relativePoint
		posData.x = RoundNumber(x, 2)
		posData.y = RoundNumber(y, 2)
	end
end

--- Set frame to default center position and clear saved data
---@param self any Draggable frame to reset
function DraggableMixin:ResetPosition()
	if self.draggableDb and self.draggableFrameName then
		self.draggableDb[self.draggableFrameName] = nil
	end

	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

--- Enable or disable dragging
---@param self any Draggable frame
---@param enabled boolean True to enable dragging, false to disable
function DraggableMixin:SetDraggingEnabled(enabled)
	if not self.draggableSettings then
		return
	end

	self.draggableSettings.enabled = enabled ~= false
	self:SetMovable(self.draggableSettings.enabled)
end

--- Update draggable settings (called when configuration changes)
---@param self any Draggable frame
---@param newSettings DraggableSettings Updated settings table
function DraggableMixin:UpdateDraggableSettings(newSettings)
	if not newSettings or not self.draggableSettings then
		return
	end

	self.draggableSettings.enabled = newSettings.enabled ~= false
	self.draggableSettings.clampToScreen = newSettings.clampToScreen ~= false
	self.draggableSettings.inset = tonumber(newSettings.inset) or 10

	self:SetMovable(self.draggableSettings.enabled)
	self:SetClampedToScreen(self.draggableSettings.clampToScreen)
end

---@type DraggableSettings
---@field enabled boolean Enable/disable dragging (default true)
---@field clampToScreen boolean Clamp frame to screen edges (default true)
---@field inset number Screen edge inset in pixels (default 10)
---@field constraints any Optional parent frame to constrain movement
