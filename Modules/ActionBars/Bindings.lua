--[[
    SUF ActionBars - LibKeyBound integration and Midnight-safe binding patch.
    Ported from QUI ActionBars (QUI/modules/frames/actionbars.lua).

    On pre-Midnight clients, binding methods are injected directly onto buttons.
    On Midnight (12.0+), mutating secure action buttons spreads taint, so we
    store binding data in the external frameState table and patch LibKeyBound's
    Binder to read from it instead.
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

local IS_MIDNIGHT = select(4, GetBuildInfo()) >= 120000

local function GetAB()
	return addon.ActionBars
end

local function ToCompactBindingLabel(key)
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

---------------------------------------------------------------------------
-- ADD KEYBIND METHODS
---------------------------------------------------------------------------

local function AddKeybindMethods(button, barKey)
	if not button then return end
	local ab = GetAB()
	if not ab then return end

	local state = ab.GetFrameState(button)
	if state.keybindMethods then return end

	local bindingPrefix = ab.BINDING_COMMANDS[barKey]
	if not bindingPrefix then return end

	local buttonIndex = ab.GetButtonIndex(button)
	if not buttonIndex then return end

	local bindingCommand = bindingPrefix .. buttonIndex
	state.bindingCommand = bindingCommand
	state.keybindMethods = true

	-- On Midnight skip method injection; the patched Binder handles it.
	if IS_MIDNIGHT then return end

	function button:GetHotkey()
		local command = GetAB() and GetAB().GetFrameState(self).bindingCommand
		local key = command and GetBindingKey(command)
		if key then return ToCompactBindingLabel(key) end
		return nil
	end

	function button:SetKey(key)
		if InCombatLockdown() then return end
		local command = GetAB() and GetAB().GetFrameState(self).bindingCommand
		if command then SetBinding(key, command) end
	end

	function button:GetBindings()
		local command = GetAB() and GetAB().GetFrameState(self).bindingCommand
		if not command then return nil end
		local keys = {}
		for i = 1, select("#", GetBindingKey(command)) do
			local key = select(i, GetBindingKey(command))
			if key then keys[#keys + 1] = key end
		end
		return #keys > 0 and table.concat(keys, ", ") or nil
	end

	function button:ClearBindings()
		if InCombatLockdown() then return end
		local command = GetAB() and GetAB().GetFrameState(self).bindingCommand
		if not command then return end
		while GetBindingKey(command) do
			SetBinding(GetBindingKey(command), nil)
		end
	end

	function button:GetActionName()
		local ab = GetAB()
		return ab and ab.GetFrameState(self).bindingCommand
	end
end

---------------------------------------------------------------------------
-- PATCH LIBKEYBOUND FOR MIDNIGHT
---------------------------------------------------------------------------

local libKeyBoundPatched = false

local function PatchLibKeyBoundForMidnight()
	if not IS_MIDNIGHT then return end
	if libKeyBoundPatched then return end

	local LibKeyBound = LibStub and LibStub("LibKeyBound-1.0", true)
	if not LibKeyBound then return end

	libKeyBoundPatched = true
	local Binder = LibKeyBound.Binder

	local function GetBindingCommand(button)
		local ab = GetAB()
		if not ab then return nil end
		local state = ab.GetFrameState(button)
		return state and state.bindingCommand
	end

	-- SetKey
	function Binder:SetKey(button, key)
		if InCombatLockdown() then
			UIErrorsFrame:AddMessage(LibKeyBound.L.CannotBindInCombat, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
			return
		end
		self:FreeKey(button, key)
		local command = GetBindingCommand(button)
		if command then
			SetBinding(key, command)
		elseif button.SetKey then
			button:SetKey(key)
		else
			SetBindingClick(key, button:GetName(), "LeftButton")
		end
		local msg
		if command then
			msg = format(LibKeyBound.L.BoundKey, GetBindingText(key), command)
		elseif button.GetActionName then
			msg = format(LibKeyBound.L.BoundKey, GetBindingText(key), button:GetActionName())
		else
			msg = format(LibKeyBound.L.BoundKey, GetBindingText(key), button:GetName())
		end
		UIErrorsFrame:AddMessage(msg, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	end

	-- ClearBindings
	function Binder:ClearBindings(button)
		if InCombatLockdown() then
			UIErrorsFrame:AddMessage(LibKeyBound.L.CannotBindInCombat, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
			return
		end
		local command = GetBindingCommand(button)
		if command then
			while GetBindingKey(command) do SetBinding(GetBindingKey(command), nil) end
		elseif button.ClearBindings then
			button:ClearBindings()
		else
			local binding = self:ToBinding(button)
			while GetBindingKey(binding) do SetBinding(GetBindingKey(binding), nil) end
		end
		local msg
		if command then
			msg = format(LibKeyBound.L.ClearedBindings, command)
		elseif button.GetActionName then
			msg = format(LibKeyBound.L.ClearedBindings, button:GetActionName())
		else
			msg = format(LibKeyBound.L.ClearedBindings, button:GetName())
		end
		UIErrorsFrame:AddMessage(msg, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	end

	-- GetBindings
	local origGetBindings = Binder.GetBindings
	function Binder:GetBindings(button)
		local command = GetBindingCommand(button)
		if command then
			local keys
			for i = 1, select("#", GetBindingKey(command)) do
				local hotKey = select(i, GetBindingKey(command))
				if keys then
					keys = keys .. ", " .. GetBindingText(hotKey)
				else
					keys = GetBindingText(hotKey)
				end
			end
			return keys
		end
		return origGetBindings(self, button)
	end

	-- FreeKey
	local origFreeKey = Binder.FreeKey
	function Binder:FreeKey(button, key)
		local command = GetBindingCommand(button)
		if command then
			local action = GetBindingAction(key)
			if action and action ~= "" and action ~= command then
				SetBinding(key, nil)
				local msg = format(LibKeyBound.L.UnboundKey, GetBindingText(key), action)
				UIErrorsFrame:AddMessage(msg, 1, 0.82, 0, 1, UIERRORS_HOLD_TIME)
			end
		else
			origFreeKey(self, button, key)
		end
	end

	-- LibKeyBound:Set wrapper
	local origSet = LibKeyBound.Set
	function LibKeyBound:Set(button, ...)
		if not button or not GetBindingCommand(button) then
			return origSet(self, button, ...)
		end
		if self:IsShown() and not InCombatLockdown() then
			local bindFrame = self.frame
			if bindFrame then
				bindFrame.button = button
				bindFrame:SetAllPoints(button)
				local hotkeyText
				local cmd = GetBindingCommand(button)
				if cmd then
					local key = GetBindingKey(cmd)
					if key then hotkeyText = ToCompactBindingLabel(key) end
				end
				bindFrame.text:SetFontObject("GameFontNormalLarge")
				bindFrame.text:SetText(hotkeyText or "")
				if bindFrame.text:GetStringWidth() > bindFrame:GetWidth() then
					bindFrame.text:SetFontObject("GameFontNormal")
				end
				bindFrame:Show()
				bindFrame:OnEnter()
			end
		elseif self.frame then
			self.frame.button = nil
			self.frame:ClearAllPoints()
			self.frame:Hide()
		end
	end

	-- Binder:OnEnter wrapper
	local origOnEnter = Binder.OnEnter
	function Binder:OnEnter()
		local button = self.button
		if not button or not GetBindingCommand(button) then
			return origOnEnter(self)
		end
		if not InCombatLockdown() then
			if self:GetRight() >= (GetScreenWidth() / 2) then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			end
			local command = GetBindingCommand(button)
			GameTooltip:SetText(command, 1, 1, 1)
			local bindings = self:GetBindings(button)
			if bindings and bindings ~= "" then
				GameTooltip:AddLine(bindings, 0, 1, 0)
				GameTooltip:AddLine(LibKeyBound.L.ClearTip)
			else
				GameTooltip:AddLine(LibKeyBound.L.NoKeysBoundTip, 0, 1, 0)
			end
			GameTooltip:Show()
		else
			GameTooltip:Hide()
		end
	end
end

---------------------------------------------------------------------------
-- EXPOSE ON ADDON
---------------------------------------------------------------------------

addon.ActionBarsBindings = {
	AddKeybindMethods          = AddKeybindMethods,
	PatchLibKeyBoundForMidnight = PatchLibKeyBoundForMidnight,
}
