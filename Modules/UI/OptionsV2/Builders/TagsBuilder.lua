local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

-- TagsBuilder: Constructs the spec for the "tags" options page

-- Local constants and helpers (copied from Registry.lua for self-containment)
local UNIT_LABELS = {
	player = "Player",
	target = "Target",
	tot = "TargetOfTarget",
	focus = "Focus",
	pet = "Pet",
	party = "Party",
	raid = "Raid",
	boss = "Boss",
}

local UNIT_TYPE_ORDER = { "player", "target", "tot", "focus", "pet", "party", "raid", "boss" }

local function GetUnitLabel(unitKey)
	return UNIT_LABELS[unitKey] or tostring(unitKey or "Unit")
end

local function CollectOUFTagsLocal()
	local ouf = addon.oUF or (_G and _G.oUF)
	if not (ouf and ouf.Tags and ouf.Tags.Methods) then
		return {}
	end
	local tagsList = {}
	for tagName in pairs(ouf.Tags.Methods) do
		if type(tagName) == "string" then
			tagsList[#tagsList + 1] = tagName
		end
	end
	table.sort(tagsList)
	return tagsList
end

local function CategorizeTagLocal(tagName)
	local t = string.lower(tagName or "")
	if t:find("health", 1, true) or t:find("hp", 1, true) or t:find("absorb", 1, true) then
		return "Health"
	end
	if t:find("power", 1, true) or t:find("pp", 1, true) or t:find("mana", 1, true) or t:find("energy", 1, true) or t:find("rage", 1, true) or t:find("rune", 1, true) then
		return "Power"
	end
	if t:find("cast", 1, true) or t:find("channel", 1, true) then
		return "Cast"
	end
	if t:find("aura", 1, true) or t:find("buff", 1, true) or t:find("debuff", 1, true) then
		return "Auras"
	end
	if t:find("threat", 1, true) or t:find("combat", 1, true) or t:find("status", 1, true) or t:find("dead", 1, true) or t:find("offline", 1, true) then
		return "Status"
	end
	if t:find("name", 1, true) or t:find("level", 1, true) or t:find("class", 1, true) or t:find("race", 1, true) then
		return "Identity"
	end
	return "Other"
end

-- Main builder function
local function BuildTagsPageSpec()
	local function TagWidthCharsFor(unitKey, fieldKey)
		local tags = addon.db.profile.tags[unitKey] or {}
		local value = tostring(tags[fieldKey] or "")
		return math.max(12, math.min(48, #value + 2))
	end

	local function GetTagsSection()
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.tags = cfg.sectionState.tags or "overview"
		return tostring(cfg.sectionState.tags)
	end
	local function SetTagsSection(key)
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.tags = tostring(key or "overview")
	end

	local sections = {
		{
			tab = "overview",
			title = "Tags Overview",
			desc = "Edit per-unit tag strings directly in V2.",
			controls = {
				{ type = "paragraph", text = "Use oUF tags and SUF custom tags in fields below. Example: [raidcolor][name] [suf:status]" },
			},
		},
	}
	local function BuildCategoryTagText(category)
		local tags = CollectOUFTagsLocal()
		local filtered = {}
		for i = 1, #tags do
			if CategorizeTagLocal(tags[i]) == category then
				filtered[#filtered + 1] = tags[i]
			end
		end
		return table.concat(filtered, ", ")
	end
	local function BuildTagDump(prefix)
		local tags = CollectOUFTagsLocal()
		local out = {}
		for i = 1, #tags do
			local tag = tags[i]
			if not prefix or tag:sub(1, #prefix) == prefix then
				out[#out + 1] = "[" .. tag .. "]"
			end
		end
		return table.concat(out, ", ")
	end
	local function BuildReferenceControls()
		local controls = {
			{ type = "paragraph", text = "Each tag below has its own copy field. Click and copy directly." },
		}
		local tags = CollectOUFTagsLocal()
		local grouped = {
			Identity = {},
			Health = {},
			Power = {},
			Cast = {},
			Auras = {},
			Status = {},
			Other = {},
		}
		for i = 1, #tags do
			local tag = tags[i]
			local category = CategorizeTagLocal(tag)
			grouped[category] = grouped[category] or {}
			grouped[category][#grouped[category] + 1] = tag
		end
		local ordered = { "Identity", "Health", "Power", "Cast", "Auras", "Status", "Other" }
		for i = 1, #ordered do
			local category = ordered[i]
			local list = grouped[category]
			if list and #list > 0 then
				controls[#controls + 1] = { type = "label", text = category .. " Tags" }
				for j = 1, #list do
					local wrapped = "[" .. tostring(list[j]) .. "]"
					controls[#controls + 1] = {
						type = "edit",
						label = wrapped,
						widthChars = #wrapped + 2,
						get = function()
							return wrapped
						end,
						set = function() end,
					}
				end
			end
		end
		return controls
	end
	for i = 1, #UNIT_TYPE_ORDER do
		local unitKey = UNIT_TYPE_ORDER[i]
		local uk = unitKey
		local unitLabel = GetUnitLabel(uk)
		sections[#sections + 1] = {
			tab = "units",
			title = unitLabel,
			desc = "Tag strings for " .. unitLabel .. ".",
			controls = {
				{
					type = "edit",
					label = "Name Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "name")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.name or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].name = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
				{
					type = "edit",
					label = "Level Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "level")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.level or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].level = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
				{
					type = "edit",
					label = "Health Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "health")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.health or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].health = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
				{
					type = "edit",
					label = "Power Tag",
					widthChars = function()
						return TagWidthCharsFor(uk, "power")
					end,
					get = function()
						local tags = addon.db.profile.tags[uk] or {}
						return tags.power or ""
					end,
					set = function(v)
						addon.db.profile.tags[uk] = addon.db.profile.tags[uk] or {}
						addon.db.profile.tags[uk].power = tostring(v or "")
						addon:ScheduleUpdateAll()
					end,
				},
			},
		}
	end
	sections[#sections + 1] = {
		tab = "reference",
		title = "Advanced Reference",
		desc = "Copy-ready oUF/SUF tag containers, including dynamically discovered tags.",
		controls = (function()
			local controls = BuildReferenceControls()
			controls[#controls + 1] = {
				type = "edit",
				label = "SUF Tags (combined)",
				get = function()
					return BuildTagDump("suf:")
				end,
				set = function() end,
			}
			controls[#controls + 1] = {
				type = "edit",
				label = "All oUF/SUF Tags (combined)",
				get = function()
					return BuildTagDump(nil)
				end,
				set = function() end,
			}
			controls[#controls + 1] = {
				type = "button",
				label = "Open Performance Page",
				onClick = function()
					if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then
						addon.optionsV2Frame:SetPage("performance")
					end
				end,
			}
			return controls
		end)(),
	}
	return {
		sectionTabs = {
			{ key = "overview", label = "Overview" },
			{ key = "units", label = "Units" },
			{ key = "reference", label = "Reference" },
			{ key = "all", label = "All" },
		},
		getActiveSection = GetTagsSection,
		setActiveSection = SetTagsSection,
		sections = sections,
	}
end

-- Register builder
addon._optionsV2Builders = addon._optionsV2Builders or {}
addon._optionsV2Builders["tags"] = BuildTagsPageSpec
