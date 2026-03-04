local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

-- UnitsBuilder: Delegates unit page specs to Registry's BuildUnitCoreSpec helper
local function BuildUnitPageSpec(unitKey)
	if addon.GetOptionsV2UnitCoreSpec then
		return addon:GetOptionsV2UnitCoreSpec(unitKey)
	end
	return nil
end

addon._optionsV2Builders = addon._optionsV2Builders or {}

local unitKeys = { "player", "target", "tot", "focus", "pet", "party", "raid", "boss" }
for i = 1, #unitKeys do
	local key = unitKeys[i]
	addon._optionsV2Builders[key] = function()
		return BuildUnitPageSpec(key)
	end
end
