local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

function addon:EnsureSimpleDropdownFrame()
	if self._simpleDropdown and self._simpleDropdown.SetShown then
		return self._simpleDropdown
	end

	local frame = CreateFrame("Frame", "SUFSimpleDropdown", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:Hide()
	frame.buttons = {}
	frame.rowHeight = 18
	frame.padding = 8
	frame.maxVisible = 18
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(frame, "panel")
	else
		frame:SetBackdropColor(0.02, 0.02, 0.03, 1.00)
		frame:SetBackdropBorderColor(0.70, 0.62, 0.34, 0.98)
	end
	frame:SetScript("OnHide", function(widget)
		if widget and widget.ownerButton and widget.ownerButton.__sufOpenState then
			widget.ownerButton.__sufOpenState:SetText("|cFFB7BDC7▼|r")
		end
		widget.ownerButton = nil
	end)

	if frame.GetName then
		local name = frame:GetName()
		if name then
			UISpecialFrames[#UISpecialFrames + 1] = name
		end
	end

	self._simpleDropdown = frame
	return frame
end

function addon:ShowSimpleDropdown(ownerButton, options, getter, setter, width)
	local frame = self:EnsureSimpleDropdownFrame()
	if not frame then
		return
	end

	for i = 1, #frame.buttons do
		frame.buttons[i]:Hide()
	end

	local list = options or {}
	local rowHeight = frame.rowHeight or 18
	local padding = frame.padding or 8
	local maxRows = math.min(#list, frame.maxVisible or 18)
	local rowWidth = math.max(140, tonumber(width) or 180)

	local function GetOwnerTopFrame(widget)
		local current = widget
		local top = nil
		for _ = 1, 24 do
			if not current then
				break
			end
			top = current
			if not current.GetParent then
				break
			end
			current = current:GetParent()
			if current == UIParent then
				break
			end
		end
		return top
	end

	local topOwner = ownerButton and GetOwnerTopFrame(ownerButton) or nil
	if topOwner then
		frame:SetFrameStrata(topOwner:GetFrameStrata() or "FULLSCREEN_DIALOG")
		frame:SetFrameLevel(math.max((topOwner:GetFrameLevel() or 1) + 80, 200))
	else
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetFrameLevel(200)
	end

	for i = 1, maxRows do
		local entry = list[i]
		local button = frame.buttons[i]
		if not button then
			button = CreateFrame("Button", nil, frame)
			button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			button.text:SetPoint("LEFT", button, "LEFT", 6, 0)
			button.text:SetPoint("RIGHT", button, "RIGHT", -6, 0)
			button.text:SetJustifyH("LEFT")
			frame.buttons[i] = button
		end
		if self.ApplySUFButtonSkin then
			self:ApplySUFButtonSkin(button, "subtle")
		end
		button:SetFrameLevel((frame:GetFrameLevel() or 200) + 2)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding - ((i - 1) * rowHeight))
		button:SetSize(rowWidth, rowHeight)
		button:SetScript("OnClick", function()
			if setter then
				pcall(setter, entry.value)
			end
			if ownerButton and ownerButton.__sufValueText then
				ownerButton.__sufValueText:SetText(tostring(entry.text or entry.value or ""))
			end
			frame:Hide()
		end)
		local isSelected = getter and (getter() == entry.value)
		button.text:SetText((isSelected and "|cFF9AD8FF" or "|cFFFFFFFF") .. tostring(entry.text or entry.value or "") .. "|r")
		button:Show()
	end

	local totalHeight = (maxRows * rowHeight) + (padding * 2)
	frame:SetSize(rowWidth + (padding * 2), math.max(rowHeight + (padding * 2), totalHeight))
	frame:ClearAllPoints()
	if ownerButton and ownerButton.GetCenter then
		frame:SetPoint("TOPLEFT", ownerButton, "BOTTOMLEFT", 0, -2)
		frame.ownerButton = ownerButton
	else
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale() or 1
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
		frame.ownerButton = nil
	end
	frame:Show()
end
