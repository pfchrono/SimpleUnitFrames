---@class EditModeIntegration
---Integrated EditMode system for SimpleUnitFrames
---Provides frame dragging, resizing, and element visibility controls
---Integrates with WoW 12.0.0+ native EditMode system

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local EditModeIntegration = {}

---Unit types to register with EditMode
local REGISTERED_UNIT_TYPES = {
	"player",
	"target",
	"tot",
	"focus",
	"pet",
	"party",
	"raid",
	"boss",
}

---Element visibility flags
local ELEMENT_FLAGS = {
	Health = "health",
	Power = "power",
	Castbar = "castbar",
	Auras = "auras",
	Portrait = "portrait",
	ClassPower = "classpower",
	Totems = "totems",
}

---Initialize EditMode integration
function EditModeIntegration:Initialize()
	if not C_EditMode then
		if addon and addon.DebugLog then
			addon:DebugLog("EditMode", "C_EditMode not available (pre-12.0.0?)", 2)
		end
		return
	end

	self:RegisterEditModeEvents()
	self:SetupFrameVisibilitySettings()
	if addon and addon.DebugLog then
		addon:DebugLog("EditMode", "EditMode integration initialized.", 2)
	end
end

---Register frame visibility settings in database defaults
function EditModeIntegration:SetupFrameVisibilitySettings()
	if not addon or not addon.db or not addon.db.profile then
		return
	end

	addon.db.profile.editMode = addon.db.profile.editMode or {}
	local editModeSettings = addon.db.profile.editMode

	-- Frame visibility settings (which unit frames to show)
	editModeSettings.frameVisibility = editModeSettings.frameVisibility or {
		player = true,
		target = true,
		tot = true,
		focus = true,
		pet = true,
		party = true,
		raid = true,
		boss = true,
	}

	-- Element visibility settings (which elements within frames to show)
	editModeSettings.elementVisibility = editModeSettings.elementVisibility or {}
	local elemVis = editModeSettings.elementVisibility
	for _, unitType in ipairs(REGISTERED_UNIT_TYPES) do
		if not elemVis[unitType] then
			elemVis[unitType] = {
				health = true,
				power = true,
				castbar = true,
				auras = true,
				portrait = true,
				classpower = true,
				totems = unitType == "player",
			}
		end
	end
end

---Register EditMode events
function EditModeIntegration:RegisterEditModeEvents()
	if not _G.EditModeManagerFrame then
		addon:DebugLog("EditMode", "EditModeManagerFrame not available, deferring setup.", 2)
		return
	end

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", function(_, eventName)
		if eventName == "PLAYER_ENTERING_WORLD" then
			if C_EditMode and C_EditMode.IsEditModeActive then
				if C_EditMode.IsEditModeActive() then
					addon.EditModeIntegration:OnEditModeEnter()
				end
			end
		end
	end)
	self.eventFrame = frame
end

---Enable EditMode for all SUF frames
function EditModeIntegration:OnEditModeEnter()
	if not (C_EditMode and C_EditMode.RegisterMovable) then
		addon:DebugLog("EditMode", "C_EditMode.RegisterMovable not available.", 1)
		return
	end

	addon:DebugLog("EditMode", "Registering SUF frames with EditMode.", 2)

	for index, frame in ipairs(addon.frames or {}) do
		if frame and frame:GetName() then
			self:RegisterFrameWithEditMode(frame)
		end
	end
end

