local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

-- CreditsBuilder: Constructs the spec for the "credits" options page
local function BuildCreditsPageSpec()
	return {
		sections = {
			{
				title = "Credits",
				desc = "Project and library attribution.",
				controls = {
					{ type = "paragraph", text = "SimpleUnitFrames (SUF)\nPrimary Author: Grevin" },
					{ type = "paragraph", text = "Core Framework Credits:\noUF authors and Ace3 community maintainers." },
					{ type = "paragraph", text = "Optional Integration Credits:\nPerformanceLib, LibSharedMedia-3.0, LibDualSpec-1.0, LibDataBroker-1.1, LibDBIcon-1.0." },
					{ type = "paragraph", text = "Utility Library Credits:\nLibSerialize, LibDeflate, LibCustomGlow-1.0, LibSimpleSticky, LibTranslit-1.0, UTF8, TaintLess, LibDispel-1.0." },
					{ type = "paragraph", text = "Reference Credits:\nGethe/wow-ui-source and Warcraft Wiki API contributors." },
					{
						type = "button",
						label = "Open README",
						onClick = function()
							if addon.Print then
								addon:Print("SimpleUnitFrames: See README.md for full credits and attribution.")
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
addon._optionsV2Builders["credits"] = BuildCreditsPageSpec
