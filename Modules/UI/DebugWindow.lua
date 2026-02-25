local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    return
end

local core = addon._core or {}
local addonName = core.addonName or "SimpleUnitFrames"

local function SetSUFWindowTitle(frame, text)
	if not frame then
		return
	end

	local titleText = frame.TitleText
	if titleText and titleText.SetText then
		titleText:ClearAllPoints()
		titleText:SetPoint("TOP", frame, "TOP", 0, -4)
		titleText:SetText(text or "")
		return
	end

	local fallback = frame._sufTitleFallback
	if not fallback then
		fallback = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		frame._sufTitleFallback = fallback
	end
	fallback:ClearAllPoints()
	fallback:SetPoint("TOP", frame, "TOP", 0, -4)
	fallback:SetText(text or "")
end

function addon:RefreshDebugPanel()
	if not self.debugPanel or not self.debugPanel.messagesText then
		return
	end
	local text = table.concat(self.debugMessages or {}, "\n")
	self.debugPanel.messagesText:SetText(text)
	local height = self.debugPanel.messagesText:GetStringHeight()
	self.debugPanel.textFrame:SetHeight(math.max(height + 10, 1))
end

function addon:ShowDebugExportDialog()
	local exportText = table.concat(self.debugMessages or {}, "\n")
	if exportText == "" then
		self:Print(addonName .. ": No debug messages to export.")
		return
	end

	if not self.debugExportFrame then
		local frame = CreateFrame("Frame", "SUFDebugExportFrame", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(520, 420)
		frame:SetPoint("CENTER")
		self:EnableMovableFrame(frame, true, "debug_export", { "CENTER", "UIParent", "CENTER", 0, 0 })
		frame:SetFrameStrata("DIALOG")

		SetSUFWindowTitle(frame, "SUF Debug Export")
		if self.ApplySUFBackdrop then
			self:ApplySUFBackdrop(frame, "window")
		end

		local note = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		note:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
		note:SetText("Ctrl+A then Ctrl+C to copy.")

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -56)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

		local editBox = CreateFrame("EditBox", nil, scroll)
		editBox:SetMultiLine(true)
		editBox:SetFontObject(GameFontHighlightSmall)
		editBox:SetWidth(470)
		editBox:SetAutoFocus(false)
		editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
		scroll:SetScrollChild(editBox)
		frame.editBox = editBox

		self.debugExportFrame = frame
	end

	SetSUFWindowTitle(self.debugExportFrame, "SUF Debug Export")
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(self.debugExportFrame, "window")
	end
	self.debugExportFrame.editBox:SetText(exportText)
	self.debugExportFrame.editBox:SetCursorPosition(0)
	self.debugExportFrame.editBox:HighlightText()
	self:PrepareWindowForDisplay(self.debugExportFrame)
	self.debugExportFrame:Show()
	self:PlayWindowOpenAnimation(self.debugExportFrame)
end

