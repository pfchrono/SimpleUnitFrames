local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local OptionsV2 = addon.OptionsV2 or {}
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
		if addon.SafeReload then
			addon:SafeReload()
		elseif addon.PromptReloadUI then
			addon:PromptReloadUI("Reload UI now?")
		else
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

	local navHost = OptionsV2:CreateSidebar(frame)
	navHost:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
	navHost:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)

	local contentHost = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	contentHost:SetPoint("TOPLEFT", navHost, "TOPRIGHT", 8, 0)
	contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
	if self.ApplySUFBackdropColors then
		self:ApplySUFBackdropColors(contentHost, style.panelBg, style.panelBorder, true)
	end

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
		ApplyScrollBarStyle(pageScroll)
		-- Apply sidebar style via Sidebar component's internal scroll bar
		if navHost and navHost.scroll then
			ApplyScrollBarStyle(navHost.scroll)
		end
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
	HookMouseWheel(pageScroll)
	-- Hook sidebar scroll via component reference
	if navHost and navHost.scroll then
		HookMouseWheel(navHost.scroll)
	end
	ApplyTemplateChrome()

	local pages = self:GetOptionsV2Pages()
	local groups = self:GetOptionsV2Groups()
	local pageByKey = BuildPageIndex(pages)
	local cfgState = addon:EnsureOptionsV2Config()

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
				self:ApplySUFBackdropColors(button, style.navSelected, style.navSelectedBorder, true)
				local textFrame = button._text or button.text
				if textFrame then
					textFrame:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
				end
			else
				self:ApplySUFBackdropColors(button, style.navDefault, style.navDefaultBorder, true)
				local textFrame = button._text or button.text
				if textFrame then
					textFrame:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
				end
			end
		end
	end

	local function RefreshSelection()
		-- Find which page button corresponds to the current page and highlight it
		-- Also highlight the active unit subtab if applicable
		local activeUnitSubtab = (cfgState.navState and cfgState.navState.activeUnitSubtab) or {}

		if navHost and navHost.tabButtons then
			navHost._currentTabButton = nil
			for buttonIdx = 1, #navHost.tabButtons do
				local button = navHost.tabButtons[buttonIdx]
				if button then
					local isActive = false
					local isSubtab = button._isSubtab
					
					if button._pageKey then
						-- This is a page button or subtab
						if isSubtab then
							-- Subtab: active if parent page matches current page AND section matches active section for that page
							if button._pageKey == frame.currentPage then
								local activeSectionForPage = activeUnitSubtab[button._pageKey] or "general"
								if button._sectionKey == activeSectionForPage then
									isActive = true
								end
							end
						else
							-- Page button: active if it matches current page
							if button._pageKey == frame.currentPage then
								isActive = true
							end
						end
					end

					button._isSelected = isActive and true or false
					if isActive and not navHost._currentTabButton then
						navHost._currentTabButton = button
					end
					
					if isActive then
						if self.ApplySUFBackdropColors then
							self:ApplySUFBackdropColors(button, style.navSelected, style.navSelectedBorder, true)
							local textFrame = button._text or button.text
							if textFrame then
								textFrame:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
							end
						end
					else
						if self.ApplySUFBackdropColors then
							self:ApplySUFBackdropColors(button, style.navDefault, style.navDefaultBorder, true)
							local textFrame = button._text or button.text
							if textFrame then
								textFrame:SetTextColor(style.textMuted[1], style.textMuted[2], style.textMuted[3])
							end
						end
					end
				end
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
			if C_Timer and C_Timer.After then
				C_Timer.After(0.1, function()
					local currentStyle = addon:GetOptionsV2Style() or {}
					-- Silent: Check if section frames are available
					if match.sectionKey and addon._optionsV2SectionFrames and addon._optionsV2SectionFrames[match.pageKey] then
						local sectionFrame = addon._optionsV2SectionFrames[match.pageKey][match.sectionKey]
						if pageScroll and sectionFrame then
							-- Get the section's top position relative to the scroll child (pageContent)
							local pageContent = pageScroll:GetScrollChild()
							if pageContent and sectionFrame:GetParent() == pageContent then
								-- Get section's relative position to its parent (pageContent)
								local numPoints = sectionFrame:GetNumPoints()
								local targetScroll = 0
								for i = 1, numPoints do
									local point, relativeTo, relativePoint, xOfs, yOfs = sectionFrame:GetPoint(i)
									if point and point:match("^TOP") and relativeTo == pageContent then
										-- Found a TOP anchor, use its Y offset (absolute value since negative = down)
										targetScroll = math.abs(yOfs or 0) - 50 -- Offset 50 pixels from top for visibility
										targetScroll = math.max(0, targetScroll)
										break
									end
								end
								pageScroll:SetVerticalScroll(targetScroll)
							end
						end
						-- Find and highlight the specific control label that matches the search query
						local query = string.lower((frame._searchQuery or ""):match("^%s*(.-)%s*$") or "")
						if query ~= "" and sectionFrame then
							-- Check regions for FontStrings (control labels and text)
							local regions = sectionFrame.GetRegions and {sectionFrame:GetRegions()} or {}
							for i = 1, #regions do
								local region = regions[i]
								if region and region.GetObjectType and region:GetObjectType() == "FontString" then
									local textContent = region:GetText() or ""
									local lowerText = string.lower(textContent)
									-- Check if this FontString contains the search query
									if lowerText:find(query, 1, true) then
										-- Store original color for restoration
										if not region.__searchOriginalColor then
											region.__searchOriginalColor = {region:GetTextColor()}
										end
										-- Apply highlight color (bold effect by using accent color)
										local highlightColor = (currentStyle.accent or {0.74, 0.58, 0.99})
										region:SetTextColor(highlightColor[1], highlightColor[2], highlightColor[3], 1)
										-- Create pulsing effect that continues until search is cleared
										if C_Timer and C_Timer.NewTicker then
											-- Cancel any existing pulse timer for this region
											if region.__searchPulseTimer then
												region.__searchPulseTimer:Cancel()
											end
											-- Track highlighted regions globally so we can cancel them when search clears
											addon._searchHighlightedRegions = addon._searchHighlightedRegions or {}
											table.insert(addon._searchHighlightedRegions, region)
											-- Start pulsing between highlight and original color
											local isPulseOn = true
											region.__searchPulseTimer = C_Timer.NewTicker(0.5, function()
												if region and region.__searchOriginalColor then
													if isPulseOn then
														-- Pulse to original color
														region:SetTextColor(region.__searchOriginalColor[1], region.__searchOriginalColor[2], region.__searchOriginalColor[3], region.__searchOriginalColor[4] or 1)
													else
														-- Pulse to highlight color
														region:SetTextColor(highlightColor[1], highlightColor[2], highlightColor[3], 1)
													end
													isPulseOn = not isPulseOn
												end
											end)
										end
										break -- Only highlight the first match in the section
									end
								end
							end
						end
					end
				end)
			end
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

	local sidebarTabs = {}

	local function RebuildNav()
		-- Clear existing sidebar tabs and registry
		for i = 1, #sidebarTabs do
			local tab = sidebarTabs[i]
			if tab then
				if tab.Hide then
					tab:Hide()
				end
				if tab.SetParent then
					tab:SetParent(nil)
				end
			end
		end
		wipe(sidebarTabs)
		
		-- Also clear the sidebar component's button registry
		if navHost and navHost.tabButtons then
			for i = 1, #navHost.tabButtons do
				local button = navHost.tabButtons[i]
				if button then
					if button.Hide then
						button:Hide()
					end
					if button.SetParent then
						button:SetParent(nil)
					end
				end
			end
			wipe(navHost.tabButtons)
		end

		local sectionNav = addon:GetOptionsUnitSectionNav()
		local groupOrder = addon:GetOptionsV2Groups() or { "General", "Units", "Advanced" }
		local navState = cfgState.navState or {}
		local expandedGroups = navState.expandedGroups or {}
		local activeUnitSubtab = navState.activeUnitSubtab or {}
		local expandedPages = navState.expandedPages or {}  -- Track which pages have subtabs expanded

		-- Group pages by their group field
		local pagesByGroup = {}
		for groupIdx = 1, #groupOrder do
			local groupName = groupOrder[groupIdx]
			pagesByGroup[groupName] = {}
		end
		
		for pageIdx = 1, #pages do
			local page = pages[pageIdx]
			if page.group and pagesByGroup[page.group] then
				pagesByGroup[page.group][#pagesByGroup[page.group] + 1] = page
			end
		end

		local tabIndex = 0

		-- Build grouped navigation
		for groupIdx = 1, #groupOrder do
			local groupName = groupOrder[groupIdx]
			local groupPages = pagesByGroup[groupName] or {}
			if #groupPages > 0 then
				tabIndex = tabIndex + 1
				-- Default to collapsed unless explicitly expanded
				local isExpanded = expandedGroups[groupName] == true

				-- Create group header with expand/collapse indicator
				local groupCapturedName = groupName
				local onClickGroupHeader = function()
				expandedGroups[groupCapturedName] = not expandedGroups[groupCapturedName]
				cfgState.navState = cfgState.navState or {}
				cfgState.navState.expandedGroups = expandedGroups
				RebuildNav()
			end
			
			local groupHeaderButton = OptionsV2:AddSidebarTab(navHost, tabIndex, groupName, onClickGroupHeader)
				if groupHeaderButton then
					groupHeaderButton._isGroupHeader = true
					groupHeaderButton._groupName = groupName
					groupHeaderButton._isExpanded = isExpanded
					local textFrame = groupHeaderButton._text or groupHeaderButton.text
					if textFrame then
						textFrame:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
					end
					if groupHeaderButton.caret then
						groupHeaderButton.caret:SetText(isExpanded and "v" or ">")
					end
					sidebarTabs[tabIndex] = groupHeaderButton
				end

				-- Add page buttons under this group (only if expanded)
				if isExpanded then
					for pageIdx = 1, #groupPages do
						local page = groupPages[pageIdx]
						local pageKey = page.key
						
						tabIndex = tabIndex + 1
						local capturedPageKey = pageKey
						local capturedGroupName = groupName
						
						-- Check if this page has subtabs (only Units pages besides party/raid/boss have subtabs)
						local hasSubtabs = (capturedGroupName == "Units" and pageKey ~= "party" and pageKey ~= "raid" and pageKey ~= "boss")
						local pageIsExpanded = expandedPages[pageKey] or false
						
						local onSelectPage = function()
							-- Navigate to the page
							frame:SetPage(capturedPageKey)
						end
						
						-- Caret click handler for pages with subtabs
						local onCaretClick = nil
						if hasSubtabs then
							onCaretClick = function()
								expandedPages[capturedPageKey] = not expandedPages[capturedPageKey]
								cfgState.navState = cfgState.navState or {}
								cfgState.navState.expandedPages = expandedPages
								RebuildNav()
							end
						end
						
						local pageButton = OptionsV2:AddSidebarTab(navHost, tabIndex, "  " .. page.label, onSelectPage, onCaretClick)
						if pageButton then
							pageButton._pageKey = pageKey
							pageButton._isPageButton = true
							pageButton._parentGroup = groupName
							pageButton._hasSubtabs = hasSubtabs
							pageButton._isExpanded = pageIsExpanded
							if hasSubtabs and pageIsExpanded then
								for sectionIdx = 1, #sectionNav do
									local section = sectionNav[sectionIdx]
									local sectionKey = section.key
									local isActive = activeUnitSubtab[pageKey] == sectionKey or (sectionIdx == 1 and not activeUnitSubtab[pageKey])

									tabIndex = tabIndex + 1
									local capturedPageKey_Sub = pageKey
									local capturedSectionKey = sectionKey
									local onSelectSection = function()
										activeUnitSubtab[capturedPageKey_Sub] = capturedSectionKey
										cfgState.navState = cfgState.navState or {}
										cfgState.navState.activeUnitSubtab = activeUnitSubtab
										-- Call spec setter for active section first
										local spec = addon:GetOptionsV2PageSpec(capturedPageKey_Sub)
										if spec and type(spec.setActiveSection) == "function" then
											pcall(spec.setActiveSection, capturedSectionKey)
										end
										-- Notify page to set active section
										if frame._activeUnitSection then
											frame._activeUnitSection[capturedPageKey_Sub] = capturedSectionKey
										end
										-- Now set page with section already selected
										frame:SetPage(capturedPageKey_Sub)
									end
									
									local subtabButton = OptionsV2:AddSidebarTab(navHost, tabIndex, "    " .. section.label, onSelectSection)
									if subtabButton then
										subtabButton._isSubtab = true
										subtabButton._sectionKey = sectionKey
										subtabButton._pageKey = capturedPageKey_Sub
										subtabButton._parentPage = pageKey
										if isActive then
											if addon.ApplySUFBackdropColors then
												addon:ApplySUFBackdropColors(subtabButton, style.navSelected, style.navSelectedBorder, true)
											end
											local textFrame = subtabButton._text or subtabButton.text
											if textFrame then
												textFrame:SetTextColor(style.accent[1], style.accent[2], style.accent[3])
											end
										end
										sidebarTabs[tabIndex] = subtabButton
									end
								end
							end
						end
					end
				end
			end
		end

		OptionsV2:UpdateSidebarLayout(navHost)
		RefreshSelection()
	end
	frame.RebuildNav = RebuildNav

	frame:SetScript("OnSizeChanged", function()
		RebuildNav()
		-- Calculate content width based on available space (sidebar is 200px + 8px margin = 208px)
		local sidebarWidth = 208
		local availableWidth = frame:GetWidth() - sidebarWidth - 28 - 10 -- Subtract scrollbar and margins
		local width = math.max(780, math.floor(availableWidth))
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
				-- Cancel all active search highlight pulse timers
				if addon._searchHighlightedRegions then
					for i, region in ipairs(addon._searchHighlightedRegions) do
						if region and region.__searchPulseTimer then
							region.__searchPulseTimer:Cancel()
							region.__searchPulseTimer = nil
						end
						-- Restore original color
						if region and region.__searchOriginalColor then
							region:SetTextColor(region.__searchOriginalColor[1], region.__searchOriginalColor[2], region.__searchOriginalColor[3], region.__searchOriginalColor[4] or 1)
							region.__searchOriginalColor = nil
						end
					end
					addon._searchHighlightedRegions = {}
				end
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
		-- Cancel all active search highlight pulse timers
		if addon._searchHighlightedRegions then
			for i, region in ipairs(addon._searchHighlightedRegions) do
				if region and region.__searchPulseTimer then
					region.__searchPulseTimer:Cancel()
					region.__searchPulseTimer = nil
				end
				-- Restore original color
				if region and region.__searchOriginalColor then
					region:SetTextColor(region.__searchOriginalColor[1], region.__searchOriginalColor[2], region.__searchOriginalColor[3], region.__searchOriginalColor[4] or 1)
					region.__searchOriginalColor = nil
				end
			end
			addon._searchHighlightedRegions = {}
		end
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
