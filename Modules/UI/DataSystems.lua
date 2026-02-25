local AceAddon = LibStub("AceAddon-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LibRangeCheck = LibStub("LibRangeCheck-3.0", true)
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    return
end

local core = addon._core or {}
local defaults = core.defaults or {}
local DEFAULT_TEXTURE = core.DEFAULT_TEXTURE or "Interface\\TargetingFrame\\UI-StatusBar"
local DATATEXT_SLOT_ORDER = core.DATATEXT_SLOT_ORDER or { "left", "center", "right" }
local FormatCompactValue = core.FormatCompactValue
local SetStatusBarTexturePreserveLayer = core.SetStatusBarTexturePreserveLayer
local GetWatchedFactionInfoCompat = core.GetWatchedFactionInfoCompat
local THEME = addon.GetSUFTheme and addon:GetSUFTheme() or {}

if type(FormatCompactValue) ~= "function" then
    FormatCompactValue = function(value) return tostring(value or 0) end
end

local function GetBackdropTheme(kind)
	local map = THEME and THEME.backdrop
	if type(map) ~= "table" then
		return nil
	end
	return map[kind or "panel"] or map.panel
end

local function GetDataBarsTheme()
	return (THEME and THEME.databars) or {}
end

local function IsEditModePosition(modeValue)
	local mode = tostring(modeValue or "ANCHOR")
	return mode == "EDIT_MODE" or mode == "EDITMODE" or mode == "EDIT"
end

local function IsShiftDragRequested()
	return IsShiftKeyDown and IsShiftKeyDown() or false
end

local function IsLeftMouseDown()
	if type(IsMouseButtonDown) == "function" then
		local ok, result = pcall(IsMouseButtonDown, "LeftButton")
		if ok then
			return result
		end
		ok, result = pcall(IsMouseButtonDown, 1)
		if ok then
			return result
		end
		ok, result = pcall(IsMouseButtonDown)
		if ok then
			return result
		end
	end
	if type(GetMouseButtonState) == "function" then
		local ok, result = pcall(GetMouseButtonState, "LeftButton")
		if ok then
			return result
		end
	end
	return false
end

local function ShouldShowDragHandle(isMouseOver)
	return isMouseOver and IsShiftDragRequested() and IsLeftMouseDown()
end

local function IsDataBarsDragContextActive(context)
	if InCombatLockdown and InCombatLockdown() then
		return false
	end
	if IsShiftDragRequested() then
		return true
	end
	local cfg = context and context.db and context.db.profile and context.db.profile.databars
	return cfg and IsEditModePosition(cfg.positionMode)
end

local function IsDataTextDragContextActive(context)
	if InCombatLockdown and InCombatLockdown() then
		return false
	end
	if IsShiftDragRequested() then
		return true
	end
	local cfg = context and context.db and context.db.profile and context.db.profile.datatext
	return cfg and IsEditModePosition(cfg.positionMode)
end

local function ForwardDragStartFromChild(root)
	local dragStart = root and root.GetScript and root:GetScript("OnDragStart")
	if dragStart then
		dragStart(root)
	end
end

local function ForwardDragStopFromChild(root)
	local dragStop = root and root.GetScript and root:GetScript("OnDragStop")
	if dragStop then
		dragStop(root)
	end
end

local function ApplyFadeState(frame, fadeCfg, isHovering)
	if not frame then
		return
	end
	if not (fadeCfg and fadeCfg.enabled == true) then
		frame._sufFadeTarget = 1
		frame._sufFadeShow = nil
		frame:SetAlpha(1)
		return
	end

	local inCombat = InCombatLockdown and InCombatLockdown() or false
	local showOnHover = fadeCfg.showOnHover ~= false
	local showInCombat = fadeCfg.showInCombat ~= false
	local shouldShow = (showInCombat and inCombat) or (showOnHover and isHovering)
	local targetAlpha = shouldShow and 1 or (tonumber(fadeCfg.fadeOutAlpha) or 0)
	local duration = shouldShow and (tonumber(fadeCfg.fadeInDuration) or 0.2) or (tonumber(fadeCfg.fadeOutDuration) or 0.3)
	local delay = shouldShow and 0 or (tonumber(fadeCfg.fadeOutDelay) or 0)

	if frame._sufFadeTarget == targetAlpha and frame._sufFadeShow == shouldShow then
		return
	end

	frame._sufFadeTarget = targetAlpha
	frame._sufFadeShow = shouldShow

	if UIFrameFadeIn and UIFrameFadeOut then
		if shouldShow then
			UIFrameFadeIn(frame, duration, frame:GetAlpha(), targetAlpha)
		else
			UIFrameFadeOut(frame, duration, frame:GetAlpha(), targetAlpha, delay)
		end
	else
		frame:SetAlpha(targetAlpha)
	end
end

if type(SetStatusBarTexturePreserveLayer) ~= "function" then
    SetStatusBarTexturePreserveLayer = function(statusBar, texture)
        if statusBar and statusBar.SetStatusBarTexture then
            statusBar:SetStatusBarTexture(texture)
        end
    end
end

if type(GetWatchedFactionInfoCompat) ~= "function" then
    GetWatchedFactionInfoCompat = function()
        if type(GetWatchedFactionInfo) == "function" then
            return GetWatchedFactionInfo()
        end
        return nil
    end
end

local function GetQuestLogXPRewardTotal()
	if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not C_QuestLog.GetInfo or not GetQuestLogRewardXP then
		return 0
	end

	local totalXP = 0
	local numEntries = tonumber((C_QuestLog.GetNumQuestLogEntries())) or 0
	for i = 1, numEntries do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHeader and not info.isHidden then
			local questRef = info.questID or i
			local questXP = tonumber((GetQuestLogRewardXP(questRef))) or tonumber((GetQuestLogRewardXP(i))) or 0
			if questXP > 0 then
				totalXP = totalXP + questXP
			end
		end
	end
	return totalXP
end

local function GetQuestLogEntryCounts()
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		local numEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()
		return tonumber(numEntries) or 0, tonumber(numQuests) or 0
	elseif GetNumQuestLogEntries then
		local numEntries, numQuests = GetNumQuestLogEntries()
		return tonumber(numEntries) or 0, tonumber(numQuests) or 0
	end
	return 0, 0
end

local function GetQuestLogMaxAcceptable()
	if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
		local base = tonumber(C_QuestLog.GetMaxNumQuestsCanAccept()) or 25
		return math.min(base + 10, 35)
	end
	return 25
end

local function BuildQuestDataTextSummary()
	local summary = {
		numEntries = 0,
		numQuests = 0,
		maxQuests = GetQuestLogMaxAcceptable(),
		totalXP = 0,
		completedXP = 0,
		totalMoney = 0,
		lines = {},
	}

	local numEntries, numQuests = GetQuestLogEntryCounts()
	summary.numEntries = numEntries
	summary.numQuests = numQuests

	if not (C_QuestLog and C_QuestLog.GetInfo) then
		return summary
	end

	local canTurnIn = C_QuestLog.ReadyForTurnIn
	for i = 1, numEntries do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHeader and not info.isHidden then
			local questRef = info.questID or i
			local questXP = tonumber(GetQuestLogRewardXP and GetQuestLogRewardXP(questRef) or 0) or tonumber(GetQuestLogRewardXP and GetQuestLogRewardXP(i) or 0) or 0
			local money = tonumber(GetQuestLogRewardMoney and GetQuestLogRewardMoney(questRef) or 0) or tonumber(GetQuestLogRewardMoney and GetQuestLogRewardMoney(i) or 0) or 0
			local complete = (info.isComplete and info.isComplete > 0) or (canTurnIn and info.questID and canTurnIn(info.questID)) or false
			summary.totalXP = summary.totalXP + questXP
			summary.totalMoney = summary.totalMoney + money
			if complete then
				summary.completedXP = summary.completedXP + questXP
			end
			summary.lines[#summary.lines + 1] = {
				title = tostring(info.title or UNKNOWN),
				complete = complete and true or false,
				xp = questXP,
			}
		end
	end

	return summary
end

local function GetBagFreeSlots()
	local totalFree = 0
	local totalSlots = 0
	local firstBag = (BACKPACK_CONTAINER ~= nil) and BACKPACK_CONTAINER or 0
	local lastBag = (NUM_BAG_SLOTS ~= nil) and NUM_BAG_SLOTS or 4
	for bag = firstBag, lastBag do
		local freeSlots, bagSlots
		if C_Container and C_Container.GetContainerNumFreeSlots then
			freeSlots = C_Container.GetContainerNumFreeSlots(bag)
		elseif GetContainerNumFreeSlots then
			freeSlots = GetContainerNumFreeSlots(bag)
		end
		if C_Container and C_Container.GetContainerNumSlots then
			bagSlots = C_Container.GetContainerNumSlots(bag)
		elseif GetContainerNumSlots then
			bagSlots = GetContainerNumSlots(bag)
		end
		totalFree = totalFree + (tonumber(freeSlots) or 0)
		totalSlots = totalSlots + (tonumber(bagSlots) or 0)
	end
	return totalFree, totalSlots
end

local function GetAverageDurabilityPercent()
	if not (GetInventoryItemDurability and GetInventoryItemMaxDurability) then
		return nil, nil, nil
	end

	local currentTotal = 0
	local maxTotal = 0
	local broken = 0
	for slot = 1, 17 do
		local current = tonumber(GetInventoryItemDurability(slot))
		local max = tonumber(GetInventoryItemMaxDurability(slot))
		if current and max and max > 0 then
			currentTotal = currentTotal + current
			maxTotal = maxTotal + max
			if current <= 0 then
				broken = broken + 1
			end
		end
	end
	if maxTotal <= 0 then
		return nil, nil, nil
	end
	return (currentTotal / maxTotal) * 100, broken, maxTotal
end

local function GetPlayerCoordsPercent()
	if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then
		return nil, nil
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		return nil, nil
	end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos or not pos.GetXY then
		return nil, nil
	end
	local x, y = pos:GetXY()
	if not (x and y) then
		return nil, nil
	end
	return x * 100, y * 100
end

local function GetLatestMailSenders()
	if not GetLatestThreeSenders then
		return {}
	end
	local senders = { GetLatestThreeSenders() }
	local out = {}
	for i = 1, #senders do
		local name = senders[i]
		if type(name) == "string" and name ~= "" then
			out[#out + 1] = name
		end
	end
	return out
end

local function ShouldShowPetXPBar()
	if not (HasPetUI and HasPetUI()) then
		return false
	end
	if not (UnitExists and UnitExists("pet")) then
		return false
	end
	if not (GetPetExperience and UnitLevel) then
		return false
	end
	if IsLevelAtEffectiveMaxLevel then
		local petLevel = tonumber(UnitLevel("pet")) or 0
		if petLevel > 0 and IsLevelAtEffectiveMaxLevel(petLevel) then
			return false
		end
	end
	local _, maxXP = GetPetExperience()
	return (tonumber(maxXP) or 0) > 0
end

local function GetLatencyPair()
	if not GetNetStats then
		return 0, 0
	end
	local _, _, home, world = GetNetStats()
	return tonumber(home) or 0, tonumber(world) or 0
end

local function FormatMemoryKB(kb)
	kb = tonumber(kb) or 0
	if kb >= 1024 then
		return string.format("%.2f MB", kb / 1024)
	end
	return string.format("%d KB", math.floor(kb + 0.5))
end

local function GetTopAddonMemoryUsage(limit)
	local top = {}
	local maxEntries = math.max(1, tonumber(limit) or 8)
	if not (UpdateAddOnMemoryUsage and GetAddOnMemoryUsage and C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetAddOnInfo and C_AddOns.IsAddOnLoaded) then
		return top, 0
	end

	UpdateAddOnMemoryUsage()
	local totalKB = 0
	local numAddons = tonumber(C_AddOns.GetNumAddOns()) or 0
	for i = 1, numAddons do
		local loaded = C_AddOns.IsAddOnLoaded(i)
		if loaded then
			local name, title = C_AddOns.GetAddOnInfo(i)
			local memKB = tonumber(GetAddOnMemoryUsage(i)) or 0
			totalKB = totalKB + memKB
			top[#top + 1] = {
				name = tostring(title or name or ("Addon " .. i)),
				memKB = memKB,
			}
		end
	end

	table.sort(top, function(a, b)
		return (a.memKB or 0) > (b.memKB or 0)
	end)
	while #top > maxEntries do
		table.remove(top)
	end
	return top, totalKB
end

local function GetPlayerMovementSpeedPercent()
	if not GetUnitSpeed then
		return 0
	end
	local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")
	local speed = tonumber(runSpeed) or 0
	local isSwimming = IsSwimming and IsSwimming()
	local isFlying = IsFlying and IsFlying()
	if isSwimming then
		speed = tonumber(swimSpeed) or speed
	elseif isFlying then
		speed = tonumber(flightSpeed) or speed
	end
	if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
		local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
		if isGliding then
			speed = tonumber(forwardSpeed) or speed
		end
	end
	local base = tonumber(BASE_MOVEMENT_SPEED) or 7
	if base <= 0 then
		base = 7
	end
	return (speed / base) * 100
end

local function CollectTrackedCurrencies(maxCount)
	local out = {}
	local limit = math.max(1, tonumber(maxCount) or 8)
	if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo then
		local size = tonumber(C_CurrencyInfo.GetCurrencyListSize()) or 0
		for i = 1, size do
			local info = C_CurrencyInfo.GetCurrencyListInfo(i)
			if info and info.name and info.quantity and not info.isHeader and not info.isTypeUnused and not info.isShowInBackpack then
				out[#out + 1] = {
					name = tostring(info.name),
					quantity = tonumber(info.quantity) or 0,
					iconFileID = info.iconFileID,
				}
				if #out >= limit then
					break
				end
			end
		end
	end
	return out
end

local dataTextMemoryCacheValue = "Mem: 0.0MB"
local dataTextMemoryCacheTime = 0
local dataTextMemorySlotActive = false
local DATATEXT_REALTIME_BUILTINS = {
	FPS = true,
	Time = true,
	Memory = true,
	Latency = true,
	Combat = true,
	MoveSpeed = true,
	Coords = true,
	Range = true,
}

function addon:GetBuiltinDataTextMap()
	if self._builtinDataTextMap then
		return self._builtinDataTextMap
	end
	local map = {
		FPS = {
			label = "FPS",
			text = function()
				return ("FPS: %d"):format(math.floor((GetFramerate and GetFramerate() or 0) + 0.5))
			end,
			tooltip = function(tooltip)
				local fps = math.floor((GetFramerate and GetFramerate() or 0) + 0.5)
				local home, world = GetLatencyPair()
				tooltip:AddDoubleLine("Framerate", tostring(fps), 0.82, 0.82, 0.82, 1, 1, 1)
				tooltip:AddDoubleLine("Latency", string.format("Home %dms / World %dms", home, world), 0.82, 0.82, 0.82, 1, 1, 1)
			end,
		},
		Time = {
			label = "Time",
			text = function()
				local hour, minute = GetGameTime()
				return ("Time: %02d:%02d"):format(hour or 0, minute or 0)
			end,
		},
		Date = {
			label = "Date",
			text = function()
				return date and date("%Y-%m-%d") or "Date: --"
			end,
		},
		Memory = {
			label = "Memory",
			text = function()
				if not dataTextMemorySlotActive then
					return dataTextMemoryCacheValue
				end
				local now = GetTime and GetTime() or 0
				if (now - (dataTextMemoryCacheTime or 0)) >= 2 then
					local memMB = (collectgarbage("count") or 0) / 1024
					dataTextMemoryCacheValue = ("Mem: %.1fMB"):format(memMB)
					dataTextMemoryCacheTime = now
				end
				return dataTextMemoryCacheValue
			end,
			click = function()
				collectgarbage("collect")
			end,
			tooltip = function(tooltip)
				local top, totalKB = GetTopAddonMemoryUsage(10)
				tooltip:AddDoubleLine("Total AddOn Memory", FormatMemoryKB(totalKB), 0.82, 0.82, 0.82, 1, 1, 1)
				tooltip:AddLine(" ")
				for i = 1, #top do
					local data = top[i]
					tooltip:AddDoubleLine(data.name, FormatMemoryKB(data.memKB), 1, 1, 1, 0.82, 0.96, 1)
				end
				tooltip:AddLine(" ")
				tooltip:AddLine("Click to collect Lua garbage.", 0.70, 0.70, 0.70)
			end,
		},
		Gold = {
			label = "Gold",
			text = function()
				local money = GetMoney and GetMoney() or 0
				local gold = math.floor((money or 0) / 10000)
				return ("Gold: %d"):format(gold)
			end,
			tooltip = function(tooltip)
				local money = tonumber(GetMoney and GetMoney() or 0) or 0
				local gold = math.floor(money / 10000)
				local silver = math.floor((money % 10000) / 100)
				local copper = money % 100
				tooltip:AddDoubleLine("Character Gold", string.format("%dg %ds %dc", gold, silver, copper), 0.82, 0.82, 0.82, 1, 1, 1)
			end,
		},
		Coords = {
			label = "Coords",
			text = function()
				local x, y = GetPlayerCoordsPercent()
				if not x or not y then
					return "Coords: --,--"
				end
				return ("Coords: %.1f, %.1f"):format(x, y)
			end,
			click = function()
				if ToggleWorldMap then
					ToggleWorldMap()
				end
			end,
		},
		Latency = {
			label = "Latency",
			text = function()
				local home, world = GetLatencyPair()
				return ("MS: %d/%d"):format(home, world)
			end,
			tooltip = function(tooltip)
				local home, world = GetLatencyPair()
				tooltip:AddDoubleLine("Home", ("%dms"):format(home), 0.82, 0.82, 0.82, 1, 1, 1)
				tooltip:AddDoubleLine("World", ("%dms"):format(world), 0.82, 0.82, 0.82, 1, 1, 1)
			end,
		},
		Bags = {
			label = "Bags",
			text = function()
				local freeSlots, totalSlots = GetBagFreeSlots()
				if (tonumber(totalSlots) or 0) <= 0 then
					return ("Bags: %d"):format(tonumber(freeSlots) or 0)
				end
				return ("Bags: %d/%d"):format(tonumber(freeSlots) or 0, tonumber(totalSlots) or 0)
			end,
			click = function()
				if ToggleAllBags then
					ToggleAllBags()
				end
			end,
		},
		Durability = {
			label = "Durability",
			text = function()
				local avg = GetAverageDurabilityPercent()
				if not avg then
					return "Dur: --%"
				end
				return ("Dur: %d%%"):format(math.floor(avg + 0.5))
			end,
			click = function()
				if ToggleCharacter then
					ToggleCharacter("PaperDollFrame")
				elseif CharacterFrame_Toggle then
					CharacterFrame_Toggle()
				end
			end,
			tooltip = function(tooltip)
				local avg, broken = GetAverageDurabilityPercent()
				if not avg then
					tooltip:AddLine("Durability unavailable.", 0.9, 0.35, 0.35)
					return
				end
				tooltip:AddDoubleLine("Average", ("%d%%"):format(math.floor(avg + 0.5)), 0.82, 0.82, 0.82, 1, 1, 1)
				tooltip:AddDoubleLine("Broken Items", tostring(tonumber(broken) or 0), 0.82, 0.82, 0.82, 1, 1, 1)
			end,
		},
		Range = {
			label = "Range",
			text = function()
				if not (LibRangeCheck and LibRangeCheck.GetRange and UnitExists and UnitExists("target")) then
					return "Range: --"
				end
				local minRange, maxRange = LibRangeCheck:GetRange("target")
				if minRange and maxRange then
					return ("Range: %d-%d"):format(math.floor(minRange + 0.5), math.floor(maxRange + 0.5))
				elseif maxRange then
					return ("Range: <=%d"):format(math.floor(maxRange + 0.5))
				elseif minRange then
					return ("Range: >=%d"):format(math.floor(minRange + 0.5))
				end
				return "Range: --"
			end,
			tooltip = function(tooltip)
				tooltip:AddLine("Target range estimate.", 0.75, 0.75, 0.75)
				if not (UnitExists and UnitExists("target")) then
					tooltip:AddLine("No target.", 0.9, 0.35, 0.35)
				end
			end,
		},
		Quests = {
			label = "Quests",
			text = function()
				local _, numQuests = GetQuestLogEntryCounts()
				local maxQuests = GetQuestLogMaxAcceptable()
				return ("Quests: %d/%d"):format(tonumber(numQuests) or 0, tonumber(maxQuests) or 25)
			end,
			click = function()
				if ToggleQuestLog then
					pcall(ToggleQuestLog)
				end
			end,
			tooltip = function(tooltip)
				local summary = BuildQuestDataTextSummary()
				local xpToLevel = math.max(1, tonumber(UnitXPMax and UnitXPMax("player") or 0) or 1)
				tooltip:AddDoubleLine("Progress", ("%d/%d"):format(summary.numQuests, summary.maxQuests), 0.82, 0.82, 0.82, 1, 1, 1)
				tooltip:AddDoubleLine("Total Quest XP", string.format("%s (%.1f%%)", BreakUpLargeNumbers and BreakUpLargeNumbers(summary.totalXP) or tostring(summary.totalXP), (summary.totalXP / xpToLevel) * 100), 0.82, 0.82, 0.82, 1, 1, 1)
				tooltip:AddDoubleLine("Completed XP", string.format("%s (%.1f%%)", BreakUpLargeNumbers and BreakUpLargeNumbers(summary.completedXP) or tostring(summary.completedXP), (summary.completedXP / xpToLevel) * 100), 0.82, 0.82, 0.82, 1, 1, 1)
				local linesShown = 0
				for i = 1, #summary.lines do
					local line = summary.lines[i]
					if linesShown == 0 then
						tooltip:AddLine(" ")
					end
					if linesShown >= 8 then
						tooltip:AddLine("...", 0.7, 0.7, 0.7)
						break
					end
					local color = line.complete and "|cff33ff99" or "|cffffcc66"
					tooltip:AddDoubleLine(line.title, color .. ((line.complete and "Complete") or "Incomplete") .. "|r", 1, 1, 1, 1, 1, 1)
					linesShown = linesShown + 1
				end
			end,
		},
		Mail = {
			label = "Mail",
			text = function()
				local hasMail = HasNewMail and HasNewMail()
				return hasMail and "Mail: New" or "Mail: None"
			end,
			tooltip = function(tooltip)
				local hasMail = HasNewMail and HasNewMail()
				tooltip:AddLine(hasMail and "New Mail" or "No Mail", hasMail and 0.2 or 0.7, 1, hasMail and 0.2 or 0.7)
				local senders = GetLatestMailSenders()
				if #senders > 0 then
					tooltip:AddLine(" ")
					for i = 1, #senders do
						tooltip:AddLine(senders[i], 1, 1, 1)
					end
				end
			end,
		},
		Combat = {
			label = "Combat",
			text = function()
				local now = GetTime and GetTime() or 0
				local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
				if inCombat then
					if not addon._combatDataTextStartTime then
						addon._combatDataTextStartTime = now
					end
					local elapsed = math.max(0, now - addon._combatDataTextStartTime)
					local mins = math.floor(elapsed / 60)
					local secs = math.floor(elapsed % 60)
					return ("Combat: %02d:%02d"):format(mins, secs)
				end
				addon._combatDataTextStartTime = nil
				return "Combat: 00:00"
			end,
		},
		MoveSpeed = {
			label = "MoveSpeed",
			text = function()
				local pct = GetPlayerMovementSpeedPercent()
				return ("Speed: %.1f%%"):format(pct)
			end,
		},
		Currencies = {
			label = "Currencies",
			text = function()
				local list = CollectTrackedCurrencies(2)
				if #list == 0 then
					return "Currency: --"
				end
				local parts = {}
				for i = 1, #list do
					local info = list[i]
					parts[#parts + 1] = ("%s %s"):format(info.name, FormatCompactValue(info.quantity))
				end
				return table.concat(parts, " | ")
			end,
			tooltip = function(tooltip)
				local list = CollectTrackedCurrencies(20)
				if #list == 0 then
					tooltip:AddLine("No tracked currencies.", 0.9, 0.35, 0.35)
					return
				end
				for i = 1, #list do
					local info = list[i]
					local icon = info.iconFileID and ("|T%d:14:14:0:0:64:64:4:60:4:60|t "):format(info.iconFileID) or ""
					tooltip:AddDoubleLine(icon .. info.name, BreakUpLargeNumbers and BreakUpLargeNumbers(info.quantity) or tostring(info.quantity), 1, 1, 1, 0.82, 0.96, 1)
				end
			end,
		},
	}
	self._builtinDataTextMap = map
	return map
end

function addon:GetAvailableDataTextSources()
	local list = {}
	local builtins = self:GetBuiltinDataTextMap()
	for key in pairs(builtins) do
		list[#list + 1] = { value = key, text = key }
	end
	if LDB and LDB.DataObjectIterator then
		for name in LDB:DataObjectIterator() do
			list[#list + 1] = { value = "LDB:" .. tostring(name), text = "LDB: " .. tostring(name) }
		end
	end
	table.sort(list, function(a, b)
		return tostring(a.text) < tostring(b.text)
	end)
	return list
end

function addon:GetDataTextSource(rawValue)
	local value = tostring(rawValue or "")
	local builtins = self:GetBuiltinDataTextMap()
	if builtins[value] then
		return "builtin", value, builtins[value]
	end
	local ldbPrefix = "LDB:"
	if value:sub(1, #ldbPrefix) == ldbPrefix and LDB and LDB.GetDataObjectByName then
		local name = value:sub(#ldbPrefix + 1)
		local obj = LDB:GetDataObjectByName(name)
		if obj then
			return "ldb", name, obj
		end
	end
	return nil, nil, nil
end

function addon:ScheduleUpdateDataTextPanel(delay)
	local wait = tonumber(delay) or 0.05
	wait = math.max(0, math.min(0.5, wait))
	if self._dataTextRefreshTimer and self._dataTextRefreshTimer.Cancel then
		return
	end
	self._dataTextRefreshTimer = C_Timer.NewTimer(wait, function()
		self._dataTextRefreshTimer = nil
		if self and self.UpdateDataTextPanel then
			self:UpdateDataTextPanel()
		end
	end)
end

function addon:UpdateDataTextPanel()
	local cfg = self.db and self.db.profile and self.db.profile.datatext
	if not (cfg and cfg.enabled and self.dataTextPanel and self.dataTextPanel.buttons) then
		if self.dataTextPanel then
			self.dataTextPanel:Hide()
		end
		return
	end

	local panelCfg = cfg.panel or defaults.profile.datatext.panel
	local panel = self.dataTextPanel
	local width = math.max(280, tonumber(panelCfg.width) or 520)
	local height = math.max(16, tonumber(panelCfg.height) or 20)
	local mode = tostring(cfg.positionMode or "ANCHOR")
	local editModePosition = IsEditModePosition(mode)
	if editModePosition and cfg.positionMode ~= "EDIT_MODE" then
		cfg.positionMode = "EDIT_MODE"
	end
	local anchor = tostring(panelCfg.anchor or "TOP")
	local relPoint = anchor
	if anchor == "TOP" then
		relPoint = "TOP"
	elseif anchor == "BOTTOM" then
		relPoint = "BOTTOM"
	else
		anchor = "TOP"
		relPoint = "TOP"
	end
	local offsetX = tonumber(panelCfg.offsetX) or 0
	local offsetY = tonumber(panelCfg.offsetY) or -14
	local mouseover = panelCfg.mouseover == true
	local backdropDisabled = panelCfg.backdrop == false

	local layout = panel._sufLayoutCache or {}
	if layout.width ~= width or layout.height ~= height then
		panel:SetSize(width, height)
		layout.width = width
		layout.height = height
	end

	local defaultPoint = { relPoint, "UIParent", relPoint, offsetX, offsetY }
	if editModePosition then
		if layout.positionMode ~= "EDIT_MODE" then
			self:ApplyStoredMoverPosition(panel, "datatext_panel", defaultPoint)
		end
	else
		if
			layout.positionMode == "EDIT_MODE"
			or layout.anchor ~= anchor
			or layout.relPoint ~= relPoint
			or layout.offsetX ~= offsetX
			or layout.offsetY ~= offsetY
		then
			panel:ClearAllPoints()
			panel:SetPoint(anchor, UIParent, relPoint, offsetX, offsetY)
		end
		layout.anchor = anchor
		layout.relPoint = relPoint
		layout.offsetX = offsetX
		layout.offsetY = offsetY
	end
	layout.positionMode = editModePosition and "EDIT_MODE" or "ANCHOR"
	if layout.mouseover ~= mouseover then
		panel:SetAlpha((mouseover and 0) or 1)
		layout.mouseover = mouseover
	end
	if layout.backdropDisabled ~= backdropDisabled then
		if backdropDisabled then
			self:ApplySUFBackdropColors(panel, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, false)
		else
			local style = GetBackdropTheme("subtle")
			if style then
				self:ApplySUFBackdropColors(panel, style.bg, style.border, false)
			else
				self:ApplySUFBackdropColors(panel, { 0.05, 0.06, 0.08, 0.86 }, { 0.24, 0.24, 0.24, 0.95 }, false)
			end
		end
		layout.backdropDisabled = backdropDisabled
	end
	local dragUnlocked = editModePosition and not (InCombatLockdown and InCombatLockdown())
	panel:SetFrameStrata(dragUnlocked and "MEDIUM" or "LOW")
	if panel.unlockHandle then
		local showHandle = ShouldShowDragHandle(panel.__sufIsMouseOver)
		panel.unlockHandle:SetShown(showHandle)
	end
	panel._sufLayoutCache = layout

	local slots = cfg.slots or defaults.profile.datatext.slots
	local hasRealtimeSource = false
	local hasMemorySource = false
	for i = 1, #DATATEXT_SLOT_ORDER do
		local slot = DATATEXT_SLOT_ORDER[i]
		local button = panel.buttons[slot]
		if button then
			local rawSource = slots[slot]
			if button._sufRawSource ~= rawSource then
				local sourceType, sourceName, sourceObj = self:GetDataTextSource(rawSource)
				button.sourceType = sourceType
				button.sourceName = sourceName
				button.sourceObj = sourceObj
				button._sufRawSource = rawSource
			end
			local text = ""
			local sourceType = button.sourceType
			local sourceObj = button.sourceObj
			local sourceName = button.sourceName
			if sourceType == "builtin" and tostring(sourceName or "") == "Memory" then
				hasMemorySource = true
			end
			if sourceType == "builtin" and DATATEXT_REALTIME_BUILTINS[tostring(sourceName or "")] then
				hasRealtimeSource = true
			elseif sourceType == "ldb" then
				hasRealtimeSource = true
			end
			if sourceType == "builtin" and sourceObj and sourceObj.text then
				text = tostring(sourceObj.text() or "")
			elseif sourceType == "ldb" and sourceObj then
				text = tostring(sourceObj.text or sourceObj.label or sourceName or "")
			end
			if button._sufText ~= text then
				button.text:SetText(text)
				button._sufText = text
			end
		end
	end
	panel._sufNeedsRealtimeTicker = hasRealtimeSource
	dataTextMemorySlotActive = hasMemorySource

	panel:SetShown(true)
end

function addon:ScheduleUpdateDataBars(delay)
	local wait = tonumber(delay) or 0.05
	wait = math.max(0, math.min(0.5, wait))
	if self._dataBarsRefreshTimer and self._dataBarsRefreshTimer.Cancel then
		return
	end
	self._dataBarsRefreshTimer = C_Timer.NewTimer(wait, function()
		self._dataBarsRefreshTimer = nil
		if self and self.UpdateDataBars then
			self:UpdateDataBars()
		end
	end)
end

function addon:EnsureDataTextPanel()
	if self.dataTextPanel then
		self:UpdateDataTextPanel()
		return
	end
	local panel = CreateFrame("Frame", "SUFDataTextPanel", UIParent, "BackdropTemplate")
	panel:SetFrameStrata("LOW")
	panel:SetClampedToScreen(true)
	panel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(panel, "subtle")
	end
	panel.buttons = {}
	panel.__sufIsMouseOver = false
	panel:SetScript("OnEnter", function(widget)
		widget.__sufIsMouseOver = true
		local panelCfg = self.db and self.db.profile and self.db.profile.datatext and self.db.profile.datatext.panel
		if panelCfg and panelCfg.mouseover then
			widget:SetAlpha(1)
		end
		if widget.unlockHandle then
			widget.unlockHandle:SetShown(ShouldShowDragHandle(widget.__sufIsMouseOver))
		end
	end)
	panel:SetScript("OnLeave", function(widget)
		widget.__sufIsMouseOver = false
		local panelCfg = self.db and self.db.profile and self.db.profile.datatext and self.db.profile.datatext.panel
		if panelCfg and panelCfg.mouseover then
			widget:SetAlpha(0)
		end
		if widget.unlockHandle then
			widget.unlockHandle:Hide()
		end
	end)

	local anchors = {
		left = { "LEFT", "LEFT", 8 },
		center = { "CENTER", "CENTER", 0 },
		right = { "RIGHT", "RIGHT", -8 },
	}
	for slot, info in pairs(anchors) do
		local button = CreateFrame("Button", nil, panel)
		button:SetSize(160, 18)
		button:SetPoint(info[1], panel, info[2], info[3], 0)
		button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.text:SetJustifyH("CENTER")
		button:SetScript("OnEnter", function(widget)
			if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
				GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
				local obj = widget.sourceObj
				local title = widget.sourceName or "DataText"
				GameTooltip:AddLine(tostring(title), 1, 1, 1)
				if widget.sourceType == "ldb" and obj and obj.OnTooltipShow and type(obj.OnTooltipShow) == "function" then
					obj.OnTooltipShow(GameTooltip)
				elseif widget.sourceType == "builtin" then
					if obj and obj.tooltip and type(obj.tooltip) == "function" then
						obj.tooltip(GameTooltip)
					else
						GameTooltip:AddLine("Built-in source", 0.75, 0.75, 0.75)
					end
				end
				GameTooltip:Show()
			end
		end)
		button:SetScript("OnLeave", function()
			if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
				GameTooltip:Hide()
			end
		end)
		button:SetScript("OnMouseDown", function(widget, mouseButton)
			if mouseButton == "LeftButton" and IsDataTextDragContextActive(addon) then
				local parent = widget:GetParent()
				if parent and parent.unlockHandle then
					parent.unlockHandle:SetShown(ShouldShowDragHandle(parent.__sufIsMouseOver))
				end
				ForwardDragStartFromChild(widget:GetParent())
			end
		end)
		button:SetScript("OnMouseUp", function(widget, mouseButton)
			if mouseButton == "LeftButton" and IsDataTextDragContextActive(addon) then
				ForwardDragStopFromChild(widget:GetParent())
				local parent = widget:GetParent()
				if parent and parent.unlockHandle then
					parent.unlockHandle:Hide()
				end
			end
		end)
		button:SetScript("OnClick", function(widget, mouseButton)
			if IsDataTextDragContextActive(addon) then
				return
			end
			local obj = widget.sourceObj
			if widget.sourceType == "ldb" and obj and obj.OnClick then
				pcall(obj.OnClick, obj, mouseButton)
			elseif widget.sourceType == "builtin" and obj and obj.click and type(obj.click) == "function" then
				pcall(obj.click, mouseButton)
			end
		end)
		panel.buttons[slot] = button
	end

	local unlockHandle = CreateFrame("Frame", nil, panel, "BackdropTemplate")
	unlockHandle:SetAllPoints(panel)
	unlockHandle:SetFrameStrata(panel:GetFrameStrata() or "LOW")
	unlockHandle:SetFrameLevel((panel:GetFrameLevel() or 1) + 20)
	unlockHandle:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(unlockHandle, "subtle")
	else
		self:ApplySUFBackdropColors(unlockHandle, { 0.08, 0.14, 0.24, 0.38 }, { 0.40, 0.68, 0.98, 0.95 }, false)
	end
	unlockHandle:EnableMouse(false)
	unlockHandle:Hide()
	local handleText = unlockHandle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	handleText:SetPoint("CENTER", unlockHandle, "CENTER", 0, 0)
	handleText:SetText("DataText: Drag to Move")
	unlockHandle.text = handleText
	panel.unlockHandle = unlockHandle

	self.dataTextPanel = panel
	self:EnableMovableFrame(panel, true, "datatext_panel", { "TOP", "UIParent", "TOP", 0, -14 }, function()
		local cfg = addon and addon.db and addon.db.profile and addon.db.profile.datatext
		local editModeDrag = cfg and IsEditModePosition(cfg.positionMode)
		panel.__sufDataTextUsedShiftFallback = IsShiftDragRequested() and not editModeDrag
		return IsDataTextDragContextActive(addon)
	end, function(movableFrame)
		local usedShiftFallback = movableFrame and movableFrame.__sufDataTextUsedShiftFallback
		if movableFrame then
			movableFrame.__sufDataTextUsedShiftFallback = nil
		end
		if usedShiftFallback then
			local cfg = addon and addon.db and addon.db.profile and addon.db.profile.datatext
			if cfg and not IsEditModePosition(cfg.positionMode) then
				cfg.positionMode = "EDIT_MODE"
			end
		end
		addon:UpdateDataTextPanel()
	end)
	self:UpdateDataTextPanel()
end

function addon:UpdateDataBars()
	local cfg = self.db and self.db.profile and self.db.profile.databars
	if not (cfg and cfg.enabled and self.dataBarsFrame and self.dataBarsFrame.xp and self.dataBarsFrame.reputation and self.dataBarsFrame.petxp) then
		if self.dataBarsFrame then
			self.dataBarsFrame:Hide()
		end
		return
	end

	local root = self.dataBarsFrame
	local barHeight = math.max(8, tonumber(cfg.height) or 10)
	local xpEnabled = cfg.showXP ~= false
	local repEnabled = cfg.showReputation ~= false
	local petEnabled = cfg.showPetXP ~= false
	local petVisible = petEnabled and ShouldShowPetXPBar()
	local barCount = (xpEnabled and 1 or 0) + (repEnabled and 1 or 0) + (petVisible and 1 or 0)
	if barCount < 1 then
		barCount = 1
	end
	root:SetSize(math.max(280, tonumber(cfg.width) or 520), (barHeight * barCount) + 4 + ((barCount - 1) * 2))
	local mode = tostring(cfg.positionMode or "ANCHOR")
	local editModePosition = IsEditModePosition(mode)
	if editModePosition and cfg.positionMode ~= "EDIT_MODE" then
		cfg.positionMode = "EDIT_MODE"
	end
	local defaultAnchor = tostring(cfg.anchor or "TOP")
	local relPoint = defaultAnchor == "BOTTOM" and "BOTTOM" or "TOP"
	local defaultPoint = { relPoint, "UIParent", relPoint, tonumber(cfg.offsetX) or 0, tonumber(cfg.offsetY) or -2 }
	if editModePosition then
		self:ApplyStoredMoverPosition(root, "databars_root", defaultPoint)
	else
		root:ClearAllPoints()
		root:SetPoint(relPoint, UIParent, relPoint, tonumber(cfg.offsetX) or 0, tonumber(cfg.offsetY) or -2)
	end
	local dragUnlocked = editModePosition and not (InCombatLockdown and InCombatLockdown())
	root:SetFrameStrata(dragUnlocked and "MEDIUM" or "LOW")
	root:EnableMouse(true)
	if root.unlockHandle then
		local showHandle = ShouldShowDragHandle(root.__sufIsMouseOver)
		root.unlockHandle:SetShown(showHandle)
	end
	root:SetShown(true)

	local xpBar = root.xp
	local repBar = root.reputation
	local petBar = root.petxp
	xpBar:SetHeight(barHeight)
	repBar:SetHeight(barHeight)
	petBar:SetHeight(barHeight)

	local previousBar = nil
	local function AnchorBar(bar)
		bar:ClearAllPoints()
		if not previousBar then
			bar:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -2)
			bar:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, -2)
		else
			bar:SetPoint("TOPLEFT", previousBar, "BOTTOMLEFT", 0, -2)
			bar:SetPoint("TOPRIGHT", previousBar, "BOTTOMRIGHT", 0, -2)
		end
		previousBar = bar
	end
	if xpEnabled then
		AnchorBar(xpBar)
	end
	if repEnabled then
		AnchorBar(repBar)
	end
	if petVisible then
		AnchorBar(petBar)
	end

	local curXP = UnitXP and UnitXP("player") or 0
	local maxXP = UnitXPMax and UnitXPMax("player") or 0
	if maxXP <= 0 then
		maxXP = 1
	end
	xpBar:SetMinMaxValues(0, maxXP)
	xpBar:SetValue(curXP)
	do
		local c = GetDataBarsTheme().xp
		if c then
			xpBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
		else
			xpBar:SetStatusBarColor(0.20, 0.45, 0.95, 0.92)
		end
	end
	xpBar.text:SetText(("XP %d%%"):format(math.floor((curXP / maxXP) * 100 + 0.5)))
	xpBar.text:SetShown(cfg.showText ~= false)
	xpBar:SetShown(xpEnabled)
	ApplyFadeState(xpBar, cfg.xpFade or defaults.profile.databars.xpFade, root.__sufIsMouseOver)

	if xpBar.restedOverlay then
		local rested = tonumber(GetXPExhaustion and GetXPExhaustion() or 0) or 0
		local overlayEnabled = (cfg.showRestedOverlay ~= false) and rested > 0 and maxXP > 0 and xpEnabled
		if overlayEnabled then
			local barWidth = xpBar:GetWidth() or 0
			local curRatio = math.max(0, math.min(1, curXP / maxXP))
			local availableRatio = math.max(0, 1 - curRatio)
			local restedRatio = math.min(availableRatio, math.max(0, rested / maxXP))
			if restedRatio <= 0 then
				xpBar.restedOverlay:SetShown(false)
				overlayEnabled = false
			end
		end
		if overlayEnabled then
			local curRatio = math.max(0, math.min(1, curXP / maxXP))
			local availableRatio = math.max(0, 1 - curRatio)
			local restedRatio = math.min(availableRatio, math.max(0, rested / maxXP))
			local barWidth = xpBar:GetWidth() or 0
			local restedWidth = math.floor(barWidth * restedRatio + 0.5)
			restedWidth = math.max(1, restedWidth)
			xpBar.restedOverlay:ClearAllPoints()
			xpBar.restedOverlay:SetPoint("LEFT", xpBar:GetStatusBarTexture() or xpBar, "RIGHT", 0, 0)
			xpBar.restedOverlay:SetPoint("TOP", xpBar, "TOP", 0, 0)
			xpBar.restedOverlay:SetPoint("BOTTOM", xpBar, "BOTTOM", 0, 0)
			xpBar.restedOverlay:SetWidth(restedWidth)
			xpBar.restedOverlay:SetShown(true)
		else
			xpBar.restedOverlay:SetShown(false)
		end
	end

	if xpBar.questOverlay then
		local questXP = GetQuestLogXPRewardTotal()
		local overlayEnabled = (cfg.showQuestXPOverlay ~= false) and questXP > 0 and maxXP > 0 and xpEnabled
		if overlayEnabled then
			local curRatio = math.max(0, math.min(1, curXP / maxXP))
			local availableRatio = math.max(0, 1 - curRatio)
			local questRatio = math.min(availableRatio, math.max(0, questXP / maxXP))
			if questRatio <= 0 then
				xpBar.questOverlay:SetShown(false)
				overlayEnabled = false
			end
		end
		if overlayEnabled then
			local curRatio = math.max(0, math.min(1, curXP / maxXP))
			local availableRatio = math.max(0, 1 - curRatio)
			local questRatio = math.min(availableRatio, math.max(0, questXP / maxXP))
			local barWidth = xpBar:GetWidth() or 0
			local questWidth = math.floor(barWidth * questRatio + 0.5)
			questWidth = math.max(1, questWidth)
			xpBar.questOverlay:ClearAllPoints()
			xpBar.questOverlay:SetPoint("LEFT", xpBar:GetStatusBarTexture() or xpBar, "RIGHT", 0, 0)
			xpBar.questOverlay:SetPoint("TOP", xpBar, "TOP", 0, 0)
			xpBar.questOverlay:SetPoint("BOTTOM", xpBar, "BOTTOM", 0, 0)
			xpBar.questOverlay:SetWidth(questWidth)
			xpBar.questOverlay:SetShown(true)
		else
			xpBar.questOverlay:SetShown(false)
		end
	end

	local factionName, _, minRep, maxRep, curRep = GetWatchedFactionInfoCompat()
	if factionName and maxRep and maxRep > minRep then
		local cur = math.max(0, (curRep or 0) - (minRep or 0))
		local max = math.max(1, (maxRep or 1) - (minRep or 0))
		repBar:SetMinMaxValues(0, max)
		repBar:SetValue(cur)
		do
			local c = GetDataBarsTheme().reputation
			if c then
				repBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
			else
				repBar:SetStatusBarColor(0.14, 0.78, 0.31, 0.92)
			end
		end
		repBar.text:SetText(("%s %d%%"):format(tostring(factionName), math.floor((cur / max) * 100 + 0.5)))
		repBar.text:SetShown(cfg.showText ~= false)
		repBar:SetShown(repEnabled)
	else
		repBar:SetShown(false)
	end

	if petVisible then
		local curPetXP, maxPetXP = GetPetExperience()
		curPetXP = tonumber(curPetXP) or 0
		maxPetXP = math.max(1, tonumber(maxPetXP) or 1)
		petBar:SetMinMaxValues(0, maxPetXP)
		petBar:SetValue(curPetXP)
		do
			local c = GetDataBarsTheme().petxp
			if c then
				petBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
			else
				petBar:SetStatusBarColor(0.70, 0.26, 0.96, 0.92)
			end
		end
		petBar.text:SetText(("Pet XP %d%%"):format(math.floor((curPetXP / maxPetXP) * 100 + 0.5)))
		petBar.text:SetShown(cfg.showText ~= false)
		petBar:SetShown(true)
	else
		petBar:SetShown(false)
	end
end

function addon:EnsureDataBars()
	if self.dataBarsFrame then
		self:UpdateDataBars()
		return
	end
	local frame = CreateFrame("Frame", "SUFDataBars", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("LOW")
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(frame, "subtle")
	else
		self:ApplySUFBackdropColors(frame, { 0.03, 0.03, 0.03, 0.84 }, { 0.18, 0.18, 0.18, 0.95 }, false)
	end
	
	frame.__sufIsMouseOver = false
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", function(widget)
		widget.__sufIsMouseOver = true
		if widget.unlockHandle then
			widget.unlockHandle:SetShown(ShouldShowDragHandle(widget.__sufIsMouseOver))
		end
		local cfg = addon and addon.db and addon.db.profile and addon.db.profile.databars
		ApplyFadeState(widget.xp, cfg and cfg.xpFade or defaults.profile.databars.xpFade, true)
	end)
	frame:SetScript("OnLeave", function(widget)
		widget.__sufIsMouseOver = false
		if widget.unlockHandle then
			widget.unlockHandle:Hide()
		end
		local cfg = addon and addon.db and addon.db.profile and addon.db.profile.databars
		ApplyFadeState(widget.xp, cfg and cfg.xpFade or defaults.profile.databars.xpFade, false)
	end)
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:SetScript("OnEvent", function(widget, event)
		if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
			local cfg = addon and addon.db and addon.db.profile and addon.db.profile.databars
			ApplyFadeState(widget.xp, cfg and cfg.xpFade or defaults.profile.databars.xpFade, widget.__sufIsMouseOver)
		end
	end)

	local xp = CreateFrame("StatusBar", nil, frame)
	xp:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	xp:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
	xp:SetStatusBarTexture(DEFAULT_TEXTURE)
	xp.text = xp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	xp.text:SetPoint("CENTER", xp, "CENTER", 0, 0)
	xp:EnableMouse(true)
	xp.restedOverlay = xp:CreateTexture(nil, "ARTWORK", nil, 1)
	xp.restedOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
	do
		local c = GetDataBarsTheme().rested
		if c then
			xp.restedOverlay:SetVertexColor(c[1], c[2], c[3], c[4])
		else
			xp.restedOverlay:SetVertexColor(0.25, 0.60, 1.00, 0.40)
		end
	end
	xp.restedOverlay:Hide()
	xp.questOverlay = xp:CreateTexture(nil, "ARTWORK", nil, 2)
	xp.questOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
	do
		local c = GetDataBarsTheme().quest
		if c then
			xp.questOverlay:SetVertexColor(c[1], c[2], c[3], c[4])
		else
			xp.questOverlay:SetVertexColor(1.00, 0.85, 0.30, 0.32)
		end
	end
	xp.questOverlay:Hide()
	xp:SetScript("OnEnter", function(widget)
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
			local curXP = tonumber(UnitXP and UnitXP("player") or 0) or 0
			local maxXP = math.max(1, tonumber(UnitXPMax and UnitXPMax("player") or 0) or 1)
			local rested = tonumber(GetXPExhaustion and GetXPExhaustion() or 0) or 0
			local questXP = tonumber(GetQuestLogXPRewardTotal()) or 0
			GameTooltip:AddLine("Experience", 1, 1, 1)
			GameTooltip:AddDoubleLine("Current", ("%d / %d (%d%%)"):format(curXP, maxXP, math.floor((curXP / maxXP) * 100 + 0.5)), 0.82, 0.82, 0.82, 1, 1, 1)
			GameTooltip:AddDoubleLine("Remaining", tostring(math.max(0, maxXP - curXP)), 0.82, 0.82, 0.82, 1, 1, 1)
			GameTooltip:AddDoubleLine("Rested Bonus", tostring(rested), 0.82, 0.82, 0.82, 1, 1, 1)
			GameTooltip:AddDoubleLine("Quest XP", tostring(questXP), 0.82, 0.82, 0.82, 1, 1, 1)
			GameTooltip:Show()
		end
	end)
	xp:SetScript("OnLeave", function()
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:Hide()
		end
	end)
	xp:SetScript("OnMouseDown", function(widget, mouseButton)
		if mouseButton == "LeftButton" and IsDataBarsDragContextActive(addon) then
			local parent = widget:GetParent()
			if parent and parent.unlockHandle then
				parent.unlockHandle:SetShown(ShouldShowDragHandle(parent.__sufIsMouseOver))
			end
			ForwardDragStartFromChild(widget:GetParent())
		end
	end)
	xp:SetScript("OnMouseUp", function(widget, mouseButton)
		if mouseButton == "LeftButton" and IsDataBarsDragContextActive(addon) then
			ForwardDragStopFromChild(widget:GetParent())
			local parent = widget:GetParent()
			if parent and parent.unlockHandle then
				parent.unlockHandle:Hide()
			end
			return
		end
		if mouseButton == "LeftButton" and ToggleCharacter then
			pcall(ToggleCharacter, "TokenFrame")
		end
	end)
	frame.xp = xp

	local rep = CreateFrame("StatusBar", nil, frame)
	rep:SetPoint("TOPLEFT", xp, "BOTTOMLEFT", 0, -2)
	rep:SetPoint("TOPRIGHT", xp, "BOTTOMRIGHT", 0, -2)
	rep:SetStatusBarTexture(DEFAULT_TEXTURE)
	rep.text = rep:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	rep.text:SetPoint("CENTER", rep, "CENTER", 0, 0)
	rep:EnableMouse(true)
	rep:SetScript("OnEnter", function(widget)
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
			local factionName, reaction, minRep, maxRep, curRep = GetWatchedFactionInfoCompat()
			if factionName and maxRep and maxRep > minRep then
				local cur = math.max(0, (curRep or 0) - (minRep or 0))
				local max = math.max(1, (maxRep or 1) - (minRep or 0))
				GameTooltip:AddLine("Reputation", 1, 1, 1)
				GameTooltip:AddDoubleLine("Faction", tostring(factionName), 0.82, 0.82, 0.82, 1, 1, 1)
				GameTooltip:AddDoubleLine("Standing", tostring(reaction or "?"), 0.82, 0.82, 0.82, 1, 1, 1)
				GameTooltip:AddDoubleLine("Progress", ("%d / %d (%d%%)"):format(cur, max, math.floor((cur / max) * 100 + 0.5)), 0.82, 0.82, 0.82, 1, 1, 1)
			else
				GameTooltip:AddLine("No watched faction.", 0.9, 0.35, 0.35)
			end
			GameTooltip:Show()
		end
	end)
	rep:SetScript("OnLeave", function()
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:Hide()
		end
	end)
	rep:SetScript("OnMouseDown", function(widget, mouseButton)
		if mouseButton == "LeftButton" and IsDataBarsDragContextActive(addon) then
			local parent = widget:GetParent()
			if parent and parent.unlockHandle then
				parent.unlockHandle:SetShown(ShouldShowDragHandle(parent.__sufIsMouseOver))
			end
			ForwardDragStartFromChild(widget:GetParent())
		end
	end)
	rep:SetScript("OnMouseUp", function(widget, mouseButton)
		if mouseButton == "LeftButton" and IsDataBarsDragContextActive(addon) then
			ForwardDragStopFromChild(widget:GetParent())
			local parent = widget:GetParent()
			if parent and parent.unlockHandle then
				parent.unlockHandle:Hide()
			end
			return
		end
		if mouseButton == "LeftButton" and ToggleCharacter then
			pcall(ToggleCharacter, "ReputationFrame")
		end
	end)
	frame.reputation = rep

	local petxp = CreateFrame("StatusBar", nil, frame)
	petxp:SetPoint("TOPLEFT", rep, "BOTTOMLEFT", 0, -2)
	petxp:SetPoint("TOPRIGHT", rep, "BOTTOMRIGHT", 0, -2)
	petxp:SetStatusBarTexture(DEFAULT_TEXTURE)
	petxp.text = petxp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	petxp.text:SetPoint("CENTER", petxp, "CENTER", 0, 0)
	petxp:EnableMouse(true)
	petxp:SetScript("OnEnter", function(widget)
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:SetOwner(widget, "ANCHOR_BOTTOMRIGHT")
			local curPetXP, maxPetXP = 0, 1
			if GetPetExperience then
				curPetXP, maxPetXP = GetPetExperience()
			end
			curPetXP = tonumber(curPetXP) or 0
			maxPetXP = math.max(1, tonumber(maxPetXP) or 1)
			local remaining = math.max(0, maxPetXP - curPetXP)
			GameTooltip:AddLine("Pet Experience", 1, 1, 1)
			GameTooltip:AddDoubleLine("Current", ("%d / %d (%d%%)"):format(curPetXP, maxPetXP, math.floor((curPetXP / maxPetXP) * 100 + 0.5)), 0.82, 0.82, 0.82, 1, 1, 1)
			GameTooltip:AddDoubleLine("Remaining", tostring(remaining), 0.82, 0.82, 0.82, 1, 1, 1)
			GameTooltip:Show()
		end
	end)
	petxp:SetScript("OnLeave", function()
		if GameTooltip and not (GameTooltip.IsForbidden and GameTooltip:IsForbidden()) then
			GameTooltip:Hide()
		end
	end)
	petxp:SetScript("OnMouseDown", function(widget, mouseButton)
		if mouseButton == "LeftButton" and IsDataBarsDragContextActive(addon) then
			local parent = widget:GetParent()
			if parent and parent.unlockHandle then
				parent.unlockHandle:SetShown(ShouldShowDragHandle(parent.__sufIsMouseOver))
			end
			ForwardDragStartFromChild(widget:GetParent())
		end
	end)
	petxp:SetScript("OnMouseUp", function(widget, mouseButton)
		if mouseButton == "LeftButton" and IsDataBarsDragContextActive(addon) then
			ForwardDragStopFromChild(widget:GetParent())
			local parent = widget:GetParent()
			if parent and parent.unlockHandle then
				parent.unlockHandle:Hide()
			end
		end
	end)
	frame.petxp = petxp

	local unlockHandle = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	unlockHandle:SetAllPoints(frame)
	unlockHandle:SetFrameStrata(frame:GetFrameStrata() or "LOW")
	unlockHandle:SetFrameLevel((frame:GetFrameLevel() or 1) + 20)
	unlockHandle:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	if self.ApplySUFBackdrop then
		self:ApplySUFBackdrop(unlockHandle, "subtle")
	else
		self:ApplySUFBackdropColors(unlockHandle, { 0.08, 0.14, 0.24, 0.38 }, { 0.40, 0.68, 0.98, 0.95 }, false)
	end
	unlockHandle:EnableMouse(false)
	unlockHandle:Hide()
	local handleText = unlockHandle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	handleText:SetPoint("CENTER", unlockHandle, "CENTER", 0, 0)
	handleText:SetText("Data Bars: Drag to Move")
	do
		local titleColor = THEME and THEME.text and THEME.text.title
		if titleColor then
			handleText:SetTextColor(titleColor[1], titleColor[2], titleColor[3], titleColor[4] or 1)
		else
			handleText:SetTextColor(0.95, 0.98, 1.00, 1)
		end
	end
	unlockHandle.text = handleText
	frame.unlockHandle = unlockHandle

	self.dataBarsFrame = frame
	self:EnableMovableFrame(frame, true, "databars_root", { "TOP", "UIParent", "TOP", 0, -2 }, function()
		local cfg = addon and addon.db and addon.db.profile and addon.db.profile.databars
		local editModeDrag = cfg and IsEditModePosition(cfg.positionMode)
		frame.__sufDataBarsUsedShiftFallback = IsShiftDragRequested() and not editModeDrag
		return IsDataBarsDragContextActive(addon)
	end, function(movableFrame)
		local usedShiftFallback = movableFrame and movableFrame.__sufDataBarsUsedShiftFallback
		if movableFrame then
			movableFrame.__sufDataBarsUsedShiftFallback = nil
		end
		if usedShiftFallback then
			local cfg = addon and addon.db and addon.db.profile and addon.db.profile.databars
			if cfg and not IsEditModePosition(cfg.positionMode) then
				cfg.positionMode = "EDIT_MODE"
			end
		end
		addon:UpdateDataBars()
	end)
	self:UpdateDataBars()
end

function addon:InitializeDataSystems()
	self:EnsureDataTextPanel()
	self:EnsureDataBars()

	local dtCfg = self.db and self.db.profile and self.db.profile.datatext
	local refreshRate = (dtCfg and tonumber(dtCfg.refreshRate)) or 1.0
	refreshRate = math.max(0.2, math.min(5.0, refreshRate))
	if self._dataTextTicker then
		self._dataTextTicker:Cancel()
		self._dataTextTicker = nil
	end
	self._dataTextTicker = C_Timer.NewTicker(refreshRate, function()
		if self.dataTextPanel and self.dataTextPanel:IsShown() and self.dataTextPanel._sufNeedsRealtimeTicker then
			self:UpdateDataTextPanel()
		end
	end)
end


