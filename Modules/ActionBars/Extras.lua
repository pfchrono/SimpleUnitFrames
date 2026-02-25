--[[
    SUF ActionBars - Extra Action Button and Zone Ability movers + Edit Mode hooks.
    Ported from QUI ActionBars (QUI/modules/frames/actionbars.lua).
    Uses addon:EnableMovableFrame / addon:SaveMoverPosition for SUF mover persistence.
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

local function GetAB()
	return addon.ActionBars
end

---------------------------------------------------------------------------
-- MODULE STATE
---------------------------------------------------------------------------

local extraActionHolder   = nil
local extraActionMover    = nil
local zoneAbilityHolder   = nil
local zoneAbilityMover    = nil
local extraButtonMoversVisible = false
local hookingSetPoint     = false
local extraActionSetPointHooked  = false
local zoneAbilitySetPointHooked  = false
local pendingExtraButtonReanchor = {}

---------------------------------------------------------------------------
-- DB ACCESSOR FOR EXTRA BUTTON SETTINGS
---------------------------------------------------------------------------

local function GetExtraButtonDB(buttonType)
	local db = addon and addon.db and addon.db.profile
	if not db then return nil end
	return db.actionBars and db.actionBars.bars and db.actionBars.bars[buttonType]
end

---------------------------------------------------------------------------
-- CREATE HOLDER + MOVER
---------------------------------------------------------------------------

local function CreateExtraButtonHolder(buttonType, displayName)
	local settings = GetExtraButtonDB(buttonType)
	if not settings then return nil, nil end

	-- Use SUF mover key for persistent position storage
	local moverKey = "suf_actionbar_" .. buttonType

	local holder = CreateFrame("Frame", "SUF_" .. buttonType .. "Holder", UIParent)
	holder:SetSize(64, 64)
	holder:SetClampedToScreen(true)

	-- Load saved position via SUF mover store, or use sensible defaults
	local stored = addon.GetMoverStore and addon:GetMoverStore()
	local savedPos = stored and stored[moverKey]
	if savedPos and savedPos.point then
		holder:ClearAllPoints()
		holder:SetPoint(savedPos.point, UIParent, savedPos.relPoint or savedPos.point,
			savedPos.x or 0, savedPos.y or 0)
	elseif settings.position and settings.position.point then
		local pos = settings.position
		holder:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
	else
		if buttonType == "extraActionButton" then
			holder:SetPoint("CENTER", UIParent, "CENTER", -100, -200)
		else
			holder:SetPoint("CENTER", UIParent, "CENTER", 100, -200)
		end
	end

	-- Mover overlay (visible only during Edit Mode or toggle)
	local mover = CreateFrame("Frame", "SUF_" .. buttonType .. "Mover", holder, "BackdropTemplate")
	mover:SetAllPoints(holder)
	mover:SetBackdrop({
		bgFile   = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 2,
	})
	mover:SetBackdropColor(0.2, 0.6, 1.0, 0.4)
	mover:SetBackdropBorderColor(0.2, 0.7, 1.0, 1)
	mover:EnableMouse(true)
	mover:SetMovable(true)
	mover:RegisterForDrag("LeftButton")
	mover:SetFrameStrata("HIGH")
	mover:Hide()

	local text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("CENTER")
	text:SetText(displayName)
	mover.text = text

	-- Drag start: move holder
	mover:SetScript("OnDragStart", function(self)
		holder:SetMovable(true)
		holder:StartMoving()
	end)

	-- Drag stop: snap and persist via SUF mover store
	mover:SetScript("OnDragStop", function(self)
		holder:StopMovingOrSizing()
		local point, _, relPoint, x, y = holder:GetPoint(1)
		if point then
			-- Round to pixel grid
			local scale = holder:GetEffectiveScale() or 1
			x = math.floor(x * scale + 0.5) / scale
			y = math.floor(y * scale + 0.5) / scale
			-- Persist in SUF mover store (same schema as load)
			local store = addon.GetMoverStore and addon:GetMoverStore()
			if store then
				store[moverKey] = {
					point    = point,
					relPoint = relPoint or point,
					x        = x,
					y        = y,
				}
			end
			-- Also persist in actionBars DB for portability
			local db = GetExtraButtonDB(buttonType)
			if db then
				db.position = { point = point, relPoint = relPoint or point, x = x, y = y }
			end
		end
	end)

	return holder, mover
end

---------------------------------------------------------------------------
-- APPLY SETTINGS (scale, position, artwork)
---------------------------------------------------------------------------

local function ApplyExtraButtonSettings(buttonType)
	if InCombatLockdown() then
		local ab = GetAB()
		if ab then ab.pendingExtraButtonRefresh = true end
		return
	end

	local settings = GetExtraButtonDB(buttonType)
	if not settings or not settings.enabled then return end

	local blizzFrame, holder
	if buttonType == "extraActionButton" then
		blizzFrame = ExtraActionBarFrame
		holder     = extraActionHolder
	else
		blizzFrame = ZoneAbilityFrame
		holder     = zoneAbilityHolder
	end
	if not blizzFrame or not holder then return end

	local scale   = settings.scale  or 1.0
	local offsetX = settings.offsetX or 0
	local offsetY = settings.offsetY or 0

	blizzFrame:SetScale(scale)

	hookingSetPoint = true
	blizzFrame:ClearAllPoints()
	blizzFrame:SetPoint("CENTER", holder, "CENTER", offsetX, offsetY)
	hookingSetPoint = false

	local width  = (blizzFrame:GetWidth()  or 64) * scale
	local height = (blizzFrame:GetHeight() or 64) * scale
	holder:SetSize(math.max(width, 64), math.max(height, 64))

	-- Artwork toggle
	if settings.hideArtwork then
		if buttonType == "extraActionButton" and blizzFrame.button and blizzFrame.button.style then
			blizzFrame.button.style:SetAlpha(0)
		end
		if buttonType == "zoneAbility" and blizzFrame.Style then
			blizzFrame.Style:SetAlpha(0)
		end
	else
		if buttonType == "extraActionButton" and blizzFrame.button and blizzFrame.button.style then
			blizzFrame.button.style:SetAlpha(1)
		end
		if buttonType == "zoneAbility" and blizzFrame.Style then
			blizzFrame.Style:SetAlpha(1)
		end
	end

	if not settings.fadeEnabled then
		blizzFrame:SetAlpha(1)
	end
end

---------------------------------------------------------------------------
-- QUEUE RE-ANCHOR (avoids recursion inside SetPoint hooks)
---------------------------------------------------------------------------

local function QueueExtraButtonReanchor(buttonType)
	if pendingExtraButtonReanchor[buttonType] then return end
	pendingExtraButtonReanchor[buttonType] = true
	C_Timer.After(0, function()
		pendingExtraButtonReanchor[buttonType] = false
		if InCombatLockdown() then
			local ab = GetAB()
			if ab then ab.pendingExtraButtonRefresh = true end
			return
		end
		local settings = GetExtraButtonDB(buttonType)
		if settings and settings.enabled then
			ApplyExtraButtonSettings(buttonType)
		end
	end)
end

---------------------------------------------------------------------------
-- HOOK BLIZZARD FRAMES (prevent them from overriding our positions)
---------------------------------------------------------------------------

local function HookExtraButtonPositioning()
	if ExtraActionBarFrame and not extraActionSetPointHooked then
		extraActionSetPointHooked = true
		hooksecurefunc(ExtraActionBarFrame, "SetPoint", function()
			if hookingSetPoint or InCombatLockdown() then return end
			local settings = GetExtraButtonDB("extraActionButton")
			if extraActionHolder and settings and settings.enabled then
				QueueExtraButtonReanchor("extraActionButton")
			end
		end)
	end

	if ZoneAbilityFrame and not zoneAbilitySetPointHooked then
		zoneAbilitySetPointHooked = true
		hooksecurefunc(ZoneAbilityFrame, "SetPoint", function()
			if hookingSetPoint or InCombatLockdown() then return end
			local settings = GetExtraButtonDB("zoneAbility")
			if zoneAbilityHolder and settings and settings.enabled then
				QueueExtraButtonReanchor("zoneAbility")
			end
		end)
	end
end

---------------------------------------------------------------------------
-- SHOW / HIDE MOVERS
---------------------------------------------------------------------------

local function ShowExtraButtonMovers()
	extraButtonMoversVisible = true
	if extraActionMover then extraActionMover:Show() end
	if zoneAbilityMover then zoneAbilityMover:Show() end
end

local function HideExtraButtonMovers()
	extraButtonMoversVisible = false
	if extraActionMover then extraActionMover:Hide() end
	if zoneAbilityMover then zoneAbilityMover:Hide() end
end

local function ToggleExtraButtonMovers()
	if extraButtonMoversVisible then
		HideExtraButtonMovers()
	else
		ShowExtraButtonMovers()
	end
end

---------------------------------------------------------------------------
-- INITIALIZE EXTRA BUTTONS
---------------------------------------------------------------------------

local function InitializeExtraButtons()
	local ab = GetAB()
	if InCombatLockdown() then
		if ab then ab.pendingExtraButtonInit = true end
		return
	end

	extraActionHolder, extraActionMover = CreateExtraButtonHolder("extraActionButton", "Extra Action")
	zoneAbilityHolder, zoneAbilityMover = CreateExtraButtonHolder("zoneAbility",       "Zone Ability")

	C_Timer.After(0.5, function()
		ApplyExtraButtonSettings("extraActionButton")
		ApplyExtraButtonSettings("zoneAbility")
		HookExtraButtonPositioning()
	end)
end

local function RefreshExtraButtons()
	if InCombatLockdown() then
		local ab = GetAB()
		if ab then ab.pendingExtraButtonRefresh = true end
		return
	end
	ApplyExtraButtonSettings("extraActionButton")
	ApplyExtraButtonSettings("zoneAbility")
end

---------------------------------------------------------------------------
-- EDIT MODE HOOKS
---------------------------------------------------------------------------

local function SetupEditModeHooks()
	if not EditModeManagerFrame then return end

	hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
		local extraSettings = GetExtraButtonDB("extraActionButton")
		local zoneSettings  = GetExtraButtonDB("zoneAbility")
		if (extraSettings and extraSettings.enabled) or (zoneSettings and zoneSettings.enabled) then
			ShowExtraButtonMovers()
		end
	end)

	hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
		HideExtraButtonMovers()
	end)
end

---------------------------------------------------------------------------
-- EXPOSE ON ADDON
---------------------------------------------------------------------------

addon.ActionBarsExtras = {
	InitializeExtraButtons  = InitializeExtraButtons,
	RefreshExtraButtons     = RefreshExtraButtons,
	ApplyExtraButtonSettings = ApplyExtraButtonSettings,
	SetupEditModeHooks      = SetupEditModeHooks,
	ShowExtraButtonMovers   = ShowExtraButtonMovers,
	HideExtraButtonMovers   = HideExtraButtonMovers,
	ToggleExtraButtonMovers = ToggleExtraButtonMovers,
}
