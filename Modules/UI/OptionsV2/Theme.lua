local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local DEFAULT_OPTIONS_V2 = {
	enabled = true,
	lastPage = "global",
	theme = {
		preset = "classic",
	},
}

local THEME_PRESETS = {
	classic = {
		windowBg = { 0.03, 0.04, 0.05, 0.96 },
		windowBorder = { 0.34, 0.29, 0.15, 0.90 },
		panelBg = { 0.05, 0.06, 0.07, 0.92 },
		panelBorder = { 0.23, 0.21, 0.15, 0.92 },
		accent = { 0.96, 0.82, 0.24 },
		accentSoft = { 0.72, 0.64, 0.32 },
		textMuted = { 0.72, 0.74, 0.78 },
		navDefault = { 0.08, 0.08, 0.08, 0.88 },
		navDefaultBorder = { 0.18, 0.18, 0.18, 0.95 },
		navHover = { 0.12, 0.13, 0.16, 0.92 },
		navHoverBorder = { 0.34, 0.31, 0.22, 0.95 },
		navSelected = { 0.12, 0.36, 0.58, 0.95 },
		navSelectedBorder = { 0.28, 0.60, 0.88, 0.95 },
	},
	midnight = {
		windowBg = { 0.07, 0.05, 0.16, 0.97 },
		windowBorder = { 0.45, 0.35, 0.64, 0.96 },
		panelBg = { 0.10, 0.07, 0.22, 0.94 },
		panelBorder = { 0.40, 0.31, 0.58, 0.95 },
		accent = { 0.78, 0.66, 1.00 },
		accentSoft = { 0.58, 0.47, 0.86 },
		textMuted = { 0.82, 0.80, 0.92 },
		navDefault = { 0.12, 0.08, 0.24, 0.90 },
		navDefaultBorder = { 0.29, 0.23, 0.44, 0.95 },
		navHover = { 0.18, 0.12, 0.33, 0.93 },
		navHoverBorder = { 0.48, 0.38, 0.72, 0.96 },
		navSelected = { 0.22, 0.18, 0.44, 0.97 },
		navSelectedBorder = { 0.70, 0.58, 0.98, 0.98 },
	},
	dark = {
		windowBg = { 0.02, 0.02, 0.03, 0.98 },
		windowBorder = { 0.18, 0.20, 0.24, 0.95 },
		panelBg = { 0.04, 0.05, 0.06, 0.94 },
		panelBorder = { 0.16, 0.18, 0.22, 0.95 },
		accent = { 0.43, 0.72, 1.00 },
		accentSoft = { 0.30, 0.54, 0.78 },
		textMuted = { 0.70, 0.74, 0.82 },
		navDefault = { 0.07, 0.08, 0.10, 0.92 },
		navDefaultBorder = { 0.15, 0.18, 0.22, 0.95 },
		navHover = { 0.11, 0.15, 0.22, 0.95 },
		navHoverBorder = { 0.24, 0.34, 0.50, 0.95 },
		navSelected = { 0.11, 0.26, 0.42, 0.98 },
		navSelectedBorder = { 0.33, 0.56, 0.85, 0.98 },
	},
}

function addon:EnsureOptionsV2Config()
	self.db = self.db or {}
	self.db.profile = self.db.profile or {}
	self.db.profile.optionsUIV2 = self.db.profile.optionsUIV2 or {}

	local cfg = self.db.profile.optionsUIV2
	if cfg.enabled == nil then
		cfg.enabled = DEFAULT_OPTIONS_V2.enabled
	end
	if type(cfg.lastPage) ~= "string" or cfg.lastPage == "" then
		cfg.lastPage = DEFAULT_OPTIONS_V2.lastPage
	end
	cfg.theme = cfg.theme or {}
	if type(cfg.theme.preset) ~= "string" or cfg.theme.preset == "" then
		cfg.theme.preset = DEFAULT_OPTIONS_V2.theme.preset
	end
	cfg.navState = cfg.navState or {}
	cfg.sectionState = cfg.sectionState or {}
	return cfg
end

function addon:IsOptionsV2Enabled()
	local cfg = self:EnsureOptionsV2Config()
	return cfg.enabled == true
end

function addon:SetOptionsV2Enabled(enabled, silent)
	local cfg = self:EnsureOptionsV2Config()
	cfg.enabled = enabled and true or false
	if not silent then
		self:Print("SimpleUnitFrames: Options UI mode set to " .. (cfg.enabled and "V2." or "legacy."))
	end
end

function addon:GetOptionsV2Style()
	local base = (self.GetOptionsUIStyle and self:GetOptionsUIStyle()) or {}
	local cfg = self:EnsureOptionsV2Config()
	local presetName = (cfg and cfg.theme and cfg.theme.preset) or "classic"
	local preset = THEME_PRESETS[presetName] or THEME_PRESETS.classic
	return {
		windowBg = preset.windowBg or base.windowBg or { 0.03, 0.04, 0.05, 0.96 },
		windowBorder = preset.windowBorder or base.windowBorder or { 0.34, 0.29, 0.15, 0.90 },
		panelBg = preset.panelBg or base.panelBg or { 0.05, 0.06, 0.07, 0.92 },
		panelBorder = preset.panelBorder or base.panelBorder or { 0.23, 0.21, 0.15, 0.92 },
		accent = preset.accent or base.accent or { 0.96, 0.82, 0.24 },
		accentSoft = preset.accentSoft or base.accentSoft or { 0.72, 0.64, 0.32 },
		textMuted = preset.textMuted or base.textMuted or { 0.72, 0.74, 0.78 },
		navDefault = preset.navDefault or base.navDefault or { 0.08, 0.08, 0.08, 0.88 },
		navDefaultBorder = preset.navDefaultBorder or base.navDefaultBorder or { 0.18, 0.18, 0.18, 0.95 },
		navHover = preset.navHover or base.navHover or { 0.12, 0.13, 0.16, 0.92 },
		navHoverBorder = preset.navHoverBorder or base.navHoverBorder or { 0.34, 0.31, 0.22, 0.95 },
		navSelected = preset.navSelected or base.navSelected or { 0.12, 0.36, 0.58, 0.95 },
		navSelectedBorder = preset.navSelectedBorder or base.navSelectedBorder or { 0.28, 0.60, 0.88, 0.95 },
	}
end