function addon:ShowDebugSettings()
	self:EnsureDebugConfig()
	if not self.debugSettingsFrame then
		local frame = CreateFrame("Frame", "SUFDebugSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(320, 360)
		frame:SetPoint("CENTER", UIParent, "CENTER", -360, 0)
		self:EnableMovableFrame(frame, true, "debug_settings", { "CENTER", "UIParent", "CENTER", -360, 0 })

		SetSUFWindowTitle(frame, "SUF Debug Settings")
		if self.ApplySUFBackdrop then
			self:ApplySUFBackdrop(frame, "window")
		end

		local enableAll = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		enableAll:SetSize(90, 24)
		enableAll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -36)
		enableAll:SetText("Enable All")
		enableAll:SetScript("OnClick", function()
			for key in pairs(self.db.profile.debug.systems) do
				self.db.profile.debug.systems[key] = true
			end
			self:ShowDebugSettings()
		end)

		local disableAll = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		disableAll:SetSize(90, 24)
		disableAll:SetPoint("LEFT", enableAll, "RIGHT", 10, 0)
		disableAll:SetText("Disable All")
		disableAll:SetScript("OnClick", function()
			for key in pairs(self.db.profile.debug.systems) do
				self.db.profile.debug.systems[key] = false
			end
			self:ShowDebugSettings()
		end)

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -68)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
		local child = CreateFrame("Frame", nil, scroll)
		child:SetSize(250, 1)
		scroll:SetScrollChild(child)
		frame.scrollChild = child

		self.debugSettingsFrame = frame
	end

	local frame = self.debugSettingsFrame
	SetSUFWindowTitle(frame, "SUF Debug Settings")
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(frame, "window")
	end
	local child = frame.scrollChild
	for i = child:GetNumChildren(), 1, -1 do
		local element = select(i, child:GetChildren())
		if element then
			element:Hide()
			element:SetParent(nil)
		end
	end

	local y = -6
	for system, value in pairs(self.db.profile.debug.systems) do
		local cb = CreateFrame("CheckButton", nil, child, "UICheckButtonTemplate")
		cb:SetPoint("TOPLEFT", child, "TOPLEFT", 6, y)
		cb:SetChecked(value)
		cb:SetScript("OnClick", function(btn)
			self.db.profile.debug.systems[system] = btn:GetChecked() and true or false
		end)
		local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
		label:SetText(system)
		y = y - 24
	end
	child:SetHeight(math.max(math.abs(y) + 8, 1))
	self:PrepareWindowForDisplay(frame)
	frame:Show()
	self:PlayWindowOpenAnimation(frame)
end

function addon:ShowDebugPanel()
	self:EnsureDebugConfig()
	if not self.debugPanel then
		local frame = CreateFrame("Frame", "SUFDebugPanel", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(620, 420)
		frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
		self:EnableMovableFrame(frame, true, "debug_console", { "CENTER", "UIParent", "CENTER", 260, 0 })

		SetSUFWindowTitle(frame, "SUF Debug Console")
		if self.ApplySUFBackdrop then
			self:ApplySUFBackdrop(frame, "window")
		end

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -36)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 46)
		local textFrame = CreateFrame("Frame", nil, scroll)
		textFrame:SetSize(560, 1)
		local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 4, 0)
		text:SetWidth(550)
		text:SetJustifyH("LEFT")
		text:SetJustifyV("TOP")
		scroll:SetScrollChild(textFrame)
		frame.messagesText = text
		frame.textFrame = textFrame

		local toggleBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		toggleBtn:SetSize(100, 24)
		toggleBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
		local function UpdateToggleLabel()
			toggleBtn:SetText(self:IsDebugEnabled() and "Enabled" or "Disabled")
		end
		UpdateToggleLabel()
		toggleBtn:SetScript("OnClick", function()
			self.db.profile.debug.enabled = not self.db.profile.debug.enabled
			UpdateToggleLabel()
			self:DebugLog("General", "Debug mode " .. (self.db.profile.debug.enabled and "enabled" or "disabled"), 2)
		end)
		frame.toggleBtn = toggleBtn

		local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		clearBtn:SetSize(80, 24)
		clearBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
		clearBtn:SetText("Clear")
		clearBtn:SetScript("OnClick", function()
			self.debugMessages = {}
			self:RefreshDebugPanel()
		end)

		local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		exportBtn:SetSize(80, 24)
		exportBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
		exportBtn:SetText("Export")
		exportBtn:SetScript("OnClick", function()
			self:ShowDebugExportDialog()
		end)

		local settingsBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		settingsBtn:SetSize(70, 24)
		settingsBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
		settingsBtn:SetText("Settings")
		settingsBtn:SetScript("OnClick", function()
			self:ShowDebugSettings()
		end)
		frame.settingsBtn = settingsBtn

		local profileStartBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		profileStartBtn:SetSize(72, 24)
		profileStartBtn:SetPoint("LEFT", settingsBtn, "RIGHT", 8, 0)
		profileStartBtn:SetText("Start")
		profileStartBtn:SetScript("OnClick", function()
			self:StartPerformanceProfileFromUI()
			if self.debugPanel and self.debugPanel.UpdateProfileButtons then
				self.debugPanel:UpdateProfileButtons()
			end
		end)
		frame.profileStartBtn = profileStartBtn

		local profileStopBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		profileStopBtn:SetSize(64, 24)
		profileStopBtn:SetPoint("LEFT", profileStartBtn, "RIGHT", 8, 0)
		profileStopBtn:SetText("Stop")
		profileStopBtn:SetScript("OnClick", function()
			self:StopPerformanceProfileFromUI()
			if self.debugPanel and self.debugPanel.UpdateProfileButtons then
				self.debugPanel:UpdateProfileButtons()
			end
		end)
		frame.profileStopBtn = profileStopBtn

		local profileAnalyzeBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		profileAnalyzeBtn:SetSize(72, 24)
		profileAnalyzeBtn:SetPoint("LEFT", profileStopBtn, "RIGHT", 8, 0)
		profileAnalyzeBtn:SetText("Analyze")
		profileAnalyzeBtn:SetScript("OnClick", function()
			self:AnalyzePerformanceProfileFromUI()
		end)
		frame.profileAnalyzeBtn = profileAnalyzeBtn

		function frame:UpdateProfileButtons()
			local recording = addon:IsPerformanceProfiling()
			if self.profileStartBtn then
				self.profileStartBtn:SetEnabled(not recording)
			end
			if self.profileStopBtn then
				self.profileStopBtn:SetEnabled(recording)
			end
		end

		self.debugPanel = frame
	end

	if self.debugPanel.toggleBtn then
		self.debugPanel.toggleBtn:SetText(self:IsDebugEnabled() and "Enabled" or "Disabled")
	end
	if self.debugPanel.UpdateProfileButtons then
		self.debugPanel:UpdateProfileButtons()
	end
	SetSUFWindowTitle(self.debugPanel, "SUF Debug Console")
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(self.debugPanel, "window")
	end
	self:PrepareWindowForDisplay(self.debugPanel)
	self.debugPanel:Show()
	self:PlayWindowOpenAnimation(self.debugPanel)
	self:RefreshDebugPanel()
