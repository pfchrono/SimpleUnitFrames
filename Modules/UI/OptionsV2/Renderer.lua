local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local function ReleaseContent(content)
	if not content or not content._sufV2Regions then
		return
	end
	for i = 1, #content._sufV2Regions do
		local region = content._sufV2Regions[i]
		if region and region.Hide then
			region:Hide()
			region:SetParent(nil)
		end
	end
	wipe(content._sufV2Regions)
end

local function Track(content, region)
	content._sufV2Regions = content._sufV2Regions or {}
	content._sufV2Regions[#content._sufV2Regions + 1] = region
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn, ...)
	if ok then
		return result
	end
	return nil
end

local function Clamp(v, min, max)
	local n = tonumber(v) or min
	if n < min then
		n = min
	elseif n > max then
		n = max
	end
	return n
end

local function ResolveWidthChars(control, initialText)
	if not control then
		return nil
	end
	local raw = control.widthChars
	if type(raw) == "function" then
		raw = SafeCall(raw, initialText)
	end
	local chars = tonumber(raw)
	if not chars then
		return nil
	end
	return math.max(4, math.floor(chars))
end

local function TintTexture(texture, color)
	if not (texture and texture.SetVertexColor and color) then
		return
	end
	texture:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
end

local function TintButtonTextures(button, color)
	if not (button and color) then
		return
	end
	TintTexture(button.GetNormalTexture and button:GetNormalTexture(), color)
	TintTexture(button.GetPushedTexture and button:GetPushedTexture(), color)
	TintTexture(button.GetHighlightTexture and button:GetHighlightTexture(), color)
	TintTexture(button.GetDisabledTexture and button:GetDisabledTexture(), color)
end

local function ApplyDropdownFontPreview(dropdown, selected, style)
	if not dropdown then
		return
	end

	local regions = { dropdown:GetRegions() }
	for i = 1, #regions do
		local region = regions[i]
		if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.SetTextColor then
			local color = style.accent or { 1, 1, 1 }
			region:SetTextColor(color[1], color[2], color[3], 1)
			if selected and type(selected.previewFont) == "string" and selected.previewFont ~= "" and region.SetFont then
				local path = selected.previewFont
				local _, size, flags = region:GetFont()
				region:SetFont(path, tonumber(size) or 12, flags)
			elseif region.SetFontObject then
				region:SetFontObject(GameFontHighlightSmall)
			end
		end
	end
end

