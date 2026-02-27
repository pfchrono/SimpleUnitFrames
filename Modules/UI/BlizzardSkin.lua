local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local SKINNABLE_FRAMES = {
	character = { "CharacterFrame", "InspectFrame" },
	spellbook = {
		"SpellBookFrame",
		"PlayerSpellsFrame",
		"PlayerSpellsFrame.SpellBookFrame",
		"PlayerSpellsFrame.TalentsFrame",
		"PlayerSpellsFrame.SpecFrame",
		"PlayerSpellsFrame.HeroTalentsContainer",
		"ClassTalentFrame",
		"ClassTalentFrame.TalentsTab",
		"ClassTalentFrame.SpecTab",
		"ClassTalentFrame.HeroTalentsTab",
		"ClassTalentLoadoutDialog",
		"ClassTalentLoadoutEditDialog",
		"ClassTalentLoadoutImportDialog",
		"ClassTalentLoadoutViewDialog",
		"HeroTalentsSelectionDialog",
	},
	collections = { "CollectionsJournal", "MountJournal", "PetJournal", "PetJournalParent", "ToyBox", "HeirloomsJournal", "WardrobeCollectionFrame", "WardrobeFrame" },
	questlog = { "QuestLogFrame", "QuestMapFrame" },
	lfg = { "LFDParentFrame", "PVEFrame", "PVPQueueFrame", "HonorFrame", "ConquestFrame", "RolePollPopup", "CompactRaidFrameManager", "CompactRaidFrameManagerDisplayFrame" },
	map = { "WorldMapFrame", "WorldMapFrame.BorderFrame", "WorldMapFrame.NavBar", "WorldMapFrame.ScrollContainer", "QuestMapFrame", "QuestMapFrame.DetailsFrame", "QuestMapFrame.QuestsFrame", "FlightMapFrame" },
	calendar = { "CalendarFrame", "TimeManagerFrame", "StopwatchFrame", "TimeManagerClockButton" },
	professions = { "ProfessionsFrame", "ProfessionsFrame.CraftingPage", "ProfessionsFrame.SpecPage", "ProfessionsFrame.OrdersPage", "ProfessionsFrame.RecipeList", "TradeSkillFrame", "ProfessionsBookFrame", "ProfessionsCustomerOrdersFrame" },
	dressup = { "DressUpFrame", "SideDressUpFrame" },
	gossip = { "GossipFrame" },
	merchant = { "MerchantFrame" },
	mail = { "MailFrame", "OpenMailFrame", "SendMailFrame" },
	economy = { "AuctionHouseFrame", "VoidStorageFrame", "ItemSocketingFrame", "TradeFrame", "ReforgingFrame" },
	friends = { "FriendsFrame", "SocialFrame", "WhoFrame", "ChannelFrame" },
	guild = {
		"GuildFrame",
		"CommunitiesFrame",
		"LookingForGuildFrame",
		"CommunitiesFrame.GuildFinderFrame",
		"CommunitiesFrame.Chat",
		"CommunitiesFrame.Chat.InsetFrame",
		"CommunitiesFrame.MemberList",
		"CommunitiesFrame.GuildBenefitsFrame",
		"CommunitiesFrame.GuildInfoFrame",
		"CommunitiesFrame.NotificationSettingsDialog",
		"CommunitiesFrame.ChatTab",
		"CommunitiesFrame.RosterTab",
		"CommunitiesFrame.GuildBenefitsTab",
		"CommunitiesFrame.GuildInfoTab",
	},
	housing = { "HousingDashboardFrame", "HouseEditorFrame", "HousingHouseSettingsFrame", "HousingModelPreviewFrame" },
	achievement = { "AchievementFrame", "WeeklyRewardsFrame", "WeeklyRewardsFrame.BorderContainer", "WeeklyRewardsFrame.SelectRewardFrame", "PVPMatchResults", "PVPMatchScoreboard" },
	encounter = { "EncounterJournal" },
}

local REQUIRED_ADDONS = {
	Blizzard_AchievementUI = true,
	Blizzard_Collections = true,
	Blizzard_EncounterJournal = true,
	Blizzard_FriendsFrame = true,
	Blizzard_GuildUI = true,
	Blizzard_InspectUI = true,
	Blizzard_Communities = true,
	Blizzard_MerchantUI = true,
	Blizzard_AuctionHouseUI = true,
	Blizzard_Calendar = true,
	Blizzard_ChallengesUI = true,
	Blizzard_PVPMatch = true,
	Blizzard_PVPUI = true,
	Blizzard_ReforgingUI = true,
	Blizzard_QuestLog = true,
	Blizzard_PlayerSpells = true,
	Blizzard_TalentUI = true,
	Blizzard_TimeManager = true,
	Blizzard_TradeSkillUI = true,
	Blizzard_WeeklyRewards = true,
	Blizzard_VoidStorageUI = true,
	Blizzard_WorldMap = true,
}

local GROUP_ADDONS = {
	character = { "Blizzard_CharacterUI", "Blizzard_InspectUI" },
	spellbook = { "Blizzard_PlayerSpells", "Blizzard_TalentUI" },
	collections = { "Blizzard_Collections" },
	questlog = { "Blizzard_QuestLog" },
	lfg = { "Blizzard_PVPUI", "Blizzard_ChallengesUI", "Blizzard_PVPMatch" },
	map = { "Blizzard_WorldMap" },
	calendar = { "Blizzard_Calendar", "Blizzard_TimeManager" },
	professions = { "Blizzard_Professions", "Blizzard_TradeSkillUI" },
	dressup = { "Blizzard_DressUpFrame" },
	gossip = { "Blizzard_GossipUI" },
	merchant = { "Blizzard_MerchantUI" },
	mail = { "Blizzard_MailUI" },
	economy = { "Blizzard_AuctionHouseUI", "Blizzard_VoidStorageUI", "Blizzard_ReforgingUI" },
	friends = { "Blizzard_FriendsFrame", "Blizzard_Communities" },
	guild = { "Blizzard_GuildUI", "Blizzard_Communities" },
	housing = {},
	achievement = { "Blizzard_AchievementUI", "Blizzard_WeeklyRewards", "Blizzard_PVPMatch" },
	encounter = { "Blizzard_EncounterJournal" },
}

local TEXTURE_BLOCKLIST = {}
local TEXTURE_ALLOWLIST = {}
local SKIN_REGISTRY_MERGED = false
local ACTIVE_APPLY_REPORT = nil
local SKINNED_FRAME_BUCKETS = {}
local SKINNED_FRAME_SET = setmetatable({}, { __mode = "k" })

local LAZY_TOPLEVEL_REFS = {
	CollectionsJournal = true,
	MountJournal = true,
	PetJournal = true,
	PetJournalParent = true,
	ToyBox = true,
	HeirloomsJournal = true,
	WardrobeCollectionFrame = true,
	WardrobeFrame = true,
	CalendarFrame = true,
	EncounterJournal = true,
	QuestLogFrame = true,
	InspectFrame = true,
	AuctionHouseFrame = true,
	VoidStorageFrame = true,
	ItemSocketingFrame = true,
	ReforgingFrame = true,
	FlightMapFrame = true,
	PVPQueueFrame = true,
	HonorFrame = true,
	ConquestFrame = true,
}

local LAZY_NESTED_ROOTS = {
	ClassTalentFrame = true,
	ProfessionsFrame = true,
}

local SOFT_NESTED_HINTS = {
	".NineSlice",
	".Inset",
	".MiniBorderFrame",
	".ScrollBar.Background",
}

local SPELLBOOK_TEXTURE_HARD_EXCLUDES = {
	"bookbg",
	"parchment",
	"paper",
	"page",
	"abilitiesbook",
}

local SPELLBOOK_CHROME_ALLOW_HINTS = {
	"nineslice", "border", "edge", "corner", "inset", "header", "title", "navbar", "search", "tab",
}

local SPELLBOOK_CONTENT_EXCLUDE_HINTS = {
	"spell", "ability", "icon", "button", "slot", "row", "list", "container", "backgroundtile", "paper", "bookbg", "parchment",
}

local AGGRESSIVE_INCLUDE_HINTS = {
	"nine", "slice", "frame", "border", "edge", "corner", "inset", "header", "title", "background", "backdrop", "trim", "shadow",
}

local AGGRESSIVE_EXCLUDE_HINTS = {
	"icon", "item", "slot", "portrait", "model", "avatar", "artifact", "reward", "currency",
	"map", "quest", "poi", "pin", "minimap", "blob", "illustration", "splash", "preview",
	"spellicon", "abilitiesbook", "paper", "parchment", "bookbg", "tab", "uipanelbutton",
}

