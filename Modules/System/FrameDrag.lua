local AceAddon = LibStub("AceAddon-3.0")
local LibSimpleSticky = LibStub("LibSimpleSticky-1.0", true)
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

function addon:IsStickyWindowsEnabled()
	local cfg = self:GetEnhancementSettings()
	return cfg and cfg.stickyWindows ~= false and LibSimpleSticky ~= nil
end

function addon:GetStickyDragTargets(sourceFrame)
	local targets = {}
	local seen = {}
	local function AddFrame(frame)
		if not frame or frame == sourceFrame then
			return
		end
		if seen[frame] then
			return
		end
		seen[frame] = true
		targets[#targets + 1] = frame
	end

	AddFrame(UIParent)

	if self.frames then
		for i = 1, #self.frames do
			AddFrame(self.frames[i])
		end
	end
	if self.headers then
		for _, header in pairs(self.headers) do
			AddFrame(header)
		end
	end

	AddFrame(self.optionsFrame)
	AddFrame(self.debugPanel)
	AddFrame(self.debugExportFrame)
	AddFrame(self.debugSettingsFrame)

	return targets
end

function addon:EnableMovableFrame(frame, allowSticky, moverKey, defaultPoint, canDrag, onDragStop)
	if not frame then
		return
	end

	if moverKey then
		frame.__sufMoverKey = moverKey
		local store = self:GetMoverStore()
		if (store and store[moverKey]) or defaultPoint then
			self:ApplyStoredMoverPosition(frame, moverKey, defaultPoint)
		end
	end

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(movableFrame)
		movableFrame.__sufDragInProgress = nil
		if type(canDrag) == "function" then
			local ok, allowed = pcall(canDrag, movableFrame)
			if not ok or not allowed then
				return
			end
		end
		movableFrame.__sufDragInProgress = true
		if allowSticky and self:IsStickyWindowsEnabled() then
			local cfg = self:GetEnhancementSettings()
			local range = math.max(4, math.min(36, tonumber(cfg.stickyRange) or 15))
			LibSimpleSticky.rangeX = range
			LibSimpleSticky.rangeY = range
			LibSimpleSticky:StartMoving(movableFrame, self:GetStickyDragTargets(movableFrame), 0, 0, 0, 0)
		else
			movableFrame:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(movableFrame)
		local wasDragging = movableFrame.__sufDragInProgress == true
		movableFrame.__sufDragInProgress = nil
		if not wasDragging then
			movableFrame:StopMovingOrSizing()
			return
		end
		if allowSticky and self:IsStickyWindowsEnabled() then
			local ok = pcall(LibSimpleSticky.StopMoving, LibSimpleSticky, movableFrame)
			if not ok then
				movableFrame:StopMovingOrSizing()
			end
		else
			movableFrame:StopMovingOrSizing()
		end
		self:SnapFrameToPixelGrid(movableFrame)
		if movableFrame.__sufMoverKey then
			self:SaveMoverPosition(movableFrame, movableFrame.__sufMoverKey)
		end
		if type(onDragStop) == "function" then
			pcall(onDragStop, movableFrame)
		end
	end)
end

local EDIT_MODE_DRAG_UNIT_TYPES = {
	player = true,
	party = true,
	target = true,
	focus = true,
	tot = true,
}

function addon:IsEditModeDraggableUnitType(unitType)
	return unitType and EDIT_MODE_DRAG_UNIT_TYPES[unitType] == true
end

function addon:GetUnitFrameMoverKey(frame)
	if not frame then
		return nil
	end
	local unitType = frame.sufUnitType
	if not self:IsEditModeDraggableUnitType(unitType) then
		return nil
	end
	if unitType == "party" then
		return "unit_party_" .. tostring(frame.unit or frame:GetName() or "member")
	end
	return "unit_" .. tostring(unitType)
end

function addon:EnsureUnitFrameUnlockHandle(frame)
	if not frame then
		return nil
	end
	if frame.unlockHandle then
		frame.unlockHandle:SetAllPoints(frame)
		return frame.unlockHandle
	end

	local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	overlay:SetAllPoints(frame)
	overlay:SetFrameStrata(frame:GetFrameStrata() or "MEDIUM")
	overlay:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)
	overlay:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	overlay:SetBackdropColor(0.08, 0.14, 0.24, 0.34)
	overlay:SetBackdropBorderColor(0.40, 0.68, 0.98, 0.95)
	overlay:EnableMouse(false)
	overlay:Hide()

	local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", overlay, "CENTER", 0, 0)
	text:SetText("Unlock: Drag Frame")
	text:SetTextColor(0.95, 0.98, 1.00, 1)
	overlay.text = text

	frame.unlockHandle = overlay
	return overlay
end

function addon:UpdateUnitFrameUnlockHandle(frame)
	if not frame then
		return
	end
	local isEligible = self:IsEditModeDraggableUnitType(frame.sufUnitType)
	if not isEligible then
		if frame.unlockHandle then
			frame.unlockHandle:Hide()
		end
		return
	end

	local overlay = self:EnsureUnitFrameUnlockHandle(frame)
	if not overlay then
		return
	end
	overlay:SetAllPoints(frame)
	overlay:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)
	local show = self:IsEditModeActive() and frame:IsShown() and not (InCombatLockdown and InCombatLockdown())
	overlay:SetShown(show)
end

function addon:EnableUnitFrameEditModeDrag(frame)
	if not frame or frame.__sufEditModeDragInit then
		return
	end
	local moverKey = self:GetUnitFrameMoverKey(frame)
	if not moverKey then
		return
	end
	self:EnsureUnitFrameUnlockHandle(frame)
	self:EnableMovableFrame(frame, true, moverKey, nil, function(movableFrame)
		if not movableFrame or not addon:IsEditModeDraggableUnitType(movableFrame.sufUnitType) then
			return false
		end
		return addon:IsEditModeActive() and not (InCombatLockdown and InCombatLockdown())
	end)
	frame.__sufEditModeDragInit = true
	frame.__sufEditMoverKey = moverKey
end

function addon:UpdateAllUnitFrameUnlockHandles()
	for _, frame in ipairs(self.frames or {}) do
		if frame then
			self:UpdateUnitFrameUnlockHandle(frame)
		end
	end
end
