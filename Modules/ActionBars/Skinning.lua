--[[
    SUF ActionBars - Button skinning and text overlay pipeline.
    Ported from QUI ActionBars (QUI/modules/frames/actionbars.lua).
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

-- Wait for Core.lua to have run and populated addon.ActionBars
local ActionBars = addon.ActionBars
if not ActionBars then
	-- Core.lua loads first; if it hasn't run yet the table won't exist.
	-- Register a very-early init hook.
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function(self)
		self:UnregisterAllEvents()
		ActionBars = addon.ActionBars
	end)
end

local function GetAB()
	return addon.ActionBars
end

---------------------------------------------------------------------------
-- STRIP BLIZZARD ARTWORK
---------------------------------------------------------------------------

local function StripBlizzardArtwork(button)
	local ab = GetAB()
	if not ab then return end
	local state = ab.GetFrameState(button)
	if state.stripped then return end
	state.stripped = true

	local normalTex = button:GetNormalTexture()
	if normalTex then normalTex:SetAlpha(0) end
	if button.NormalTexture then button.NormalTexture:SetAlpha(0) end

	local icon = button.icon or button.Icon
	if icon and icon.GetMaskTexture and icon.RemoveMaskTexture then
		for i = 1, 10 do
			local mask = icon:GetMaskTexture(i)
			if mask then icon:RemoveMaskTexture(mask) end
		end
	end

	if button.FloatingBG   then button.FloatingBG:SetAlpha(0) end
	if button.SlotBackground then button.SlotBackground:SetAlpha(0) end
	if button.SlotArt      then button.SlotArt:SetAlpha(0) end
end

---------------------------------------------------------------------------
-- CLEAR SKINNING STATE (cleanup ghost textures on bar transitions)
---------------------------------------------------------------------------

local function ClearButtonSkinningState(button)
	local ab = GetAB()
	if not ab then return end
	local state = ab.GetFrameState(button)
	
	-- Hide and clear user-created textures
	if state.backdrop then
		state.backdrop:Hide()
	end
	if state.normal then
		state.normal:Hide()
	end
	if state.gloss then
		state.gloss:Hide()
	end
	
	-- Reset skin tracking
	state.skinKey = nil
	state.stripped = nil
end

---------------------------------------------------------------------------
-- SKIN BUTTON
---------------------------------------------------------------------------

local function SkinButton(button, settings)
	local ab = GetAB()
	if not ab or not button or not settings or not settings.skinEnabled then return end
	local state = ab.GetFrameState(button)

	local settingsKey = string.format("%d_%.2f_%s_%.2f_%s_%.2f",
		settings.iconSize   or 36,
		settings.iconZoom   or 0.07,
		tostring(settings.showBackdrop),
		settings.backdropAlpha or 0.8,
		tostring(settings.showGloss),
		settings.glossAlpha or 0.6
	)
	if state.skinKey == settingsKey then return end
	state.skinKey = settingsKey

	StripBlizzardArtwork(button)

	local zoom = settings.iconZoom or 0.07
	local icon = button.icon or button.Icon
	if icon then
		icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
		icon:ClearAllPoints()
		icon:SetAllPoints(button)
	end

	if settings.showBackdrop then
		if not state.backdrop then
			state.backdrop = button:CreateTexture(nil, "BACKGROUND", nil, -8)
			state.backdrop:SetColorTexture(0, 0, 0, 1)
		end
		state.backdrop:SetAlpha(settings.backdropAlpha or 0.8)
		state.backdrop:ClearAllPoints()
		state.backdrop:SetAllPoints(button)
		state.backdrop:Show()
	elseif state.backdrop then
		state.backdrop:Hide()
	end

	if settings.showBorders ~= false then
		local iconSize = settings.iconSize or 36
		if not state.normal then
			state.normal = button:CreateTexture(nil, "OVERLAY", nil, 1)
			state.normal:SetTexture(ab.TEXTURES.normal)
			state.normal:SetVertexColor(0, 0, 0, 1)
		end
		state.normal:SetSize(iconSize, iconSize)
		state.normal:ClearAllPoints()
		state.normal:SetAllPoints(button)
		state.normal:Show()
	elseif state.normal then
		state.normal:Hide()
	end

	if settings.showGloss then
		if not state.gloss then
			state.gloss = button:CreateTexture(nil, "OVERLAY", nil, 2)
			state.gloss:SetTexture(ab.TEXTURES.gloss)
			state.gloss:SetBlendMode("ADD")
		end
		state.gloss:SetVertexColor(1, 1, 1, settings.glossAlpha or 0.6)
		state.gloss:SetAllPoints(button)
		state.gloss:Show()
	elseif state.gloss then
		state.gloss:Hide()
	end

	local cooldown = button.cooldown or button.Cooldown
	if cooldown then
		cooldown:ClearAllPoints()
		cooldown:SetAllPoints(button)
	end

	ab.skinnedButtons[button] = true
end

---------------------------------------------------------------------------
-- STRIP COLOUR CODES / KEYBIND VALIDITY
---------------------------------------------------------------------------

local RANGE_INDICATOR = RANGE_INDICATOR or "●"

local function StripColorCodes(text)
	if not text then return "" end
	return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function IsValidKeybindText(text)
	if not text or text == "" then return false end
	local stripped = StripColorCodes(text)
	if stripped == "" then return false end
	if stripped == RANGE_INDICATOR then return false end
	if stripped == "[]" then return false end
	return true
end

---------------------------------------------------------------------------
-- TEXT UPDATES
---------------------------------------------------------------------------

local BUTTON_BINDING_MAP = {
	ActionButton            = "ACTIONBUTTON",
	MultiBarBottomRightButton = "MULTIACTIONBAR2BUTTON",
	MultiBarBottomLeftButton  = "MULTIACTIONBAR1BUTTON",
	MultiBarRightButton       = "MULTIACTIONBAR3BUTTON",
	MultiBarLeftButton        = "MULTIACTIONBAR4BUTTON",
	MultiBar5Button           = "MULTIACTIONBAR5BUTTON",
	MultiBar6Button           = "MULTIACTIONBAR6BUTTON",
	MultiBar7Button           = "MULTIACTIONBAR7BUTTON",
}

local function FormatCompactBindingLabel(key)
	if not key or key == "" then return nil end

	key = key:upper():gsub("%s+", "")
	local modifiers = {}
	local removed

	key, removed = key:gsub("SHIFT%-", "")
	if removed > 0 then modifiers[#modifiers + 1] = "S" end
	key, removed = key:gsub("ALT%-", "")
	if removed > 0 then modifiers[#modifiers + 1] = "A" end
	key, removed = key:gsub("CTRL%-", "")
	if removed > 0 then modifiers[#modifiers + 1] = "C" end

	if key == "LEFTBUTTON" then key = "BUTTON1" end
	if key == "RIGHTBUTTON" then key = "BUTTON2" end
	if key == "MIDDLEBUTTON" then key = "BUTTON3" end

	local buttonIndex = key:match("^BUTTON(%d+)$")
	if buttonIndex then
		key = "M" .. buttonIndex
	elseif key == "MOUSEWHEELUP" then
		key = "MWU"
	elseif key == "MOUSEWHEELDOWN" then
		key = "MWD"
	end

	if #modifiers > 0 then
		return table.concat(modifiers, "") .. "(" .. key .. ")"
	end

	return key
end

local function GetKeybindForButton(button)
	local name = button and button:GetName()
	if not name then return nil end
	for prefix, bindPrefix in pairs(BUTTON_BINDING_MAP) do
		local num = name:match("^" .. prefix .. "(%d+)$")
		if num then
			local key = GetBindingKey(bindPrefix .. num)
			if key then
				return FormatCompactBindingLabel(key)
			end
		end
	end
	return nil
end

local function UpdateKeybindText(button, settings)
	local hotkey = button.HotKey or button.hotKey
	if not hotkey then return end

	if not settings.showKeybinds then
		hotkey:SetAlpha(0)
		hotkey:Hide()
		return
	end

	local abbreviated = GetKeybindForButton(button)

	local shouldShow = abbreviated and abbreviated ~= ""
	if shouldShow and settings.hideEmptyKeybinds then
		if button.action then
			local ab = GetAB()
			if ab and not ab.SafeHasAction(button.action) then
				shouldShow = false
			end
		end
	end

	if not shouldShow then
		hotkey:SetAlpha(0)
		hotkey:Hide()
		return
	end

	hotkey:SetText(abbreviated)
	hotkey:Show()
	hotkey:SetAlpha(1)

	local ab = GetAB()
	local fontPath, outline = ab and ab.GetFontSettings() or "Fonts\\FRIZQT__.TTF", "OUTLINE"
	hotkey:SetFont(fontPath, settings.keybindFontSize or 11, outline)

	local c = settings.keybindColor
	hotkey:SetTextColor(c and c[1] or 1, c and c[2] or 1, c and c[3] or 1, c and c[4] or 1)
	hotkey:ClearAllPoints()
	local anchor = settings.keybindAnchor or "TOPRIGHT"
	hotkey:SetPoint(anchor, button, anchor, settings.keybindOffsetX or 0, settings.keybindOffsetY or 0)
end

local function UpdateMacroText(button, settings)
	local name = button.Name
	if not name then return end

	if not settings.showMacroNames then
		name:SetAlpha(0)
		return
	end

	name:SetAlpha(1)
	local ab = GetAB()
	local fontPath, outline = ab and ab.GetFontSettings() or "Fonts\\FRIZQT__.TTF", "OUTLINE"
	name:SetFont(fontPath, settings.macroNameFontSize or 10, outline)

	local c = settings.macroNameColor
	name:SetTextColor(c and c[1] or 1, c and c[2] or 1, c and c[3] or 1, c and c[4] or 1)
	name:ClearAllPoints()
	local anchor = settings.macroNameAnchor or "BOTTOM"
	name:SetPoint(anchor, button, anchor, settings.macroNameOffsetX or 0, settings.macroNameOffsetY or 0)
end

local function UpdateCountText(button, settings)
	local count = button.Count
	if not count then return end

	if not settings.showCounts then
		count:SetAlpha(0)
		return
	end

	count:SetAlpha(1)
	local ab = GetAB()
	local fontPath, outline = ab and ab.GetFontSettings() or "Fonts\\FRIZQT__.TTF", "OUTLINE"
	count:SetFont(fontPath, settings.countFontSize or 14, outline)

	local c = settings.countColor
	count:SetTextColor(c and c[1] or 1, c and c[2] or 1, c and c[3] or 1, c and c[4] or 1)
	count:ClearAllPoints()
	local anchor = settings.countAnchor or "BOTTOMRIGHT"
	count:SetPoint(anchor, button, anchor, settings.countOffsetX or 0, settings.countOffsetY or 0)
end

local function UpdateButtonText(button, settings)
	UpdateKeybindText(button, settings)
	UpdateMacroText(button, settings)
	UpdateCountText(button, settings)
end

---------------------------------------------------------------------------
-- SKIN ALL BARS
---------------------------------------------------------------------------

local function SkinBar(barKey)
	local ab = GetAB()
	if not ab then return end
	local db = ab.GetDB()
	if not db or not db.enabled then return end

	local barSettings = ab.GetBarSettings(barKey)
	if not barSettings or not barSettings.enabled then return end

	local effectiveSettings = ab.GetEffectiveSettings(barKey)
	if not effectiveSettings then return end

	local buttons = ab.GetBarButtons(barKey)
	for _, button in ipairs(buttons) do
		SkinButton(button, effectiveSettings)
		UpdateButtonText(button, effectiveSettings)

		-- Register LibKeyBound binding methods
		if addon.ActionBarsBindings then
			addon.ActionBarsBindings.AddKeybindMethods(button, barKey)
		end

		-- LibKeyBound hover-register hook
		local state = ab.GetFrameState(button)
		if not state.onEnterHooked then
			state.onEnterHooked = true
			button:HookScript("OnEnter", function(self)
				local LibKeyBound = LibStub and LibStub("LibKeyBound-1.0", true)
				if LibKeyBound and LibKeyBound:IsShown() then
					LibKeyBound:Set(self)
				end
			end)
		end
	end
end

local function SkinAllBars()
	local ab = GetAB()
	if not ab then return end
	local db = ab.GetDB()
	if not db or not db.enabled then return end

	for barKey in pairs(ab.BAR_FRAMES) do
		if ab.BUTTON_PATTERNS[barKey] then
			SkinBar(barKey)
		end
		if addon.ActionBarsFade then
			addon.ActionBarsFade.SetupBarMouseover(barKey)
		end
	end
end

---------------------------------------------------------------------------
-- EXPOSE ON ADDON
---------------------------------------------------------------------------

addon.ActionBarsSkinning = {
	SkinButton                = SkinButton,
	SkinBar                   = SkinBar,
	SkinAllBars               = SkinAllBars,
	UpdateKeybindText         = UpdateKeybindText,
	UpdateMacroText           = UpdateMacroText,
	UpdateCountText           = UpdateCountText,
	UpdateButtonText          = UpdateButtonText,
	ClearButtonSkinningState  = ClearButtonSkinningState,
}
