local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local THEME = {
	name = "SUFBanner",
	options = {
		windowBg = { 0.07, 0.06, 0.12, 0.95 },
		windowBorder = { 0.57, 0.45, 0.72, 0.96 },
		panelBg = { 0.10, 0.08, 0.17, 0.93 },
		panelBorder = { 0.46, 0.35, 0.62, 0.94 },
		accent = { 0.74, 0.58, 0.99 },
		accentSoft = { 0.55, 0.42, 0.78 },
		textMuted = { 0.78, 0.78, 0.90 },
		searchBg = { 0.09, 0.08, 0.14, 0.96 },
		searchBorder = { 0.60, 0.46, 0.80, 0.96 },
		navDefault = { 0.11, 0.09, 0.16, 0.90 },
		navDefaultBorder = { 0.34, 0.27, 0.47, 0.95 },
		navHover = { 0.17, 0.14, 0.24, 0.93 },
		navHoverBorder = { 0.48, 0.38, 0.66, 0.95 },
		navSelected = { 0.29, 0.20, 0.47, 0.95 },
		navSelectedBorder = { 0.72, 0.57, 0.96, 0.96 },
		navSearch = { 0.20, 0.12, 0.28, 0.93 },
		navSearchBorder = { 0.57, 0.41, 0.76, 0.94 },
	},
	backdrop = {
		window = {
			bg = { 0.07, 0.06, 0.12, 0.95 },
			border = { 0.57, 0.45, 0.72, 0.96 },
		},
		panel = {
			bg = { 0.10, 0.08, 0.17, 0.92 },
			border = { 0.46, 0.35, 0.62, 0.94 },
		},
		subtle = {
			bg = { 0.10, 0.08, 0.17, 0.72 },
			border = { 0.39, 0.31, 0.56, 0.90 },
		},
	},
	databars = {
		xp = { 0.10, 0.50, 0.96, 0.92 },
		reputation = { 0.28, 0.80, 0.36, 0.92 },
		petxp = { 0.70, 0.28, 0.96, 0.92 },
		rested = { 0.45, 0.66, 1.00, 0.42 },
		quest = { 0.90, 0.64, 0.98, 0.34 },
	},
	text = {
		title = { 0.86, 0.78, 1.00, 1.00 },
		header = { 0.90, 0.84, 1.00, 1.00 },
		body = { 0.86, 0.84, 0.95, 1.00 },
		muted = { 0.72, 0.70, 0.82, 1.00 },
		accent = { 0.78, 0.62, 1.00, 1.00 },
		warn = { 1.00, 0.56, 0.60, 1.00 },
		good = { 0.56, 1.00, 0.66, 1.00 },
	},
	textures = {
		divider = { 0.55, 0.42, 0.78, 0.42 },
		icon = { 0.90, 0.84, 1.00, 0.95 },
	},
	buttons = {
		default = {
			normal = { bg = { 0.14, 0.11, 0.20, 0.92 }, border = { 0.44, 0.34, 0.61, 0.96 }, text = { 0.90, 0.85, 1.00, 1.00 } },
			hover = { bg = { 0.20, 0.16, 0.30, 0.95 }, border = { 0.64, 0.51, 0.85, 0.98 }, text = { 0.98, 0.95, 1.00, 1.00 } },
			pressed = { bg = { 0.26, 0.19, 0.39, 0.98 }, border = { 0.76, 0.61, 0.97, 1.00 }, text = { 1.00, 1.00, 1.00, 1.00 } },
			disabled = { bg = { 0.10, 0.09, 0.14, 0.72 }, border = { 0.29, 0.26, 0.36, 0.80 }, text = { 0.55, 0.55, 0.62, 1.00 } },
		},
		subtle = {
			normal = { bg = { 0.11, 0.09, 0.16, 0.85 }, border = { 0.35, 0.28, 0.49, 0.90 }, text = { 0.85, 0.82, 0.92, 1.00 } },
			hover = { bg = { 0.16, 0.13, 0.24, 0.92 }, border = { 0.53, 0.42, 0.72, 0.95 }, text = { 0.95, 0.92, 0.99, 1.00 } },
			pressed = { bg = { 0.22, 0.16, 0.32, 0.96 }, border = { 0.66, 0.52, 0.84, 0.98 }, text = { 1.00, 0.98, 1.00, 1.00 } },
			disabled = { bg = { 0.08, 0.08, 0.11, 0.68 }, border = { 0.25, 0.23, 0.31, 0.78 }, text = { 0.52, 0.52, 0.58, 1.00 } },
		},
	},
	controls = {
		checkbox = {
			box = { 0.14, 0.11, 0.20, 0.95 },
			boxBorder = { 0.49, 0.38, 0.68, 0.96 },
			check = { 0.83, 0.70, 1.00, 1.00 },
			label = { 0.86, 0.84, 0.95, 1.00 },
		},
		slider = {
			bg = { 0.12, 0.10, 0.18, 0.85 },
			border = { 0.41, 0.32, 0.58, 0.92 },
			bar = { 0.64, 0.50, 0.88, 0.95 },
			thumb = { 0.90, 0.82, 1.00, 1.00 },
			text = { 0.86, 0.84, 0.95, 1.00 },
		},
		editbox = {
			bg = { 0.10, 0.08, 0.16, 0.92 },
			border = { 0.50, 0.39, 0.69, 0.95 },
			text = { 0.90, 0.88, 0.97, 1.00 },
		},
		scrollbar = {
			bg = { 0.08, 0.07, 0.13, 0.88 },
			border = { 0.37, 0.30, 0.52, 0.92 },
			thumb = { 0.70, 0.56, 0.94, 0.95 },
			button = { 0.86, 0.78, 1.00, 0.95 },
		},
		statusbar = {
			bar = { 0.66, 0.52, 0.90, 0.92 },
			bg = { 0.14, 0.11, 0.20, 0.82 },
		},
	},
}

