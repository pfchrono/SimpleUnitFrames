local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local core = addon._core or {}
local BANNER_PATH = "Interface\\AddOns\\SimpleUnitFrames\\Media\\SUFBanner"
local ICON_PATH = core.ICON_PATH or "Interface\\Icons\\INV_Misc_QuestionMark"
local ADDON_ID = "SimpleUnitFrames"

local function BuildPageIndex(pages)
	local index = {}
	for i = 1, #pages do
		local page = pages[i]
		index[page.key] = page
	end
	return index
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

local function TintRegionList(owner, color, nameMatch)
	if not (owner and owner.GetRegions and color) then
		return
	end
	local regions = { owner:GetRegions() }
	for i = 1, #regions do
		local region = regions[i]
		if region and region.GetObjectType and region:GetObjectType() == "Texture" then
			local apply = true
			if nameMatch then
				local name = string.lower(tostring(region.GetName and region:GetName() or ""))
				apply = false
				for j = 1, #nameMatch do
					if name:find(nameMatch[j], 1, true) then
						apply = true
						break
					end
				end
			end
			if apply then
				TintTexture(region, color)
			end
		end
	end
end

local function GetAddonVersionText()
	local version = nil
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		version = C_AddOns.GetAddOnMetadata(ADDON_ID, "Version")
	elseif GetAddOnMetadata then
		version = GetAddOnMetadata(ADDON_ID, "Version")
	end
	version = tostring(version or ""):match("^%s*(.-)%s*$")
	if version == "" then
		return "v?"
	end
	return "v" .. version
end

