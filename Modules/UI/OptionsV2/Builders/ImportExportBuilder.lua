local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

-- ImportExportBuilder: Constructs the spec for the "importexport" options page
-- NOTE: This page is listed in GetOptionsV2Pages() but not yet implemented in Registry.lua
-- This builder provides a placeholder until the feature is fully implemented

local function BuildImportExportPageSpec()
	return {
		sections = {
			{
				title = "Import / Export (Coming Soon)",
				desc = "Profile import, export, validation, and previews.",
				controls = {
					{ type = "paragraph", text = "This feature is planned for a future release." },
					{ type = "paragraph", text = "It will allow you to:" },
					{ type = "paragraph", text = "• Export current profile to clipboard" },
					{ type = "paragraph", text = "• Import profile from text" },
					{ type = "paragraph", text = "• Validate profile data structure" },
					{ type = "paragraph", text = "• Preview changes before applying" },
					{
						type = "button",
						label = "Open Global Page",
						onClick = function()
							if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
								addon.optionsV2Frame:SetPage("global")
							end
						end,
					},
				},
			},
		},
	}
end

-- Register builder
addon._optionsV2Builders = addon._optionsV2Builders or {}
addon._optionsV2Builders["importexport"] = BuildImportExportPageSpec