local function EnsureBackdrop(frame)
	if not (frame and frame.SetBackdrop) then
		return
	end
	if frame.GetBackdrop and frame:GetBackdrop() then
		return
	end
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
end

-- Per Blizzard_SharedXML/Shared/Scroll/ScrollBar.lua lines 10-31, ScrollBar steppers/track/thumb are simple widgets.
function addon:ApplySUFBackdropColors(target, bgColor, borderColor, ensureBackdrop)
	if not target then
		return
	end
	if ensureBackdrop then
		EnsureBackdrop(target)
	end
	if bgColor then
		if target.SetVertexColor then
			target:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
		end
		if target.SetColorTexture then
			target:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
		end
		if target.SetBackdropColor then
			target:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
		end
	end
	if borderColor and target.SetBackdropBorderColor then
		target:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
	end
end

local function ShouldSkipFontString(fontString)
	if not fontString then
		return true
	end
	local text = fontString.GetText and fontString:GetText() or nil
	if type(text) == "string" and text:find("|c", 1, true) then
		return true
	end
	local parent = fontString.GetParent and fontString:GetParent() or nil
	if parent and parent.GetObjectType and parent:GetObjectType() == "Button" and parent.__sufButtonHooks then
		return true
	end
	return false
end

local function ResolveFontRole(fontString)
	local name = tostring((fontString.GetName and fontString:GetName()) or "")
	local text = tostring((fontString.GetText and fontString:GetText()) or "")
	local lowered = (name .. " " .. text):lower()

	if lowered:find("title", 1, true) then
		return "title"
	end
	if lowered:find("header", 1, true) or lowered:find("section", 1, true) then
		return "header"
	end
	if lowered:find("warning", 1, true) or lowered:find("error", 1, true) or lowered:find("fail", 1, true) then
		return "warn"
	end
	if lowered:find("success", 1, true) or lowered:find("enabled", 1, true) or lowered:find("complete", 1, true) then
		return "good"
	end
	if lowered:find("hint", 1, true) or lowered:find("muted", 1, true) or lowered:find("disable", 1, true) then
		return "muted"
	end
	if lowered:find("accent", 1, true) then
		return "accent"
	end
	return "body"