local MAP_CHROME_ALLOW_HINTS = {
	"borderframe", "navbar", "nineslice", "inset", "scrollbar", "header", "title", "edge", "corner",
}

local MAP_CONTENT_EXCLUDE_HINTS = {
	"worldmap", "questmap", "mapcanvas", "maptile", "mapoverlay", "poi", "pin", "cursor", "fog",
}

local function AddUniqueString(list, value)
	if type(value) ~= "string" or value == "" then
		return
	end
	for i = 1, #list do
		if list[i] == value then
			return
		end
	end
	list[#list + 1] = value
end

local function MergeSkinRegistryData()
	if SKIN_REGISTRY_MERGED then
		return
	end
	SKIN_REGISTRY_MERGED = true
	if not addon.GetBlizzardSkinRegistry then
		return
	end
	local registry = addon:GetBlizzardSkinRegistry()
	if type(registry) ~= "table" then
		return
	end

	local groups = registry.groups
	if type(groups) == "table" then
		for groupKey, refs in pairs(groups) do
			if type(groupKey) == "string" and type(refs) == "table" then
				SKINNABLE_FRAMES[groupKey] = SKINNABLE_FRAMES[groupKey] or {}
				for i = 1, #refs do
					AddUniqueString(SKINNABLE_FRAMES[groupKey], refs[i])
				end
			end
		end
	end

	local required = registry.requiredAddons
	if type(required) == "table" then
		for addonName, enabled in pairs(required) do
			if enabled == true and type(addonName) == "string" and addonName ~= "" then
				REQUIRED_ADDONS[addonName] = true
			end
		end
	end

	local groupAddons = registry.groupAddons
	if type(groupAddons) == "table" then
		for groupKey, addonList in pairs(groupAddons) do
			if type(groupKey) == "string" and type(addonList) == "table" then
				GROUP_ADDONS[groupKey] = GROUP_ADDONS[groupKey] or {}
				for i = 1, #addonList do
					AddUniqueString(GROUP_ADDONS[groupKey], addonList[i])
				end
			end
		end
	end

	local blocklist = registry.textureBlocklist
	if type(blocklist) == "table" then
		for key, value in pairs(blocklist) do
			if value == true then
				TEXTURE_BLOCKLIST[key] = true
			end
		end
	end

	local allowlist = registry.textureAllowlist
	if type(allowlist) == "table" then
		for key, value in pairs(allowlist) do
			if value == true then
				TEXTURE_ALLOWLIST[key] = true
			end
		end
	end
end

MergeSkinRegistryData()

local function AddReportSample(report, key, value, maxCount)
	if not (report and type(key) == "string" and type(value) == "string" and value ~= "") then
		return
	end
	report[key] = report[key] or {}
	local list = report[key]
	local limit = tonumber(maxCount) or 12
	if #list >= limit then
		return
	end
	for i = 1, #list do
		if list[i] == value then
			return
		end
	end
	list[#list + 1] = value
end

local function CopyTableDeepLocal(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = (type(value) == "table") and CopyTableDeepLocal(value) or value
	end
	return copy
end

local function Increment(report, key)
	if not report then
		return
	end
	report[key] = (report[key] or 0) + 1
end

local function GetDomainReport(report, domainKey)
	if not (report and type(domainKey) == "string" and domainKey ~= "") then
		return nil
	end
	report.domains = report.domains or {}
	local domain = report.domains[domainKey]
	if not domain then
		domain = {
			seen = 0,
			applied = 0,
			missing = 0,
			protected = 0,
			forbidden = 0,
			already = 0,
		}
		report.domains[domainKey] = domain
	end
	return domain
end

local function TrackSkinnedFrame(groupKey, frame)
	if not frame then
		return
	end
	local bucketKey = (type(groupKey) == "string" and groupKey ~= "") and groupKey or "__adhoc"
	local bucket = SKINNED_FRAME_BUCKETS[bucketKey]
	if not bucket then
		bucket = {}
		SKINNED_FRAME_BUCKETS[bucketKey] = bucket
	end
	if not SKINNED_FRAME_SET[frame] then
		SKINNED_FRAME_SET[frame] = true
		bucket[#bucket + 1] = frame
	end
end

local function IsBlockedValue(value)
	if value == nil then
		return false
	end
	return TEXTURE_BLOCKLIST[value] == true
end

local function IsAllowedValue(value)
	if value == nil then
		return false
	end
	return TEXTURE_ALLOWLIST[value] == true
end

local function SafeGetRegions(owner)
	if not (owner and owner.GetRegions) then
		return {}
	end
	local results = { pcall(owner.GetRegions, owner) }
	if results[1] ~= true then
		return {}
	end
	table.remove(results, 1)
	return results
end

local function SafeGetChildren(owner)
	if not (owner and owner.GetChildren) then
		return {}
	end
	local results = { pcall(owner.GetChildren, owner) }
	if results[1] ~= true then
		return {}
	end
	table.remove(results, 1)
	return results
end

local function SafeGetNumChildren(owner)
	if not (owner and owner.GetNumChildren) then
		return 0
	end
	local ok, count = pcall(owner.GetNumChildren, owner)
	if ok and type(count) == "number" then
		return count
	end
	return 0
end

local function SafeGetObjectType(owner)
	if not (owner and owner.GetObjectType) then
		return nil
	end
	local ok, objectType = pcall(owner.GetObjectType, owner)
	if ok and type(objectType) == "string" then
		return objectType
	end
	return nil
end

local function SafeGetName(owner)
	if not (owner and owner.GetName) then
		return ""
	end
	local ok, name = pcall(owner.GetName, owner)
	if ok and type(name) == "string" then
		return name
	end
	return ""
end

local STRONG_PLUS_INCLUDE_HINTS = {
	"nine", "slice", "frame", "border", "edge", "corner", "inset", "dialog", "panel",
	"background", "backdrop", "bookbg", "parchment", "title", "header", "shadow",
	"titlebg", "title-bg", "portraitframe", "metal", "trim", "decor",
	"ui-", "blizzard", "quest", "character", "paperdoll", "journal", "collections",
	"pve", "lfg", "calendar", "friends", "guild", "merchant", "mail", "auction",
}

local STRONG_PLUS_EXCLUDE_HINTS = {
	"icon", "spellicon", "portrait", "model", "item", "reward", "currency", "avatar",
	"cooldown", "minimap", "bag", "slot", "tab", "button", "uipanelbutton",
	"card", "preview", "splash", "illustration", "scene", "render", "screenshot",
}

local function ContainsHint(text, hints)
	if type(text) ~= "string" then
		return false
	end
	local lowered = text:lower()
	for i = 1, #hints do
		if lowered:find(hints[i], 1, true) then
			return true
		end
	end
	return false
end

local function GetThemeBackdropStyle(intensity)
	local theme = addon.GetSUFTheme and addon:GetSUFTheme()
	if not theme or not theme.backdrop then
		return nil
	end
	if intensity == "strong" or intensity == "strongplus" then
		return theme.backdrop.panel or theme.backdrop.window or theme.backdrop.subtle
	end
	return theme.backdrop.subtle or theme.backdrop.panel or theme.backdrop.window
end

local function IsContentHeavyGroup(groupKey)
	return groupKey == "spellbook" or groupKey == "map" or groupKey == "encounter" or groupKey == "collections" or groupKey == "calendar"
end

local function ScaleColorAlpha(color, alphaScale)
	if type(color) ~= "table" then
		return color
	end
	local out = { color[1], color[2], color[3], color[4] or 1 }
	out[4] = (out[4] or 1) * (alphaScale or 1)
	return out
end

local function CaptureTextureColor(original, texture)
	if not (original and texture and texture.GetVertexColor) then
		return
	end
	original.textures = original.textures or {}
	if original.textures[texture] then
		return
	end
	local ok, r, g, b, a = pcall(texture.GetVertexColor, texture)
	if ok and r then
		original.textures[texture] = { r, g, b, a }
	end
end

local function TintTexture(original, texture, color, alphaMul)
	if not (texture and texture.SetVertexColor and color) then
		return
	end
	CaptureTextureColor(original, texture)
	texture:SetVertexColor(color[1], color[2], color[3], (color[4] or 1) * (alphaMul or 1))
end

local function CaptureFontColor(original, fontString)
	if not (original and fontString and fontString.GetTextColor) then
		return
	end
	original.fontStrings = original.fontStrings or {}
	if original.fontStrings[fontString] then
		return
	end
	local ok, r, g, b, a = pcall(fontString.GetTextColor, fontString)
	if ok and r then
		original.fontStrings[fontString] = { r, g, b, a }
	end
end

local function ShouldSkipContrastFont(fontString)
	if not fontString then
		return true
	end
	local text = fontString.GetText and fontString:GetText() or nil
	if type(text) == "string" and text:find("|c", 1, true) then
		return true
	end
	local parent = fontString.GetParent and fontString:GetParent() or nil
	local function IsSpellbookTree(node)
		local guard = 0
		while node and guard < 8 do
			local name = SafeGetName(node):lower()
			if name:find("playerspellsframe", 1, true)
				or name:find("spellbookframe", 1, true)
				or name:find("classtalentframe", 1, true) then
				return true
			end
			node = node.GetParent and node:GetParent() or nil
			guard = guard + 1
		end
		return false
	end
	local guard = 0
	while parent and guard < 4 do
		local parentType = SafeGetObjectType(parent) or ""
		if (parentType == "Button" or parentType == "CheckButton") and (not IsSpellbookTree(parent)) then
			return true
		end
		parent = parent.GetParent and parent:GetParent() or nil
		guard = guard + 1
	end
	return false
end

local function GetReadableTextColor(style)
	local bg = style and style.bg
	if type(bg) ~= "table" then
		return { 0.93, 0.93, 0.95, 1 }
	end
	local r = tonumber(bg[1]) or 0.1
	local g = tonumber(bg[2]) or 0.1
	local b = tonumber(bg[3]) or 0.1
	local luminance = (0.299 * r) + (0.587 * g) + (0.114 * b)
	if luminance <= 0.5 then
		return { 0.95, 0.95, 0.97, 1.0 }
	end
	return { 0.10, 0.10, 0.12, 1.0 }
end

local function ApplyContrastAwareTextPass(frame, style, report, groupKey)
	if not (frame and style) then
		return false
	end
	local original = frame.__sufBlizzardSkinOriginal
	local textColor = GetReadableTextColor(style)
	if groupKey == "spellbook" then
		textColor = { 0.97, 0.97, 0.98, 1.0 }
	elseif groupKey == "collections" then
		textColor = { 0.95, 0.95, 0.96, 1.0 }
	elseif groupKey == "calendar" then
		textColor = { 0.95, 0.95, 0.96, 1.0 }
	end
	local changed = false
	local seen = {}

	local function TryApply(fontString)
		if not (fontString and fontString.SetTextColor and not seen[fontString]) then
			return
		end
		seen[fontString] = true
		if groupKey ~= "spellbook" and ShouldSkipContrastFont(fontString) then
			return
		end
		local rawText = fontString.GetText and fontString:GetText() or nil
		if type(rawText) == "string" and rawText:find("|c", 1, true) then
			return
		end
		CaptureFontColor(original, fontString)
		fontString:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
		changed = true
		Increment(report, "contrastTextAdjusted")
	end

	local function Walk(owner, depth)
		if not owner or depth > 6 then
			return
		end
		local regions = SafeGetRegions(owner)
		for i = 1, #regions do
			local region = regions[i]
			if SafeGetObjectType(region) == "FontString" then
				TryApply(region)
			end
		end
		local children = SafeGetChildren(owner)
		for i = 1, #children do
			local child = children[i]
			if SafeGetObjectType(child) == "FontString" then
				TryApply(child)
			end
			Walk(child, depth + 1)
		end
	end

	Walk(frame, 0)
	return changed
end

local function TintKnownTextureKeys(original, owner, keys, color)
	if not (owner and type(keys) == "table" and color) then
		return false
	end
	local changed = false
	for i = 1, #keys do
		local key = keys[i]
		local tex = owner[key]
		if tex and tex.SetVertexColor then
			TintTexture(original, tex, color, 1)
			changed = true
		end
	end
	return changed
end

local function TintNineSlice(original, owner, bgColor, borderColor, tintCenters)
	if not owner then
		return false
	end
	local changed = false
	local ns = owner.NineSlice or owner
	if not ns then
		return false
	end

	local borderKeys = {
		"TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
		"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
		"Border",
	}
	for i = 1, #borderKeys do
		local tex = ns[borderKeys[i]]
		if tex and tex.SetVertexColor and borderColor then
			TintTexture(original, tex, borderColor, 1)
			changed = true
		end
	end

	if tintCenters ~= false then
		local centerKeys = { "Center", "Bg", "Background", "Inset", "TitleBG", "Header" }
		for i = 1, #centerKeys do
			local tex = ns[centerKeys[i]]
			if tex and tex.SetVertexColor and bgColor then
				TintTexture(original, tex, bgColor, 1)
				changed = true
			end
		end
	end

	return changed
end

local function ApplyThemeToFrameTextures(frame, style, groupKey)
	if not (frame and style) then
		return false
	end
	local original = frame.__sufBlizzardSkinOriginal
	local bgColor = style.bg
	local borderColor = style.border
	if groupKey == "spellbook" or groupKey == "encounter" or groupKey == "collections" or groupKey == "calendar" then
		borderColor = ScaleColorAlpha(borderColor, 0.55)
	end
	local changed = false
	local tintCenters = not IsContentHeavyGroup(groupKey)

	if TintNineSlice(original, frame, bgColor, borderColor, tintCenters) then
		changed = true
	end
	local borderKeys = {
		"TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
		"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
		"TopBorder", "BottomBorder", "LeftBorder", "RightBorder",
		"Border", "TopTileStreaks", "PortraitFrame",
	}
	local bgKeys = {
		"Bg", "BG", "Background", "BackgroundTile", "Center",
		"TitleBg", "TitleBG", "InsetBg", "Inset", "Header",
	}
	if TintKnownTextureKeys(original, frame, borderKeys, borderColor) then
		changed = true
	end
	local allowWideBgTint = not IsContentHeavyGroup(groupKey)
	local chromeBgKeys = { "TitleBg", "TitleBG", "Header" }
	if allowWideBgTint and TintKnownTextureKeys(original, frame, bgKeys, bgColor) then
		changed = true
	elseif (not allowWideBgTint) and TintKnownTextureKeys(original, frame, chromeBgKeys, bgColor) then
		changed = true
	end

	local extraTargets = {
		frame.Inset,
		frame.InsetFrame,
		frame.BorderFrame,
		frame.Bg,
		frame.Background,
	}
	for i = 1, #extraTargets do
		if TintNineSlice(original, extraTargets[i], bgColor, borderColor, tintCenters) then
			changed = true
		end
		if TintKnownTextureKeys(original, extraTargets[i], borderKeys, borderColor) then
			changed = true
		end
		if allowWideBgTint and TintKnownTextureKeys(original, extraTargets[i], bgKeys, bgColor) then
			changed = true
		end
		if allowWideBgTint and extraTargets[i] and extraTargets[i].SetVertexColor and bgColor then
			TintTexture(original, extraTargets[i], bgColor, 1)
			changed = true
		end
	end

	return changed
end

local function ChooseStrongPlusTint(style, texture)
	if not (style and texture) then
		return nil
	end
	local name = texture.GetName and texture:GetName() or ""
	local atlas = texture.GetAtlas and texture:GetAtlas() or ""
	local path = texture.GetTexture and texture:GetTexture() or ""
	local probe = table.concat({ tostring(name), tostring(atlas), tostring(path) }, " "):lower()
	local accent = style.border or style.bg
	local bg = style.bg
	local border = style.border or style.bg

	if probe:find("background", 1, true) or probe:find("center", 1, true) or probe:find("inset", 1, true) then
		return bg
	end
	if probe:find("highlight", 1, true) or probe:find("selection", 1, true) then
		return accent
	end
	return border
end

local function IsStrongPlusTextureEligible(texture, aggressive, groupKey)
	if not (texture and texture.GetObjectType and texture:GetObjectType() == "Texture") then
		return false
	end
	if texture.IsForbidden and texture:IsForbidden() then
		return false
	end
	local name = texture.GetName and texture:GetName() or ""
	local atlas = texture.GetAtlas and texture:GetAtlas() or ""
	local path = texture.GetTexture and texture:GetTexture() or ""
	local allowed = IsAllowedValue(path) or IsAllowedValue(name) or IsAllowedValue(atlas)
	if allowed then
		Increment(ACTIVE_APPLY_REPORT, "allowlistBypass")
	end
	if (not allowed) and (IsBlockedValue(path) or IsBlockedValue(name) or IsBlockedValue(atlas)) then
		Increment(ACTIVE_APPLY_REPORT, "blockedByTextureBlocklist")
		local sample = tostring(path or atlas or name or "")
		if sample ~= "" then
			AddReportSample(ACTIVE_APPLY_REPORT, "blockedTextureSamples", sample, 20)
		end
		return false
	end
	local probe = table.concat({ tostring(name), tostring(atlas), tostring(path) }, " ")
	if probe == "" then
		return false
	end
	local loweredProbe = probe:lower()
	local function HasParentNameHint(tex, hints, maxDepth)
		local p = tex and tex.GetParent and tex:GetParent() or nil
		local depth = 0
		while p and depth < (maxDepth or 8) do
			local n = SafeGetName(p):lower()
			if n ~= "" then
				for i = 1, #hints do
					if n:find(hints[i], 1, true) then
						return true
					end
				end
			end
			p = p.GetParent and p:GetParent() or nil
			depth = depth + 1
		end
		return false
	end
	local layer = texture.GetDrawLayer and texture:GetDrawLayer() or nil
	if groupKey == "spellbook" then
		for i = 1, #SPELLBOOK_TEXTURE_HARD_EXCLUDES do
			if loweredProbe:find(SPELLBOOK_TEXTURE_HARD_EXCLUDES[i], 1, true) then
				return false
			end
		end
		local isChrome = ContainsHint(probe, SPELLBOOK_CHROME_ALLOW_HINTS)
		if ContainsHint(probe, SPELLBOOK_CONTENT_EXCLUDE_HINTS) and not isChrome then
			return false
		end
		if HasParentNameHint(texture, { "spell", "ability", "button", "entry", "list", "container", "talent" }, 10) and not isChrome then
			return false
		end
		if layer == "ARTWORK" and not isChrome then
			return false
		end
	end
	if groupKey == "map" then
		local isChrome = ContainsHint(probe, MAP_CHROME_ALLOW_HINTS)
		if ContainsHint(probe, MAP_CONTENT_EXCLUDE_HINTS) and not isChrome then
			return false
		end
		local parent = texture.GetParent and texture:GetParent() or nil
		local guard = 0
		local chromeParent = false
		while parent and guard < 8 do
			local parentName = SafeGetName(parent):lower()
			if parentName ~= "" then
				if parentName:find("borderframe", 1, true)
					or parentName:find("navbar", 1, true)
					or parentName:find("nineslice", 1, true)
					or parentName:find("inset", 1, true)
					or parentName:find("scrollbar", 1, true) then
					chromeParent = true
					break
				end
				if parentName:find("worldmapframe.scrollcontainer", 1, true)
					or parentName:find("worldmapframe.mapcanvas", 1, true)
					or parentName:find("questmapframe.mapframe", 1, true) then
					return false
				end
			end
			parent = parent.GetParent and parent:GetParent() or nil
			guard = guard + 1
		end
		if layer == "ARTWORK" and (not chromeParent) and (not isChrome) then
			return false
		end
	end
	local parent = texture.GetParent and texture:GetParent() or nil
	local guard = 0
	while parent and guard < 6 do
		local parentType = parent.GetObjectType and parent:GetObjectType() or ""
		local parentName = parent.GetName and parent:GetName() or ""
		if parentType == "Button" or parentType == "CheckButton" then
			return false
		end
		if type(parentName) == "string" and parentName ~= "" then
			local lowered = parentName:lower()
			if lowered:find("tab", 1, true) or lowered:find("button", 1, true) then
				return false
			end
		end
		parent = parent.GetParent and parent:GetParent() or nil
		guard = guard + 1
	end
	if (not aggressive) and ContainsHint(probe, STRONG_PLUS_EXCLUDE_HINTS) then
		return false
	end
	if aggressive then
		if ContainsHint(probe, AGGRESSIVE_EXCLUDE_HINTS) then
			return false
		end
		local w = texture.GetWidth and texture:GetWidth() or 0
		local h = texture.GetHeight and texture:GetHeight() or 0
		local isLargeArt = (w >= 220 and h >= 120)
		local isChrome = ContainsHint(probe, AGGRESSIVE_INCLUDE_HINTS)
		if isLargeArt and not isChrome then
			return false
		end
		if layer ~= "BACKGROUND" and layer ~= "BORDER" and (not isChrome) then
			return false
		end
		return true
	end
	local w = texture.GetWidth and texture:GetWidth() or 0
	local h = texture.GetHeight and texture:GetHeight() or 0
	local isLargeArt = (w >= 180 and h >= 90)
	if isLargeArt then
		local isKnownChrome = loweredProbe:find("border", 1, true)
			or loweredProbe:find("edge", 1, true)
			or loweredProbe:find("corner", 1, true)
			or loweredProbe:find("title", 1, true)
			or loweredProbe:find("header", 1, true)
			or loweredProbe:find("nineslice", 1, true)
		if not isKnownChrome then
			return false
		end
	end
	if not ContainsHint(probe, STRONG_PLUS_INCLUDE_HINTS) then
		if w < 64 and h < 64 then
			return false
		end
		local layer = texture.GetDrawLayer and texture:GetDrawLayer() or nil
		if layer ~= "BACKGROUND" and layer ~= "BORDER" and layer ~= "ARTWORK" then
			return false
		end
	end
	return true
end

local function ResolveFrameReference(ref)
	if type(ref) ~= "string" or ref == "" then
		return nil
	end
	if not ref:find(".", 1, true) then
		return _G[ref]
	end
	local obj = _G
	for segment in ref:gmatch("[^%.]+") do
		if obj == nil then
			return nil
		end
		local ok, nextObj = pcall(function()
			return obj[segment]
		end)
		if not ok then
			return nil
		end
		obj = nextObj
		if obj == nil then
			return nil
		end
	end
	return obj
end

local function ApplyStrongPlusTexturePass(frame, style, report, groupKey)
	if not (frame and style) then
		return false
	end
	local original = frame.__sufBlizzardSkinOriginal
	local changed = false
	local cfg = (addon and addon.GetBlizzardSkinSettings) and addon:GetBlizzardSkinSettings() or {}
	local labMode = cfg and cfg.labMode == true
	local aggressive = labMode and cfg and cfg.aggressiveRecursive == true
	local reassertHooks = labMode and cfg and cfg.aggressiveReassertHooks == true
	local hookBudget = 4000

	local function IsAncestorSkinned(owner)
		local node = owner
		local guard = 0
		while node and guard < 8 do
			if node.__sufBlizzardSkinned then
				return true
			end
			node = node.GetParent and node:GetParent() or nil
			guard = guard + 1
		end
		return false
	end

	local function EnsureTextureReassertHook(texture)
		if not (hooksecurefunc and texture and texture.SetVertexColor) then
			return
		end
		if texture.__sufStrongPlusHooked == true then
			return
		end
		if (tonumber(report and report.reassertHooked) or 0) >= hookBudget then
			Increment(report, "reassertHookBudgetDrops")
			return
		end
		hooksecurefunc(texture, "SetVertexColor", function(sel, _, _, _, a)
			if not sel or sel.__sufStrongPlusApplying then
				return
			end
			if not (addon and addon.GetBlizzardSkinSettings) then
				return
			end
			local currentCfg = addon:GetBlizzardSkinSettings()
			if not currentCfg or currentCfg.enabled ~= true then
				return
			end
			if tostring(currentCfg.intensity or "subtle") ~= "strongplus" then
				return
			end
			if currentCfg.labMode ~= true or currentCfg.aggressiveReassertHooks ~= true then
				return
			end
			if not IsAncestorSkinned(sel.GetParent and sel:GetParent() or nil) then
				return
			end
			local sName = (sel.GetName and sel:GetName() or ""):lower()
			local sAtlas = (sel.GetAtlas and sel:GetAtlas() or ""):lower()
			local sPath = tostring(sel.GetTexture and sel:GetTexture() or ""):lower()
			local sProbe = table.concat({ sName, sAtlas, sPath }, " ")
			local sw = sel.GetWidth and sel:GetWidth() or 0
			local sh = sel.GetHeight and sel:GetHeight() or 0
			local isChrome = sProbe:find("border", 1, true)
				or sProbe:find("edge", 1, true)
				or sProbe:find("corner", 1, true)
				or sProbe:find("nineslice", 1, true)
				or sProbe:find("trim", 1, true)
				or sProbe:find("header", 1, true)
			if (sw >= 220 and sh >= 120) and (not isChrome) then
				return
			end
			local contentHints = {
				"playerspellsframe", "classtalentframe", "worldmapframe", "questmapframe",
				"spellbook", "talent", "spec", "specialization", "card", "paper", "parchment", "mapcanvas",
			}
			for i = 1, #contentHints do
				if sProbe:find(contentHints[i], 1, true) then
					return
				end
			end
			local parent = sel.GetParent and sel:GetParent() or nil
			local guard = 0
			while parent and guard < 8 do
				local pname = SafeGetName(parent):lower()
				if pname:find("playerspellsframe", 1, true)
					or pname:find("classtalentframe", 1, true)
					or pname:find("worldmapframe", 1, true)
					or pname:find("questmapframe", 1, true)
					or pname:find("spec", 1, true)
					or pname:find("talent", 1, true)
					or pname:find("card", 1, true) then
					return
				end
				parent = parent.GetParent and parent:GetParent() or nil
				guard = guard + 1
			end
			local currentStyle = GetThemeBackdropStyle("strongplus")
			local override = ChooseStrongPlusTint(currentStyle, sel)
			if not override then
				return
			end
			sel.__sufStrongPlusApplying = true
			sel:SetVertexColor(override[1], override[2], override[3], tonumber(a) or (override[4] or 1))
			sel.__sufStrongPlusApplying = nil
			Increment(ACTIVE_APPLY_REPORT, "reassertCalls")
		end)
		texture.__sufStrongPlusHooked = true
		Increment(report, "reassertHooked")
	end

	local function ApplyRegions(owner)
		if not (owner and owner.GetRegions) then
			return
		end
		local regions = SafeGetRegions(owner)
		for i = 1, #regions do
			local region = regions[i]
			if IsStrongPlusTextureEligible(region, aggressive, groupKey) then
				local tint = ChooseStrongPlusTint(style, region)
				if tint then
					TintTexture(original, region, tint, 1)
					if reassertHooks then
						EnsureTextureReassertHook(region)
					end
					changed = true
					Increment(report, "strongPlusTextures")
				end
			end
		end
	end

	local function Walk(owner, depth)
		if not owner or depth > 5 then
			return
		end
		ApplyRegions(owner)
		if not owner.GetChildren then
			return
		end
		local children = SafeGetChildren(owner)
		for i = 1, #children do
			Walk(children[i], depth + 1)
		end
	end

	Increment(report, "strongPlusPasses")
	Walk(frame, 0)
	return changed
end

local function ApplyControlSkinsWithoutButtons(root, variant)
	if not (root and root.GetNumChildren) then
		return
	end
	local function Walk(parent, depth)
		if depth > 8 then
			return
		end
		local children = SafeGetChildren(parent)
		for i = 1, #children do
			local child = children[i]
			local objectType = SafeGetObjectType(child)
			if objectType == "CheckButton" and addon.ApplySUFCheckBoxSkin then
				addon:ApplySUFCheckBoxSkin(child)
			elseif objectType == "Slider" and addon.ApplySUFSliderSkin then
				addon:ApplySUFSliderSkin(child)
			elseif objectType == "ScrollFrame" and addon.ApplySUFScrollBarSkin then
				addon:ApplySUFScrollBarSkin(child)
			elseif objectType == "StatusBar" and addon.ApplySUFStatusBarSkin then
				addon:ApplySUFStatusBarSkin(child)
			elseif objectType == "EditBox" and addon.ApplySUFEditBoxSkin then
				addon:ApplySUFEditBoxSkin(child)
			elseif objectType == "FontString" and addon.ApplySUFFontStringSkin then
				addon:ApplySUFFontStringSkin(child)
			elseif objectType == "Button" and addon.ApplySUFButtonSkin then
				local childName = SafeGetName(child):lower()
				local isTab = childName:find("tab", 1, true) ~= nil
					or childName:find("toptab", 1, true) ~= nil
					or childName:find("sidebutton", 1, true) ~= nil
				if not isTab then
					addon:ApplySUFButtonSkin(child, "subtle")
				end
			end
			if child and child.GetNumChildren and SafeGetNumChildren(child) > 0 then
				Walk(child, depth + 1)
			end
		end
	end
	Walk(root, 0)
end

local function ApplyScrollBarSweep(root, report)
	if not (root and root.GetNumChildren and addon.ApplySUFScrollBarSkin) then
		return
	end
	local visited = {}
	local function TrySkin(obj)
		if not obj or visited[obj] then
			return
		end
		visited[obj] = true
		addon:ApplySUFScrollBarSkin(obj)
		Increment(report, "scrollbarsSkinned")
	end
	local function Walk(node, depth)
		if not node or depth > 10 then
			return
		end
		if node.ScrollBar then
			TrySkin(node.ScrollBar)
		end
		local objType = SafeGetObjectType(node)
		if objType == "ScrollFrame" or objType == "Slider" then
			TrySkin(node)
		end
		local name = SafeGetName(node)
		if type(name) == "string" and name ~= "" and name:find("Scroll", 1, true) then
			TrySkin(node)
		end
		if node.GetChildren then
			local children = SafeGetChildren(node)
			for i = 1, #children do
				Walk(children[i], depth + 1)
			end
		end
	end
	Walk(root, 0)
end

local function TryLoadGroupAddons(groupKey, report)
	if not (LoadAddOn and IsAddOnLoaded) then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		Increment(report, "addonLoadDeferredCombat")
		return
	end
	local addonNames = GROUP_ADDONS[groupKey]
	if type(addonNames) ~= "table" then
		return
	end
	for i = 1, #addonNames do
		local name = addonNames[i]
		if name and not IsAddOnLoaded(name) then
			Increment(report, "addonLoadAttempts")
			local ok = pcall(LoadAddOn, name)
			if ok and IsAddOnLoaded(name) then
				Increment(report, "addonLoaded")
			else
				Increment(report, "addonLoadFailed")
			end
		end
	end
end

local function AreGroupAddonsLoaded(groupKey)
	if not IsAddOnLoaded then
		return true
	end
	local addonNames = GROUP_ADDONS[groupKey]
	if type(addonNames) ~= "table" or #addonNames == 0 then
		return true
	end
	for i = 1, #addonNames do
		local name = addonNames[i]
		if name and not IsAddOnLoaded(name) then
			return false
		end
	end
	return true
end

local function GetRefRootName(ref)
	if type(ref) ~= "string" or ref == "" then
		return ""
	end
	return (ref:match("^([^%.]+)")) or ref
end

local function IsLazyTopLevelReference(ref)
	return type(ref) == "string" and LAZY_TOPLEVEL_REFS[ref] == true
end

local function IsLazyNestedRoot(rootName)
	return type(rootName) == "string" and LAZY_NESTED_ROOTS[rootName] == true
end

local function IsSoftNestedReference(ref)
	if type(ref) ~= "string" then
		return false
	end
	for i = 1, #SOFT_NESTED_HINTS do
		if ref:find(SOFT_NESTED_HINTS[i], 1, true) then
			return true
		end
	end
	return false
end

local function CaptureOriginalFrameStyle(frame)
	if not frame or frame.__sufBlizzardSkinOriginal then
		return
	end
	local original = {}
	if frame.GetBackdrop then
		local okBackdrop, backdrop = pcall(frame.GetBackdrop, frame)
		if okBackdrop and backdrop then
			original.hadBackdrop = true
			original.backdrop = backdrop
		else
			original.hadBackdrop = false
		end
	end
	if frame.GetBackdropColor then
		local okBg, r, g, b, a = pcall(frame.GetBackdropColor, frame)
		if okBg and r then
			original.bg = { r, g, b, a }
		end
	end
	if frame.GetBackdropBorderColor then
		local okBorder, r, g, b, a = pcall(frame.GetBackdropBorderColor, frame)
		if okBorder and r then
			original.border = { r, g, b, a }
		end
	end
	frame.__sufBlizzardSkinOriginal = original
end

local function RestoreFrameSkin(frame, report)
	if not frame then
		return
	end
	if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
		Increment(report, "skippedProtected")
		return
	end
	local original = frame.__sufBlizzardSkinOriginal
	if not original then
		Increment(report, "skippedUntracked")
		return
	end
	if frame.SetBackdrop then
		if original.hadBackdrop == true and original.backdrop then
			pcall(frame.SetBackdrop, frame, original.backdrop)
		elseif original.hadBackdrop == false then
			pcall(frame.SetBackdrop, frame, nil)
		end
	end
	if original.bg and frame.SetBackdropColor then
		pcall(frame.SetBackdropColor, frame, original.bg[1], original.bg[2], original.bg[3], original.bg[4] or 1)
	end
	if original.border and frame.SetBackdropBorderColor then
		pcall(frame.SetBackdropBorderColor, frame, original.border[1], original.border[2], original.border[3], original.border[4] or 1)
	end
	if original.textures then
		for texture, color in pairs(original.textures) do
			if texture and texture.SetVertexColor and color then
				pcall(texture.SetVertexColor, texture, color[1], color[2], color[3], color[4] or 1)
			end
		end
	end
	if original.fontStrings then
		for fontString, color in pairs(original.fontStrings) do
			if fontString and fontString.SetTextColor and color then
				pcall(fontString.SetTextColor, fontString, color[1], color[2], color[3], color[4] or 1)
			end
		end
	end
	frame.__sufBlizzardSkinned = nil
	Increment(report, "restored")
end

local function SafeApplyFrameSkin(frame, intensity, report, forceApply, groupKey)
	if not frame then
		Increment(report, "missing")
		return
	end
	local domain = GetDomainReport(report, groupKey)
	if frame.__sufBlizzardSkinHooked ~= true and frame.HookScript then
		frame:HookScript("OnShow", function(selfFrame)
			if addon and addon.ApplyBlizzardSkinToFrame then
				addon:ApplyBlizzardSkinToFrame(selfFrame)
			end
		end)
		frame.__sufBlizzardSkinHooked = true
	end

	if (not forceApply) and frame.__sufBlizzardSkinned == intensity then
		Increment(report, "skippedAlreadySkinned")
		Increment(domain, "already")
		return
	end

	if frame.IsForbidden and frame:IsForbidden() then
		Increment(report, "skippedForbidden")
		Increment(domain, "forbidden")
		AddReportSample(report, "protectedSamples", SafeGetName(frame) ~= "" and SafeGetName(frame) or tostring(frame), 20)
		return
	end

	if InCombatLockdown and InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
		Increment(report, "skippedProtected")
		Increment(domain, "protected")
		AddReportSample(report, "protectedSamples", SafeGetName(frame) ~= "" and SafeGetName(frame) or tostring(frame), 20)
		return
	end

	CaptureOriginalFrameStyle(frame)
	local style = GetThemeBackdropStyle(intensity)
	local visualApplied = false
	local isStrong = (intensity == "strong" or intensity == "strongplus")
	local isStrongPlus = (intensity == "strongplus")
	local contentHeavyGroup = IsContentHeavyGroup(groupKey)

	if (not contentHeavyGroup) and addon.ApplySUFBackdrop then
		addon:ApplySUFBackdrop(frame, isStrong and "panel" or "subtle")
		if frame.SetBackdrop then
			visualApplied = true
		end
	elseif (not contentHeavyGroup) and addon.ApplySUFBackdropColors then
		if style then
			addon:ApplySUFBackdropColors(frame, style.bg, style.border, true)
			if frame.SetBackdropColor or frame.SetBackdropBorderColor then
				visualApplied = true
			end
		end
	end
	if style then
		if ApplyThemeToFrameTextures(frame, style, groupKey) then
			visualApplied = true
		end
		local enableStrongPlusRecursive = isStrongPlus and (not contentHeavyGroup)
		if enableStrongPlusRecursive and ApplyStrongPlusTexturePass(frame, style, report, groupKey) then
			visualApplied = true
		end
		if ApplyContrastAwareTextPass(frame, style, report, groupKey) then
			visualApplied = true
		end
	end

	if isStrongPlus then
		if not contentHeavyGroup then
			ApplyControlSkinsWithoutButtons(frame, "default")
			visualApplied = true
		end
	elseif addon.ApplySUFControlSkinsInFrame then
		addon:ApplySUFControlSkinsInFrame(frame, isStrong and "default" or "subtle")
		visualApplied = true
	end
	ApplyScrollBarSweep(frame, report)
	frame.__sufBlizzardSkinned = intensity
	TrackSkinnedFrame(groupKey, frame)
	Increment(report, "applied")
	Increment(domain, "applied")
	if not visualApplied then
		Increment(report, "noVisualTargets")
	end
end

function addon:GetBlizzardSkinSettings()
	local defaults = {
		enabled = false,
		intensity = "subtle",
		labMode = false,
		aggressiveRecursive = false,
		aggressiveReassertHooks = false,
		character = true,
		spellbook = true,
		collections = true,
		questlog = true,
		lfg = true,
		map = true,
		calendar = true,
		professions = true,
		dressup = true,
		gossip = true,
		merchant = true,
		mail = true,
		economy = true,
		friends = true,
		guild = true,
		housing = true,
		achievement = true,
		encounter = true,
	}

	if not (self.db and self.db.profile) then
		return defaults
	end

	self.db.profile.blizzardSkin = self.db.profile.blizzardSkin or CopyTableDeepLocal(defaults)
	local cfg = self.db.profile.blizzardSkin
	for key, value in pairs(defaults) do
		if cfg[key] == nil then
			cfg[key] = value
		end
	end
	return cfg
end

function addon:ApplyBlizzardSkinToFrame(frame)
	local cfg = self:GetBlizzardSkinSettings()
	if not cfg or cfg.enabled ~= true then
		return
	end
	SafeApplyFrameSkin(frame, tostring(cfg.intensity or "subtle"), nil, false, "__adhoc")
end

function addon:ApplyBlizzardSkinSafeProfile()
	local cfg = self:GetBlizzardSkinSettings()
	if not cfg then
		return
	end
	cfg.labMode = false
	cfg.aggressiveRecursive = false
	cfg.aggressiveReassertHooks = false
	cfg.intensity = "strongplus"
	if self.ApplyBlizzardSkinningNow then
		self:ApplyBlizzardSkinningNow(true)
	end
end

function addon:ApplyBlizzardSkinningNow(forceApply)
	local cfg = self:GetBlizzardSkinSettings()
	if not cfg or cfg.enabled ~= true then
		return
	end

	local report = {
		mode = "apply",
		at = date("%H:%M:%S"),
		seen = 0,
		applied = 0,
		noVisualTargets = 0,
		strongPlusPasses = 0,
		strongPlusTextures = 0,
		scrollbarsSkinned = 0,
		blockedByTextureBlocklist = 0,
		allowlistBypass = 0,
		contrastTextAdjusted = 0,
		reassertHooked = 0,
		reassertCalls = 0,
		reassertHookBudgetDrops = 0,
		nestedRefsSeen = 0,
		resolvedNestedRefs = 0,
		unresolvedNestedRefs = 0,
		missing = 0,
		skippedProtected = 0,
		skippedForbidden = 0,
		skippedAlreadySkinned = 0,
		disabledGroups = 0,
		addonLoadAttempts = 0,
		addonLoaded = 0,
		addonLoadFailed = 0,
		addonLoadDeferredCombat = 0,
		nestedSkippedRootMissing = 0,
		missingWhileGroupUnloaded = 0,
		missingLazyTopLevel = 0,
		missingSoftNested = 0,
		nestedRootLazy = 0,
	}
	ACTIVE_APPLY_REPORT = report
	local intensity = tostring(cfg.intensity or "subtle")
	for key, frameNames in pairs(SKINNABLE_FRAMES) do
		if cfg[key] ~= false then
			local domain = GetDomainReport(report, key)
			TryLoadGroupAddons(key, report)
			for i = 1, #frameNames do
				local ref = frameNames[i]
				local frame = ResolveFrameReference(ref)
				Increment(report, "seen")
				Increment(domain, "seen")
				local isNestedRef = (type(ref) == "string" and ref:find(".", 1, true) ~= nil)
				local rootName = GetRefRootName(ref)
				local rootFrame = (rootName ~= "") and _G[rootName] or nil
				if isNestedRef then
					Increment(report, "nestedRefsSeen")
				end
				local skipRef = false
				if isNestedRef and not rootFrame then
					if IsLazyNestedRoot(rootName) then
						Increment(report, "nestedRootLazy")
						AddReportSample(report, "lazyNestedRootSamples", tostring(rootName), 20)
					else
						Increment(report, "nestedSkippedRootMissing")
						AddReportSample(report, "missingRootSamples", tostring(rootName), 20)
					end
					skipRef = true
				end
				if not skipRef then
					if frame then
						if isNestedRef then
							Increment(report, "resolvedNestedRefs")
						end
						SafeApplyFrameSkin(frame, intensity, report, forceApply == true, key)
					else
						local groupLoaded = AreGroupAddonsLoaded(key)
						if not groupLoaded then
							Increment(report, "missingWhileGroupUnloaded")
						end
						if isNestedRef and IsSoftNestedReference(ref) then
							Increment(report, "missingSoftNested")
							AddReportSample(report, "softNestedSamples", tostring(ref), 20)
						elseif (not isNestedRef) and IsLazyTopLevelReference(ref) then
							Increment(report, "missingLazyTopLevel")
							AddReportSample(report, "lazyMissingSamples", tostring(ref), 20)
						else
							Increment(report, "missing")
							Increment(domain, "missing")
							if isNestedRef then
								Increment(report, "unresolvedNestedRefs")
								AddReportSample(report, "missingNestedSamples", tostring(ref), 20)
							else
								if groupLoaded then
									AddReportSample(report, "missingSamples", tostring(ref), 20)
								else
									AddReportSample(report, "missingUnloadedSamples", tostring(ref), 20)
								end
							end
						end
					end
				end
			end
		else
			Increment(report, "disabledGroups")
			local domain = GetDomainReport(report, key)
			Increment(domain, "disabled")
		end
	end
	ACTIVE_APPLY_REPORT = nil
	self._blizzardSkinLastReport = report
end

function addon:ReapplyBlizzardSkinBuckets(forceApply)
	local cfg = self:GetBlizzardSkinSettings()
	if not cfg or cfg.enabled ~= true then
		return
	end

	local report = {
		mode = "reapply",
		at = date("%H:%M:%S"),
		buckets = 0,
		seen = 0,
		applied = 0,
		noVisualTargets = 0,
		strongPlusPasses = 0,
		strongPlusTextures = 0,
		scrollbarsSkinned = 0,
		blockedByTextureBlocklist = 0,
		allowlistBypass = 0,
		contrastTextAdjusted = 0,
		reassertHooked = 0,
		reassertCalls = 0,
		reassertHookBudgetDrops = 0,
		skippedProtected = 0,
		skippedForbidden = 0,
		skippedAlreadySkinned = 0,
		invalid = 0,
	}
	ACTIVE_APPLY_REPORT = report
	local intensity = tostring(cfg.intensity or "subtle")

	for groupKey, bucket in pairs(SKINNED_FRAME_BUCKETS) do
		if type(bucket) == "table" and cfg[groupKey] ~= false then
			local domain = GetDomainReport(report, groupKey)
			Increment(report, "buckets")
			for i = #bucket, 1, -1 do
				local frame = bucket[i]
				if frame and frame.GetObjectType then
					Increment(report, "seen")
					Increment(domain, "seen")
					SafeApplyFrameSkin(frame, intensity, report, forceApply == true, groupKey)
				else
					bucket[i] = bucket[#bucket]
					bucket[#bucket] = nil
					Increment(report, "invalid")
				end
			end
		end
	end
	ACTIVE_APPLY_REPORT = nil
	self._blizzardSkinLastReport = report
end

function addon:RemoveBlizzardSkinningNow()
	local report = {
		mode = "restore",
		at = date("%H:%M:%S"),
		restored = 0,
		skippedProtected = 0,
		skippedUntracked = 0,
	}
	for _, frameNames in pairs(SKINNABLE_FRAMES) do
		for i = 1, #frameNames do
			local frame = ResolveFrameReference(frameNames[i])
			if frame then
				RestoreFrameSkin(frame, report)
			end
		end
	end
	SKINNED_FRAME_BUCKETS = {}
	SKINNED_FRAME_SET = setmetatable({}, { __mode = "k" })
	self._blizzardSkinLastReport = report
end

function addon:GetBlizzardSkinReport()
	return self._blizzardSkinLastReport
end

function addon:GetBlizzardSkinCoverageReport()
	local report = self:GetBlizzardSkinReport()
	if type(report) ~= "table" then
		return nil
	end
	local out = {
		mode = report.mode,
		at = report.at,
		seen = report.seen or 0,
		applied = report.applied or 0,
		missing = report.missing or 0,
		protected = report.skippedProtected or 0,
		forbidden = report.skippedForbidden or 0,
		blockedByTextureBlocklist = report.blockedByTextureBlocklist or 0,
		domains = {},
		missingSamples = report.missingSamples,
		missingNestedSamples = report.missingNestedSamples,
		protectedSamples = report.protectedSamples,
		blockedTextureSamples = report.blockedTextureSamples,
	}
	if type(report.domains) == "table" then
		for key, value in pairs(report.domains) do
			if type(value) == "table" then
				out.domains[key] = CopyTableDeepLocal(value)
			end
		end
	end
	return out
end

local function BuildDomainCoverageLines(report)
	local domains = report and report.domains
	if type(domains) ~= "table" then
		return {}
	end
	local keys = {}
	for key in pairs(domains) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	local lines = {}
	for i = 1, #keys do
		local key = keys[i]
		local d = domains[key]
		if type(d) == "table" then
			local seen = tonumber(d.seen or 0) or 0
			local applied = tonumber(d.applied or 0) or 0
			local already = tonumber(d.already or 0) or 0
			local missing = tonumber(d.missing or 0) or 0
			local protected = tonumber(d.protected or 0) or 0
			local forbidden = tonumber(d.forbidden or 0) or 0
			local disabled = tonumber(d.disabled or 0) or 0
			local denom = seen > 0 and seen or 1
			local covered = applied + already
			local hitRate = (covered / denom) * 100
			lines[#lines + 1] = ("%s: hit=%.1f%% (%d/%d) applied=%d already=%d missing=%d protected=%d forbidden=%d disabled=%d"):format(
				key, hitRate, covered, seen, applied, already, missing, protected, forbidden, disabled
			)
		end
	end
	return lines
end

function addon:PrintBlizzardSkinReport()
	local report = self:GetBlizzardSkinReport()
	if not report then
		if self.DebugLog then
			self:DebugLog("BlizzardSkin", "Report is empty.", 2)
		elseif self.Print then
			self:Print("SimpleUnitFrames: Blizzard skin report is empty.")
		end
		return
	end
	if self.DebugLog then
		if report.mode == "apply" or report.mode == "reapply" then
			local modeLabel = (report.mode == "reapply") and "Reapply" or "Apply"
			self:DebugLog("BlizzardSkin", ("%s @%s | buckets=%d seen=%d applied=%d noVisual=%d spPass=%d spTint=%d scrollbars=%d blocked=%d allowed=%d contrast=%d hookSet=%d hookCalls=%d hookDrop=%d nestedSeen=%d nestedOK=%d nestedMiss=%d nestedSoftMiss=%d nestedRootMiss=%d nestedRootLazy=%d missing=%d missingLazy=%d missingUnloaded=%d invalid=%d already=%d protected=%d forbidden=%d disabledGroups=%d loadTry=%d loadOK=%d loadFail=%d loadDeferCombat=%d"):format(
				modeLabel,
				tostring(report.at or ""),
				tonumber(report.buckets or 0) or 0,
				tonumber(report.seen or 0) or 0,
				tonumber(report.applied or 0) or 0,
				tonumber(report.noVisualTargets or 0) or 0,
				tonumber(report.strongPlusPasses or 0) or 0,
				tonumber(report.strongPlusTextures or 0) or 0,
				tonumber(report.scrollbarsSkinned or 0) or 0,
				tonumber(report.blockedByTextureBlocklist or 0) or 0,
				tonumber(report.allowlistBypass or 0) or 0,
				tonumber(report.contrastTextAdjusted or 0) or 0,
				tonumber(report.reassertHooked or 0) or 0,
				tonumber(report.reassertCalls or 0) or 0,
				tonumber(report.reassertHookBudgetDrops or 0) or 0,
				tonumber(report.nestedRefsSeen or 0) or 0,
				tonumber(report.resolvedNestedRefs or 0) or 0,
				tonumber(report.unresolvedNestedRefs or 0) or 0,
				tonumber(report.missingSoftNested or 0) or 0,
				tonumber(report.nestedSkippedRootMissing or 0) or 0,
				tonumber(report.nestedRootLazy or 0) or 0,
				tonumber(report.missing or 0) or 0,
				tonumber(report.missingLazyTopLevel or 0) or 0,
				tonumber(report.missingWhileGroupUnloaded or 0) or 0,
				tonumber(report.invalid or 0) or 0,
				tonumber(report.skippedAlreadySkinned or 0) or 0,
				tonumber(report.skippedProtected or 0) or 0,
				tonumber(report.skippedForbidden or 0) or 0,
				tonumber(report.disabledGroups or 0) or 0,
				tonumber(report.addonLoadAttempts or 0) or 0,
				tonumber(report.addonLoaded or 0) or 0,
				tonumber(report.addonLoadFailed or 0) or 0,
				tonumber(report.addonLoadDeferredCombat or 0) or 0
			), 2)
			local coverageLines = BuildDomainCoverageLines(report)
			for i = 1, #coverageLines do
				self:DebugLog("BlizzardSkin", "Coverage " .. coverageLines[i], 2)
			end
			if report.missingNestedSamples and #report.missingNestedSamples > 0 then
				self:DebugLog("BlizzardSkin", "Missing nested samples: " .. table.concat(report.missingNestedSamples, ", "), 2)
			end
			if report.softNestedSamples and #report.softNestedSamples > 0 then
				self:DebugLog("BlizzardSkin", "Soft-missing nested samples: " .. table.concat(report.softNestedSamples, ", "), 2)
			end
			if report.missingSamples and #report.missingSamples > 0 then
				self:DebugLog("BlizzardSkin", "Missing top-level samples: " .. table.concat(report.missingSamples, ", "), 2)
			end
			if report.lazyMissingSamples and #report.lazyMissingSamples > 0 then
				self:DebugLog("BlizzardSkin", "Lazy top-level samples: " .. table.concat(report.lazyMissingSamples, ", "), 2)
			end
			if report.missingUnloadedSamples and #report.missingUnloadedSamples > 0 then
				self:DebugLog("BlizzardSkin", "Missing while group addon unloaded: " .. table.concat(report.missingUnloadedSamples, ", "), 2)
			end
			if report.missingRootSamples and #report.missingRootSamples > 0 then
				self:DebugLog("BlizzardSkin", "Missing nested root samples: " .. table.concat(report.missingRootSamples, ", "), 2)
			end
			if report.lazyNestedRootSamples and #report.lazyNestedRootSamples > 0 then
				self:DebugLog("BlizzardSkin", "Lazy nested root samples: " .. table.concat(report.lazyNestedRootSamples, ", "), 2)
			end
			if report.protectedSamples and #report.protectedSamples > 0 then
				self:DebugLog("BlizzardSkin", "Protected/forbidden samples: " .. table.concat(report.protectedSamples, ", "), 2)
			end
			if report.blockedTextureSamples and #report.blockedTextureSamples > 0 then
				self:DebugLog("BlizzardSkin", "Blocked texture samples: " .. table.concat(report.blockedTextureSamples, ", "), 2)
			end
		else
			self:DebugLog("BlizzardSkin", ("Restore @%s | restored=%d protected=%d untracked=%d"):format(
				tostring(report.at or ""),
				tonumber(report.restored or 0) or 0,
				tonumber(report.skippedProtected or 0) or 0,
				tonumber(report.skippedUntracked or 0) or 0
			), 2)
		end
	elseif self.Print then
		if report.mode == "apply" or report.mode == "reapply" then
			local modeLabel = (report.mode == "reapply") and "reapply" or "apply"
			self:Print(("SimpleUnitFrames: Blizzard skin %s @%s | buckets=%d seen=%d applied=%d noVisual=%d spPass=%d spTint=%d scrollbars=%d blocked=%d allowed=%d contrast=%d hookSet=%d hookCalls=%d hookDrop=%d nestedSeen=%d nestedOK=%d nestedMiss=%d nestedSoftMiss=%d nestedRootMiss=%d nestedRootLazy=%d missing=%d missingLazy=%d missingUnloaded=%d invalid=%d already=%d protected=%d forbidden=%d disabledGroups=%d loadTry=%d loadOK=%d loadFail=%d loadDeferCombat=%d"):format(
				modeLabel,
				tostring(report.at or ""),
				tonumber(report.buckets or 0) or 0,
				tonumber(report.seen or 0) or 0,
				tonumber(report.applied or 0) or 0,
				tonumber(report.noVisualTargets or 0) or 0,
				tonumber(report.strongPlusPasses or 0) or 0,
				tonumber(report.strongPlusTextures or 0) or 0,
				tonumber(report.scrollbarsSkinned or 0) or 0,
				tonumber(report.blockedByTextureBlocklist or 0) or 0,
				tonumber(report.allowlistBypass or 0) or 0,
				tonumber(report.contrastTextAdjusted or 0) or 0,
				tonumber(report.reassertHooked or 0) or 0,
				tonumber(report.reassertCalls or 0) or 0,
				tonumber(report.reassertHookBudgetDrops or 0) or 0,
				tonumber(report.nestedRefsSeen or 0) or 0,
				tonumber(report.resolvedNestedRefs or 0) or 0,
				tonumber(report.unresolvedNestedRefs or 0) or 0,
				tonumber(report.missingSoftNested or 0) or 0,
				tonumber(report.nestedSkippedRootMissing or 0) or 0,
				tonumber(report.nestedRootLazy or 0) or 0,
				tonumber(report.missing or 0) or 0,
				tonumber(report.missingLazyTopLevel or 0) or 0,
				tonumber(report.missingWhileGroupUnloaded or 0) or 0,
				tonumber(report.invalid or 0) or 0,
				tonumber(report.skippedAlreadySkinned or 0) or 0,
				tonumber(report.skippedProtected or 0) or 0,
				tonumber(report.skippedForbidden or 0) or 0,
				tonumber(report.disabledGroups or 0) or 0,
				tonumber(report.addonLoadAttempts or 0) or 0,
				tonumber(report.addonLoaded or 0) or 0,
				tonumber(report.addonLoadFailed or 0) or 0,
				tonumber(report.addonLoadDeferredCombat or 0) or 0
			))
			local coverageLines = BuildDomainCoverageLines(report)
			for i = 1, #coverageLines do
				self:Print("SimpleUnitFrames: Blizzard skin coverage " .. coverageLines[i])
			end
			if report.missingNestedSamples and #report.missingNestedSamples > 0 then
				self:Print("SimpleUnitFrames: Missing nested samples: " .. table.concat(report.missingNestedSamples, ", "))
			end
			if report.softNestedSamples and #report.softNestedSamples > 0 then
				self:Print("SimpleUnitFrames: Soft-missing nested samples: " .. table.concat(report.softNestedSamples, ", "))
			end
			if report.missingSamples and #report.missingSamples > 0 then
				self:Print("SimpleUnitFrames: Missing top-level samples: " .. table.concat(report.missingSamples, ", "))
			end
			if report.lazyMissingSamples and #report.lazyMissingSamples > 0 then
				self:Print("SimpleUnitFrames: Lazy top-level samples: " .. table.concat(report.lazyMissingSamples, ", "))
			end
			if report.missingUnloadedSamples and #report.missingUnloadedSamples > 0 then
				self:Print("SimpleUnitFrames: Missing while group addon unloaded: " .. table.concat(report.missingUnloadedSamples, ", "))
			end
			if report.missingRootSamples and #report.missingRootSamples > 0 then
				self:Print("SimpleUnitFrames: Missing nested root samples: " .. table.concat(report.missingRootSamples, ", "))
			end
			if report.lazyNestedRootSamples and #report.lazyNestedRootSamples > 0 then
				self:Print("SimpleUnitFrames: Lazy nested root samples: " .. table.concat(report.lazyNestedRootSamples, ", "))
			end
			if report.protectedSamples and #report.protectedSamples > 0 then
				self:Print("SimpleUnitFrames: Protected/forbidden samples: " .. table.concat(report.protectedSamples, ", "))
			end
			if report.blockedTextureSamples and #report.blockedTextureSamples > 0 then
				self:Print("SimpleUnitFrames: Blocked texture samples: " .. table.concat(report.blockedTextureSamples, ", "))
			end
		else
			self:Print(("SimpleUnitFrames: Blizzard skin restore @%s | restored=%d protected=%d untracked=%d"):format(
				tostring(report.at or ""),
				tonumber(report.restored or 0) or 0,
				tonumber(report.skippedProtected or 0) or 0,
				tonumber(report.skippedUntracked or 0) or 0
			))
		end
	end
end

function addon:PrintBlizzardSkinCoverageReport()
	self:PrintBlizzardSkinReport()
end

function addon:SetupBlizzardSkinning()
	if self._blizzardSkinEventFrame then
		return
	end

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", function(_, event, arg1)
		if event == "PLAYER_ENTERING_WORLD" then
			if C_Timer and C_Timer.After then
				C_Timer.After(0.2, function()
					local cfg = addon:GetBlizzardSkinSettings()
					if cfg and cfg.enabled == true then
						addon:ApplyBlizzardSkinningNow()
					end
				end)
			else
				local cfg = addon:GetBlizzardSkinSettings()
				if cfg and cfg.enabled == true then
					addon:ApplyBlizzardSkinningNow()
				end
			end
			return
		end

		if event == "ADDON_LOADED" and REQUIRED_ADDONS[arg1] then
			if C_Timer and C_Timer.After then
				C_Timer.After(0, function()
					local cfg = addon:GetBlizzardSkinSettings()
					if cfg and cfg.enabled == true then
						addon:ApplyBlizzardSkinningNow()
					end
				end)
			else
				local cfg = addon:GetBlizzardSkinSettings()
				if cfg and cfg.enabled == true then
					addon:ApplyBlizzardSkinningNow()
				end
			end
		end
	end)

	self._blizzardSkinEventFrame = frame
end