end

function addon:HideDebugPanel()
	if self.debugPanel then
		self.debugPanel:Hide()
	end
end

function addon:ToggleDebugPanel()
	if self.debugPanel and self.debugPanel:IsShown() then
		self:HideDebugPanel()
	else
		self:ShowDebugPanel()
	end
end

function addon:HandleDebugSlash(msg)
	self:EnsureDebugConfig()
	local command = (msg or ""):lower():match("^%s*(.-)%s*$")

	if command == "" then
		self:ToggleDebugPanel()
	elseif command == "on" or command == "enable" then
		self.db.profile.debug.enabled = true
		self:ShowDebugPanel()
	elseif command == "off" or command == "disable" then
		self.db.profile.debug.enabled = false
		self:HideDebugPanel()
	elseif command == "clear" then
		self.debugMessages = {}
		self:RefreshDebugPanel()
	elseif command == "export" then
		self:ShowDebugExportDialog()
	elseif command == "settings" then
		self:ShowDebugSettings()
	elseif command == "help" then
		self:Print(addonName .. ": /sufdebug, /sufdebug on|off|clear|export|settings")
	else
		local systems = self.db.profile.debug.systems
		local matchedKey
		for key in pairs(systems) do
			if key:lower() == command then
				matchedKey = key
				break
			end
		end
		if matchedKey then
			systems[matchedKey] = not systems[matchedKey]
			self:Print(addonName .. ": Debug system " .. matchedKey .. " = " .. tostring(systems[matchedKey]))
		else
			self:Print(addonName .. ": Unknown debug command. Use /sufdebug help")
		end
	end
end