end

function addon:ApplySUFFontStringSkin(fontString, role)
	if not (fontString and fontString.GetObjectType and fontString:GetObjectType() == "FontString") then
		return
	end
	if ShouldSkipFontString(fontString) then
		return
	end
	local key = role or ResolveFontRole(fontString)
	local palette = THEME.text and THEME.text[key]
	if not palette then
		palette = THEME.text and THEME.text.body
	end
	if palette and fontString.SetTextColor then
		fontString:SetTextColor(palette[1], palette[2], palette[3], palette[4] or 1)
	end
end

function addon:ApplySUFTextureSkin(texture)
	if not (texture and texture.GetObjectType and texture:GetObjectType() == "Texture") then
		return
	end
	if texture.__sufTextureSkinned then
		return
	end

	local tex = texture.GetTexture and texture:GetTexture() or nil
	if type(tex) ~= "string" then
		return
	end
	local texLower = tex:lower()
	local tint = THEME.textures or {}
	local isWhitePixel = texLower:find("white8x8", 1, true) ~= nil
	if not isWhitePixel then
		return
	end

	local width = texture.GetWidth and texture:GetWidth() or 0
	local height = texture.GetHeight and texture:GetHeight() or 0
	local isDivider = (width <= 4 and height > 20) or (height <= 4 and width > 20)
	local color = isDivider and tint.divider or tint.icon
	if color and texture.SetVertexColor then
		texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
		texture.__sufTextureSkinned = true
	end
end

function addon:GetSUFTheme()
	return THEME
end

function addon:GetOptionsUIStyle()
	return THEME.options
end

function addon:SyncThemeFromOptionsV2()
	if not self.GetOptionsV2Style then
		return
	end
	local v2 = self:GetOptionsV2Style()
	if type(v2) ~= "table" then
		return
	end

	THEME.options.windowBg = { v2.windowBg[1], v2.windowBg[2], v2.windowBg[3], v2.windowBg[4] or 1 }
	THEME.options.windowBorder = { v2.windowBorder[1], v2.windowBorder[2], v2.windowBorder[3], v2.windowBorder[4] or 1 }
	THEME.options.panelBg = { v2.panelBg[1], v2.panelBg[2], v2.panelBg[3], v2.panelBg[4] or 1 }
	THEME.options.panelBorder = { v2.panelBorder[1], v2.panelBorder[2], v2.panelBorder[3], v2.panelBorder[4] or 1 }
	THEME.options.accent = { v2.accent[1], v2.accent[2], v2.accent[3], v2.accent[4] or 1 }
	THEME.options.accentSoft = { v2.accentSoft[1], v2.accentSoft[2], v2.accentSoft[3], v2.accentSoft[4] or 1 }
	THEME.options.textMuted = { v2.textMuted[1], v2.textMuted[2], v2.textMuted[3], v2.textMuted[4] or 1 }
	THEME.options.navDefault = { v2.navDefault[1], v2.navDefault[2], v2.navDefault[3], v2.navDefault[4] or 1 }
	THEME.options.navDefaultBorder = { v2.navDefaultBorder[1], v2.navDefaultBorder[2], v2.navDefaultBorder[3], v2.navDefaultBorder[4] or 1 }
	THEME.options.navHover = { v2.navHover[1], v2.navHover[2], v2.navHover[3], v2.navHover[4] or 1 }
	THEME.options.navHoverBorder = { v2.navHoverBorder[1], v2.navHoverBorder[2], v2.navHoverBorder[3], v2.navHoverBorder[4] or 1 }
	THEME.options.navSelected = { v2.navSelected[1], v2.navSelected[2], v2.navSelected[3], v2.navSelected[4] or 1 }
	THEME.options.navSelectedBorder = { v2.navSelectedBorder[1], v2.navSelectedBorder[2], v2.navSelectedBorder[3], v2.navSelectedBorder[4] or 1 }

	THEME.backdrop.window.bg = THEME.options.windowBg
	THEME.backdrop.window.border = THEME.options.windowBorder
	THEME.backdrop.panel.bg = THEME.options.panelBg
	THEME.backdrop.panel.border = THEME.options.panelBorder
	THEME.backdrop.subtle.bg = { THEME.options.navDefault[1], THEME.options.navDefault[2], THEME.options.navDefault[3], 0.72 }
	THEME.backdrop.subtle.border = THEME.options.navDefaultBorder

	THEME.text.title = { THEME.options.accent[1], THEME.options.accent[2], THEME.options.accent[3], 1 }
	THEME.text.header = { THEME.options.accentSoft[1], THEME.options.accentSoft[2], THEME.options.accentSoft[3], 1 }
	THEME.text.body = { THEME.options.textMuted[1], THEME.options.textMuted[2], THEME.options.textMuted[3], 1 }
	THEME.text.muted = { THEME.options.textMuted[1], THEME.options.textMuted[2], THEME.options.textMuted[3], 0.9 }
	THEME.text.accent = { THEME.options.accent[1], THEME.options.accent[2], THEME.options.accent[3], 1 }

	THEME.controls.editbox.bg = THEME.options.navDefault
	THEME.controls.editbox.border = THEME.options.navDefaultBorder
	THEME.controls.slider.bg = THEME.options.navDefault
	THEME.controls.slider.border = THEME.options.navDefaultBorder
	THEME.controls.slider.bar = THEME.options.accentSoft
	THEME.controls.slider.thumb = THEME.options.accent
	THEME.controls.checkbox.box = THEME.options.navDefault
	THEME.controls.checkbox.boxBorder = THEME.options.navDefaultBorder
	THEME.controls.checkbox.check = THEME.options.accent
	THEME.controls.checkbox.label = THEME.options.textMuted
	THEME.controls.scrollbar.bg = THEME.options.navDefault
	THEME.controls.scrollbar.border = THEME.options.navDefaultBorder
	THEME.controls.scrollbar.thumb = THEME.options.accentSoft
	THEME.controls.scrollbar.button = THEME.options.accent
