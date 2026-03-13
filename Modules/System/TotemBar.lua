--[[
SimpleUnitFrames Totem Bar
Hooks Blizzard's native TotemFrame and reparents it to position above player frame auras.
Avoids oUF element secret value errors by letting Blizzard handle GetTotemInfo() calls.
]]

local addon = LibStub("AceAddon-3.0"):GetAddon("SimpleUnitFrames", true)
if not addon then return end

-- Guard: Shaman only
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local TotemBar = {}
addon.TotemBar = TotemBar

---------------------------------------------------------------------------
-- THEME COLORS (derived from player's class color)
---------------------------------------------------------------------------
local function GetClassTheme()
	local _, playerClass = UnitClass("player")
	if not playerClass then
		playerClass = "SHAMAN"
	end
	
	-- Use Blizzard's built-in class colors
	local classColor = RAID_CLASS_COLORS[playerClass]
	if not classColor then
		-- Fallback to shaman color if something goes wrong
		classColor = RAID_CLASS_COLORS["SHAMAN"] or {r = 0.36, g = 0.7, b = 0.77}
	end
	
	-- Derive theme from class color: make it darker/lighter as needed
	local r, g, b = classColor.r, classColor.g, classColor.b
	
	return {
		background = { r * 0.4, g * 0.4, b * 0.4, 0.72 },     -- Very dark, semi-transparent
		border = { r * 0.8, g * 0.8, b * 0.8, 0.94 },         -- Medium shade for border
		buttonBg = { r * 0.5, g * 0.5, b * 0.5, 0.25 },       -- Dark button background, 25% visible
		buttonBorder = { r * 0.75, g * 0.75, b * 0.75, 0.90 }, -- Slightly lighter border
		highlight = { r * 1.2, g * 1.2, b * 1.2, 0.85 },       -- Bright highlight on hover
	}
end

local TOTEM_THEME = GetClassTheme()

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
TotemBar.hooked = false
TotemBar.durationTicker = nil
TotemBar.playerFrame = nil  -- Cache the player frame reference
TotemBar.backgroundInitialized = false  -- Per-button backgrounds initialized flag

---------------------------------------------------------------------------
-- UTILITY: Safely format duration for display
---------------------------------------------------------------------------
local function IsSecretValue(value)
	return type(issecretvalue) == "function" and issecretvalue(value) or false
end

local function SafeNumber(value, fallback)
	if IsSecretValue(value) then
		return fallback
	end
	local numericValue = tonumber(value)
	if numericValue == nil then
		return fallback
	end
	return numericValue
end

local function FormatDuration(seconds)
	if not seconds or seconds <= 0 then return "" end
	if seconds >= 60 then
		return string.format("%dm", math.floor(seconds / 60))
	elseif seconds >= 10 then
		return string.format("%d", math.floor(seconds))
	else
		return string.format("%.1f", seconds)
	end
end

---------------------------------------------------------------------------
-- RESKIN: Style a single totem button to match theme
---------------------------------------------------------------------------
local function ReskinTotemButton(button)
	if not button then return end
	
	-- Create background border if it doesn't exist
	if not button.__sufBorder then
		-- Ensure button exists as a frame
		button:SetFrameLevel(button:GetFrameLevel() or 1)
		
		-- Create a background container frame for this button
		if not button.__sufBgContainer then
			local bgContainer = CreateFrame("Frame", nil, button:GetParent())
			bgContainer:SetFrameLevel(button:GetFrameLevel() - 2)
			bgContainer:SetFrameStrata(button:GetFrameStrata())
			button.__sufBgContainer = bgContainer
		end
		
		local bgContainer = button.__sufBgContainer
		
		-- Copy button's position and size to background container
		bgContainer:ClearAllPoints()
		bgContainer:SetWidth(button:GetWidth())
		bgContainer:SetHeight(button:GetHeight())
		bgContainer:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		
		-- Create border texture
		local border = bgContainer:CreateTexture(nil, "BACKGROUND", nil, -8)
		border:SetColorTexture(TOTEM_THEME.border[1], TOTEM_THEME.border[2], TOTEM_THEME.border[3], TOTEM_THEME.border[4])
		border:SetAllPoints(bgContainer)
		button.__sufBorder = border
		
		-- Create background overlay
		local bg = bgContainer:CreateTexture(nil, "BACKGROUND", nil, -7)
		bg:SetColorTexture(TOTEM_THEME.buttonBg[1], TOTEM_THEME.buttonBg[2], TOTEM_THEME.buttonBg[3], TOTEM_THEME.buttonBg[4])
		bg:SetPoint("TOPLEFT", bgContainer, "TOPLEFT", 1, -1)
		bg:SetPoint("BOTTOMRIGHT", bgContainer, "BOTTOMRIGHT", -1, 1)
		button.__sufBackground = bg
		
		-- Create highlight border (visible on hover)
		local highlight = bgContainer:CreateTexture(nil, "OVERLAY", nil, -6)
		highlight:SetColorTexture(TOTEM_THEME.highlight[1], TOTEM_THEME.highlight[2], TOTEM_THEME.highlight[3], TOTEM_THEME.highlight[4])
		highlight:SetAllPoints(bgContainer)
		highlight:Hide()
		button.__sufHighlight = highlight
		
		-- Add hover effects
		button:HookScript("OnEnter", function()
			highlight:Show()
		end)
		button:HookScript("OnLeave", function()
			highlight:Hide()
		end)
	end
end

---------------------------------------------------------------------------
-- RESKIN: Initialize totem bar backgrounds (per-button backgrounds now)
---------------------------------------------------------------------------
local function CreateTotemBackground(totemFrame)
	if not totemFrame or TotemBar.backgroundInitialized then return end
	
	-- We now use per-button backgrounds instead of a unified container
	-- Each totem button gets its own background via ReskinTotemButton()
	-- This ensures proper alignment of each button with its background
	
	TotemBar.backgroundInitialized = true
end

---------------------------------------------------------------------------
-- DURATION TEXT UPDATER
---------------------------------------------------------------------------
local function UpdateTotemDurations()
	local tf = TotemFrame
	if not tf or not tf.totemPool then return	end
	
	-- Query Blizzard's button pool for active totem buttons
	for button in tf.totemPool:EnumerateActive() do
		if button.slot and button.Duration then
			-- WoW 12.0.0+: GetTotemTimeLeft may return secret values in restricted contexts.
			local remaining = SafeNumber(GetTotemTimeLeft(button.slot), 0) or 0
			if remaining > 0 then
				button.Duration:SetText(FormatDuration(remaining))
				button.Duration:Show()
			else
				button.Duration:SetText("")
				button.Duration:Hide()
			end
		end
	end
end

---------------------------------------------------------------------------
-- HOOK SETUP: Position and restyle Blizzard's TotemFrame
---------------------------------------------------------------------------
local function HookTotemFrame()
	if TotemBar.hooked or InCombatLockdown() then
		return
	end
	
	local tf = TotemFrame
	if not tf or not tf.totemPool then
		return
	end
	
	TotemBar.hooked = true
	
	-- Reparent to UIParent so we can freely reposition relative to player frame
	tf:SetParent(UIParent)
	tf:SetFrameStrata("MEDIUM")
	tf:SetFrameLevel(30)  -- Above player frame
	
	-- TAINT SAFETY: Satisfy the managed frame system with a no-op layout parent
	-- This prevents taint propagation from show/hide operations
	C_Timer.After(0, function()
		if tf then
			tf.layoutParent = {
				MarkDirty = function() end,
				MarkClean = function() end,
				AddManagedFrame = function() end,
				RemoveManagedFrame = function() end,
				Layout = function() end,
			}
		end
	end)
	
	-- Create background container
	CreateTotemBackground(tf)
	
	-- Make draggable for user repositioning
	tf:SetMovable(true)
	tf:EnableMouse(true)
	-- NO RegisterForDrag - it breaks our anchor points
	-- Totem bar stays anchored to player auras only
	
	-- Hook Blizzard's Update to refresh our positioning and reskinning
	hooksecurefunc(tf, "Update", function()
		C_Timer.After(0, function()
			-- Reskin any new totem buttons
			if tf and tf.totemPool then
				for button in tf.totemPool:EnumerateActive() do
					ReskinTotemButton(button)
				end
			end
			addon.TotemBar:RefreshTotemLayout()
		end)
	end)
end

---------------------------------------------------------------------------
-- POSITION TOTEM FRAME RELATIVE TO PLAYER FRAME
---------------------------------------------------------------------------
function TotemBar:PositionTotemBar()
	local tf = TotemFrame
	local playerFrame = addon.frames and addon.frames[1]  -- Player frame is always first
	
	if not tf or not playerFrame then
		return
	end
	
	-- Position above player frame auras
	local auraFrame = playerFrame.Auras
	if auraFrame and auraFrame:IsVisible() then
		tf:ClearAllPoints()
		tf:SetPoint("BOTTOMLEFT", auraFrame, "TOPLEFT", 0, 4)
		tf:SetPoint("BOTTOMRIGHT", auraFrame, "TOPRIGHT", 0, 4)
		tf:SetHeight(40)
	else
		-- Fallback: position above class power or main frame
		local anchor = playerFrame.ClassPowerAnchor or playerFrame.AdditionalPower or playerFrame
		tf:ClearAllPoints()
		tf:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
		tf:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 4)
		tf:SetHeight(40)
	end