local function RenderSectionTabs(content, style, spec, y, pageKey)
	if not spec or type(spec.sectionTabs) ~= "table" then
		return y, nil
	end
	local getActive = spec.getActiveSection
	local setActive = spec.setActiveSection
	if type(getActive) ~= "function" or type(setActive) ~= "function" then
		return y, nil
	end
	addon._optionsV2RuntimeSectionState = addon._optionsV2RuntimeSectionState or {}
	local runtimeState = addon._optionsV2RuntimeSectionState
	local tabs = spec.sectionTabs
	local active = runtimeState[pageKey] and tostring(runtimeState[pageKey]) or tostring(SafeCall(getActive) or "all")
	addon._optionsV2SearchFlash = addon._optionsV2SearchFlash or {}
	local flashSection = addon._optionsV2SearchFlash[pageKey]
	local contentWidth = math.max(320, math.floor((content:GetWidth() or 320) - 20))
	local strip = CreateFrame("Frame", nil, content)
	strip:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
	strip:SetWidth(contentWidth)
	strip:SetHeight(26)
	Track(content, strip)
	local count = #tabs
	local spacing = 4
	local minTabWidth = 72
	local rows = 1
	local row = 1
	local col = 0
	local maxCols = math.max(1, math.floor((strip:GetWidth() + spacing) / (minTabWidth + spacing)))
	local tabWidth = math.floor((strip:GetWidth() - (spacing * math.max(0, maxCols - 1))) / maxCols)
	if tabWidth < 56 then
		maxCols = math.max(1, math.floor((strip:GetWidth() + spacing) / (56 + spacing)))
		tabWidth = math.floor((strip:GetWidth() - (spacing * math.max(0, maxCols - 1))) / maxCols)
	end
	tabWidth = math.max(56, tabWidth)
	tabWidth = math.min(140, tabWidth)
	for i = 1, count do
		local tab = tabs[i]
		if col >= maxCols then
			row = row + 1
			rows = math.max(rows, row)
			col = 0
		end
		local x = col * (tabWidth + spacing)
		local yOffset = -((row - 1) * 24)
		local btn = CreateFrame("Button", nil, strip, "BackdropTemplate")
		btn:SetSize(tabWidth, 22)
		btn:SetPoint("TOPLEFT", strip, "TOPLEFT", x, yOffset)
		btn:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		local selected = active == tostring(tab.key)
		local shouldFlash = selected and flashSection and tostring(flashSection) == tostring(tab.key)
		if addon.ApplySUFBackdropColors then
			if shouldFlash then
				addon:ApplySUFBackdropColors(btn, style.navHover or style.navSelected, style.navHoverBorder or style.navSelectedBorder, false)
			elseif selected then
				addon:ApplySUFBackdropColors(btn, style.navSelected, style.navSelectedBorder, false)
			else
				addon:ApplySUFBackdropColors(btn, style.navDefault, style.navDefaultBorder, false)
			end
		end
		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
		fs:SetText(tostring(tab.label or tab.key))
		if shouldFlash then
			fs:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
		elseif selected then
			fs:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
		else
			fs:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
		end
		btn:SetScript("OnClick", function()
			local target = tostring(tab.key)
			runtimeState[pageKey] = target
			local ok = pcall(setActive, target)
			if not ok then
				return
			end
			if addon.optionsV2Frame and addon.optionsV2Frame.currentPage and addon.optionsV2Frame.SetPage then
				local currentPage = addon.optionsV2Frame.currentPage
				addon.optionsV2Frame:SetPage(currentPage)
				if C_Timer and C_Timer.After then
					C_Timer.After(0, function()
						if addon.optionsV2Frame and addon.optionsV2Frame:IsShown() and addon.optionsV2Frame.RefreshCurrentPage then
							addon.optionsV2Frame:RefreshCurrentPage()
						end
					end)
				end
			end
		end)
		Track(content, btn)
		col = col + 1
	end
	strip:SetHeight(rows * 24)
	if flashSection and tostring(flashSection) == tostring(active) then
		addon._optionsV2SearchFlash[pageKey] = nil
	end
	return y - (rows * 24) - 8, active
end

local function OpenColorPicker(initialR, initialG, initialB, onChanged)
	if type(ColorPickerFrame) ~= "table" then
		return false
	end
	local r = tonumber(initialR) or 1
	local g = tonumber(initialG) or 1
	local b = tonumber(initialB) or 1
	local function ApplyFromPicker()
		local nr, ng, nb
		if ColorPickerFrame.GetColorRGB then
			nr, ng, nb = ColorPickerFrame:GetColorRGB()
		elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker and ColorPickerFrame.Content.ColorPicker.GetColorRGB then
			nr, ng, nb = ColorPickerFrame.Content.ColorPicker:GetColorRGB()
		end
		if nr and ng and nb and type(onChanged) == "function" then
			onChanged(nr, ng, nb)
		end
	end
	if ColorPickerFrame.SetupColorPickerAndShow then
		local info = {
			r = r,
			g = g,
			b = b,
			hasOpacity = false,
			swatchFunc = ApplyFromPicker,
			opacityFunc = nil,
			cancelFunc = nil,
		}
		ColorPickerFrame:SetupColorPickerAndShow(info)
		return true
	end
	if ColorPickerFrame.SetColorRGB then
		ColorPickerFrame.func = ApplyFromPicker
		ColorPickerFrame.opacityFunc = nil
		ColorPickerFrame.cancelFunc = nil
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame:Show()
		return true
	end
	return false
end