end

function addon:ApplySUFBackdrop(frame, variant)
	if not frame then
		return
	end
	local style = THEME.backdrop[variant or "panel"] or THEME.backdrop.panel
	self:ApplySUFBackdropColors(frame, style.bg, style.border, true)
	if frame.TitleText and frame.TitleText.SetTextColor then
		local t = THEME.text.title
		frame.TitleText:SetTextColor(t[1], t[2], t[3], t[4])
	end
end

local function GetButtonTheme(variant)
	local buttonThemes = THEME.buttons or {}
	return buttonThemes[variant or "default"] or buttonThemes.default
end

function addon:ApplySUFButtonSkin(button, variant)
	if not (button and button.GetObjectType and button:GetObjectType() == "Button") then
		return
	end
	local style = GetButtonTheme(variant)
	if not style then
		return
	end

	EnsureBackdrop(button)
	button.__sufButtonVariant = variant or "default"

	if not button.__sufButtonTexturesCleared then
		if button.SetNormalTexture then button:SetNormalTexture("") end
		if button.SetHighlightTexture then button:SetHighlightTexture("") end
		if button.SetPushedTexture then button:SetPushedTexture("") end
		if button.SetDisabledTexture then button:SetDisabledTexture("") end
		button.__sufButtonTexturesCleared = true
	end

	local function ApplyState(widget, stateName)
		local use = style[stateName] or style.normal
		addon:ApplySUFBackdropColors(widget, use.bg, use.border, true)
		local fs = widget.GetFontString and widget:GetFontString()
		if fs and fs.SetTextColor then
			fs:SetTextColor(use.text[1], use.text[2], use.text[3], use.text[4] or 1)
		end
	end

	local function RefreshState(widget)
		if widget.IsEnabled and not widget:IsEnabled() then
			ApplyState(widget, "disabled")
		elseif widget.__sufPressed then
			ApplyState(widget, "pressed")
		elseif widget.IsMouseOver and widget:IsMouseOver() then
			ApplyState(widget, "hover")
		else
			ApplyState(widget, "normal")
		end
	end

	if not button.__sufButtonHooks then
		button:HookScript("OnEnter", function(widget)
			widget.__sufPressed = nil
			RefreshState(widget)
		end)
		button:HookScript("OnLeave", function(widget)
			widget.__sufPressed = nil
			RefreshState(widget)
		end)
		button:HookScript("OnMouseDown", function(widget)
			widget.__sufPressed = true
			RefreshState(widget)
		end)
		button:HookScript("OnMouseUp", function(widget)
			widget.__sufPressed = nil
			RefreshState(widget)
		end)
		button:HookScript("OnShow", function(widget)
			RefreshState(widget)
		end)
		button.__sufButtonHooks = true
	end

	RefreshState(button)