end

---------------------------------------------------------------------------
-- REFRESH TOTEM LAYOUT
---------------------------------------------------------------------------
function TotemBar:RefreshTotemLayout()
	local tf = TotemFrame
	if not tf or not tf.totemPool then return end
	
	-- Reskin all active totem buttons
	for button in tf.totemPool:EnumerateActive() do
		ReskinTotemButton(button)
	end
	
	-- Let Blizzard position the buttons internally, we just ensure frame is visible
	self:PositionTotemBar()
	
	-- Start/manage duration ticker
	local hasActive = false
	for button in tf.totemPool:EnumerateActive() do
		if button.slot then
			hasActive = true
			break
		end
	end
	
	if hasActive and not self.durationTicker then
		self.durationTicker = C_Timer.NewTicker(0.1, UpdateTotemDurations)
	elseif not hasActive and self.durationTicker then
		self.durationTicker:Cancel()
		self.durationTicker = nil
	end
end

---------------------------------------------------------------------------
-- COMBAT EVENT LISTENER: Refresh on combat state change
---------------------------------------------------------------------------
function TotemBar:SetupCombatListener()
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	eventFrame:SetScript("OnEvent", function()
		-- Refresh totem positioning after combat state change
		C_Timer.After(0.1, function()
			addon.TotemBar:RefreshTotemLayout()
		end)
	end)
