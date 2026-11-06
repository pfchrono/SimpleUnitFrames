---
--- UnitAuras: SUF's adapter over the oUF 14 Auras element (Blizzard AuraContainer).
---
--- oUF 14 dropped the Lua-side aura scanner in favour of Blizzard's AuraContainer widget, which
--- filters, sorts and lays out buttons C-side (and is safe with secret aura data). Each unit frame
--- gets one container with two groups (buffs, debuffs). The container resizes itself, and Blizzard
--- forbids untrusted layout scripts on it once groups exist, so other widgets (totems, etc.) must
--- anchor to frame.AurasAnchor - a plain SUF frame occupying the first aura row - never to
--- frame.Auras directly.
---

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local UnitAuras = {}
addon.UnitAuras = UnitAuras

local SORT_METHODS = {
	DEFAULT = "Default",
	TIME_REMAINING = "Expiration",
	NAME = "Name",
}

local SORT_DIRECTIONS = {
	ASC = "Normal",
	DESC = "Reverse",
}

local COOLDOWN_SCALE = 0.86

local function IsAvailable(frame)
	return frame and frame.CreateAuras and AuraContainerSortMethod and AuraContainerSortDirection
end

local function ResolveSortMethod(value)
	local key = SORT_METHODS[tostring(value or "DEFAULT")] or SORT_METHODS.DEFAULT
	return AuraContainerSortMethod[key]
end

local function ResolveSortDirection(value)
	local key = SORT_DIRECTIONS[tostring(value or "ASC")] or SORT_DIRECTIONS.ASC
	return AuraContainerSortDirection[key]
end

---Normalized aura settings for a unit type.
---@return table
function UnitAuras:GetSettings(unitType)
	local cfg = addon:GetUnitAuraLayoutSettings(unitType) or {}
	local onlyPlayer = cfg.onlyShowPlayer == true
	return {
		enabled = cfg.enabled ~= false,
		size = addon:GetUnitAuraSize(unitType) or 18,
		spacingX = math.max(0, tonumber(cfg.spacingX) or 4),
		spacingY = math.max(0, tonumber(cfg.spacingY) or 4),
		maxCols = math.max(1, math.floor(tonumber(cfg.maxCols) or 8)),
		initialAnchor = tostring(cfg.initialAnchor or "BOTTOMLEFT"),
		growthX = tostring(cfg.growthX or "RIGHT"),
		growthY = tostring(cfg.growthY or "UP"),
		sortMethod = ResolveSortMethod(cfg.sortMethod),
		sortDirection = ResolveSortDirection(cfg.sortDirection),
		buffFilter = onlyPlayer and "HELPFUL|PLAYER" or "HELPFUL",
		debuffFilter = onlyPlayer and "HARMFUL|PLAYER" or "HARMFUL",
		showStealable = cfg.showStealableBuffs ~= false,
		numBuffs = math.max(0, math.floor(tonumber(cfg.numBuffs) or 8)),
		numDebuffs = math.max(0, math.floor(tonumber(cfg.numDebuffs) or 8)),
	}
end

local function GetLineSize(settings)
	return (settings.maxCols * settings.size) + ((settings.maxCols - 1) * settings.spacingX)
end

local function GetGroupLayout(settings)
	return {
		elementSpacing = settings.spacingX,
		lineSpacing = settings.spacingY,
		groupSpacing = settings.spacingX,
		groupLineSpacing = settings.spacingY,
		forceNewLine = true, -- debuffs start on their own row, like the old split layout
	}
end

---Iterate every aura button currently created by the frame's container.
function UnitAuras:ForEachButton(frame, callback)
	local auras = frame and frame.Auras
	local groups = frame and frame.__sufAuraGroups
	if not (auras and groups and auras.GetAuraGroupFrameCount) then
		return
	end
	for _, key in pairs(groups) do
		for index = 1, auras:GetAuraGroupFrameCount(key) or 0 do
			local button = auras:GetAuraGroupFrame(key, index)
			if button then
				callback(button)
			end
		end
	end
end

local function StyleButton(element, button)
	if button.Cooldown then
		button.Cooldown:SetScale(COOLDOWN_SCALE)
	end
	if button.Icon then
		button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	if button.Count and button.Count.SetFontObject then
		button.Count:SetFontObject("NumberFontNormalSmall")
	end
	if button.Stealable then
		button.Stealable:SetAlpha(element.__sufShowStealable and 1 or 0)
	end
end