end

function addon:ApplySUFButtonSkinsInFrame(root, variant)
	if not (root and root.GetNumChildren) then
		return
	end
	local function Walk(parent, depth)
		if depth > 8 then
			return
		end
		local children = { parent:GetChildren() }
		for i = 1, #children do
			local child = children[i]
			if child and child.GetObjectType and child:GetObjectType() == "Button" then
				addon:ApplySUFButtonSkin(child, variant)
			end
			if child and child.GetNumChildren and child:GetNumChildren() > 0 then
				Walk(child, depth + 1)
			end
		end
	end
	Walk(root, 0)
end

function addon:ApplySUFCheckBoxSkin(checkButton)
	if not (checkButton and checkButton.GetObjectType and checkButton:GetObjectType() == "CheckButton") then
		return
	end
	local cfg = THEME.controls and THEME.controls.checkbox
	if not cfg then
		return
	end
	local name = checkButton.GetName and checkButton:GetName() or nil
	local normal = checkButton.GetNormalTexture and checkButton:GetNormalTexture()
	local pushed = checkButton.GetPushedTexture and checkButton:GetPushedTexture()
	local highlight = checkButton.GetHighlightTexture and checkButton:GetHighlightTexture()
	local checked = checkButton.GetCheckedTexture and checkButton:GetCheckedTexture()
	local disabledChecked = checkButton.GetDisabledCheckedTexture and checkButton:GetDisabledCheckedTexture()
	local label = name and _G[name .. "Text"] or nil

	if normal and normal.SetVertexColor then
		normal:SetVertexColor(cfg.box[1], cfg.box[2], cfg.box[3], cfg.box[4])
	end
	if pushed and pushed.SetVertexColor then
		pushed:SetVertexColor(cfg.box[1] * 0.85, cfg.box[2] * 0.85, cfg.box[3] * 0.85, cfg.box[4])
	end
	if highlight and highlight.SetVertexColor then
		highlight:SetVertexColor(cfg.check[1], cfg.check[2], cfg.check[3], 0.22)
	end
	if checked and checked.SetVertexColor then
		checked:SetVertexColor(cfg.check[1], cfg.check[2], cfg.check[3], cfg.check[4])
	end
	if disabledChecked and disabledChecked.SetVertexColor then
		disabledChecked:SetVertexColor(cfg.check[1] * 0.7, cfg.check[2] * 0.7, cfg.check[3] * 0.7, 0.7)
	end
	if label and label.SetTextColor then
		label:SetTextColor(cfg.label[1], cfg.label[2], cfg.label[3], cfg.label[4] or 1)
	end

	if not checkButton.__sufCheckBorder and checkButton.CreateTexture then
		local border = checkButton:CreateTexture(nil, "BORDER")
		border:SetPoint("TOPLEFT", checkButton, "TOPLEFT", 4, -4)
		border:SetPoint("BOTTOMRIGHT", checkButton, "BOTTOMRIGHT", -4, 4)
		border:SetTexture("Interface\\Buttons\\WHITE8x8")
		border:SetVertexColor(cfg.boxBorder[1], cfg.boxBorder[2], cfg.boxBorder[3], cfg.boxBorder[4])
		checkButton.__sufCheckBorder = border
	end
end

