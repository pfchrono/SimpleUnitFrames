local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local function CopyTableDeepLocal(source)
	local out = {}
	for key, value in pairs(source or {}) do
		out[key] = (type(value) == "table") and CopyTableDeepLocal(value) or value
	end
	return out
end

local REPEATING_SUFFIXES = {
	"",
	".NineSlice",
	".NineSlice.TopEdge",
	".NineSlice.RightEdge",
	".NineSlice.LeftEdge",
	".NineSlice.BottomEdge",
	".NineSlice.TopRightCorner",
	".NineSlice.TopLeftCorner",
	".NineSlice.BottomRightCorner",
	".NineSlice.BottomLeftCorner",
	".Inset",
	".Inset.Bg",
	".Inset.NineSlice",
	".Inset.NineSlice.TopEdge",
	".Inset.NineSlice.RightEdge",
	".Inset.NineSlice.LeftEdge",
	".Inset.NineSlice.BottomEdge",
	".Inset.NineSlice.TopRightCorner",
	".Inset.NineSlice.TopLeftCorner",
	".Inset.NineSlice.BottomRightCorner",
	".Inset.NineSlice.BottomLeftCorner",
	".ScrollBar.Background",
}

local REGISTRY = {
	groups = {
		spellbook = {
			"PlayerSpellsFrame.SpellBookFrame.BookBGHalved",
			"PlayerSpellsFrame.SpellBookFrame.BookBGLeft",
			"PlayerSpellsFrame.SpellBookFrame.BookBGRight",
			"PlayerSpellsFrame.SpellBookFrame.BookCornerFlipbook",
		},
		map = {
			"WorldMapFrame.BorderFrame",
			"WorldMapFrame.MiniBorderFrame",
		},
		professions = {
			"ProfessionsFrame.TabSystem",
			"ProfessionsFrame.CraftingPage.CraftingOutputLog",
			"ProfessionsBookFrame",
			"ProfessionsCustomerOrdersFrame",
		},
		guild = {
			"CommunitiesFrame.GuildMemberDetailFrame.Border",
			"CommunitiesFrame.Chat.MessageFrame.ScrollBar",
		},
		achievement = {
			"WeeklyRewardsFrame.BorderContainer",
			"WeeklyRewardsFrame.SelectRewardButton.Background",
		},
		calendar = {
			"TimeManagerFrame",
			"StopwatchFrame",
			"TimeManagerClockButton",
		},
		lfg = {
			"CompactRaidFrameManager",
			"CompactRaidFrameManagerDisplayFrame",
			"RolePollPopup",
		},
	},
	repeatingRootsByGroup = {
		map = { "WorldMapFrame", "QuestMapFrame" },
		spellbook = { "PlayerSpellsFrame", "ClassTalentFrame" },
		professions = { "ProfessionsFrame" },
		achievement = { "WeeklyRewardsFrame" },
		guild = { "CommunitiesFrame" },
	},
	requiredAddons = {
		Blizzard_TimeManager = true,
	},
	groupAddons = {
		calendar = { "Blizzard_TimeManager" },
	},
	textureBlocklist = {
		["Interface\\QuestFrame\\UI-QuestLog-BookIcon"] = true,
		["Interface\\Spellbook\\Spellbook-Icon"] = true,
		["Interface\\FriendsFrame\\FriendsFrameScrollIcon"] = true,
		["Interface\\MacroFrame\\MacroFrame-Icon"] = true,
		["Interface\\TimeManager\\GlobeIcon"] = true,
		["Interface\\MailFrame\\Mail-Icon"] = true,
		["Interface\\ContainerFrame\\UI-Bag-1Slot"] = true,
		["Interface\\SpellBook\\SpellBook-SkillLineTab-Glow"] = true,
		[130724] = true,
		[136797] = true,
		[131116] = true,
		[136382] = true,
		[130709] = true,
		[136830] = true,
	},
	textureAllowlist = {
		-- Explicitly permit known chrome assets when blocklist heuristics would otherwise skip.
		["Interface\\DialogFrame\\UI-DialogBox-Gold-Background"] = true,
		["UI-Frame-OrnateMetal-Border"] = true,
	},
}

local cachedRegistry = nil

function addon:GetBlizzardSkinRegistry()
	if cachedRegistry then
		return cachedRegistry
	end

	local out = CopyTableDeepLocal(REGISTRY)
	out.groups = out.groups or {}

	local rootsByGroup = out.repeatingRootsByGroup or {}
	for groupKey, roots in pairs(rootsByGroup) do
		if type(groupKey) == "string" and type(roots) == "table" then
			out.groups[groupKey] = out.groups[groupKey] or {}
			local groupList = out.groups[groupKey]
			for i = 1, #roots do
				local root = roots[i]
				if type(root) == "string" and root ~= "" then
					for s = 1, #REPEATING_SUFFIXES do
						groupList[#groupList + 1] = root .. REPEATING_SUFFIXES[s]
					end
				end
			end
		end
	end

	cachedRegistry = out
	return cachedRegistry
end
