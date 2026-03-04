--- SimpleUnitFrames Pixel-Perfect Scaling System
--- Adapted from QUI scaling.lua patterns for SUF architecture
---
--- The WoW UI coordinate system uses virtual units where the screen height equals
--- 768 / uiScale. Physical screen pixels don't always align with these virtual units,
--- causing borders, sizes, and gaps to render inconsistently (e.g., a "1 pixel" border
--- sometimes renders as 2 pixels, or a 300px frame is actually 299 or 301 pixels).
---
--- This module provides functions that snap all dimensions and positions to the
--- physical pixel grid, ensuring:
---   - 1 pixel always means exactly 1 physical screen pixel
---   - 300 pixels always means exactly 300 physical screen pixels
---   - Positions land on pixel boundaries so borders and gaps are consistent
---
--- Key concept: "pixel size" = the virtual-coordinate size of 1 physical screen pixel
--- for a given frame, calculated as: 768 / (physicalScreenHeight * effectiveScale)

local ADDON_NAME, ns = ...
local addon = LibStub("AceAddon-3.0"):GetAddon("SimpleUnitFrames")

-- PERF LOCALS
local floor = math.floor
local ceil = math.ceil
local max = math.max
local Round = function(x) return floor(x + 0.5) end
local UIParent = UIParent
local InCombatLockdown = InCombatLockdown
local GetPhysicalScreenSize = GetPhysicalScreenSize
local GetScreenWidth = GetScreenWidth
local GetScreenHeight = GetScreenHeight

--- Cached physical screen height (updated on UI_SCALE_CHANGED).
local cachedPhysicalHeight = select(2, GetPhysicalScreenSize()) or 1080

--------------------------------------------------------------------------------
-- Pixel Math Core
--------------------------------------------------------------------------------

--- Get the virtual-coordinate size of 1 physical screen pixel for a given frame.
--- This is the fundamental unit for all pixel-perfect calculations.
---
--- The formula: pixelSize = 768 / (physicalScreenHeight * frame:GetEffectiveScale())
---
--- A frame's effective scale is the product of its own scale and all ancestor scales.
--- Using the correct frame (not just UIParent) matters when frames in the hierarchy
--- have been scaled with SetScale().
---
--- @param frame? Frame The frame context (defaults to UIParent)
--- @return number The size of 1 physical pixel in the frame's coordinate space
function addon:GetPixelSize(frame)
	local es
	if frame then
		local ok, val = pcall(frame.GetEffectiveScale, frame)
		es = ok and val or UIParent:GetEffectiveScale()
	else
		es = UIParent:GetEffectiveScale()
	end
	if es == 0 then return 1 end
	if cachedPhysicalHeight == 0 then return 1 end
	return 768 / (cachedPhysicalHeight * es)
end

--- Convert a physical pixel count to virtual coordinate units for a given frame.
--- Use this when you want "exactly N physical pixels" in a frame's coordinate space.
---
--- Example: addon:Pixels(1, myFrame) returns the exact size of 1 physical pixel
--- Example: addon:Pixels(300, myFrame) returns exactly 300 physical pixels
---
--- @param n number Number of physical pixels desired
--- @param frame? Frame The frame context (defaults to UIParent)
--- @return number Virtual coordinate size equal to exactly N physical pixels
function addon:Pixels(n, frame)
	if n == 0 then return 0 end
	return n * self:GetPixelSize(frame)
end

--- Snap a virtual-coordinate value to the nearest physical pixel boundary.
--- Use this when you have a value in virtual coordinates (e.g., from a database
--- setting or calculation) and need it to land exactly on a pixel boundary.
---
--- @param value number The value in virtual coordinates
--- @param frame? Frame The frame context (defaults to UIParent)
--- @return number The value snapped to the nearest pixel boundary
function addon:PixelRound(value, frame)
	if value == 0 then return 0 end
	local px = self:GetPixelSize(frame)
	return Round(value / px) * px
end

--- Floor a virtual-coordinate value down to the nearest pixel boundary.
--- @param value number The value in virtual coordinates
--- @param frame? Frame The frame context (defaults to UIParent)
--- @return number The value floored to the nearest pixel boundary
function addon:PixelFloor(value, frame)
	if value == 0 then return 0 end
	local px = self:GetPixelSize(frame)
	return floor(value / px) * px
end

--- Ceil a virtual-coordinate value up to the nearest pixel boundary.
--- @param value number The value in virtual coordinates
--- @param frame? Frame The frame context (defaults to UIParent)
--- @return number The value ceiled to the nearest pixel boundary
function addon:PixelCeil(value, frame)
	if value == 0 then return 0 end
	local px = self:GetPixelSize(frame)
	return ceil(value / px) * px
end