end

---------------------------------------------------------------------------
-- HOOK INTO PLAYER FRAME LAYOUT UPDATES
---------------------------------------------------------------------------
function TotemBar:HookPlayerFrameLayoutUpdates()
	local playerFrame = addon.frames and addon.frames[1]
	if not playerFrame then
		C_Timer.After(0.5, function()
			addon.TotemBar:HookPlayerFrameLayoutUpdates()
		end)
		return
	end
	
	-- Position totem bar whenever player frame applies size changes
	local originalApplySize = addon.ApplySize
	if originalApplySize then
		local hooked = false
		if not hooked then
			hooked = true
			hooksecurefunc(addon, "ApplySize", function(self, frame)
				if frame == playerFrame then
					C_Timer.After(0, function()
						addon.TotemBar:RefreshTotemLayout()
					end)
				end
			end)
		end
	end
	
	-- Add OnUpdate handler to periodically re-anchor totem frame to auras
	-- This ensures frame stays in position even if something moves it
	if not playerFrame.__sufTotemBarRefreshHooked then
		playerFrame.__sufTotemBarRefreshHooked = true
		local refreshCounter = 0
		playerFrame:HookScript("OnUpdate", function()
			refreshCounter = refreshCounter + 1
			-- Refresh totem positioning every 30-60 OnUpdate calls (~0.5-1.0 second)
			if refreshCounter >= 45 then
				refreshCounter = 0
				addon.TotemBar:PositionTotemBar()
			end
		end)
	end
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
function TotemBar:Initialize()
	if self.started then return end
	
	-- Guard: Ensure player frame is spawned
	if not addon.frames or not addon.frames[1] then
		C_Timer.After(0.5, function()
			self:Initialize()
		end)
		return
	end
	
	self.started = true
	
	-- Defer hook setup to avoid taint during addon load
	C_Timer.After(0.1, function()
		HookTotemFrame()
		self:SetupCombatListener()
		self:HookPlayerFrameLayoutUpdates()
		self:RefreshTotemLayout()
	end)
end

-- Schedule initialization when addon is ready
if addon.OnAddOnReady then
	addon:RegisterMessage("SUF_AddOnReady", function()
		TotemBar:Initialize()
	end)
else
	-- Fallback: initialize after a short delay
	C_Timer.After(1, function()
		addon.TotemBar:Initialize()
	end)
end
