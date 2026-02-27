local AceAddon = LibStub("AceAddon-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
local LibDropDown = LibStub("LibDropdown-1.0", true)
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local core = addon._core or {}
local defaults = core.defaults or {}
local iconPath = core.ICON_PATH or "Interface\\Icons\\INV_Misc_QuestionMark"
local CopyTableDeep = core.CopyTableDeep

local function IsRightClickButton(mouseButton)
	return tostring(mouseButton or "") == "RightButton"
end

function addon:ApplyLauncherVisibility()
	if not self.db or not self.db.profile then
		return
	end
	self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)

	local function EnsureLibDBIconButtonClicks()
		if not (LibDBIcon and LibDBIcon.GetMinimapButton) then
			return
		end
		local button = LibDBIcon:GetMinimapButton("SimpleUnitFrames")
		if button and button.RegisterForClicks then
			button:RegisterForClicks("AnyUp")
		end
	end

	if self.ldbObject and LibDBIcon then
		if not LibDBIcon:IsRegistered("SimpleUnitFrames") then
			LibDBIcon:Register("SimpleUnitFrames", self.ldbObject, self.db.profile.minimap)
		end
		EnsureLibDBIconButtonClicks()
		if self.db.profile.minimap.hide then
			LibDBIcon:Hide("SimpleUnitFrames")
		else
			LibDBIcon:Show("SimpleUnitFrames")
		end
		if self.minimapButton then
			self.minimapButton:Hide()
		end
		return
	end

	self:CreateFallbackMinimapButton()
	if self.minimapButton then
		self.minimapButton:SetShown(not self.db.profile.minimap.hide)
	end
end

function addon:AddLauncherTooltipLines(tooltip)
	if not (tooltip and tooltip.AddLine and tooltip.AddDoubleLine) then
		return
	end
	local fps = math.floor((GetFramerate and GetFramerate() or 0) + 0.5)
	local homeLatency, worldLatency = 0, 0
	if GetNetStats then
		local _, _, home, world = GetNetStats()
		homeLatency = tonumber(home) or 0
		worldLatency = tonumber(world) or 0
	end
	local memMB = (collectgarbage("count") or 0) / 1024

	tooltip:AddLine("SimpleUnitFrames")
	tooltip:AddLine("Left Click: Open Options", 1, 1, 1)
	tooltip:AddLine("Right Click: Quick Menu", 1, 1, 1)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine("FPS:", tostring(fps), 0.82, 0.82, 0.82, 1, 1, 1)
	tooltip:AddDoubleLine("MS:", string.format("H:%d  W:%d", homeLatency or 0, worldLatency or 0), 0.82, 0.82, 0.82, 1, 1, 1)
	tooltip:AddDoubleLine("Lua Mem:", string.format("%.1f MB", memMB), 0.82, 0.82, 0.82, 1, 1, 1)
end