--------------------------------------------------------------------------------
-- Frame-Aware Pixel-Perfect Sizing
--------------------------------------------------------------------------------

--- Set frame size to exactly widthPixels x heightPixels physical screen pixels.
--- Uses the frame's own effective scale for accurate pixel mapping.
---
--- Unlike standard SetSize() which uses raw values, this accounts for any
--- intermediate scaling in the frame's parent chain.
---
--- @param frame Frame The frame to size
--- @param widthPixels? number Desired width in physical pixels
--- @param heightPixels? number Desired height in physical pixels
function addon:SetPixelPerfectSize(frame, widthPixels, heightPixels)
	if not frame then return end
	local px = self:GetPixelSize(frame)
	if widthPixels and heightPixels then
		frame:SetSize(Round(widthPixels) * px, Round(heightPixels) * px)
	elseif widthPixels then
		frame:SetWidth(Round(widthPixels) * px)
	elseif heightPixels then
		frame:SetHeight(Round(heightPixels) * px)
	end
end

--- Set frame width to exactly widthPixels physical screen pixels.
--- @param frame Frame The frame to size
--- @param widthPixels number Desired width in physical pixels
function addon:SetPixelPerfectWidth(frame, widthPixels)
	if not frame then return end
	local px = self:GetPixelSize(frame)
	frame:SetWidth(Round(widthPixels) * px)
end

--- Set frame height to exactly heightPixels physical screen pixels.
--- @param frame Frame The frame to size
--- @param heightPixels number Desired height in physical pixels
function addon:SetPixelPerfectHeight(frame, heightPixels)
	if not frame then return end
	local px = self:GetPixelSize(frame)
	frame:SetHeight(Round(heightPixels) * px)
end

--------------------------------------------------------------------------------
-- Pixel-Perfect Positioning
--------------------------------------------------------------------------------

--- SetPoint with offsets specified in physical pixel counts, snapped to grid.
--- The offsets are in physical pixels (e.g., 5 means 5 physical pixels right/up).
---
--- @param frame Frame The frame to position
--- @param point string Anchor point (e.g., "TOPLEFT")
--- @param relativeTo Frame|nil The reference frame (nil for parent)
--- @param relativePoint string The reference point on relativeTo
--- @param xPixels? number X offset in physical pixels (default 0)
--- @param yPixels? number Y offset in physical pixels (default 0)
function addon:SetPixelPerfectPoint(frame, point, relativeTo, relativePoint, xPixels, yPixels)
	if not frame then return end
	local px = self:GetPixelSize(frame)
	local x = xPixels and Round(xPixels) * px or 0
	local y = yPixels and Round(yPixels) * px or 0
	frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

--- Snap existing virtual-coordinate offsets to the nearest pixel boundary.
--- Use this when you have offsets in virtual coordinates (e.g., from the database
--- or a calculation) that need to be pixel-aligned.
---
--- Unlike SetPixelPerfectPoint where offsets are pixel counts, here the offsets
--- are already in virtual coordinates and just need to be snapped to the grid.
---
--- @param frame Frame The frame to position
--- @param point string Anchor point
--- @param relativeTo Frame|nil The reference frame
--- @param relativePoint string The reference point on relativeTo
--- @param offsetX? number X offset in virtual coordinates (will be snapped)
--- @param offsetY? number Y offset in virtual coordinates (will be snapped)
function addon:SetSnappedPoint(frame, point, relativeTo, relativePoint, offsetX, offsetY)
	if not frame then return end
	local px = self:GetPixelSize(frame)
	local x = offsetX and Round(offsetX / px) * px or 0
	local y = offsetY and Round(offsetY / px) * px or 0
	frame:SetPoint(point, relativeTo, relativePoint, x, y)
end

--- Snap a frame's current position to the pixel grid after a drag operation.
--- Call this after StopMovingOrSizing() to ensure the frame lands on pixel
--- boundaries, preventing ±1px size rendering errors.
---
--- Returns the snapped anchor data so callers can save it to the database.
---
--- @param frame Frame The frame to snap
--- @return string? point Anchor point
--- @return Frame? relativeTo Relative frame
--- @return string? relativePoint Relative anchor
--- @return number? x Snapped X offset
--- @return number? y Snapped Y offset
function addon:SnapFramePosition(frame)
	if not frame then return end
	if InCombatLockdown() then return end
	local point, relativeTo, relativePoint, x, y = frame:GetPoint()
	if not point then return end
	x = self:PixelRound(x or 0, frame)
	y = self:PixelRound(y or 0, frame)
	frame:ClearAllPoints()
	frame:SetPoint(point, relativeTo, relativePoint, x, y)
	return point, relativeTo, relativePoint, x, y
end

--------------------------------------------------------------------------------
-- Pixel-Perfect Backdrop
--------------------------------------------------------------------------------