function addon:ApplySUFSliderSkin(slider)
	if not (slider and slider.GetObjectType and slider:GetObjectType() == "Slider") then
		return
	end
	local cfg = THEME.controls and THEME.controls.slider
	if not cfg then
		return
	end
	self:ApplySUFBackdropColors(slider, cfg.bg, cfg.border, true)

	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if thumb and thumb.SetVertexColor then
		thumb:SetVertexColor(cfg.thumb[1], cfg.thumb[2], cfg.thumb[3], cfg.thumb[4])
	end

	local name = slider.GetName and slider:GetName() or nil
	local low = name and _G[name .. "Low"] or nil
	local high = name and _G[name .. "High"] or nil
	local text = name and _G[name .. "Text"] or nil
	if low and low.SetTextColor then
		low:SetTextColor(cfg.text[1], cfg.text[2], cfg.text[3], cfg.text[4] or 1)
	end
	if high and high.SetTextColor then
		high:SetTextColor(cfg.text[1], cfg.text[2], cfg.text[3], cfg.text[4] or 1)
	end
	if text and text.SetTextColor then
		text:SetTextColor(cfg.text[1], cfg.text[2], cfg.text[3], cfg.text[4] or 1)
	end

	if not slider.__sufSliderBar and slider.CreateTexture then
		local bar = slider:CreateTexture(nil, "ARTWORK", nil, -1)
		bar:SetTexture("Interface\\Buttons\\WHITE8x8")
		bar:SetVertexColor(cfg.bar[1], cfg.bar[2], cfg.bar[3], cfg.bar[4])
		bar:SetPoint("LEFT", slider, "LEFT", 10, 0)
		bar:SetPoint("RIGHT", slider, "RIGHT", -10, 0)
		bar:SetHeight(2)
		slider.__sufSliderBar = bar
	end
end

function addon:ApplySUFEditBoxSkin(editBox)
	if not (editBox and editBox.GetObjectType and editBox:GetObjectType() == "EditBox") then
		return
	end
	local cfg = THEME.controls and THEME.controls.editbox
	if not cfg then
		return
	end
	self:ApplySUFBackdropColors(editBox, cfg.bg, cfg.border, true)
	if editBox.SetTextColor then
		editBox:SetTextColor(cfg.text[1], cfg.text[2], cfg.text[3], cfg.text[4])
	end
	if editBox.SetTextInsets then
		editBox:SetTextInsets(6, 6, 4, 4)
	end
end

function addon:ApplySUFScrollBarSkin(scrollFrameOrBar)
	if not scrollFrameOrBar or not scrollFrameOrBar.GetObjectType then
		return
	end
	local cfg = THEME.controls and THEME.controls.scrollbar
	if not cfg then
		return
	end

	local scrollBar = scrollFrameOrBar
	if scrollFrameOrBar:GetObjectType() == "ScrollFrame" then
		scrollBar = scrollFrameOrBar.ScrollBar
		if not scrollBar then
			local name = scrollFrameOrBar.GetName and scrollFrameOrBar:GetName() or nil
			if name then
				scrollBar = _G[name .. "ScrollBar"]
			end
		end
	end
	if not (scrollBar and scrollBar.GetObjectType and scrollBar:GetObjectType() == "Slider") then
		return
	end

	addon:ApplySUFSliderSkin(scrollBar)

	local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
	if thumb and thumb.SetVertexColor then
		thumb:SetVertexColor(cfg.thumb[1], cfg.thumb[2], cfg.thumb[3], cfg.thumb[4])
	end

	local up = scrollBar.ScrollUpButton
	local down = scrollBar.ScrollDownButton
	local name = scrollBar.GetName and scrollBar:GetName() or nil
	if not up and name then
		up = _G[name .. "ScrollUpButton"]
	end
	if not down and name then
		down = _G[name .. "ScrollDownButton"]
	end
	if up and up.GetObjectType and up:GetObjectType() == "Button" then
		addon:ApplySUFButtonSkin(up, "subtle")
	end
	if down and down.GetObjectType and down:GetObjectType() == "Button" then
		addon:ApplySUFButtonSkin(down, "subtle")
	end