local function BuildImportExportReportText(addonRef, state)
	state = state or {}
	local lines = {}
	if state.message and state.message ~= "" then
		lines[#lines + 1] = state.message
	end
	local report = state.report
	if report then
		lines[#lines + 1] = ("Top-level keys: %d"):format(tonumber(report.keyCount or 0) or 0)
		lines[#lines + 1] = ("Units: %d | Tags: %d | Plugin Units: %d"):format(
			tonumber(report.unitCount or 0) or 0,
			tonumber(report.tagCount or 0) or 0,
			tonumber(report.pluginUnitCount or 0) or 0
		)
		if report.reloadReasons and #report.reloadReasons > 0 then
			lines[#lines + 1] = "Affects: " .. table.concat(report.reloadReasons, ", ")
		end
		if report.warnings and #report.warnings > 0 then
			for i = 1, #report.warnings do
				lines[#lines + 1] = "Warning: " .. tostring(report.warnings[i])
			end
		end
		if report.errors and #report.errors > 0 then
			for i = 1, #report.errors do
				lines[#lines + 1] = "Error: " .. tostring(report.errors[i])
			end
		end
	end
	if state.preview and state.preview.summary then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Preview:"
		lines[#lines + 1] = tostring(state.preview.summary)
	end
	if #lines == 0 then
		lines[1] = "Ready. Paste import code, then Validate or Import."
	end
	return table.concat(lines, "\n")
end

function addon:RenderOptionsV2ImportExport(content, page, style)
	local state = self._optionsV2ImportExportState or {}
	self._optionsV2ImportExportState = state
	state.codeText = state.codeText or ""
	state.message = state.message or "Ready."

	local y = -8
	local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
	title:SetText((page and page.label) or "Import / Export")
	title:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3])
	Track(content, title)
	y = y - 28

	local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
	desc:SetWidth(math.max(320, content:GetWidth() - 20))
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText("Export current addon settings to a code string, or import a code string and validate its effect before applying.")
	desc:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
	Track(content, desc)
	y = y - 44

	local cardWidth = math.max(420, content:GetWidth() - 20)
	local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
	card:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
	card:SetSize(cardWidth, 520)
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(card, style.panelBg, style.panelBorder, true)
	end
	Track(content, card)

	local cardTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	cardTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -12)
	cardTitle:SetText("Profile Code")
	cardTitle:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3])
	Track(content, cardTitle)

	local editBox = CreateFrame("EditBox", nil, card, "InputBoxTemplate")
	editBox:SetAutoFocus(false)
	editBox:SetMultiLine(true)
	editBox:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -34)
	editBox:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -34)
	editBox:SetTextInsets(6, 6, 6, 6)
	editBox:SetJustifyH("LEFT")
	editBox:SetJustifyV("TOP")
	editBox:SetText(state.codeText or "")
	Track(content, editBox)

	local measure = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	measure:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
	measure:SetWidth(math.max(220, cardWidth - 36))
	measure:SetJustifyH("LEFT")
	measure:SetJustifyV("TOP")
	measure:Hide()
	Track(content, measure)

	local status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -8)
	status:SetPoint("TOPRIGHT", editBox, "BOTTOMRIGHT", 0, -8)
	status:SetJustifyH("LEFT")
	status:SetJustifyV("TOP")
	status:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
	Track(content, status)

	local buttonRow = CreateFrame("Frame", nil, card)
	buttonRow:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -8)
	buttonRow:SetPoint("TOPRIGHT", status, "BOTTOMRIGHT", 0, -8)
	buttonRow:SetHeight(26)
	Track(content, buttonRow)

	local exportButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
	exportButton:SetPoint("LEFT", buttonRow, "LEFT", 0, 0)
	exportButton:SetSize(90, 24)
	exportButton:SetText("Export")
	Track(content, exportButton)

	local validateButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
	validateButton:SetPoint("LEFT", exportButton, "RIGHT", 8, 0)
	validateButton:SetSize(90, 24)
	validateButton:SetText("Validate")
	Track(content, validateButton)

	local importButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
	importButton:SetPoint("LEFT", validateButton, "RIGHT", 8, 0)
	importButton:SetSize(90, 24)
	importButton:SetText("Import")
	Track(content, importButton)

	local resultTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	resultTitle:SetPoint("TOPLEFT", buttonRow, "BOTTOMLEFT", 0, -10)
	resultTitle:SetText("Validation / Impact")
	resultTitle:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3])
	Track(content, resultTitle)

	local resultPanel = CreateFrame("Frame", nil, card, "BackdropTemplate")
	resultPanel:SetPoint("TOPLEFT", resultTitle, "BOTTOMLEFT", 0, -6)
	resultPanel:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, 0)
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(resultPanel, style.navDefault or style.panelBg, style.navDefaultBorder or style.panelBorder, true)
	end
	Track(content, resultPanel)

	local resultText = resultPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	resultText:SetPoint("TOPLEFT", resultPanel, "TOPLEFT", 8, -8)
	resultText:SetPoint("TOPRIGHT", resultPanel, "TOPRIGHT", -8, -8)
	resultText:SetJustifyH("LEFT")
	resultText:SetJustifyV("TOP")
	resultText:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
	Track(content, resultText)

	local function UpdateResult()
		resultText:SetText(BuildImportExportReportText(self, state))
		local textHeight = math.max(80, math.floor((resultText:GetStringHeight() or 0) + 16))
		resultPanel:SetHeight(textHeight)
	end

	local function UpdateEditHeight()
		state.codeText = editBox:GetText() or ""
		measure:SetText(state.codeText ~= "" and state.codeText or " ")
		local measured = measure:GetStringHeight() or 0
		local lines = 1
		if state.codeText ~= "" then
			lines = select(2, state.codeText:gsub("\n", "\n")) + 1
		end
		local baseline = lines * 14
		local target = math.max(120, math.min(460, math.floor(math.max(measured + 18, baseline + 18))))
		editBox:SetHeight(target)

		local statusText = ("Code length: %d chars, %d lines"):format(#state.codeText, lines)
		status:SetText(statusText)
		UpdateResult()

		local resultHeight = resultPanel:GetHeight() or 80
		local cardHeight = 34 + target + 8 + 18 + 8 + 26 + 10 + 18 + 6 + resultHeight + 12
		card:SetHeight(cardHeight)
		content:SetHeight(math.max(360, 56 + cardHeight))
	end

	exportButton:SetScript("OnClick", function()
		local encoded, err = self:SerializeProfile()
		if not encoded then
			state.report = nil
			state.preview = nil
			state.message = "Export failed: " .. tostring(err or "unknown error")
			UpdateResult()
			return
		end
		editBox:SetText(encoded)
		editBox:HighlightText(0)
		state.message = "Export complete. Use this string for backup/import."
		state.report = nil
		state.preview = nil
		UpdateEditHeight()
	end)

	local function ParseAndValidate()
		local raw = editBox:GetText() or ""
		if raw == "" then
			state.report = nil
			state.preview = nil
			state.message = "No import string provided."
			UpdateResult()
			return nil, nil
		end
		local data, parseErr = self:DeserializeProfile(raw)
		if not data then
			state.report = nil
			state.preview = nil
			state.message = "Invalid import string: " .. tostring(parseErr or "decode error")
			UpdateResult()
			return nil, nil
		end
		local report, validateErr = self:ValidateImportedProfileData(data)
		if not report then
			state.report = nil
			state.preview = nil
			state.message = "Validation failed: " .. tostring(validateErr or "invalid payload")
			UpdateResult()
			return nil, nil
		end
		local preview = self:BuildImportedProfilePreview(data, report)
		state.report = report
		state.preview = preview
		state.message = report.ok and "Validation passed." or ("Validation failed: " .. tostring(validateErr or "errors found"))
		UpdateResult()
		if report.ok == false then
			return nil, nil
		end
		return data, report
	end

	validateButton:SetScript("OnClick", function()
		ParseAndValidate()
	end)

	importButton:SetScript("OnClick", function()
		local data = ParseAndValidate()
		if not data then
			return
		end
		local ok, applyErr, details = self:ApplyImportedProfile(data)
		if not ok then
			state.message = "Import failed: " .. tostring(applyErr or "unknown error")
			if details and details.report then
				state.report = details.report
			end
			if details and details.preview then
				state.preview = details.preview
			end
			UpdateResult()
			return
		end
		state.message = "Import applied successfully."
		if details and details.report then
			state.report = details.report
		end
		if details and details.preview then
			state.preview = details.preview
		end
		UpdateResult()
	end)

	editBox:SetScript("OnTextChanged", function(_, userInput)
		if userInput then
			UpdateEditHeight()
		end
	end)
	editBox:SetScript("OnEscapePressed", function(selfBox)
		selfBox:ClearFocus()
	end)

	UpdateEditHeight()
	if self.ApplySUFControlSkinsInFrame then
		self:ApplySUFControlSkinsInFrame(content, "subtle")
	end
end

function addon:RenderOptionsV2Page(content, page)
	if not content then
		return
	end
	ReleaseContent(content)

	local style = (self.GetOptionsV2Style and self:GetOptionsV2Style()) or {}
	if page and page.key == "importexport" then
		self:RenderOptionsV2ImportExport(content, page, style)
		return
	end
	local spec = self.GetOptionsV2PageSpec and self:GetOptionsV2PageSpec(page and page.key)
	local sections = (spec and spec.sections) or {}
	local y = -8

	local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
	title:SetText((page and page.label) or "Options")
	title:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3])
	Track(content, title)
	y = y - 28

	local desc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	desc:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
	desc:SetWidth(math.max(320, content:GetWidth() - 20))
	desc:SetJustifyH("LEFT")
	desc:SetJustifyV("TOP")
	desc:SetText((page and page.desc) or "No description available.")
	desc:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
	Track(content, desc)
	y = y - 44
	local activeSectionKey = nil
	y, activeSectionKey = RenderSectionTabs(content, style, spec, y, page and page.key or "global")

	local cardWidth = math.max(420, content:GetWidth() - 20)
	for sectionIndex = 1, #sections do
		local section = sections[sectionIndex]
		local sectionTab = tostring(section.tab or "all")
		if not activeSectionKey or activeSectionKey == "all" or sectionTab == activeSectionKey then
			local controls = section.controls or {}
			local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
			card:SetPoint("TOPLEFT", content, "TOPLEFT", 10, y)
			card:SetSize(cardWidth, 48)
			if self.ApplySUFBackdropColors then
				self:ApplySUFBackdropColors(card, style.panelBg, style.panelBorder, true)
			end
			Track(content, card)

			local sy = -12
			local sectionTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			sectionTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
			sectionTitle:SetText(tostring(section.title or "Section"))
			sectionTitle:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3])
			Track(content, sectionTitle)
			sy = sy - 18

			if section.desc and section.desc ~= "" then
				local sectionDesc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				sectionDesc:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				sectionDesc:SetWidth(cardWidth - 24)
				sectionDesc:SetJustifyH("LEFT")
				sectionDesc:SetJustifyV("TOP")
				sectionDesc:SetText(tostring(section.desc))
				sectionDesc:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
				Track(content, sectionDesc)
				sy = sy - 22
			end

			for controlIndex = 1, #controls do
			local control = controls[controlIndex]
			local controlType = tostring(control.type or "")
			local disabled = SafeCall(control.disabled) == true
			local labelText = tostring(control.label or "Control")

			if controlType == "label" then
				local label = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				label:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				label:SetText(tostring(control.text or labelText))
				label:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3])
				Track(content, label)
				sy = sy - 18
			elseif controlType == "paragraph" then
				local paragraph = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				paragraph:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				paragraph:SetWidth(cardWidth - 24)
				paragraph:SetJustifyH("LEFT")
				paragraph:SetJustifyV("TOP")
				local paragraphText = control.getText and SafeCall(control.getText) or control.text or ""
				paragraph:SetText(tostring(paragraphText))
				paragraph:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
				Track(content, paragraph)
				local h = math.max(18, math.floor((paragraph:GetStringHeight() or 14) + 4))
				sy = sy - h
			elseif controlType == "edit" then
				local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				label:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				label:SetText(labelText)
				Track(content, label)
				sy = sy - 16

				local edit = CreateFrame("EditBox", nil, card, "InputBoxTemplate")
				edit:SetAutoFocus(false)
				local initialText = SafeCall(control.get)
				initialText = initialText ~= nil and tostring(initialText) or ""
				local editWidth = math.min(360, cardWidth - 24)
				if control.width then
					editWidth = math.max(90, math.min(cardWidth - 24, math.floor(tonumber(control.width) or editWidth)))
				else
					local chars = ResolveWidthChars(control, initialText)
					if chars then
					editWidth = math.max(90, math.min(cardWidth - 24, (chars * 7) + 26))
					end
				end
				edit:SetSize(editWidth, 22)
				edit:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				edit:SetEnabled(not disabled)
				if addon.ApplySUFBackdropColors then
					addon:ApplySUFBackdropColors(edit, style.navDefault or style.panelBg, style.navDefaultBorder or style.panelBorder, true)
				end
				if edit.SetTextColor then
					edit:SetTextColor((style.accent or { 1, 1, 1 })[1], (style.accent or { 1, 1, 1 })[2], (style.accent or { 1, 1, 1 })[3], 1)
				end
				edit:SetText(initialText)
				edit:SetScript("OnEnterPressed", function(selfBox)
					if disabled then
						return
					end
					SafeCall(control.set, selfBox:GetText() or "")
					selfBox:ClearFocus()
				end)
				edit:SetScript("OnEditFocusLost", function(selfBox)
					if disabled then
						return
					end
					SafeCall(control.set, selfBox:GetText() or "")
				end)
				Track(content, edit)
				sy = sy - 30
			elseif controlType == "check" then
				local check = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
				check:SetPoint("TOPLEFT", card, "TOPLEFT", 8, sy)
				check.text = check.text or _G[check:GetName() and (check:GetName() .. "Text") or ""]
				if check.text then
					check.text:SetText(labelText)
					check.text:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
				else
					local fallback = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
					fallback:SetPoint("LEFT", check, "RIGHT", 2, 0)
					fallback:SetText(labelText)
					Track(content, fallback)
				end
				local current = SafeCall(control.get)
				check:SetChecked(current and true or false)
				check:SetEnabled(not disabled)
				check:SetScript("OnClick", function(selfButton)
					if disabled then
						return
					end
					SafeCall(control.set, selfButton:GetChecked() and true or false)
				end)
				Track(content, check)
				sy = sy - 24
			elseif controlType == "slider" then
				local minV = tonumber(control.min) or 0
				local maxV = tonumber(control.max) or 1
				local step = tonumber(control.step) or 0.1
				local fmt = tostring(control.format or "%.2f")

				local rowLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				rowLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				rowLabel:SetText(labelText)
				Track(content, rowLabel)

				local valueText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				valueText:SetPoint("LEFT", rowLabel, "RIGHT", 8, 0)
				Track(content, valueText)
				sy = sy - 18

				local slider = CreateFrame("Slider", nil, card, "OptionsSliderTemplate")
				slider:SetPoint("TOPLEFT", card, "TOPLEFT", 14, sy)
				slider:SetWidth(cardWidth - 40)
				slider:SetMinMaxValues(minV, maxV)
				slider:SetValueStep(step)
				if slider.SetObeyStepOnDrag then
					slider:SetObeyStepOnDrag(true)
				end
				local initial = Clamp(SafeCall(control.get) or minV, minV, maxV)
				slider:SetValue(initial)
				valueText:SetText(string.format(fmt, initial))
				slider:SetEnabled(not disabled)
				slider:SetScript("OnValueChanged", function(selfSlider, newValue)
					local normalized = Clamp(newValue, minV, maxV)
					valueText:SetText(string.format(fmt, normalized))
					if selfSlider._sufSync then
						return
					end
					if disabled then
						return
					end
					SafeCall(control.set, normalized)
				end)
				Track(content, slider)
				sy = sy - 38
			elseif controlType == "color" then
				local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				label:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				label:SetText(labelText)
				Track(content, label)

				local swatch = CreateFrame("Button", nil, card, "BackdropTemplate")
				swatch:SetPoint("LEFT", label, "RIGHT", 10, 0)
				swatch:SetSize(20, 14)
				swatch:SetBackdrop({
					bgFile = "Interface\\Buttons\\WHITE8x8",
					edgeFile = "Interface\\Buttons\\WHITE8x8",
					edgeSize = 1,
				})
				local function RefreshSwatch()
					local color = SafeCall(control.get)
					local cr = tonumber(color and color[1]) or 1
					local cg = tonumber(color and color[2]) or 1
					local cb = tonumber(color and color[3]) or 1
					swatch:SetBackdropColor(cr, cg, cb, 1)
					swatch:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
				end
				RefreshSwatch()
				swatch:SetEnabled(not disabled)
				swatch:SetScript("OnClick", function()
					if disabled then
						return
					end
					local color = SafeCall(control.get)
					local cr = tonumber(color and color[1]) or 1
					local cg = tonumber(color and color[2]) or 1
					local cb = tonumber(color and color[3]) or 1
					local opened = OpenColorPicker(cr, cg, cb, function(nr, ng, nb)
						SafeCall(control.set, nr, ng, nb)
						RefreshSwatch()
					end)
					if not opened then
						-- Fallback: nudge color if picker is unavailable.
						local nr = math.max(0, math.min(1, cr + 0.1))
						if nr >= 1 then nr = 0 end
						SafeCall(control.set, nr, cg, cb)
						RefreshSwatch()
					end
				end)
				Track(content, swatch)
				sy = sy - 22
			elseif controlType == "button" then
				local button = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
				button:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				button:SetSize(math.min(260, cardWidth - 24), 24)
				button:SetText(labelText)
				button:SetEnabled(not disabled)
				if addon.ApplySUFButtonSkin then
					addon:ApplySUFButtonSkin(button, "subtle")
				else
					if addon.ApplySUFBackdropColors then
						addon:ApplySUFBackdropColors(button, style.navDefault or style.panelBg, style.navDefaultBorder or style.panelBorder, true)
					end
					TintButtonTextures(button, style.accentSoft or style.accent)
				end
				button:SetScript("OnClick", function()
					if disabled then
						return
					end
					SafeCall(control.onClick)
				end)
				Track(content, button)
				sy = sy - 30
			elseif controlType == "dropdown" then
				local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				label:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				label:SetText(labelText)
				Track(content, label)
				-- Leave enough room so dropdown art never intersects label text.
				sy = sy - 20

				local canUseDropdown = type(UIDropDownMenu_Initialize) == "function"
					and type(UIDropDownMenu_CreateInfo) == "function"
					and type(UIDropDownMenu_AddButton) == "function"
					and type(UIDropDownMenu_SetText) == "function"
				if canUseDropdown then
					local dropdown = CreateFrame("Frame", nil, card, "UIDropDownMenuTemplate")
					-- UIDropDownMenuTemplate has built-in top padding; anchor lower to avoid label overlap.
					dropdown:SetPoint("TOPLEFT", card, "TOPLEFT", -2, sy + 2)
					Track(content, dropdown)

					local function GetOptions()
						local options = SafeCall(control.options)
						if type(options) ~= "table" then
							options = {}
						end
						return options
					end
					local function CurrentValue()
						return tostring(SafeCall(control.get) or "")
					end
					local function CurrentText()
						local current = CurrentValue()
						local options = GetOptions()
						for i = 1, #options do
							local opt = options[i]
							if tostring(opt.value) == current then
								return tostring(opt.text or opt.value)
							end
						end
						return current ~= "" and current or "(none)"
					end
					local function FindSelectedOption()
						local current = CurrentValue()
						local options = GetOptions()
						for i = 1, #options do
							local opt = options[i]
							if tostring(opt.value) == current then
								return opt
							end
						end
						return nil
					end
					local function RefreshDropdown()
						if UIDropDownMenu_SetWidth then
							UIDropDownMenu_SetWidth(dropdown, math.min(320, math.max(180, cardWidth - 36)))
						end
						if UIDropDownMenu_JustifyText then
							UIDropDownMenu_JustifyText(dropdown, "LEFT")
						end
						UIDropDownMenu_SetText(dropdown, CurrentText())
						local selected = FindSelectedOption()
						ApplyDropdownFontPreview(dropdown, selected, style)
						local regions = { dropdown:GetRegions() }
						for ri = 1, #regions do
							local region = regions[ri]
							if region and region.GetObjectType and region:GetObjectType() == "Texture" then
								local rname = string.lower(tostring(region.GetName and region:GetName() or ""))
								if rname:find("middle", 1, true) then
									TintTexture(region, style.navDefault or style.panelBg)
								else
									TintTexture(region, style.navDefaultBorder or style.panelBorder)
								end
							end
						end
						local children = { dropdown:GetChildren() }
						for ci = 1, #children do
							local child = children[ci]
							if child and child.GetObjectType and child:GetObjectType() == "Button" then
								TintButtonTextures(child, style.accentSoft or style.accent)
							end
						end
						if UIDropDownMenu_DisableDropDown and UIDropDownMenu_EnableDropDown then
							if disabled then
								UIDropDownMenu_DisableDropDown(dropdown)
							else
								UIDropDownMenu_EnableDropDown(dropdown)
							end
						end
					end

					UIDropDownMenu_Initialize(dropdown, function(_, level)
						if level ~= 1 then
							return
						end
						local current = CurrentValue()
						local options = GetOptions()
						local listFrame = _G["DropDownList" .. tostring(level)]
						for i = 1, #options do
							local opt = options[i]
							local info = UIDropDownMenu_CreateInfo()
							info.text = tostring(opt.text or opt.value)
							info.value = opt.value
							info.checked = tostring(opt.value) == current
							info.disabled = disabled
							info.func = function()
								if disabled then
									return
								end
								SafeCall(control.set, opt.value)
								RefreshDropdown()
							end
							if type(opt.previewTexture) == "string" and opt.previewTexture ~= "" then
								info.icon = opt.previewTexture
								info.tCoordLeft = 0
								info.tCoordRight = 1
								info.tCoordTop = 0
								info.tCoordBottom = 1
								info.iconInfo = info.iconInfo or {}
								info.iconInfo.tCoordLeft = 0
								info.iconInfo.tCoordRight = 1
								info.iconInfo.tCoordTop = 0
								info.iconInfo.tCoordBottom = 1
							end
							UIDropDownMenu_AddButton(info, level)
							if type(opt.previewFont) == "string" and opt.previewFont ~= "" and listFrame then
								local buttonIndex = tonumber(listFrame.numButtons) or 0
								if buttonIndex > 0 then
									local button = _G[listFrame:GetName() .. "Button" .. tostring(buttonIndex)]
									if button then
										local textRegion = button.NormalText or (button.GetFontString and button:GetFontString()) or _G[button:GetName() .. "NormalText"]
										if textRegion and textRegion.SetFont then
											local _, size, flags = textRegion:GetFont()
											textRegion:SetFont(opt.previewFont, tonumber(size) or 12, flags)
										end
									end
								end
							end
						end
					end)

					RefreshDropdown()
					-- Reserve enough vertical space so dropdown never overlays help/next controls.
					sy = sy - 46
				else
					local unavailable = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
					unavailable:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
					unavailable:SetText("Dropdown unavailable in this UI environment.")
					Track(content, unavailable)
					sy = sy - 18
				end
			elseif controlType == "select_cycle" then
				local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				label:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				label:SetText(labelText)
				Track(content, label)

				local currentText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				currentText:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy - 14)
				currentText:SetTextColor((style.textMuted or { 0.8, 0.8, 0.8 })[1], (style.textMuted or { 0.8, 0.8, 0.8 })[2], (style.textMuted or { 0.8, 0.8, 0.8 })[3])
				Track(content, currentText)

				local cycle = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
				cycle:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, sy + 2)
				cycle:SetSize(120, 22)
				cycle:SetText("Next")
				cycle:SetEnabled(not disabled)
				if addon.ApplySUFButtonSkin then
					addon:ApplySUFButtonSkin(cycle, "subtle")
				end
				cycle:SetScript("OnClick", function()
					if disabled then
						return
					end
					local options = SafeCall(control.options) or {}
					if #options == 0 then
						return
					end
					local current = tostring(SafeCall(control.get) or "")
					local idx = 1
					for i = 1, #options do
						if tostring(options[i].value) == current then
							idx = i + 1
							break
						end
					end
					if idx > #options then
						idx = 1
					end
					local selected = options[idx]
					if selected and selected.value ~= nil then
						SafeCall(control.set, selected.value)
						currentText:SetText("Current: " .. tostring(selected.text or selected.value))
					end
				end)
				Track(content, cycle)

				local initialValue = tostring(SafeCall(control.get) or "")
				currentText:SetText("Current: " .. initialValue)
				sy = sy - 40
			end

			if control.help and control.help ~= "" then
				local help = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
				help:SetPoint("TOPLEFT", card, "TOPLEFT", 12, sy)
				help:SetWidth(cardWidth - 24)
				help:SetJustifyH("LEFT")
				help:SetJustifyV("TOP")
				help:SetText(tostring(control.help))
				Track(content, help)
				sy = sy - 18
			end
			end

			local cardHeight = math.max(58, -sy + 10)
			card:SetHeight(cardHeight)
			y = y - cardHeight - 10
		end
	end

	content:SetHeight(math.max(360, -y + 12))
	if self.ApplySUFControlSkinsInFrame then
		self:ApplySUFControlSkinsInFrame(content, "subtle")
	end
end