function addon:ShowLauncherMenu(anchorFrame)
	local forceFallbackMenu = InCombatLockdown and InCombatLockdown() or false
	if (not UIDropDownMenu_Initialize or not ToggleDropDownMenu) and UIParentLoadAddOn then
		pcall(UIParentLoadAddOn, "Blizzard_UIDropDownMenu")
	end

	local function ShowFallbackMenu(anchor)
		if not self.launcherFallbackMenu then
			local menu = CreateFrame("Frame", "SUFLauncherFallbackMenu", UIParent, "BackdropTemplate")
			menu:SetSize(180, 120)
			menu:SetFrameStrata("TOOLTIP")
			menu:SetToplevel(true)
			menu:EnableMouse(true)
			menu:SetClampedToScreen(true)
			menu:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 4, right = 4, top = 4, bottom = 4 },
			})
			menu:SetBackdropColor(0, 0, 0, 0.92)
			if self.ApplySUFBackdrop then
				self:ApplySUFBackdrop(menu, "window")
			end

			local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			title:SetPoint("TOP", menu, "TOP", 0, -10)
			title:SetText("SimpleUnitFrames")
			local theme = self.GetSUFTheme and self:GetSUFTheme()
			local titleColor = theme and theme.text and theme.text.title
			if titleColor then
				title:SetTextColor(titleColor[1], titleColor[2], titleColor[3], titleColor[4] or 1)
			end

			local function CreateMenuButton(parent, label, y, fn)
				local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
				btn:SetSize(150, 22)
				btn:SetPoint("TOP", parent, "TOP", 0, y)
				btn:SetText(label)
				if self.ApplySUFButtonSkin then
					self:ApplySUFButtonSkin(btn, "default")
				end
				btn:SetScript("OnClick", function()
					parent:Hide()
					fn()
				end)
				return btn
			end

			CreateMenuButton(menu, "Open SUF Options", -30, function() self:ShowOptions() end)
			CreateMenuButton(menu, "Open PerfLib UI", -56, function() self:TogglePerformanceDashboard() end)
			CreateMenuButton(menu, "Open SUF Debug", -82, function() self:ShowDebugPanel() end)

			menu:SetScript("OnMouseDown", function(_, button)
				if button == "RightButton" then
					menu:Hide()
				end
			end)

			self.launcherFallbackMenu = menu
		end

		local menu = self.launcherFallbackMenu
		menu:ClearAllPoints()
		if type(anchor) == "table" and anchor.GetCenter then
			menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
		else
			local x, y = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale() or 1
			menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
		end
		menu:Show()
	end

	local function ShowLibDropDownMenu(anchor)
		if not (LibDropDown and LibDropDown.OpenAce3Menu) then
			return false
		end
		if self._launcherLibDropDownMenu and self._launcherLibDropDownMenu.Release then
			pcall(self._launcherLibDropDownMenu.Release, self._launcherLibDropDownMenu)
			self._launcherLibDropDownMenu = nil
		end

		local menuConfig = {
			type = "group",
			name = "SimpleUnitFrames",
			args = {
				title = {
					type = "header",
					name = "SimpleUnitFrames",
					order = 1,
				},
				openOptions = {
					type = "execute",
					name = "Open SUF Options",
					order = 10,
					func = function()
						if addon then addon:ShowOptions() end
					end,
				},
				openPerf = {
					type = "execute",
					name = "Open PerfLib UI",
					order = 20,
					func = function()
						if addon then addon:TogglePerformanceDashboard() end
					end,
				},
				openDebug = {
					type = "execute",
					name = "Open SUF Debug",
					order = 30,
					func = function()
						if addon then addon:ShowDebugPanel() end
					end,
				},
			},
		}

		local ok, menuFrame = pcall(function()
			return LibDropDown:OpenAce3Menu(menuConfig)
		end)
		if not ok or not menuFrame then
			return false
		end

		menuFrame:ClearAllPoints()
		if type(anchor) == "table" and anchor.GetCenter then
			menuFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
		else
			local x, y = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale() or 1
			menuFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale - 8)
		end

		self._launcherLibDropDownMenu = menuFrame
		return true
	end

	if forceFallbackMenu then
		ShowFallbackMenu(anchorFrame)
		return
	end

	if ShowLibDropDownMenu(anchorFrame) then
		return
	end

	if not UIDropDownMenu_Initialize or not ToggleDropDownMenu then
		ShowFallbackMenu(anchorFrame)
		return
	end

	if not self.launcherDropdown then
		self.launcherDropdown = CreateFrame("Frame", "SUFLauncherDropdown", UIParent, "UIDropDownMenuTemplate")
		self.launcherDropdown.displayMode = "MENU"
	end

	local menu = {
		{ text = "SimpleUnitFrames", isTitle = true, notCheckable = true },
		{ text = "Open SUF Options", notCheckable = true, func = function() self:ShowOptions() end },
		{ text = "Open PerfLib UI", notCheckable = true, func = function() self:TogglePerformanceDashboard() end },
		{ text = "Open SUF Debug", notCheckable = true, func = function() self:ShowDebugPanel() end },
		{ text = "Close", notCheckable = true, func = function() end },
	}

	local anchor = anchorFrame
	if type(anchor) ~= "table" or not anchor.GetObjectType then
		anchor = "cursor"
	end

	UIDropDownMenu_Initialize(self.launcherDropdown, function(_, level)
		if level ~= 1 then
			return
		end
		for i = 1, #menu do
			local info = UIDropDownMenu_CreateInfo()
			for key, value in pairs(menu[i]) do
				info[key] = value
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end, "MENU")

	CloseDropDownMenus()
	ToggleDropDownMenu(1, nil, self.launcherDropdown, anchor, 0, 0)
end

function addon:CreateFallbackMinimapButton()
	if self.minimapButton then
		return
	end

	local button = CreateFrame("Button", "SUFMinimapButton", Minimap)
	button:SetSize(32, 32)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	bg:SetSize(54, 54)
	bg:SetPoint("TOPLEFT")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(iconPath)
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER")
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local function UpdatePosition()
		if not self.db or not self.db.profile then
			return
		end
		self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)
		local angle = math.rad(self.db.profile.minimap.minimapPos or 220)
		local x = math.cos(angle) * 80
		local y = math.sin(angle) * 80
		button:ClearAllPoints()
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end

	button:SetScript("OnDragStart", function()
		button:StartMoving()
	end)
	button:SetScript("OnDragStop", function()
		button:StopMovingOrSizing()
		local mx, my = Minimap:GetCenter()
		local bx, by = button:GetCenter()
		if mx and my and bx and by then
			local angle = math.deg(math.atan2(by - my, bx - mx))
			self.db.profile.minimap.minimapPos = angle
			UpdatePosition()
		end
	end)
	button:SetMovable(true)

	button:SetScript("OnClick", function(_, mouseButton)
		if IsRightClickButton(mouseButton) then
			self:ShowLauncherMenu(button)
		else
			self:ShowOptions()
		end
	end)

	button:SetScript("OnEnter", function()
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:SetOwner(button, "ANCHOR_LEFT")
			GameTooltip:ClearLines()
			self:AddLauncherTooltipLines(GameTooltip)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:Hide()
		end
	end)

	self.minimapButton = button
	UpdatePosition()
end

function addon:InitializeLauncher()
	if not self.db or not self.db.profile then
		return
	end
	self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)

	if LDB and not self.ldbObject then
		self.ldbObject = LDB:NewDataObject("SimpleUnitFrames", {
			type = "launcher",
			text = "SimpleUnitFrames",
			icon = iconPath,
			OnClick = function(frameRef, mouseButton)
				if IsRightClickButton(mouseButton) then
					self:ShowLauncherMenu(frameRef or "cursor")
				else
					self:ShowOptions()
				end
			end,
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then
					return
				end
				tooltip:ClearLines()
				self:AddLauncherTooltipLines(tooltip)
			end,
		})
	end

	self:ApplyLauncherVisibility()
end