---Create frame.AurasAnchor and the frame.Auras container with buff/debuff groups.
function UnitAuras:Create(frame)
	if frame.Auras or not IsAvailable(frame) then
		return frame.Auras
	end

	local settings = self:GetSettings(frame.sufUnitType)

	local anchor = CreateFrame("Frame", nil, frame)
	anchor:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 4)
	anchor:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 4)
	anchor:SetHeight(settings.size + 2)
	if anchor.EnableMouse then
		anchor:EnableMouse(false)
	end
	frame.AurasAnchor = anchor

	local auras = frame:CreateAuras({
		initialAnchor = settings.initialAnchor,
		growthX = settings.growthX,
		growthY = settings.growthY,
		layoutLimit = GetLineSize(settings),
	})
	-- above Blizzard frames (MEDIUM) so buttons receive mouse for tooltips; the container is a
	-- restricted Blizzard widget, so don't let a refused strata change break Style
	pcall(auras.SetFrameStrata, auras, "HIGH")
	auras:SetPoint(settings.initialAnchor, anchor, settings.initialAnchor, 0, 0)

	-- element-wide button options (read when buttons are created)
	auras.size = settings.size
	auras.showCount = true
	auras.showDebuffBorder = true
	auras.showStealableBorder = true -- visibility is toggled per button via alpha
	auras.tooltipAnchor = "ANCHOR_BOTTOMRIGHT"
	auras.__sufShowStealable = settings.showStealable
	auras.PostCreateButton = StyleButton

	frame.Auras = auras
	frame.__sufAuraGroups = {
		buffs = auras:AddGroup(settings.buffFilter, {
			maxFrameCount = settings.numBuffs,
			sortMethod = settings.sortMethod,
			sortDirection = settings.sortDirection,
			layout = GetGroupLayout(settings),
		}),
		debuffs = auras:AddGroup(settings.debuffFilter, {
			maxFrameCount = settings.numDebuffs,
			sortMethod = settings.sortMethod,
			sortDirection = settings.sortDirection,
			layout = GetGroupLayout(settings),
		}),
	}
	frame.__sufAuraSettingsSig = nil

	return auras
end

local function BuildSignature(settings)
	return table.concat({
		settings.size, settings.spacingX, settings.spacingY, settings.maxCols,
		settings.initialAnchor, settings.growthX, settings.growthY,
		settings.sortMethod, settings.sortDirection, settings.buffFilter, settings.debuffFilter,
		tostring(settings.showStealable), settings.numBuffs, settings.numDebuffs,
	}, "|")
end

---Push the current profile settings into the container (cheap when unchanged).
function UnitAuras:ApplyLayout(frame)
	local auras = frame and frame.Auras
	local groups = frame and frame.__sufAuraGroups
	if not (auras and groups) then
		return
	end

	local settings = self:GetSettings(frame.sufUnitType)
	local signature = BuildSignature(settings)
	if frame.__sufAuraSettingsSig == signature then
		return
	end
	frame.__sufAuraSettingsSig = signature

	auras:SetFlowLayoutAnchorPoint(settings.initialAnchor)
	auras:SetFlowLayoutGrowthDirection(settings.growthX == "LEFT" and -1 or 1, settings.growthY == "DOWN" and -1 or 1)
	auras:SetFlowLayoutMaximumLineSize(GetLineSize(settings))
	auras:ClearAllPoints()
	auras:SetPoint(settings.initialAnchor, frame.AurasAnchor or frame, settings.initialAnchor, 0, 0)

	local layout = GetGroupLayout(settings)
	auras:SetAuraGroupFilterString(groups.buffs, settings.buffFilter)
	auras:SetAuraGroupFilterString(groups.debuffs, settings.debuffFilter)
	auras:SetAuraGroupMaxFrameCount(groups.buffs, settings.numBuffs)
	auras:SetAuraGroupMaxFrameCount(groups.debuffs, settings.numDebuffs)
	for _, key in pairs(groups) do
		auras:SetAuraGroupSortMethod(key, settings.sortMethod, settings.sortDirection)
		auras:SetAuraGroupLayout(key, layout)
	end

	auras.size = settings.size
	auras.__sufShowStealable = settings.showStealable
	self:ForEachButton(frame, function(button)
		button:SetSize(settings.size, settings.size)
		StyleButton(auras, button)
	end)
end

---Re-anchor the first aura row above another widget (class power, additional power).
function UnitAuras:SetTopAnchor(frame, topAnchor, size)
	local anchor = frame and frame.AurasAnchor
	if not anchor then
		return
	end
	topAnchor = topAnchor or frame
	local signature = tostring(topAnchor) .. "|" .. tostring(size)
	if frame.__sufAuraAnchorSig == signature then
		return
	end
	frame.__sufAuraAnchorSig = signature
	anchor:ClearAllPoints()
	anchor:SetPoint("BOTTOMLEFT", topAnchor, "TOPLEFT", 0, 4)
	anchor:SetPoint("BOTTOMRIGHT", topAnchor, "TOPRIGHT", 0, 4)
	anchor:SetHeight((size or 18) + 2)
end

---Show or hide the aura display; disabling also stops the container from processing auras.
function UnitAuras:SetShown(frame, shown)
	local auras = frame and frame.Auras
	if not auras then
		return
	end
	shown = shown and true or false
	if frame.__sufAuraShown == shown then
		return
	end
	frame.__sufAuraShown = shown
	auras:SetShown(shown)
	if frame.AurasAnchor then
		frame.AurasAnchor:SetShown(shown)
	end
end

return UnitAuras