end

function addon:ApplySUFStatusBarSkin(statusBar)
	if not (statusBar and statusBar.GetObjectType and statusBar:GetObjectType() == "StatusBar") then
		return
	end
	local cfg = THEME.controls and THEME.controls.statusbar
	if not cfg then
		return
	end
	if statusBar.SetStatusBarColor then
		statusBar:SetStatusBarColor(cfg.bar[1], cfg.bar[2], cfg.bar[3], cfg.bar[4])
	end
	local tex = statusBar.GetStatusBarTexture and statusBar:GetStatusBarTexture()
	if tex and tex.SetVertexColor then
		tex:SetVertexColor(cfg.bar[1], cfg.bar[2], cfg.bar[3], cfg.bar[4])
	end
	if not statusBar.__sufStatusBarBG and statusBar.CreateTexture then
		local bg = statusBar:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(statusBar)
		bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		bg:SetVertexColor(cfg.bg[1], cfg.bg[2], cfg.bg[3], cfg.bg[4])
		statusBar.__sufStatusBarBG = bg
	end
end

function addon:ApplySUFControlSkinsInFrame(root, variant)
	if not (root and root.GetNumChildren) then
		return
	end
	local function ApplyRegions(frame)
		if not (frame and frame.GetRegions) then
			return
		end
		local regions = { frame:GetRegions() }
		for i = 1, #regions do
			local region = regions[i]
			if region and region.GetObjectType then
				local regionType = region:GetObjectType()
				if regionType == "FontString" then
					addon:ApplySUFFontStringSkin(region)
				elseif regionType == "Texture" then
					addon:ApplySUFTextureSkin(region)
				end
			end
		end
	end
	local function Walk(parent, depth)
		if depth > 10 then
			return
		end
		ApplyRegions(parent)
		local children = { parent:GetChildren() }
		for i = 1, #children do
			local child = children[i]
			if child and child.GetObjectType then
				local objectType = child:GetObjectType()
				if objectType == "CheckButton" then
					addon:ApplySUFCheckBoxSkin(child)
				elseif objectType == "Slider" then
					addon:ApplySUFSliderSkin(child)
				elseif objectType == "ScrollFrame" then
					addon:ApplySUFScrollBarSkin(child)
				elseif objectType == "StatusBar" then
					addon:ApplySUFStatusBarSkin(child)
				elseif objectType == "EditBox" then
					addon:ApplySUFEditBoxSkin(child)
				elseif objectType == "Button" then
					local buttonVariant = variant
					local childName = child.GetName and child:GetName() or ""
					if tostring(childName):find("Tab", 1, true) then
						buttonVariant = "subtle"
					end
					addon:ApplySUFButtonSkin(child, buttonVariant)
				end
			end
			if child and child.GetNumChildren and child:GetNumChildren() > 0 then
				Walk(child, depth + 1)
			end
		end
	end
	Walk(root, 0)
end

function addon:ApplyThemeToPerformanceWindows()
	local frames = {}
	local function AddFrame(frame)
		if frame and frame.GetObjectType and frame:GetObjectType() == "Frame" then
			frames[#frames + 1] = frame
		end
	end

	local perf = self.performanceLib
	if perf then
		local accessors = { "GetDashboardFrame", "GetFrame", "GetOptionsFrame", "GetMainFrame" }
		for i = 1, #accessors do
			local fn = perf[accessors[i]]
			if type(fn) == "function" then
				local ok, frame = pcall(fn, perf)
				if ok then
					AddFrame(frame)
				end
			end
		end
	end

	local globals = {
		"PerformanceLibDashboard",
		"PerformanceLibFrame",
		"PerformanceLibOptions",
		"PerformanceDashboardFrame",
	}
	for i = 1, #globals do
		AddFrame(_G[globals[i]])
	end

	for i = 1, #frames do
		self:ApplySUFBackdrop(frames[i], "window")
		if self.ApplySUFControlSkinsInFrame then
			self:ApplySUFControlSkinsInFrame(frames[i])
		end
	end
end