--- Apply a backdrop with an exact N-pixel border using the frame's own scale.
--- Guarantees the border is exactly borderPixels physical pixels thick.
---
--- @param frame Frame The frame (must inherit BackdropTemplate)
--- @param borderPixels? number Border thickness in physical pixels (default 1)
--- @param bgFile? string Background texture path (nil for border-only)
--- @param r? number Border color red (0-1)
--- @param g? number Border color green (0-1)
--- @param b? number Border color blue (0-1)
--- @param a? number Border color alpha (0-1, default 1)
function addon:SetPixelPerfectBackdrop(frame, borderPixels, bgFile, r, g, b, a)
	if not frame then return end
	local px = self:GetPixelSize(frame)
	local edgeSize = max(1, Round(borderPixels or 1)) * px
	local backdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = edgeSize,
	}
	if bgFile then
		backdrop.bgFile = bgFile
		backdrop.insets = {
			left = edgeSize,
			right = edgeSize,
			top = edgeSize,
			bottom = edgeSize,
		}
	end
	frame:SetBackdrop(backdrop)
	if r then
		frame:SetBackdropBorderColor(r, g, b, a or 1)
	end
end

--------------------------------------------------------------------------------
-- Texel Snapping
--------------------------------------------------------------------------------

--- Apply pixel-grid snapping to a frame for crisp texture rendering.
--- Calls SetSnapToPixelGrid(true) and SetTexelSnappingBias(0) if available.
--- These are WoW 12.0+ APIs that prevent sub-pixel texture blurring.
---
--- @param frame Frame The frame (or texture) to snap
function addon:ApplyPixelSnapping(frame)
	if not frame then return end
	if frame.SetSnapToPixelGrid then
		pcall(frame.SetSnapToPixelGrid, frame, true)
	end
	if frame.SetTexelSnappingBias then
		pcall(frame.SetTexelSnappingBias, frame, 0)
	end
end

--------------------------------------------------------------------------------
-- UI Scale Management
--------------------------------------------------------------------------------

--- Get the pixel-perfect scale for the current screen resolution.
--- At this scale, 1 virtual unit = 1 physical pixel, eliminating all rounding.
--- Formula: 768 / physicalScreenHeight
--- @return number The pixel-perfect scale value
function addon:GetPixelPerfectScale()
	if cachedPhysicalHeight == 0 then return 1 end
	return 768 / cachedPhysicalHeight
end

--- Get smart default scale based on screen resolution
--- @return number Recommended UI scale for current resolution
function addon:GetSmartDefaultScale()
	if cachedPhysicalHeight >= 2160 then return 0.53 end     -- 4K
	if cachedPhysicalHeight >= 1440 then return 0.64 end     -- 1440p
	return 1.0                                                -- 1080p or lower
end

--------------------------------------------------------------------------------
-- Event Handling & Initialization
--------------------------------------------------------------------------------

--- Event handler for UI_SCALE_CHANGED.
--- Updates cached physical screen dimensions and triggers frame refresh.
local function OnUIScaleChanged()
	local physicalWidth, physicalHeight = GetPhysicalScreenSize()
	cachedPhysicalHeight = physicalHeight or 1080
	
	-- Cache screen dimensions on addon
	addon.physicalWidth = physicalWidth
	addon.physicalHeight = physicalHeight
	addon.screenWidth = GetScreenWidth()
	addon.screenHeight = GetScreenHeight()
	addon.resolution = string.format('%dx%d', physicalWidth or 0, physicalHeight or 0)
	
	-- Refresh all frames with pixel-perfect sizing/positioning
	if addon.ScheduleUpdateAll then
		addon:ScheduleUpdateAll()
	end
end

--- Initialize pixel-perfect system.
--- Called during addon initialization to set up event handlers and cache.
function addon:InitializePixelPerfect()
	-- Cache initial screen dimensions
	local physicalWidth, physicalHeight = GetPhysicalScreenSize()
	cachedPhysicalHeight = physicalHeight or 1080
	self.physicalWidth = physicalWidth
	self.physicalHeight = physicalHeight
	self.screenWidth = GetScreenWidth()
	self.screenHeight = GetScreenHeight()
	self.resolution = string.format('%dx%d', physicalWidth or 0, physicalHeight or 0)
	
	-- Register UI_SCALE_CHANGED event
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("UI_SCALE_CHANGED")
	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "UI_SCALE_CHANGED" then
			OnUIScaleChanged()
		end
	end)
	
	-- Store reference for cleanup
	addon._pixelPerfectEventFrame = eventFrame
	
	-- Debug output if available
	if self.DebugLog then
		self:DebugLog("PixelPerfect", string.format("Initialized: %s (%dx%d physical)", 
			self.resolution, physicalWidth or 0, physicalHeight or 0), 2)
	end
end
