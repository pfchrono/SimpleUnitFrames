--[[
    SimpleUnitFrames – Custom Trackers
    Draggable icon bars for tracking spells, items, trinkets, and consumables.
    Adapted from QUI Custom Trackers by Grevin.
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

local LSM = LibStub("LibSharedMedia-3.0", true)
local LCG = LibStub("LibCustomGlow-1.0", true)

---------------------------------------------------------------------------
-- MODULE TABLE
---------------------------------------------------------------------------
local CT = {}
CT.activeBars = {}
CT.infoCache = {}
CT.autoLearnQueue = {}
CT.itemSpellIndex = {}
addon.CustomTrackers = CT

---------------------------------------------------------------------------
-- CONSTANTS
---------------------------------------------------------------------------
local BASE_CROP = 0.08

local HOUSING_INSTANCE_TYPES = {
    ["neighborhood"] = true,
    ["interior"] = true,
}

local function IsPlayerInInstance()
    local _, instanceType = GetInstanceInfo()
    if not instanceType or instanceType == "none" then return false end
    if HOUSING_INSTANCE_TYPES[instanceType] then return false end
    return true
end

---------------------------------------------------------------------------
-- DB HELPERS
---------------------------------------------------------------------------
local function GetDB()
    if addon.db and addon.db.profile and addon.db.profile.customTrackers then
        return addon.db.profile.customTrackers
    end
    return nil
end

local function GetAutoLearnConfig()
    local db = GetDB()
    if not db then return nil end
    db.autoLearn = db.autoLearn or {}
    local cfg = db.autoLearn
    if cfg.enabled == nil then cfg.enabled = false end
    if cfg.learnSpells == nil then cfg.learnSpells = true end
    if cfg.learnItems == nil then cfg.learnItems = true end
    if cfg.targetBarID == nil then cfg.targetBarID = "" end
    return cfg
end

---------------------------------------------------------------------------
-- FONT HELPERS
---------------------------------------------------------------------------
local function GetFont()
    if LSM then
        local name = addon.db and addon.db.profile and addon.db.profile.media and addon.db.profile.media.font
        if name then
            local path = LSM:Fetch("font", name)
            if path then return path end
        end
    end
    return STANDARD_TEXT_FONT
end

local function GetFontOutline()
    return "OUTLINE"
end

---------------------------------------------------------------------------
-- INFO CACHE
---------------------------------------------------------------------------
local function GetCachedSpellInfo(spellID)
    if not spellID then return nil end
    local key = "spell_" .. spellID
    if CT.infoCache[key] then return CT.infoCache[key] end
    local info = C_Spell.GetSpellInfo(spellID)
    if info then
        CT.infoCache[key] = { name = info.name, icon = info.iconID, id = spellID, type = "spell" }
        return CT.infoCache[key]
    end
    return nil
end

local function GetCachedItemInfo(itemID)
    if not itemID then return nil end
    local key = "item_" .. itemID
    if CT.infoCache[key] then return CT.infoCache[key] end
    local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
    if name then
        CT.infoCache[key] = { name = name, icon = icon, id = itemID, type = "item" }
        return CT.infoCache[key]
    end
    C_Item.RequestLoadItemDataByID(itemID)
    return nil
end

---------------------------------------------------------------------------
-- COOLDOWN INFO
---------------------------------------------------------------------------
local function GetSpellCooldownInfo(spellID)
    if not spellID then return 0, 0, false, nil end
    local info = C_Spell.GetSpellCooldown(spellID)
    if info then
        return info.startTime, info.duration, info.isEnabled, info.isOnGCD
    end
    return 0, 0, true, nil
end

local function GetItemCooldownInfo(itemID)
    if not itemID then return 0, 0, false end
    local startTime, duration, enable = C_Item.GetItemCooldown(itemID)
    return startTime or 0, duration or 0, enable ~= 0
end

local function GetItemStackCount(itemID, includeCharges)
    if not itemID then return 0 end
    local includeUses = includeCharges ~= false
    local count = C_Item.GetItemCount(itemID, false, includeUses, true)
    return count or 0
end

-- Cache for multi-charge spells
local knownChargeSpells = {}
local chargeSpellLastCast = {}

local function GetSpellChargeCount(spellID)
    if not spellID then return 0, 1, 0, 0 end
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if not chargeInfo then return 0, 1, 0, 0 end
    local maxCharges = chargeInfo.maxCharges
    if not maxCharges then return 0, 1, 0, 0 end
    local ok, isSecret = pcall(function() return maxCharges ~= maxCharges end)  -- NaN check (secret values)
    -- Safer: just try to compare
    local safeOk, safeResult = pcall(function() return maxCharges > 1 end)
    if not safeOk then
        local cached = knownChargeSpells[spellID]
        if cached and cached > 1 then
            return chargeInfo.currentCharges, cached,
                   chargeInfo.cooldownStartTime or 0,
                   chargeInfo.cooldownDuration or 0
        end
        return 0, 1, 0, 0
    end
    if safeResult then
        knownChargeSpells[spellID] = maxCharges
        return chargeInfo.currentCharges or 0, maxCharges,
               chargeInfo.cooldownStartTime or 0,
               chargeInfo.cooldownDuration or 0
    end
    knownChargeSpells[spellID] = 1
    return 0, 1, 0, 0
end

local function IsCooldownFrameActive(cooldownFrame)
    if not cooldownFrame then return false end
    local ok, shown = pcall(cooldownFrame.IsShown, cooldownFrame)
    return ok and shown == true
end

---------------------------------------------------------------------------
-- ITEM HELPERS
---------------------------------------------------------------------------
local function IsEquipmentItem(itemID)
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    if not classID then return false end
    return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
end

local function IsItemUsable(itemID, itemCount)
    if IsEquipmentItem(itemID) then
        return C_Item.IsEquippedItem(itemID)
    end
    return itemCount and itemCount > 0
end

local function IsSpellUsable(spellID)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then return false end
    if IsSpellKnownOrOverridesKnown then
        return IsSpellKnownOrOverridesKnown(spellID)
    elseif IsPlayerSpell then
        return IsPlayerSpell(spellID)
    end
    return IsSpellKnown(spellID)
end

local function BuildBarLookup()
    local db = GetDB()
    local bars = (db and db.bars) or {}
    local byID = {}
    for i = 1, #bars do
        local bar = bars[i]
        if bar and bar.id then
            byID[bar.id] = bar
        end
    end
    return bars, byID
end

function CT:IsEntryTracked(entryType, entryID, barID)
    local bars, byID = BuildBarLookup()
    if barID and byID[barID] then
        local entries = byID[barID].entries or {}
        for i = 1, #entries do
            local entry = entries[i]
            if entry and entry.type == entryType and entry.id == entryID then
                return true
            end
        end
        return false
    end

    for i = 1, #bars do
        local entries = bars[i].entries or {}
        for j = 1, #entries do
            local entry = entries[j]
            if entry and entry.type == entryType and entry.id == entryID then
                return true
            end
        end
    end
    return false
end

function CT:GetAutoLearnTargetBarID()
    local cfg = GetAutoLearnConfig()
    if not cfg then return nil end
    local bars, byID = BuildBarLookup()
    if cfg.targetBarID and cfg.targetBarID ~= "" and byID[cfg.targetBarID] then
        return cfg.targetBarID
    end
    return bars[1] and bars[1].id or nil
end

local function AddItemSpellMapping(itemSpellIndex, itemID)
    if not itemID or itemID <= 0 then return end
    local _, spellID = C_Item.GetItemSpell(itemID)
    if not spellID or spellID <= 0 then return end
    itemSpellIndex[spellID] = itemSpellIndex[spellID] or {}
    itemSpellIndex[spellID][itemID] = true
end

function CT:RebuildItemSpellIndex()
    wipe(self.itemSpellIndex)

    -- Bags
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID then
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            local slots = C_Container.GetContainerNumSlots(bag) or 0
            for slot = 1, slots do
                local itemID = C_Container.GetContainerItemID(bag, slot)
                if itemID then
                    AddItemSpellMapping(self.itemSpellIndex, itemID)
                end
            end
        end
    end

    -- Equipped items
    for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            AddItemSpellMapping(self.itemSpellIndex, itemID)
        end
    end
end

function CT:ResolveItemIDForSpell(spellID)
    if not spellID or spellID <= 0 then return nil end
    local mapped = self.itemSpellIndex and self.itemSpellIndex[spellID]
    if not mapped then return nil end

    local bestItem
    for itemID in pairs(mapped) do
        if C_Item.IsEquippedItem(itemID) then
            return itemID
        end
        if not bestItem then
            bestItem = itemID
        end
    end
    return bestItem
end

function CT:TryAutoLearnEntry(entryType, entryID, sourceLabel)
    local cfg = GetAutoLearnConfig()
    if not cfg or cfg.enabled ~= true then return false end
    if entryType == "spell" and cfg.learnSpells ~= true then return false end
    if entryType == "item" and cfg.learnItems ~= true then return false end
    if not entryID or entryID <= 0 then return false end

    local barID = self:GetAutoLearnTargetBarID()
    if not barID then return false end
    if self:IsEntryTracked(entryType, entryID) then return false end

    if InCombatLockdown() then
        local key = tostring(entryType) .. ":" .. tostring(entryID)
        self.autoLearnQueue[key] = {
            type = entryType,
            id = entryID,
            source = sourceLabel,
            barID = barID,
        }
        return false
    end

    local added = self:AddEntry(barID, entryType, entryID)
    if added and addon and addon.Print then
        local label = entryType == "spell" and "Spell" or "Item"
        addon:Print(("SimpleUnitFrames: Auto-learned %s %d into '%s'."):format(label, entryID, tostring(barID)))
    end
    return added
end

function CT:FlushAutoLearnQueue()
    if InCombatLockdown() then return end
    for key, queued in pairs(self.autoLearnQueue) do
        if queued and queued.type and queued.id then
            self:TryAutoLearnEntry(queued.type, queued.id, queued.source)
        end
        self.autoLearnQueue[key] = nil
    end
end

---------------------------------------------------------------------------
-- ACTIVE STATE DETECTION (casting / channeling / buff)
---------------------------------------------------------------------------
local function GetSpellCastInfo(spellID)
    if not spellID then return false end
    local _, _, _, startMS, endMS, _, _, _, castID = UnitCastingInfo("player")
    if castID and castID == spellID then return true, startMS, endMS end
    return false
end

local function GetSpellChannelInfo(spellID)
    if not spellID then return false end
    local _, _, _, startMS, endMS, _, _, _, chanID = UnitChannelInfo("player")
    if chanID and chanID == spellID then return true, startMS, endMS end
    return false
end

local function GetSpellBuffInfo(spellID)
    if not spellID then return false end
    if InCombatLockdown() then return false end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and aura then
            return true, aura.expirationTime, aura.duration
        end
    end
    return false
end

local function GetSpellActiveInfo(spellID)
    if not spellID then return false end
    local isCasting, castStart, castEnd = GetSpellCastInfo(spellID)
    if isCasting and castStart and castEnd then
        return true, castStart / 1000, (castEnd - castStart) / 1000, "cast"
    end
    local isChanneling, chanStart, chanEnd = GetSpellChannelInfo(spellID)
    if isChanneling and chanStart and chanEnd then
        return true, chanStart / 1000, (chanEnd - chanStart) / 1000, "channel"
    end
    local hasBuff, expiration, buffDuration = GetSpellBuffInfo(spellID)
    if hasBuff and expiration and buffDuration then
        return true, expiration - buffDuration, buffDuration, "buff"
    end
    return false
end

local function GetItemActiveInfo(itemID)
    if not itemID then return false end
    local itemSpellID = select(2, C_Item.GetItemSpell(itemID))
    if itemSpellID then return GetSpellActiveInfo(itemSpellID) end
    return false
end

---------------------------------------------------------------------------
-- GLOW (LibCustomGlow)
---------------------------------------------------------------------------
local function StartActiveGlow(icon, config)
    if not icon or not LCG then return end
    if icon._activeGlowShown then return end
    if config and config.activeGlowEnabled == false then return end

    local w, h = icon:GetSize()
    if not w or not h or w < 10 or h < 10 then return end

    local glowType = (config and config.activeGlowType) or "Pixel Glow"
    local color = (config and config.activeGlowColor) or { 1, 0.85, 0.3, 1 }
    local lines = (config and config.activeGlowLines) or 8
    local frequency = (config and config.activeGlowFrequency) or 0.25
    local thickness = (config and config.activeGlowThickness) or 2
    local scale = (config and config.activeGlowScale) or 1.0

    if glowType == "Pixel Glow" then
        LCG.PixelGlow_Start(icon, color, lines, frequency, nil, thickness, 0, 0, true, "_SUFActiveGlow")
        icon._activeGlowShown = true
        icon._activeGlowType = glowType
    elseif glowType == "Autocast Shine" then
        LCG.AutoCastGlow_Start(icon, color, lines, frequency, scale, 0, 0, "_SUFActiveGlow")
        icon._activeGlowShown = true
        icon._activeGlowType = glowType
    end
end

local function StopActiveGlow(icon)
    if not icon or not LCG then return end
    if not icon._activeGlowShown then return end
    local glowType = icon._activeGlowType or "Pixel Glow"
    if glowType == "Pixel Glow" then
        pcall(LCG.PixelGlow_Stop, icon, "_SUFActiveGlow")
    elseif glowType == "Autocast Shine" then
        pcall(LCG.AutoCastGlow_Stop, icon, "_SUFActiveGlow")
    end
    icon._activeGlowShown = nil
    icon._activeGlowType = nil
end

---------------------------------------------------------------------------
-- POSITIONING
---------------------------------------------------------------------------
local function FindSUFFrame(unit)
    local nameMap = {
        player = "SUF_Player",
        target = "SUF_Target",
        focus  = "SUF_Focus",
        pet    = "SUF_Pet",
    }
    local name = nameMap[unit]
    return name and _G[name] or nil
end

local function PositionBar(bar)
    if not bar or not bar.config then return end
    local config = bar.config

    -- Locked to player frame
    if config.lockedToPlayer then
        local playerFrame = FindSUFFrame("player")
        if playerFrame then
            bar:SetParent(playerFrame)
            bar:SetFrameLevel(playerFrame:GetFrameLevel() + 10)
            local lockPos = config.lockPosition or "bottomcenter"
            local bs = config.borderSize or 2
            local ux = config.offsetX or 0
            local uy = config.offsetY or 0
            bar:ClearAllPoints()
            if lockPos == "topleft" then
                bar:SetPoint("BOTTOMLEFT", playerFrame, "TOPLEFT", bs + ux, bs + uy)
            elseif lockPos == "topcenter" then
                bar:SetPoint("BOTTOM", playerFrame, "TOP", ux, bs + uy)
            elseif lockPos == "topright" then
                bar:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT", -bs + ux, bs + uy)
            elseif lockPos == "bottomleft" then
                bar:SetPoint("TOPLEFT", playerFrame, "BOTTOMLEFT", bs + ux, -bs + uy)
            elseif lockPos == "bottomcenter" then
                bar:SetPoint("TOP", playerFrame, "BOTTOM", ux, -bs + uy)
            elseif lockPos == "bottomright" then
                bar:SetPoint("TOPRIGHT", playerFrame, "BOTTOMRIGHT", -bs + ux, -bs + uy)
            else
                bar:SetPoint("TOP", playerFrame, "BOTTOM", ux, -bs + uy)
            end
            return
        end
    end

    -- Locked to target frame
    if config.lockedToTarget then
        local targetFrame = FindSUFFrame("target")
        if targetFrame then
            bar:SetParent(targetFrame)
            bar:SetFrameLevel(targetFrame:GetFrameLevel() + 10)
            local lockPos = config.targetLockPosition or "bottomcenter"
            local bs = config.borderSize or 2
            local ux = config.offsetX or 0
            local uy = config.offsetY or 0
            bar:ClearAllPoints()
            if lockPos == "topleft" then
                bar:SetPoint("BOTTOMLEFT", targetFrame, "TOPLEFT", bs + ux, bs + uy)
            elseif lockPos == "topcenter" then
                bar:SetPoint("BOTTOM", targetFrame, "TOP", ux, bs + uy)
            elseif lockPos == "topright" then
                bar:SetPoint("BOTTOMRIGHT", targetFrame, "TOPRIGHT", -bs + ux, bs + uy)
            elseif lockPos == "bottomleft" then
                bar:SetPoint("TOPLEFT", targetFrame, "BOTTOMLEFT", bs + ux, -bs + uy)
            elseif lockPos == "bottomcenter" then
                bar:SetPoint("TOP", targetFrame, "BOTTOM", ux, -bs + uy)
            elseif lockPos == "bottomright" then
                bar:SetPoint("TOPRIGHT", targetFrame, "BOTTOMRIGHT", -bs + ux, -bs + uy)
            else
                bar:SetPoint("TOP", targetFrame, "BOTTOM", ux, -bs + uy)
            end
            return
        end
    end

    -- Free-floating on UIParent
    bar:SetParent(UIParent)
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetClampedToScreen(true)

    local offsetX = config.offsetX or 0
    local offsetY = config.offsetY or -300
    local growDir = config.growDirection or "RIGHT"

    bar:ClearAllPoints()
    if growDir == "RIGHT" then
        bar:SetPoint("LEFT", UIParent, "CENTER", offsetX, offsetY)
    elseif growDir == "LEFT" then
        bar:SetPoint("RIGHT", UIParent, "CENTER", offsetX, offsetY)
    elseif growDir == "DOWN" then
        bar:SetPoint("TOP", UIParent, "CENTER", offsetX, offsetY)
    elseif growDir == "UP" then
        bar:SetPoint("BOTTOM", UIParent, "CENTER", offsetX, offsetY)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    end
end

---------------------------------------------------------------------------
-- ICON CREATION
---------------------------------------------------------------------------
local function CreateTrackerIcon(parent, clickable)
    local icon = CreateFrame("Frame", nil, parent)
    icon.__sufCustomTrackerIcon = true
    icon:SetSize(36, 36)

    -- Border
    icon.border = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
    icon.border:SetColorTexture(0, 0, 0, 1)

    -- Icon texture
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()

    -- Cooldown frame (Blizzard's built-in – handles secret values internally)
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon.cooldown:SetDrawSwipe(false)
    icon.cooldown:SetDrawEdge(false)
    icon.cooldown:SetHideCountdownNumbers(false)
    icon.cooldown:EnableMouse(false)
    if icon.cooldown.SetDrawBling then icon.cooldown:SetDrawBling(false) end

    -- Duration text (custom, hidden by default – we use Blizzard countdown)
    icon.durationText = icon:CreateFontString(nil, "OVERLAY")
    icon.durationText:SetFont(GetFont(), 14, GetFontOutline())
    icon.durationText:Hide()

    -- Stack/charge text
    icon.stackText = icon:CreateFontString(nil, "OVERLAY")
    icon.stackText:SetFont(GetFont(), 12, GetFontOutline())
    icon.stackText:Hide()

    -- Tooltip
    local function ShowTooltip(iconFrame)
        if iconFrame:GetAlpha() == 0 then return end
        if iconFrame.entry then
            GameTooltip_SetDefaultAnchor(GameTooltip, iconFrame)
            if iconFrame.entry.type == "spell" then
                GameTooltip:SetSpellByID(iconFrame.entry.id)
            elseif iconFrame.entry.type == "item" then
                pcall(GameTooltip.SetItemByID, GameTooltip, iconFrame.entry.id)
            end
            GameTooltip:Show()
        end
    end

    icon:SetScript("OnEnter", function(self) ShowTooltip(self) end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Forward drag to parent bar
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function(self)
        local bar = self:GetParent()
        if bar and bar.config and not bar.config.locked
           and not bar.config.lockedToPlayer
           and not bar.config.lockedToTarget then
            bar:StartMoving()
        end
    end)
    icon:SetScript("OnDragStop", function(self)
        local bar = self:GetParent()
        if bar then
            bar:StopMovingOrSizing()
            local handler = bar:GetScript("OnDragStop")
            if handler then handler(bar) end
        end
    end)

    -- Clickable secure button (only when requested)
    if clickable then
        icon.clickButton = CreateFrame("Button", nil, icon, "SecureActionButtonTemplate")
        icon.clickButton:SetAllPoints()
        icon.clickButton:RegisterForClicks("AnyUp", "AnyDown")
        icon.clickButton:EnableMouse(true)
        icon.clickButton:Hide()
        icon.clickButton:RegisterForDrag("LeftButton")
        icon.clickButton:SetScript("OnDragStart", function(self)
            local bar = self:GetParent():GetParent()
            if bar and bar.config and not bar.config.locked
               and not bar.config.lockedToPlayer
               and not bar.config.lockedToTarget then
                bar:StartMoving()
            end
        end)
        icon.clickButton:SetScript("OnDragStop", function(self)
            local bar = self:GetParent():GetParent()
            if bar then
                bar:StopMovingOrSizing()
                local handler = bar:GetScript("OnDragStop")
                if handler then handler(bar) end
            end
        end)
        icon.clickButton:SetScript("OnEnter", function(self) ShowTooltip(self:GetParent()) end)
        icon.clickButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    return icon
end

---------------------------------------------------------------------------
-- SECURE BUTTON ATTRIBUTES
---------------------------------------------------------------------------
local function UpdateIconSecureAttributes(icon, entry, config)
    if not icon or not icon.clickButton then return end
    if InCombatLockdown() then
        icon._pendingSecureUpdate = true
        return
    end
    local function Clear()
        icon.clickButton:SetAttribute("type", nil)
        icon.clickButton:SetAttribute("spell", nil)
        icon.clickButton:SetAttribute("item", nil)
    end
    if not config or not config.clickableIcons then
        Clear(); icon.clickButton:Hide(); return
    end
    if not entry then
        Clear(); icon.clickButton:Hide(); return
    end
    if entry.type == "spell" then
        local info = GetCachedSpellInfo(entry.id)
        if info and info.name then
            icon.clickButton:SetAttribute("type", "spell")
            icon.clickButton:SetAttribute("spell", info.name)
            icon.clickButton:Show()
        else
            Clear(); icon.clickButton:Hide()
        end
    elseif entry.type == "item" then
        local info = GetCachedItemInfo(entry.id)
        if info and info.name then
            icon.clickButton:SetAttribute("type", "item")
            icon.clickButton:SetAttribute("item", info.name)
            icon.clickButton:Show()
        else
            Clear(); icon.clickButton:Hide()
        end
    else
        Clear(); icon.clickButton:Hide()
    end
    icon._pendingSecureUpdate = nil
end

---------------------------------------------------------------------------
-- ICON STYLING
---------------------------------------------------------------------------
local function StyleTrackerIcon(icon, config)
    if not icon or not config then return end

    local aspectRatio = config.aspectRatioCrop or 1.0
    local width = config.iconSize or 36
    local height = width / aspectRatio
    icon:SetSize(width, height)

    -- Border
    local bs = config.borderSize or 2
    if bs > 0 then
        icon.border:Show()
        icon.border:ClearAllPoints()
        icon.border:SetPoint("TOPLEFT", -bs, bs)
        icon.border:SetPoint("BOTTOMRIGHT", bs, -bs)
    else
        icon.border:Hide()
    end

    -- TexCoords with zoom + aspect crop
    local zoom = config.zoom or 0
    local left = BASE_CROP + zoom
    local right = 1 - BASE_CROP - zoom
    local top = BASE_CROP + zoom
    local bottom = 1 - BASE_CROP - zoom
    if aspectRatio > 1.0 then
        local cropAmount = 1.0 - (1.0 / aspectRatio)
        local availH = bottom - top
        local offset = (cropAmount * availH) / 2.0
        top = top + offset
        bottom = bottom - offset
    end
    icon.tex:SetTexCoord(left, right, top, bottom)

    -- Stack text style (support per-bar stackFont)
    local function ResolveBarlFont(name)
        if name and LSM then
            local path = LSM:Fetch("font", name)
            if path then return path end
        end
        return GetFont()
    end
    local stackFontPath = ResolveBarlFont(config.stackFont)
    local stackFontSize = config.stackSize or 12
    local stackColor = config.stackColor or { 1, 1, 1, 1 }
    icon.stackText:SetFont(stackFontPath, stackFontSize, GetFontOutline())
    icon.stackText:SetTextColor(stackColor[1], stackColor[2], stackColor[3], stackColor[4] or 1)
    icon.stackText:ClearAllPoints()
    icon.stackText:SetPoint(
        config.stackAnchor or "BOTTOMRIGHT",
        icon,
        config.stackAnchor or "BOTTOMRIGHT",
        config.stackOffsetX or -2,
        config.stackOffsetY or 2
    )

    -- Duration text style (also style Blizzard's countdown)
    local dColor = config.durationColor or { 1, 1, 1, 1 }
    local dSize = config.durationSize or 14
    local dFontPath = ResolveBarlFont(config.durationFont)
    -- Style custom durationText fontstring (used when we render our own timer)
    icon.durationText:SetFont(dFontPath, dSize, GetFontOutline())
    icon.durationText:SetTextColor(dColor[1], dColor[2], dColor[3], dColor[4] or 1)
    icon.durationText:ClearAllPoints()
    icon.durationText:SetPoint(
        config.durationAnchor or "CENTER",
        icon,
        config.durationAnchor or "CENTER",
        config.durationOffsetX or 0,
        config.durationOffsetY or 0
    )
    -- Also attempt to style Blizzard's built-in countdown text via GetRegions
    if icon.cooldown then
        local cooldown = icon.cooldown
        local ok, regions = pcall(function() return { cooldown:GetRegions() } end)
        if ok and regions then
            for _, region in ipairs(regions) do
                if region and region.GetObjectType
                   and region:GetObjectType() == "FontString" then
                    region:SetFont(dFontPath, dSize, GetFontOutline())
                    region:SetTextColor(dColor[1], dColor[2], dColor[3], dColor[4] or 1)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- ICON LAYOUT
---------------------------------------------------------------------------
local function LayoutBarIcons(bar)
    if not bar or not bar.icons then return end
    local config = bar.config
    local growDir = config.growDirection or "RIGHT"
    local spacing = config.spacing or 4
    local aspectRatio = config.aspectRatioCrop or 1.0
    local iconWidth = config.iconSize or 36
    local iconHeight = iconWidth / aspectRatio
    local numIcons = #bar.icons

    for _, icon in ipairs(bar.icons) do icon:ClearAllPoints() end

    for i, icon in ipairs(bar.icons) do
        local offset = (i - 1) * (iconWidth + spacing)
        if growDir == "RIGHT" then
            icon:SetPoint("LEFT", bar, "LEFT", offset, 0)
        elseif growDir == "LEFT" then
            icon:SetPoint("RIGHT", bar, "RIGHT", -offset, 0)
        elseif growDir == "DOWN" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("TOP", bar, "TOP", 0, -offset)
        elseif growDir == "UP" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("BOTTOM", bar, "BOTTOM", 0, offset)
        elseif growDir == "CENTER" then
            local totalW = numIcons * iconWidth + (numIcons - 1) * spacing
            local startX = -totalW / 2 + iconWidth / 2
            icon:SetPoint("CENTER", bar, "CENTER", startX + (i - 1) * (iconWidth + spacing), 0)
        elseif growDir == "CENTER_VERTICAL" then
            local totalH = numIcons * iconHeight + (numIcons - 1) * spacing
            local startY = totalH / 2 - iconHeight / 2
            icon:SetPoint("CENTER", bar, "CENTER", 0, startY - (i - 1) * (iconHeight + spacing))
        end
        icon:Show()
    end

    if numIcons == 0 then
        bar:SetSize(1, 1)
        return
    end
    if growDir == "RIGHT" or growDir == "LEFT" or growDir == "CENTER" then
        bar:SetSize(numIcons * iconWidth + (numIcons - 1) * spacing, iconHeight)
    else
        bar:SetSize(iconWidth, numIcons * iconHeight + (numIcons - 1) * spacing)
    end
end

local function LayoutVisibleIcons(bar)
    if not bar or not bar.icons then return end
    local config = bar.config
    local growDir = config.growDirection or "RIGHT"
    local spacing = config.spacing or 4
    local aspectRatio = config.aspectRatioCrop or 1.0
    local iconWidth = config.iconSize or 36
    local iconHeight = iconWidth / aspectRatio

    local visible = {}
    for _, icon in ipairs(bar.icons) do
        if icon.isVisible ~= false then visible[#visible + 1] = icon end
    end

    for _, icon in ipairs(bar.icons) do icon:ClearAllPoints() end

    local n = #visible
    for i, icon in ipairs(visible) do
        local offset = (i - 1) * (iconWidth + spacing)
        if growDir == "RIGHT" then
            icon:SetPoint("LEFT", bar, "LEFT", offset, 0)
        elseif growDir == "LEFT" then
            icon:SetPoint("RIGHT", bar, "RIGHT", -offset, 0)
        elseif growDir == "DOWN" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("TOP", bar, "TOP", 0, -offset)
        elseif growDir == "UP" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("BOTTOM", bar, "BOTTOM", 0, offset)
        elseif growDir == "CENTER" then
            local totalW = n * iconWidth + (n - 1) * spacing
            local startX = -totalW / 2 + iconWidth / 2
            icon:SetPoint("CENTER", bar, "CENTER", startX + (i - 1) * (iconWidth + spacing), 0)
        elseif growDir == "CENTER_VERTICAL" then
            local totalH = n * iconHeight + (n - 1) * spacing
            local startY = totalH / 2 - iconHeight / 2
            icon:SetPoint("CENTER", bar, "CENTER", 0, startY - (i - 1) * (iconHeight + spacing))
        end
    end

    if n == 0 then bar:SetSize(1, 1); return end
    if growDir == "RIGHT" or growDir == "LEFT" or growDir == "CENTER" then
        bar:SetSize(n * iconWidth + (n - 1) * spacing, iconHeight)
    else
        bar:SetSize(iconWidth, n * iconHeight + (n - 1) * spacing)
    end
end

---------------------------------------------------------------------------
-- ACTIVE ICON SET (performance – only track learnable spells)
---------------------------------------------------------------------------
local pendingActiveSetRebuilds = {}

local function RebuildActiveSet(bar)
    if not bar then return end
    local hasSecureChildren = bar.icons and bar.icons[1] and bar.icons[1].clickButton
    local inCombat = hasSecureChildren and InCombatLockdown()

    bar.activeIcons = bar.activeIcons or {}
    wipe(bar.activeIcons)

    local config = bar.config
    local hideNonUsable = config.hideNonUsable

    for _, icon in ipairs(bar.icons or {}) do
        local entry = icon.entry
        if entry and entry.id then
            local isUsable = true
            if entry.type == "spell" then
                isUsable = IsSpellUsable(entry.id)
            elseif entry.type == "item" then
                if IsEquipmentItem(entry.id) then
                    isUsable = C_Item.IsEquippedItem(entry.id)
                end
            end

            if isUsable then
                bar.activeIcons[#bar.activeIcons + 1] = icon
                icon._usable = true
                icon.isVisible = true
                icon.tex:SetDesaturated(false)
                if inCombat then icon:SetAlpha(1) else icon:Show() end
            else
                if hideNonUsable then
                    if inCombat then icon:SetAlpha(0) else icon:Hide() end
                    icon.isVisible = false
                else
                    if inCombat then icon:SetAlpha(1) else icon:Show() end
                    icon.isVisible = true
                    icon.tex:SetDesaturated(true)
                    icon.cooldown:Clear()
                end
                icon._usable = false
            end
        end
    end

    if inCombat then
        pendingActiveSetRebuilds[bar] = true
    else
        LayoutVisibleIcons(bar)
    end
end

CT.RebuildActiveSet = RebuildActiveSet

---------------------------------------------------------------------------
-- UPDATE BAR ICONS
---------------------------------------------------------------------------
function CT:UpdateBarIcons(bar)
    if not bar then return end
    local config = bar.config
    local entries = config.entries or {}

    for _, icon in ipairs(bar.icons or {}) do
        icon:Hide()
        icon:SetParent(nil)
    end
    bar.icons = {}

    if #entries == 0 then
        bar:SetSize(1, 1)
        if bar.bg then bar.bg:SetAlpha(0) end
        return
    end

    local clickable = config.clickableIcons and not config.dynamicLayout
    for _, entry in ipairs(entries) do
        local icon = CreateTrackerIcon(bar, clickable)
        StyleTrackerIcon(icon, config)
        icon.entry = entry
        icon.isVisible = true

        local info
        if entry.type == "spell" then
            info = GetCachedSpellInfo(entry.id)
        else
            info = GetCachedItemInfo(entry.id)
        end

        if info and info.icon then
            icon.tex:SetTexture(info.icon)
        else
            icon.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        UpdateIconSecureAttributes(icon, entry, config)
        bar.icons[#bar.icons + 1] = icon
    end

    LayoutBarIcons(bar)
    PositionBar(bar)

    if bar.bg then
        bar.bg:SetAlpha(config.bgOpacity or 0)
    end
end

---------------------------------------------------------------------------
-- COOLDOWN POLLING
---------------------------------------------------------------------------
function CT:StartCooldownPolling(bar)
    if not bar then return end
    if bar.ticker then bar.ticker:Cancel() end

    bar.DoUpdate = function()
        if not bar:IsShown() then return end

        local config = bar.config
        local hideGCD = config.hideGCD ~= false
        local showOnlyOnCooldown = config.showOnlyOnCooldown
        local showOnlyWhenActive = config.showOnlyWhenActive
        local showOnlyWhenOffCooldown = config.showOnlyWhenOffCooldown
        local showOnlyInCombat = config.showOnlyInCombat
        local dynamicLayout = config.dynamicLayout == true
        local showActiveState = config.showActiveState ~= false
        local hideNonUsable = config.hideNonUsable
        local noDesaturateWithCharges = config.noDesaturateWithCharges == true
        local stackColor = config.stackColor or { 1, 1, 1, 1 }
        local visibilityChanged = false

        for _, icon in ipairs(bar.activeIcons or bar.icons or {}) do
            local entry = icon.entry
            if entry and entry.id then
                local startTime, duration, enabled, isOnGCD
                local count, maxCharges = 0, 1
                local chargeStartTime, chargeDuration = 0, 0

                if entry.type == "spell" then
                    startTime, duration, enabled, isOnGCD = GetSpellCooldownInfo(entry.id)
                    count, maxCharges, chargeStartTime, chargeDuration = GetSpellChargeCount(entry.id)
                else
                    startTime, duration, enabled = GetItemCooldownInfo(entry.id)
                    count = GetItemStackCount(entry.id, config.showItemCharges)
                    isOnGCD = false
                    icon._usable = IsItemUsable(entry.id, count)
                end

                local isActive, activeStartTime, activeDuration = false, nil, nil
                if showActiveState then
                    if entry.type == "spell" then
                        isActive, activeStartTime, activeDuration = GetSpellActiveInfo(entry.id)
                    else
                        isActive, activeStartTime, activeDuration = GetItemActiveInfo(entry.id)
                    end
                end

                -- Set cooldown display
                local isOnCD = false
                local rechargeActive = false

                if isActive and activeStartTime and activeDuration
                   and activeDuration > 0 and not showOnlyOnCooldown then
                    pcall(function()
                        icon.cooldown:SetReverse(true)
                        icon.cooldown:SetCooldown(activeStartTime, activeDuration)
                    end)
                    isOnCD = false
                else
                    local isChargeSpell = maxCharges > 1
                    icon.cooldown:SetReverse(false)

                    if isChargeSpell then
                        if chargeStartTime and chargeDuration then
                            pcall(function()
                                icon.cooldown:SetCooldown(chargeStartTime, chargeDuration)
                            end)
                            rechargeActive = IsCooldownFrameActive(icon.cooldown)
                        else
                            icon.cooldown:Clear()
                        end

                        if config.showRechargeSwipe then
                            pcall(icon.cooldown.SetSwipeColor, icon.cooldown, 0, 0, 0, 0.6)
                            pcall(icon.cooldown.SetDrawSwipe, icon.cooldown, true)
                        else
                            pcall(icon.cooldown.SetDrawSwipe, icon.cooldown, false)
                        end
                        pcall(icon.cooldown.SetDrawEdge, icon.cooldown, false)

                        if rechargeActive then icon.cooldown:Show()
                        else icon.cooldown:Hide() end

                        -- Detect main CD (all charges depleted)
                        icon.cooldown:Clear()
                        pcall(function() icon.cooldown:SetCooldown(startTime, duration) end)
                        local mainCDActive = IsCooldownFrameActive(icon.cooldown)
                        if chargeStartTime and chargeDuration then
                            pcall(function() icon.cooldown:SetCooldown(chargeStartTime, chargeDuration) end)
                        end

                        if hideGCD then
                            local safeOk, safeResult = pcall(function()
                                return duration and duration > 0 and duration <= 1.5
                            end)
                            if (isOnGCD or (safeOk and safeResult)) then
                                mainCDActive = false
                            end
                        end
                        isOnCD = mainCDActive

                        if not rechargeActive and not isOnGCD then
                            chargeSpellLastCast[entry.id] = nil
                        end
                        if hideGCD and rechargeActive and isOnGCD then
                            local chargeCheckOk, hasMissing = pcall(function() return count < maxCharges end)
                            if chargeCheckOk then
                                if not hasMissing then
                                    chargeSpellLastCast[entry.id] = nil
                                    rechargeActive = false
                                end
                            else
                                local lastCast = chargeSpellLastCast[entry.id]
                                if not lastCast or (GetTime() - lastCast) >= 120 then
                                    rechargeActive = false
                                end
                            end
                        end
                    else
                        -- Normal cooldown
                        if startTime and duration then
                            pcall(function() icon.cooldown:SetCooldown(startTime, duration) end)
                        end
                        pcall(icon.cooldown.SetDrawSwipe, icon.cooldown, false)
                        pcall(icon.cooldown.SetDrawEdge, icon.cooldown, false)

                        if hideGCD then
                            local isJustGCD = isOnGCD
                            if not isJustGCD then
                                local safeOk, safeResult = pcall(function()
                                    return duration and duration > 0 and duration <= 1.5
                                end)
                                if safeOk and safeResult then isJustGCD = true end
                            end
                            if isJustGCD then
                                icon.cooldown:Clear()
                                isOnCD = false
                            else
                                local checkOk, checkResult = pcall(function()
                                    return startTime and startTime > 0 and duration and duration > 0
                                end)
                                isOnCD = checkOk and checkResult or IsCooldownFrameActive(icon.cooldown)
                            end
                        else
                            local checkOk, checkResult = pcall(function()
                                return startTime and startTime > 0 and duration and duration > 0
                            end)
                            isOnCD = checkOk and checkResult or IsCooldownFrameActive(icon.cooldown)
                        end
                    end
                end

                local isUsable = icon._usable ~= false
                local baseVisible = isUsable or not hideNonUsable
                local inCombat = UnitAffectingCombat("player")
                local combatVisible = (not showOnlyInCombat) or inCombat

                local layoutVisible = baseVisible
                if layoutVisible then
                    if showOnlyWhenActive then
                        layoutVisible = isActive
                    elseif showOnlyOnCooldown then
                        layoutVisible = isOnCD or rechargeActive
                    elseif showOnlyWhenOffCooldown then
                        local hasCharges = false
                        if maxCharges > 1 then
                            local cok, cres = pcall(function() return count and count > 0 end)
                            hasCharges = cok and cres
                        end
                        layoutVisible = not isOnCD and (not isActive or hasCharges)
                    end
                end

                local inCombatLockdown = icon.clickButton and InCombatLockdown()

                if dynamicLayout then
                    if layoutVisible ~= icon.isVisible then
                        visibilityChanged = true
                        icon.isVisible = layoutVisible
                        if layoutVisible then
                            if inCombatLockdown then icon:SetAlpha(1) else icon:Show() end
                        else
                            StopActiveGlow(icon)
                            if inCombatLockdown then icon:SetAlpha(0) else icon:Hide() end
                        end
                    end
                else
                    if baseVisible ~= icon.isVisible then
                        visibilityChanged = true
                        icon.isVisible = baseVisible
                        if baseVisible then
                            if inCombatLockdown then icon:SetAlpha(1) else icon:Show() end
                        else
                            StopActiveGlow(icon)
                            if inCombatLockdown then icon:SetAlpha(0) else icon:Hide() end
                        end
                    end
                end

                local shouldRender = (dynamicLayout and layoutVisible or (not dynamicLayout and baseVisible))
                                     and combatVisible

                if shouldRender then
                    if isActive and not showOnlyOnCooldown then
                        icon:SetAlpha(1)
                        icon.tex:SetDesaturated(false)
                        StartActiveGlow(icon, config)
                    elseif showOnlyWhenActive then
                        StopActiveGlow(icon)
                        icon:SetAlpha(dynamicLayout and 1 or 0)
                        icon.tex:SetDesaturated(false)
                    elseif showOnlyOnCooldown then
                        StopActiveGlow(icon)
                        -- noDesaturateWithCharges: keep icon full-color when charges remain
                        local chargesRemain = false
                        if noDesaturateWithCharges and maxCharges > 1 then
                            local cok, cres = pcall(function() return count and count > 0 end)
                            chargesRemain = cok and cres
                        end
                        if dynamicLayout then
                            icon:SetAlpha(1)
                            icon.tex:SetDesaturated(not chargesRemain)
                        else
                            if isOnCD or rechargeActive then
                                icon:SetAlpha(1); icon.tex:SetDesaturated(not chargesRemain)
                            else
                                icon:SetAlpha(0); icon.tex:SetDesaturated(false)
                            end
                        end
                    elseif showOnlyWhenOffCooldown then
                        StopActiveGlow(icon)
                        if dynamicLayout then
                            icon:SetAlpha(1); icon.tex:SetDesaturated(false)
                        else
                            if not isOnCD then
                                icon:SetAlpha(1); icon.tex:SetDesaturated(false)
                            else
                                icon:SetAlpha(0); icon.tex:SetDesaturated(true)
                            end
                        end
                    else
                        StopActiveGlow(icon)
                        icon:SetAlpha(1)
                        if not isUsable then
                            icon.tex:SetDesaturated(true); icon.cooldown:Clear()
                        elseif isOnCD then
                            icon.tex:SetDesaturated(true)
                        else
                            icon.tex:SetDesaturated(false)
                        end
                    end
                else
                    StopActiveGlow(icon)
                    icon:SetAlpha(0)
                end

                -- Hide custom duration text; Blizzard's countdown is shown via cooldown frame
                icon.durationText:Hide()
                icon.cooldown:SetHideCountdownNumbers(config.hideDurationText == true)

                -- Stack text
                local showStack = (entry.type == "item") or (entry.type == "spell" and maxCharges > 1)
                if showStack and not config.hideStackText then
                    local okGtOne, isGtOne = pcall(function() return count and count > 1 end)
                    if okGtOne and isGtOne then
                        icon.stackText:SetText(count)
                        icon.stackText:SetTextColor(stackColor[1], stackColor[2], stackColor[3], stackColor[4] or 1)
                        icon.stackText:Show()
                    else
                        local okEqZero, isEqZero = pcall(function() return count and count == 0 end)
                        if okEqZero and isEqZero then
                            icon.stackText:SetText("0")
                            icon.stackText:SetTextColor(stackColor[1] * 0.5, stackColor[2] * 0.5, stackColor[3] * 0.5, stackColor[4] or 1)
                            icon.stackText:Show()
                        elseif okGtOne and okEqZero then
                            icon.stackText:SetText("")
                            icon.stackText:Hide()
                        else
                            -- Secret value – pass directly without numeric comparisons
                            icon.stackText:SetText(count)
                            icon.stackText:SetTextColor(stackColor[1], stackColor[2], stackColor[3], stackColor[4] or 1)
                            icon.stackText:Show()
                        end
                    end
                else
                    icon.stackText:SetText("")
                    icon.stackText:Hide()
                end
            end
        end

        if visibilityChanged then
            local hasSecureChildren = bar.icons and bar.icons[1] and bar.icons[1].clickButton
            if not hasSecureChildren or not InCombatLockdown() then
                LayoutVisibleIcons(bar)
            end
        end
    end

    bar.ticker = C_Timer.NewTicker(0.5, bar.DoUpdate)
end

---------------------------------------------------------------------------
-- DRAGGING
---------------------------------------------------------------------------
function CT:SetupDragging(bar)
    if not bar then return end
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetClampedToScreen(true)

    bar:SetScript("OnDragStart", function(self)
        if not self.config.locked
           and not self.config.lockedToPlayer
           and not self.config.lockedToTarget then
            self:StartMoving()
        end
    end)

    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local screenX, screenY = UIParent:GetCenter()
        local growDir = self.config.growDirection or "RIGHT"

        if growDir == "RIGHT" then
            local left = self:GetLeft()
            local cy = select(2, self:GetCenter())
            if left and screenX and cy and screenY then
                self.config.offsetX = math.floor(left - screenX + 0.5)
                self.config.offsetY = math.floor(cy - screenY + 0.5)
            end
        elseif growDir == "LEFT" then
            local right = self:GetRight()
            local cy = select(2, self:GetCenter())
            if right and screenX and cy and screenY then
                self.config.offsetX = math.floor(right - screenX + 0.5)
                self.config.offsetY = math.floor(cy - screenY + 0.5)
            end
        elseif growDir == "DOWN" then
            local cx = self:GetCenter()
            local top = self:GetTop()
            if cx and screenX and top and screenY then
                self.config.offsetX = math.floor(cx - screenX + 0.5)
                self.config.offsetY = math.floor(top - screenY + 0.5)
            end
        elseif growDir == "UP" then
            local cx = self:GetCenter()
            local bottom = self:GetBottom()
            if cx and screenX and bottom and screenY then
                self.config.offsetX = math.floor(cx - screenX + 0.5)
                self.config.offsetY = math.floor(bottom - screenY + 0.5)
            end
        else
            local bx, by = self:GetCenter()
            if bx and screenX and by and screenY then
                self.config.offsetX = math.floor(bx - screenX + 0.5)
                self.config.offsetY = math.floor(by - screenY + 0.5)
            end
        end

        PositionBar(self)

        -- Save to DB
        local db = GetDB()
        if db and db.bars then
            for _, barConfig in ipairs(db.bars) do
                if barConfig.id == self.barID then
                    barConfig.offsetX = self.config.offsetX
                    barConfig.offsetY = self.config.offsetY
                    break
                end
            end
        end

        if CT.onPositionChanged then
            CT.onPositionChanged(self.barID, self.config.offsetX, self.config.offsetY)
        end
    end)
end

---------------------------------------------------------------------------
-- BAR CREATION / DELETION
---------------------------------------------------------------------------
function CT:CreateBar(barID, config)
    if not barID or not config then return nil end
    if self.activeBars[barID] then return self.activeBars[barID] end

    local bar = CreateFrame("Frame", "SUF_CustomTracker_" .. barID, UIParent, "BackdropTemplate")
    bar:SetFrameStrata("MEDIUM")
    bar:SetFrameLevel(60)
    bar.barID = barID
    bar.config = config
    bar.icons = {}

    PositionBar(bar)

    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    local bgColor = config.bgColor or { 0, 0, 0, 1 }
    bar:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], config.bgOpacity or 0)

    self:SetupDragging(bar)
    self:UpdateBarIcons(bar)
    RebuildActiveSet(bar)
    self:StartCooldownPolling(bar)

    self.activeBars[barID] = bar

    if config.enabled then bar:Show() else bar:Hide() end

    return bar
end

function CT:DeleteBar(barID)
    local bar = self.activeBars[barID]
    if not bar then return end
    if bar.ticker then bar.ticker:Cancel() end
    for _, icon in ipairs(bar.icons or {}) do
        icon:Hide()
        icon:SetParent(nil)
    end
    bar:Hide()
    bar:SetParent(nil)
    self.activeBars[barID] = nil
end

function CT:UpdateBar(barID)
    local bar = self.activeBars[barID]
    if not bar then return end
    local db = GetDB()
    if not db or not db.bars then return end
    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then
            bar.config = barConfig
            local bgColor = barConfig.bgColor or { 0, 0, 0, 1 }
            bar:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], barConfig.bgOpacity or 0)
            self:UpdateBarIcons(bar)
            RebuildActiveSet(bar)
            if barConfig.enabled then bar:Show() else bar:Hide() end
            break
        end
    end
end

function CT:RefreshAll()
    for barID in pairs(self.activeBars) do self:DeleteBar(barID) end
    local db = GetDB()
    if not db or not db.bars then return end
    for _, barConfig in ipairs(db.bars) do
        if barConfig.id then
            -- clickableIcons and dynamicLayout are mutually exclusive
            if barConfig.dynamicLayout and barConfig.clickableIcons then
                barConfig.clickableIcons = false
            end
            self:CreateBar(barConfig.id, barConfig)
        end
    end
end

function CT:RefreshBarPosition(barID)
    local bar = self.activeBars[barID]
    if bar then PositionBar(bar) end
end

---------------------------------------------------------------------------
-- ENTRY MANAGEMENT
---------------------------------------------------------------------------
function CT:AddEntry(barID, entryType, entryID)
    local db = GetDB()
    if not db or not db.bars then return false end
    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then
            if not barConfig.entries then barConfig.entries = {} end
            -- Duplicate check
            for _, entry in ipairs(barConfig.entries) do
                if entry.type == entryType and entry.id == entryID then
                    return false
                end
            end
            barConfig.entries[#barConfig.entries + 1] = { type = entryType, id = entryID }
            if self.activeBars[barID] then
                self.activeBars[barID].config = barConfig
                self:UpdateBarIcons(self.activeBars[barID])
                RebuildActiveSet(self.activeBars[barID])
            end
            return true
        end
    end
    return false
end

function CT:RemoveEntry(barID, entryType, entryID)
    local db = GetDB()
    if not db or not db.bars then return false end
    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then
            local entries = barConfig.entries
            if entries then
                for i, entry in ipairs(entries) do
                    if entry.type == entryType and entry.id == entryID then
                        table.remove(entries, i)
                        if self.activeBars[barID] then
                            self.activeBars[barID].config = barConfig
                            self:UpdateBarIcons(self.activeBars[barID])
                            RebuildActiveSet(self.activeBars[barID])
                        end
                        return true
                    end
                end
            end
        end
    end
    return false
end

function CT:MoveEntry(barID, entryIndex, direction)
    local db = GetDB()
    if not db or not db.bars then return false end
    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then
            local entries = barConfig.entries
            if not entries then return false end
            local newIndex = entryIndex + direction
            if newIndex < 1 or newIndex > #entries then return false end
            local entry = table.remove(entries, entryIndex)
            table.insert(entries, newIndex, entry)
            if self.activeBars[barID] then
                self.activeBars[barID].config = barConfig
                self:UpdateBarIcons(self.activeBars[barID])
                RebuildActiveSet(self.activeBars[barID])
            end
            return true
        end
    end
    return false
end

function CT:CreateNewBar()
    local db = GetDB()
    if not db then return nil end
    if not db.bars then db.bars = {} end

    -- Generate unique ID
    local id = "bar_" .. tostring(GetTime()):gsub("%.", "_")
    for i = 1, 1000 do
        local testID = "bar_" .. i
        local found = false
        for _, b in ipairs(db.bars) do
            if b.id == testID then found = true; break end
        end
        if not found then id = testID; break end
    end

    local newBar = {
        id = id,
        name = "Bar " .. (#db.bars + 1),
        enabled = true,
        entries = {},
        iconSize = 36,
        spacing = 4,
        borderSize = 2,
        growDirection = "RIGHT",
        aspectRatioCrop = 1.0,
        zoom = 0,
        offsetX = 0,
        offsetY = -300,
        locked = false,
        lockedToPlayer = false,
        lockedToTarget = false,
        lockPosition = "bottomcenter",
        targetLockPosition = "bottomcenter",
        hideNonUsable = false,
        showOnlyOnCooldown = false,
        showOnlyWhenActive = false,
        showOnlyWhenOffCooldown = false,
        showOnlyInCombat = false,
        dynamicLayout = false,
        clickableIcons = false,
        hideGCD = true,
        showRechargeSwipe = false,
        hideDurationText = false,
        hideStackText = false,
        showItemCharges = true,
        bgOpacity = 0,
        bgColor = { 0, 0, 0, 1 },
        durationColor = { 1, 1, 1, 1 },
        durationSize = 14,
        stackColor = { 1, 1, 1, 1 },
        stackSize = 12,
        showActiveState = true,
        activeGlowEnabled = true,
        activeGlowType = "Pixel Glow",
        activeGlowColor = { 1, 0.85, 0.3, 1 },
        activeGlowLines = 8,
        activeGlowFrequency = 0.25,
        activeGlowThickness = 2,
        activeGlowScale = 1.0,
        noDesaturateWithCharges = false,
        durationFont = nil,
        durationOffsetX = 0,
        durationOffsetY = 0,
        durationAnchor = "CENTER",
        stackFont = nil,
        stackOffsetX = -2,
        stackOffsetY = 2,
        stackAnchor = "BOTTOMRIGHT",
    }

    db.bars[#db.bars + 1] = newBar
    self:CreateBar(newBar.id, newBar)
    return newBar.id
end

function CT:DeleteBarByID(barID)
    local db = GetDB()
    if not db or not db.bars then return end
    self:DeleteBar(barID)
    for i, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then
            table.remove(db.bars, i)
            break
        end
    end
end

function CT:GetBarConfig(barID)
    local db = GetDB()
    if not db or not db.bars then return nil end
    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then return barConfig end
    end
    return nil
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------
local pendingTalentRebuild = false

function CT:Init()
    local initFrame = CreateFrame("Frame")

    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    initFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    initFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    initFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    initFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    initFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    -- Player-scoped UNIT_* events: avoid receiving raid/party-wide unit traffic.
    initFrame:RegisterUnitEvent("UNIT_AURA", "player")
    initFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    initFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    initFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    initFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    initFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    initFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    initFrame:RegisterUnitEvent("UNIT_PET", "player")
    initFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    initFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    initFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(0.5, function() CT:RefreshAll() end)
            C_Timer.After(0.75, function() CT:RebuildItemSpellIndex() end)
            return
        end

        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            C_Timer.After(0.1, function()
                for _, bar in pairs(CT.activeBars) do
                    if bar then RebuildActiveSet(bar) end
                end
            end)
            return
        end

        if event == "PLAYER_TALENT_UPDATE" then
            if pendingTalentRebuild then return end
            pendingTalentRebuild = true
            C_Timer.After(0.1, function()
                pendingTalentRebuild = false
                for _, bar in pairs(CT.activeBars) do
                    if bar then RebuildActiveSet(bar) end
                end
            end)
            return
        end

        if event == "UNIT_PET" then
            local unit = ...
            if unit == "player" then
                C_Timer.After(0.2, function()
                    for _, bar in pairs(CT.activeBars) do
                        if bar then
                            RebuildActiveSet(bar)
                            if bar.DoUpdate then bar.DoUpdate() end
                        end
                    end
                end)
            end
            return
        end

        if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            if event == "PLAYER_REGEN_ENABLED" then
                -- Sync alpha-based visibility back to Show/Hide
                for bar in pairs(pendingActiveSetRebuilds) do
                    if bar then
                        for _, icon in ipairs(bar.icons or {}) do
                            if icon.isVisible then icon:Show() else icon:Hide() end
                        end
                        LayoutVisibleIcons(bar)
                        -- Process pending secure updates
                        for _, icon in ipairs(bar.icons or {}) do
                            if icon._pendingSecureUpdate then
                                UpdateIconSecureAttributes(icon, icon.entry, bar.config)
                            end
                        end
                    end
                end
                wipe(pendingActiveSetRebuilds)
                CT:FlushAutoLearnQueue()
            end
            for _, bar in pairs(CT.activeBars) do
                if bar and bar:IsShown() and bar.DoUpdate then bar.DoUpdate() end
            end
            return
        end

        if event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
            for _, bar in pairs(CT.activeBars) do
                if bar and bar:IsShown() and bar.DoUpdate then bar.DoUpdate() end
            end
            return
        end

        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP"
           or event == "UNIT_SPELLCAST_SUCCEEDED"
           or event == "UNIT_SPELLCAST_CHANNEL_START"
           or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            local unit, _, spellID = ...
            if unit == "player" then
                if event == "UNIT_SPELLCAST_SUCCEEDED" and spellID then
                    if knownChargeSpells[spellID] and knownChargeSpells[spellID] > 1 then
                        chargeSpellLastCast[spellID] = GetTime()
                    end
                    CT:TryAutoLearnEntry("spell", tonumber(spellID), "spellcast")
                    local mappedItemID = CT:ResolveItemIDForSpell(tonumber(spellID))
                    if mappedItemID then
                        CT:TryAutoLearnEntry("item", tonumber(mappedItemID), "spellcast-item")
                    end
                end
                for _, bar in pairs(CT.activeBars) do
                    if bar and bar:IsShown() and bar.DoUpdate then bar.DoUpdate() end
                end
            end
            return
        end

        -- Item / aura / equipment events – refresh icons and update
        if event == "GET_ITEM_INFO_RECEIVED" or event == "BAG_UPDATE_DELAYED"
           or event == "PLAYER_EQUIPMENT_CHANGED" or event == "SPELL_UPDATE_USABLE"
           or event == "UNIT_AURA" then
            if event == "UNIT_AURA" then
                local unit = ...
                if unit ~= "player" then return end
            elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
                CT:RebuildItemSpellIndex()
            end
            for _, bar in pairs(CT.activeBars) do
                if bar and bar:IsShown() and bar.DoUpdate then bar.DoUpdate() end
            end
        end
    end)
end

-- Global refresh hook (called from options UI)
addon.RefreshCustomTrackers = function()
    CT:RefreshAll()
end