function addon:CreateOptionsV2Window()
	if self.optionsV2Frame then
		return self.optionsV2Frame
	end

	local style = self:GetOptionsV2Style()
	local frame = CreateFrame("Frame", "SUFOptionsWindowV2", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(1200, 680)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(980, 560, UIParent:GetWidth() - 40, UIParent:GetHeight() - 40)
	else
		frame:SetMinResize(980, 560)
	end
	if self.EnableMovableFrame then
		self:EnableMovableFrame(frame, true, "options_window_v2", { "CENTER", "UIParent", "CENTER", 0, 0 })
	end
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(frame, style.windowBg, style.windowBorder, true)
	end
	frame.TitleText:SetText("SimpleUnitFrames Option")
	frame.TitleText:SetTextColor(style.accent[1], style.accent[2], style.accent[3])

	local close = frame.CloseButton
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local resizeGrip = CreateFrame("Button", nil, frame)
	resizeGrip:SetSize(18, 18)
	resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeGrip:SetScript("OnMouseDown", function()
		frame:StartSizing("BOTTOMRIGHT")
	end)
	resizeGrip:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)
	frame._resizeGrip = resizeGrip

	local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	header:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
	header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -30)
	header:SetHeight(96)
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(header, style.panelBg, style.panelBorder, true)
	end

	local banner = header:CreateTexture(nil, "ARTWORK")
	banner:SetPoint("LEFT", header, "LEFT", 12, 0)
	banner:SetSize(96, 96)
	banner:SetTexture(BANNER_PATH)
	if not banner:GetTexture() then
		banner:SetTexture(ICON_PATH)
	end
	banner:SetTexCoord(0, 1, 0, 1)

	local versionText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	versionText:SetPoint("TOPLEFT", banner, "TOPRIGHT", 10, -8)
	versionText:SetJustifyH("LEFT")
	versionText:SetText(GetAddonVersionText())
	versionText:SetTextColor(style.accent[1], style.accent[2], style.accent[3], 1)

	local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	subtitle:SetPoint("TOPLEFT", versionText, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", header, "RIGHT", -312, 0)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetText("Use search to jump directly to pages and settings.")
	subtitle:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])

	local utilityRow = CreateFrame("Frame", nil, header)
	utilityRow:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -6)
	utilityRow:SetPoint("RIGHT", header, "RIGHT", -312, 0)
	utilityRow:SetHeight(22)

	local reloadButton = CreateFrame("Button", nil, utilityRow, "UIPanelButtonTemplate")
	reloadButton:SetPoint("LEFT", utilityRow, "LEFT", 0, 0)
	reloadButton:SetSize(76, 22)
	reloadButton:SetText("ReloadUI")
	reloadButton:SetScript("OnClick", function()
		if addon.PromptReloadUI then
			addon:PromptReloadUI("Reload UI now?")
		elseif ReloadUI then
			ReloadUI()
		end
	end)

	local debugButton = CreateFrame("Button", nil, utilityRow, "UIPanelButtonTemplate")
	debugButton:SetPoint("LEFT", reloadButton, "RIGHT", 4, 0)
	debugButton:SetSize(54, 22)
	debugButton:SetText("Debug")
	debugButton:SetScript("OnClick", function()
		if addon.ToggleDebugPanel then
			addon:ToggleDebugPanel()
		elseif addon.ShowDebugPanel then
			addon:ShowDebugPanel()
		end
	end)

	local perfButton = CreateFrame("Button", nil, utilityRow, "UIPanelButtonTemplate")
	perfButton:SetPoint("LEFT", debugButton, "RIGHT", 4, 0)
	perfButton:SetSize(44, 22)
	perfButton:SetText("Perf")
	perfButton:SetScript("OnClick", function()
		if addon.TogglePerformanceDashboard then
			addon:TogglePerformanceDashboard()
		end
	end)

	local searchLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	searchLabel:SetPoint("TOPRIGHT", header, "TOPRIGHT", -12, -12)
	searchLabel:SetText("Search")
	searchLabel:SetTextColor(style.accent[1], style.accent[2], style.accent[3])

	local searchBox = CreateFrame("EditBox", nil, header, "InputBoxTemplate")
	searchBox:SetPoint("TOPRIGHT", header, "TOPRIGHT", -12, -30)
	searchBox:SetSize(280, 20)
	searchBox:SetAutoFocus(false)
	searchBox:SetTextInsets(6, 6, 0, 0)

	local searchBoxChrome = CreateFrame("Frame", nil, header, "BackdropTemplate")
	searchBoxChrome:SetPoint("TOPLEFT", searchBox, "TOPLEFT", -2, 2)
	searchBoxChrome:SetPoint("BOTTOMRIGHT", searchBox, "BOTTOMRIGHT", 2, -2)

	local searchStatus = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	searchStatus:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", -2, -4)
	searchStatus:SetText("")
	searchStatus:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])

	local navHost = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	navHost:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
	navHost:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
	navHost:SetWidth(280)
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(navHost, style.panelBg, style.panelBorder, true)
	end

	local contentHost = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	contentHost:SetPoint("TOPLEFT", navHost, "TOPRIGHT", 8, 0)
	contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(contentHost, style.panelBg, style.panelBorder, true)
	end

	local navScroll = CreateFrame("ScrollFrame", nil, navHost, "UIPanelScrollFrameTemplate")
	navScroll:SetPoint("TOPLEFT", navHost, "TOPLEFT", 8, -8)
	navScroll:SetPoint("BOTTOMRIGHT", navHost, "BOTTOMRIGHT", -28, 8)
	navScroll:EnableMouseWheel(true)
	local navContent = CreateFrame("Frame", nil, navScroll)
	navContent:SetSize(1, 1)
	navScroll:SetScrollChild(navContent)

	local pageScroll = CreateFrame("ScrollFrame", nil, contentHost, "UIPanelScrollFrameTemplate")
	pageScroll:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 8, -8)
	pageScroll:SetPoint("BOTTOMRIGHT", contentHost, "BOTTOMRIGHT", -28, 8)
	pageScroll:EnableMouseWheel(true)
	local pageContent = CreateFrame("Frame", nil, pageScroll)
	pageContent:SetSize(860, 320)
	pageScroll:SetScrollChild(pageContent)

	local function ApplyScrollBarStyle(scroll)
		if not scroll then
			return
		end
		local bar = scroll.ScrollBar
		if not bar then
			return
		end
		if addon.ApplySUFBackdropColors then
			addon:ApplySUFBackdropColors(bar, style.navDefault, style.navDefaultBorder, true)
		end
		local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
		TintTexture(thumb, style.accentSoft or style.accent)
		local up = bar.ScrollUpButton or (bar.GetName and _G[(bar:GetName() or "") .. "ScrollUpButton"]) or nil
		local down = bar.ScrollDownButton or (bar.GetName and _G[(bar:GetName() or "") .. "ScrollDownButton"]) or nil
		TintButtonTextures(up, style.accentSoft or style.accent)
		TintButtonTextures(down, style.accentSoft or style.accent)
	end

	local function ApplyTemplateChrome()
		if frame.NineSlice then
			local edgeColor = style.windowBorder or style.accent
			TintTexture(frame.NineSlice.TopEdge, edgeColor)
			TintTexture(frame.NineSlice.BottomEdge, edgeColor)
			TintTexture(frame.NineSlice.LeftEdge, edgeColor)
			TintTexture(frame.NineSlice.RightEdge, edgeColor)
			TintTexture(frame.NineSlice.TopLeftCorner, edgeColor)
			TintTexture(frame.NineSlice.TopRightCorner, edgeColor)
			TintTexture(frame.NineSlice.BottomLeftCorner, edgeColor)
			TintTexture(frame.NineSlice.BottomRightCorner, edgeColor)
			TintTexture(frame.NineSlice.TitleBg, edgeColor)
			TintTexture(frame.NineSlice.TitleBG, edgeColor)
		end
		if frame.Inset then
			TintTexture(frame.Inset.Bg, style.panelBg or style.windowBg)
			TintTexture(frame.Inset.BgBorder, style.panelBorder or style.windowBorder)
		end
		TintTexture(frame.TitleBg, style.windowBorder or style.accentSoft or style.accent)
		TintTexture(frame.TitleBG, style.windowBorder or style.accentSoft or style.accent)
		TintTexture(frame.TopTileStreaks, style.windowBorder or style.accentSoft or style.accent)
		TintRegionList(frame, style.windowBorder or style.accentSoft or style.accent, { "title", "streak", "header" })
		if frame.TitleContainer then
			TintRegionList(frame.TitleContainer, style.windowBorder or style.accentSoft or style.accent)
		end
		TintButtonTextures(frame.CloseButton, style.accentSoft or style.accent)
		TintButtonTextures(resizeGrip, style.accentSoft or style.accent)
		if addon.ApplySUFBackdropColors then
			addon:ApplySUFBackdropColors(searchBoxChrome, style.navDefault, style.navDefaultBorder, true)
		end
		if searchBox.SetTextColor then
			searchBox:SetTextColor(style.accent[1], style.accent[2], style.accent[3], 1)
		end
		ApplyScrollBarStyle(navScroll)
		ApplyScrollBarStyle(pageScroll)
	end

	local function HookMouseWheel(scroll)
		scroll:SetScript("OnMouseWheel", function(selfFrame, delta)
			local step = 24
			local current = selfFrame:GetVerticalScroll() or 0
			local nextValue = math.max(0, current - (delta * step))
			selfFrame:SetVerticalScroll(nextValue)
			if selfFrame.ScrollBar then
				selfFrame.ScrollBar:SetValue(nextValue)
			end
		end)
	end
	HookMouseWheel(navScroll)
	HookMouseWheel(pageScroll)
	ApplyTemplateChrome()

	local pages = self:GetOptionsV2Pages()
	local groups = self:GetOptionsV2Groups()
	local pageByKey = BuildPageIndex(pages)
	local navButtons = {}
	local cfgState = addon:EnsureOptionsV2Config()
	cfgState.navState = cfgState.navState or {}
	if cfgState.navStateInitialized ~= true then
		for i = 1, #groups do
			local g = groups[i]
			cfgState.navState[g] = (g == "General")
		end
		cfgState.navStateInitialized = true
	end

	local function StopAutoRefresh()
		if frame._sufV2AutoRefreshTicker and frame._sufV2AutoRefreshTicker.Cancel then
			frame._sufV2AutoRefreshTicker:Cancel()
		end
		frame._sufV2AutoRefreshTicker = nil
	end

	local function UpdateAutoRefresh()
		StopAutoRefresh()
		local cfg = addon.db and addon.db.profile and addon.db.profile.performance
		if frame.currentPage ~= "performance" then
			return
		end
		if cfg and cfg.optionsAutoRefresh == false then
			return
		end
		frame._sufV2AutoRefreshTicker = C_Timer.NewTicker(1.0, function()
			if not frame:IsShown() or frame.currentPage ~= "performance" then
				StopAutoRefresh()
				return
			end
			frame:SetPage("performance")
		end)
	end

	local function SetButtonState(button, selected)
		if not button then
			return
		end
		if not button._pageKey then
			return
		end
		if self.ApplySUFBackdropColors then
			if selected then
				self:ApplySUFBackdropColors(button, style.navSelected, style.navSelectedBorder, false)
				if button._text then
					button._text:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
				end
			else
				self:ApplySUFBackdropColors(button, style.navDefault, style.navDefaultBorder, false)
				if button._text then
					button._text:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
				end
			end
		end
	end

	local function RefreshSelection()
		for i = 1, #navButtons do
			local button = navButtons[i]
			if button and button._pageKey then
				SetButtonState(button, frame.currentPage == button._pageKey)
			end
		end
	end

	local function RunSearch(delta)
		local raw = searchBox:GetText() or ""
		local query = raw:match("^%s*(.-)%s*$")
		if query == "" then
			frame._searchQuery = nil
			frame._searchResults = nil
			frame._searchIndex = nil
			searchStatus:SetText("")
			return
		end
		local sameQuery = (frame._searchQuery == query and type(frame._searchResults) == "table" and #frame._searchResults > 0)
		if not sameQuery then
			frame._searchQuery = query
			frame._searchResults = addon:SearchOptionsV2(query) or {}
			frame._searchIndex = 1
		elseif delta and delta ~= 0 then
			local count = #frame._searchResults
			frame._searchIndex = ((frame._searchIndex - 1 + delta) % count) + 1
		end

		local results = frame._searchResults or {}
		if #results == 0 then
			searchStatus:SetText("No matches")
			return
		end

		local idx = frame._searchIndex or 1
		local match = results[idx]
		local target = match and pageByKey[match.pageKey]
		if target then
			if match.sectionKey and addon.GetOptionsV2PageSpec then
				addon._optionsV2SearchFlash = addon._optionsV2SearchFlash or {}
				addon._optionsV2SearchFlash[target.key] = tostring(match.sectionKey)
				local spec = addon:GetOptionsV2PageSpec(target.key)
				if spec and type(spec.setActiveSection) == "function" then
					spec.setActiveSection(match.sectionKey)
				end
			end
			frame:SetPage(target.key)
			local label = match.label or target.label or target.key
			searchStatus:SetText(("%d/%d: %s"):format(idx, #results, tostring(label)))
		else
			searchStatus:SetText(("%d/%d"):format(idx, #results))
		end
	end

	function frame:SetPage(pageKey)
		local page = pageByKey[pageKey] or pages[1]
		if not page then
			return
		end
		style = addon:GetOptionsV2Style()
		if addon.ApplySUFBackdropColors then
			addon:ApplySUFBackdropColors(frame, style.windowBg, style.windowBorder, true)
			addon:ApplySUFBackdropColors(header, style.panelBg, style.panelBorder, true)
			addon:ApplySUFBackdropColors(navHost, style.panelBg, style.panelBorder, true)
			addon:ApplySUFBackdropColors(contentHost, style.panelBg, style.panelBorder, true)
		end
		ApplyTemplateChrome()
		frame.TitleText:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
		versionText:SetText(GetAddonVersionText())
		versionText:SetTextColor(style.accent[1], style.accent[2], style.accent[3], 1)
		subtitle:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
		searchLabel:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
		searchStatus:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
		if addon.ApplySUFButtonSkin then
			addon:ApplySUFButtonSkin(reloadButton, "subtle")
			addon:ApplySUFButtonSkin(debugButton, "subtle")
			addon:ApplySUFButtonSkin(perfButton, "subtle")
		end
		frame.currentPage = page.key
		local cfg = addon:EnsureOptionsV2Config()
		cfg.lastPage = page.key
		addon:RenderOptionsV2Page(pageContent, page)
		RefreshSelection()
		UpdateAutoRefresh()
	end

	function frame:RefreshCurrentPage()
		local key = frame.currentPage or ((pages[1] and pages[1].key) or "global")
		local page = pageByKey[key] or pages[1]
		if not page then
			return
		end
		addon:RenderOptionsV2Page(pageContent, page)
		RefreshSelection()
	end

	local function RebuildNav()
		for i = 1, #navButtons do
			local btn = navButtons[i]
			btn:Hide()
			btn:SetParent(nil)
		end
		wipe(navButtons)

		local y = -4
		local width = math.max(180, math.floor(navScroll:GetWidth() - 10))
		navContent:SetWidth(width)
		for g = 1, #groups do
			local group = groups[g]
			local expanded = cfgState.navState[group]
			if expanded == nil then
				expanded = (group == "General")
				cfgState.navState[group] = expanded
			end

			local groupBtn = CreateFrame("Button", nil, navContent, "BackdropTemplate")
			groupBtn:SetPoint("TOPLEFT", navContent, "TOPLEFT", 0, y)
			groupBtn:SetSize(width, 22)
			groupBtn:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8",
				edgeSize = 1,
			})
			if self.ApplySUFBackdropColors then
				self:ApplySUFBackdropColors(groupBtn, style.navDefault, style.navDefaultBorder, false)
			end
			local gfs = groupBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			gfs:SetPoint("LEFT", groupBtn, "LEFT", 6, 0)
			gfs:SetText((expanded and "[-] " or "[+] ") .. tostring(group))
			gfs:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
			groupBtn:SetScript("OnClick", function()
				cfgState.navState[group] = not (cfgState.navState[group] == true)
				RebuildNav()
			end)
			navButtons[#navButtons + 1] = groupBtn
			y = y - 24

			if expanded then
				for i = 1, #pages do
					local page = pages[i]
					if page.group == group then
						local btn = CreateFrame("Button", nil, navContent, "BackdropTemplate")
						btn:SetPoint("TOPLEFT", navContent, "TOPLEFT", 8, y)
						btn:SetSize(width - 8, 22)
						btn:SetBackdrop({
							bgFile = "Interface\\Buttons\\WHITE8x8",
							edgeFile = "Interface\\Buttons\\WHITE8x8",
							edgeSize = 1,
						})
						if self.ApplySUFBackdropColors then
							self:ApplySUFBackdropColors(btn, style.navDefault, style.navDefaultBorder, false)
						end

						local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
						fs:SetPoint("LEFT", btn, "LEFT", 8, 0)
						fs:SetText(page.label)
						btn._text = fs
						btn._pageKey = page.key
						btn:SetScript("OnClick", function()
							frame:SetPage(page.key)
						end)
						btn:SetScript("OnEnter", function(selfButton)
							if frame.currentPage ~= selfButton._pageKey and addon.ApplySUFBackdropColors then
								addon:ApplySUFBackdropColors(selfButton, style.navHover, style.navHoverBorder, false)
							end
						end)
						btn:SetScript("OnLeave", function(selfButton)
							SetButtonState(selfButton, frame.currentPage == selfButton._pageKey)
						end)

						navButtons[#navButtons + 1] = btn
						y = y - 24
					end
				end
			end
			y = y - 6
		end
		navContent:SetHeight(math.max(1, -y + 8))
		RefreshSelection()
	end
	frame.RebuildNav = RebuildNav

	frame:SetScript("OnSizeChanged", function()
		RebuildNav()
		local width = math.max(780, math.floor(pageScroll:GetWidth() - 8))
		pageContent:SetWidth(width)
		if frame.currentPage then
			frame:SetPage(frame.currentPage)
		end
	end)
	frame:HookScript("OnHide", function()
		StopAutoRefresh()
	end)

	searchBox:SetScript("OnTextChanged", function(selfBox, userInput)
		if userInput then
			frame._searchQuery = nil
			frame._searchResults = nil
			frame._searchIndex = nil
			if selfBox:GetText() == "" then
				searchStatus:SetText("")
			end
		end
	end)
	searchBox:SetScript("OnEnterPressed", function()
		RunSearch(1)
	end)
	searchBox:SetScript("OnEscapePressed", function(selfBox)
		selfBox:ClearFocus()
		selfBox:SetText("")
		searchStatus:SetText("")
		frame._searchQuery = nil
		frame._searchResults = nil
		frame._searchIndex = nil
	end)
	searchBox:SetScript("OnKeyDown", function(selfBox, key)
		if key == "UP" then
			RunSearch(-1)
			return
		end
		if key == "DOWN" then
			RunSearch(1)
			return
		end
		if key == "TAB" then
			selfBox:ClearFocus()
			return
		end
	end)

	RebuildNav()
	self.optionsV2Frame = frame
	return frame
end