---Register a single frame with EditMode
---@param frame Frame The frame to register
function EditModeIntegration:RegisterFrameWithEditMode(frame)
	if not (frame and C_EditMode and C_EditMode.RegisterMovable) then
		return
	end

	local frameName = frame:GetName() or ("SUFFrame_" .. tostring(frame))
	local unitType = frame.sufUnitType or "unknown"

	local systemName = "SimpleUnitFrames_" .. frameName
	local displayName = self:GetFrameDisplayName(unitType)
	local category = self:GetFrameCategory(unitType)

	-- Register movable frame
	local ok = pcall(function()
		C_EditMode.RegisterMovable(frame, {
			system = Enum.EditModeSystem.UnitFrame,
			name = systemName,
			displayName = displayName,
			category = category,
			allowResize = true,
			minWidth = 100,
			minHeight = 20,
			maxWidth = 500,
			maxHeight = 200,
		})
	end)

	if ok then
		addon:DebugLog("EditMode", ("Registered frame: %s (%s)"):format(frameName, unitType), 3)
		
		-- Hook frame drag/resize events
		self:HookFrameEditMode(frame)
	else
		addon:DebugLog("EditMode", ("Failed to register frame: %s"):format(frameName), 1)
	end
end

---Hook frame into EditMode drag/resize system
---@param frame Frame Frame to hook
function EditModeIntegration:HookFrameEditMode(frame)
	if not frame then
		return
	end

	-- Store original position for reset
	if not frame.__sufEditModeOriginalPosition then
		local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint(1)
		frame.__sufEditModeOriginalPosition = {
			point = point,
			relativeTo = relativeTo and relativeTo:GetName() or nil,
			relativePoint = relativePoint,
			offsetX = offsetX or 0,
			offsetY = offsetY or 0,
		}
	end

	-- On EditMode exit, save position to mover system
	if frame:GetScript("OnShow") then
		frame.__sufOriginalOnShow = frame:GetScript("OnShow")
	end
	frame:SetScript("OnShow", function(f)
		if addon.EditModeIntegration:IsEditModeActive() then
			addon.EditModeIntegration:OnFrameShownInEditMode(f)
		end
		if f.__sufOriginalOnShow then
			f.__sufOriginalOnShow(f)
		end
	end)
end

---Handle frame shown event during EditMode
---@param frame Frame The frame being shown
function EditModeIntegration:OnFrameShownInEditMode(frame)
	if not frame or not addon then
		return
	end

	-- Save position to mover system
	local moverKey = frame.__sufMoverKey
	if moverKey and addon.SaveMoverPosition then
		addon:SaveMoverPosition(frame, moverKey)
		if addon.DebugLog then
			addon:DebugLog("EditMode", ("Saved position for: %s"):format(moverKey), 3)
		end
	end
end

---Check if EditMode is currently active
---@return boolean True if EditMode is active
function EditModeIntegration:IsEditModeActive()
	if C_EditMode and C_EditMode.IsEditModeActive then
		return C_EditMode.IsEditModeActive()
	end
	if _G.EditModeManagerFrame then
		return _G.EditModeManagerFrame.editModeActive  == true
	end
	return false
end

---Get display name for frame based on unit type
---@param unitType string Unit type identifier
---@return string Display name for EditMode UI
function EditModeIntegration:GetFrameDisplayName(unitType)
	local names = {
		player = "Player Frame",
		target = "Target Frame",
		tot = "Target of Target",
		focus = "Focus Frame",
		pet = "Pet Frame",
		party = "Party Frames",
		raid = "Raid Frames",
		boss = "Boss Frames",
	}
	return names[unitType] or "Unit Frame"
end

---Get category for frame
---@param unitType string Unit type identifier
---@return string Category name
function EditModeIntegration:GetFrameCategory(unitType)
	if unitType == "player" or unitType == "target" or unitType == "tot" or unitType == "focus" or unitType == "pet" then
		return "Personal Frames"
	elseif unitType == "party" or unitType == "raid" then
		return "Group Frames"
	elseif unitType == "boss" then
		return "Encounter Frames"
	end
	return "Unit Frames"
end

---Get element visibility setting for unit type
---@param unitType string Unit type identifier
---@param element string Element flag (from ELEMENT_FLAGS)
---@return boolean True if element should be visible
function EditModeIntegration:IsElementVisible(unitType, element)
	if not (addon.db and addon.db.profile and addon.db.profile.editMode) then
		return true
	end

	local elemVis = addon.db.profile.editMode.elementVisibility
	if not elemVis or not elemVis[unitType] then
		return true
	end

	return elemVis[unitType][element] ~= false
