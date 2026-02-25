local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local UNIT_SECTION_NAV = {
	{ key = "general", label = "General" },
	{ key = "bars", label = "Bars" },
	{ key = "castbar", label = "Castbar" },
	{ key = "auras", label = "Auras" },
	{ key = "plugins", label = "Plugins" },
	{ key = "advanced", label = "Advanced" },
}

local UNIT_SUB_TABS = {
	{ key = "all", label = "All" },
	{ key = "general", label = "General" },
	{ key = "bars", label = "Bars" },
	{ key = "castbar", label = "Castbar" },
	{ key = "auras", label = "Auras" },
	{ key = "plugins", label = "Plugins" },
	{ key = "advanced", label = "Advanced" },
}

function addon:GetOptionsUnitSectionNav()
	return UNIT_SECTION_NAV
end

function addon:GetOptionsUnitSubTabs()
	return UNIT_SUB_TABS
end
