---ThemeMixin: Reusable component for frame theming (colors, backdrops, fonts)
---Abstraction for safe color/backdrop/font application with WoW 12.0.0+ compatibility
---@class ThemeMixin
ThemeMixin = {}

--- Initialize theming on a frame with theme settings
---@param self any Frame to apply theme to (inherits mixin via CreateFromMixins)
---@param themeSettings ThemeSettings Configuration table with colors/fonts/backdrops
function ThemeMixin:InitTheme(themeSettings)
	if not themeSettings then
		return
	end

	self.themeSettings = {
		backgroundColor = themeSettings.backgroundColor or {r = 0, g = 0, b = 0, a = 0.5},
		borderColor = themeSettings.borderColor or {r = 1, g = 1, b = 1, a = 1},
		textColor = themeSettings.textColor or {r = 1, g = 1, b = 1, a = 1},
		healthColor = themeSettings.healthColor or {r = 0, g = 1, b = 0, a = 1},
		font = themeSettings.font or "Fonts\\FRIZQT__.TTF",
		fontSize = tonumber(themeSettings.fontSize) or 16,
		fontFlags = themeSettings.fontFlags or "OUTLINE",
		statusbarTexture = themeSettings.statusbarTexture or "Interface\\TargetingFrame\\UI-StatusBar",
	}

	-- Apply initial theme
	self:ApplyTheme()
end

--- Apply all theme settings to frame and children
---@param self any Frame to theme
function ThemeMixin:ApplyTheme()
	if not self.themeSettings then
		return
	end

	self:ApplyBackdropTheme()
	self:ApplyFontTheme()
	self:ApplyStatusbarTheme()
end

--- Apply backdrop color/texture safely (WoW 12.0.0+ compatible)
---@param self any Frame to apply backdrop to
function ThemeMixin:ApplyBackdropTheme()
	if not (self.themeSettings and self.themeSettings.backgroundColor) then
		return
	end

	local bgColor = self.themeSettings.backgroundColor
	local borderColor = self.themeSettings.borderColor

	SafeSetBackdropColor(self, bgColor)
	if borderColor then
		SafeSetBorderColor(self, borderColor)
	end
end

--- Apply font settings to all FontString children
---@param self any Frame with FontString children to theme
function ThemeMixin:ApplyFontTheme()
	if not (self.themeSettings and self.themeSettings.font) then
		return
	end

	local settings = self.themeSettings

	for _, child in ipairs({self:GetChildren()}) do
		if child:IsObjectType("FontString") then
			SafeSetFontStringTheme(child, settings.textColor, settings.font, settings.fontSize, settings.fontFlags)
		end
	end
end

--- Apply statusbar texture and color (for health/power bars)
---@param self any Frame with statusbar textures
function ThemeMixin:ApplyStatusbarTheme()
	if not (self.themeSettings and self.themeSettings.statusbarTexture) then
		return
	end

	local texture = self.themeSettings.statusbarTexture

	for _, child in ipairs({self:GetChildren()}) do
		if child:IsObjectType("StatusBar") then
			SafeSetStatusbarTexture(child, texture)
		end
	end
end

--- Update font color on text elements
---@param self any Frame with text
---@param fontColor table Color table {r, g, b, a}
function ThemeMixin:SetTextColor(fontColor)
	if not fontColor then
		return
	end

	self.themeSettings.textColor = fontColor

	for _, child in ipairs({self:GetChildren()}) do
		if child:IsObjectType("FontString") then
			SafeSetFontColor(child, fontColor)
		end
	end
end

--- Update background color
---@param self any Frame with backdrop
---@param bgColor table Color table {r, g, b, a}
function ThemeMixin:SetBackgroundColor(bgColor)
	if not bgColor then
		return
	end

	self.themeSettings.backgroundColor = bgColor
	SafeSetBackdropColor(self, bgColor)
end

--- Update border/edge color
---@param self any Frame with border
---@param borderColor table Color table {r, g, b, a}
function ThemeMixin:SetBorderColor(borderColor)
	if not borderColor then
		return
	end

	self.themeSettings.borderColor = borderColor
	SafeSetBorderColor(self, borderColor)
end

--- Safe backdrop color application (WoW 12.0.0+ secret value compatible)
---@param frame any Frame to color
---@param bgColor table Color {r, g, b, a}
local function SafeSetBackdropColor(frame, bgColor)
	if not (frame and bgColor) then
		return
	end

	if not frame:GetBackdrop() then
		frame:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
	end

	local r = tonumber(bgColor.r) or 0
	local g = tonumber(bgColor.g) or 0
	local b = tonumber(bgColor.b) or 0
	local a = tonumber(bgColor.a) or 0.5

	if not IsSecretValue(r) then
		frame:SetBackdropColor(r, g, b, a)
	end
end

--- Safe border color application
---@param frame any Frame to border
---@param borderColor table Color {r, g, b, a}
local function SafeSetBorderColor(frame, borderColor)
	if not (frame and borderColor) then
		return
	end

	if not frame:GetBackdrop() then
		frame:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16})
	end

	local r = tonumber(borderColor.r) or 1
	local g = tonumber(borderColor.g) or 1
	local b = tonumber(borderColor.b) or 1
	local a = tonumber(borderColor.a) or 1

	if not IsSecretValue(r) then
		frame:SetBackdropBorderColor(r, g, b, a)
	end
end

--- Safe font color on FontString
---@param fontString any FontString to color
---@param color table Color {r, g, b, a}
local function SafeSetFontColor(fontString, color)
	if not (fontString and color) then
		return
	end

	local r = tonumber(color.r) or 1
	local g = tonumber(color.g) or 1
	local b = tonumber(color.b) or 1
	local a = tonumber(color.a) or 1

	if not IsSecretValue(r) then
		fontString:SetTextColor(r, g, b, a)
	end
end

--- Safe FontString theme application
---@param fontString any FontString to theme
---@param color table Color {r, g, b, a}
---@param font string Font path
---@param size number Font size
---@param flags string Font flags
local function SafeSetFontStringTheme(fontString, color, font, size, flags)
	if not fontString then
		return
	end

	font = font or "Fonts\\FRIZQT__.TTF"
	size = tonumber(size) or 16
	flags = flags or "OUTLINE"

	SafeSetFontColor(fontString, color)

	if not IsSecretValue(font) then
		fontString:SetFont(font, size, flags)
	end
end

--- Safe statusbar texture application
---@param statusbar any StatusBar to theme
---@param texture string Statusbar texture path
local function SafeSetStatusbarTexture(statusbar, texture)
	if not (statusbar and texture) then
		return
	end

	if not IsSecretValue(texture) then
		statusbar:SetStatusBarTexture(texture)
	end
end

--- Detect if value is WoW 12.0.0+ secret value (protected return)
---@param value any Value to check
---@return boolean True if value is secret
local function IsSecretValue(value)
	if value == nil then
		return false
	end

	local valueType = type(value)
	if valueType == "string" then
		return value:match("^%[PROTECTED%]") ~= nil
	elseif valueType == "number" then
		return tostring(value):match("^-?1.#IND") ~= nil or value ~= value
	end

	return false
end

---@type ThemeSettings
---@field backgroundColor table Color table {r, g, b, a} for background
---@field borderColor table Color table {r, g, b, a} for borders
---@field textColor table Color table {r, g, b, a} for text
---@field healthColor table Color table {r, g, b, a} for health bar
---@field font string Font path (default: "Fonts\\FRIZQT__.TTF")
---@field fontSize integer Font size in pixels (default: 16)
---@field fontFlags string Font flags (default: "OUTLINE")
---@field statusbarTexture string Statusbar texture path