end

---Toggle element visibility for unit type
---@param unitType string Unit type identifier
---@param element string Element flag (from ELEMENT_FLAGS)
---@param visible boolean Whether element should be visible
function EditModeIntegration:SetElementVisibility(unitType, element, visible)
	self:SetupFrameVisibilitySettings()
	local elemVis = addon.db.profile.editMode.elementVisibility
	if not elemVis[unitType] then
		elemVis[unitType] = {}
	end
	elemVis[unitType][element] = visible
	addon:ScheduleUpdateAll()
end

---Toggle frame visibility for unit type
---@param unitType string Unit type identifier
---@param visible boolean Whether frame should be visible
function EditModeIntegration:SetFrameVisibility(unitType, visible)
	self:SetupFrameVisibilitySettings()
	addon.db.profile.editMode.frameVisibility[unitType] = visible
	addon:ScheduleUpdateAll()
end

---Get frame visibility setting
---@param unitType string Unit type identifier
---@return boolean True if frame should be visible
function EditModeIntegration:IsFrameVisible(unitType)
	if not (addon.db and addon.db.profile and addon.db.profile.editMode) then
		return true
	end
	return addon.db.profile.editMode.frameVisibility[unitType] ~= false
end

---Apply element visibility settings to frame
---@param frame Frame Frame to apply settings to
---@param unitType string Unit type identifier
function EditModeIntegration:ApplyElementVisibility(frame, unitType)
	if not frame then
		return
	end

	-- Health visibility (StatusBar)
	if frame.Health and frame.Health.SetShown then
		frame.Health:SetShown(self:IsElementVisible(unitType, "health"))
	end

	-- Power visibility (StatusBar)
	if frame.Power and frame.Power.SetShown then
		frame.Power:SetShown(self:IsElementVisible(unitType, "power"))
	end

	-- Castbar visibility (StatusBar)
	if frame.Castbar and frame.Castbar.SetShown then
		frame.Castbar:SetShown(self:IsElementVisible(unitType, "castbar"))
	end

	-- Auras visibility (Frame or element; check for SetShown)
	if frame.Auras and frame.Auras.SetShown then
		frame.Auras:SetShown(self:IsElementVisible(unitType, "auras"))
	end

	-- Portrait visibility (PlayerModel/Texture)
	if frame.Portrait and frame.Portrait.SetShown then
		frame.Portrait:SetShown(self:IsElementVisible(unitType, "portrait"))
	end
	if frame.Portrait2D and frame.Portrait2D.SetShown then
		frame.Portrait2D:SetShown(self:IsElementVisible(unitType, "portrait"))
	end
	if frame.Portrait3D and frame.Portrait3D.SetShown then
		frame.Portrait3D:SetShown(self:IsElementVisible(unitType, "portrait"))
	end

	-- Class power visibility (Frame or element; check for SetShown)
	if frame.ClassPower and frame.ClassPower.SetShown then
		frame.ClassPower:SetShown(self:IsElementVisible(unitType, "classpower"))
	end

	-- Totem Bar visibility (player only, managed by TotemBar module)
	if unitType == "player" then
		local totemVisible = self:IsElementVisible(unitType, "totems")
		-- TotemBar is a separate system; visibility is controlled there
		if addon and addon.DebugLog then
			addon:DebugLog("EditMode", ("Totem visibility: %s"):format(tostring(totemVisible)), 3)
		end
	end
end

---Expose EditMode integration to addon
addon.EditModeIntegration = EditModeIntegration

function addon:GetEditModeIntegration()
	return self.EditModeIntegration
end

-- NOTE: Initialize is called from addon:OnInitialize() after db is created
-- Do NOT call Initialize() at module load time; addon.db doesn't exist yet
