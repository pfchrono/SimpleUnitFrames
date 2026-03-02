---
--- AuraTooltipHelper: Helper module for displaying enhanced aura tooltips via LibQTip
--- Provides custom 2-column tooltips showing aura details (name, type, stacks, duration, description)
---

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    _G["SimpleUnitFrames_AuraTooltipHelper"] = {}
    return _G["SimpleUnitFrames_AuraTooltipHelper"]
end

-- Public module
local AuraTooltipHelper = {}

-- Attach to addon for easy access
addon.AuraTooltipHelper = AuraTooltipHelper

--- Get the LibQTip-2.0 library
--- @return LibQTip-2.0|nil
local function GetQTip()
    return LibStub:GetLibrary("LibQTip-2.0")
end

--- Format duration with remaining time
--- @param duration number Total duration in seconds (0 = permanent)
--- @param expirationTime number When aura expires (GetTime() reference)
--- @return string Formatted time string
local function FormatDuration(duration, expirationTime)
    if not duration or duration == 0 then
        return "|cFF00FF00Permanent|r"
    end
    if expirationTime and expirationTime > 0 then
        local remaining = expirationTime - GetTime()
        if remaining > 0 then
            return SecondsToTime(remaining)
        end
    end
    return SecondsToTime(duration)
end

--- Get aura type display (Buff or Debuff)
--- @param isBuff boolean True for buff, false for debuff
--- @return string Color-coded aura type
local function GetAuraTypeDisplay(isBuff)
    if isBuff == true then
        return "|cFF00FF00Buff|r"
    elseif isBuff == false then
        return "|cFFFF0000Debuff|r"
    end
    return "Aura"
end

--- Create an enhanced aura tooltip using LibQTip
--- @param unit string UnitID (e.g., "player", "target")
--- @param auraInstanceID number Aura instance ID
--- @return LibQTip-2.0.Tooltip|nil The created tooltip, or nil if unavailable
function AuraTooltipHelper:CreateAuraTooltip(unit, auraInstanceID)
    if not unit or not auraInstanceID then
        return nil
    end
    
    local QTip = GetQTip()
    if not QTip then
        return nil
    end
    
    -- Get aura data via C_UnitAuras API
    local auraData = nil
    if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        pcall(function()
            auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
        end)
    end
    
    if not auraData or not auraData.name then
        return nil
    end
    
    -- If no description available, signal to use GameTooltip fallback instead
    if not auraData.description or auraData.description == "" then
        return nil  -- Return nil to trigger GameTooltip fallback
    end
    
    -- Create 2-column tooltip
    local tooltipKey = "SUF_AuraTooltip_" .. unit .. "_" .. auraInstanceID
    local tooltip = QTip:AcquireTooltip(tooltipKey, 2, "LEFT", "LEFT")
    if not tooltip then
        return nil
    end
    
    -- Configure appearance
    tooltip:SetDefaultFont("GameFontNormalSmall")
    tooltip:SetDefaultHeadingFont("GameFontNormalSmall")
    tooltip:SetCellMarginH(3)
    tooltip:SetCellMarginV(2)
    
    -- Add aura name as header (spans both columns)
    tooltip:AddHeadingRow(auraData.name, "")
    
    -- Add dispel type if available
    if auraData.dispelName and auraData.dispelName ~= "" then
        tooltip:AddRow("Type:", auraData.dispelName)
    end
    
    -- Add stack count if greater than 1
    if auraData.applications and auraData.applications > 1 then
        tooltip:AddRow("Stacks:", format("|cFFFFA500%d|r", auraData.applications))
    end
    
    -- Add duration if aura is not permanent
    if auraData.duration and auraData.duration > 0 then
        local durationStr = FormatDuration(auraData.duration, auraData.expirationTime)
        tooltip:AddRow("Duration:", durationStr)
    elseif auraData.duration == 0 then
        tooltip:AddRow("Duration:", "|cFF00FF00Permanent|r")
    end
    
    -- Add Buff/Debuff indicator if available
    if auraData.isBuff ~= nil then
        local typeStr = GetAuraTypeDisplay(auraData.isBuff)
        tooltip:AddRow("Category:", typeStr)
    end
    
    -- Add description if available  
    if auraData.description and auraData.description ~= "" then
        tooltip:AddSeparator()
        -- Add description spanning both columns
        local row = tooltip:AddRow(auraData.description)
        local cell = row:GetCell(1)
        cell:SetColSpan(2)
    end
    
    return tooltip
end

--- Release an aura tooltip
--- @param tooltip LibQTip-2.0.Tooltip The tooltip to release
function AuraTooltipHelper:ReleaseAuraTooltip(tooltip)
    if not tooltip then return end
    local QTip = GetQTip()
    if QTip then
        QTip:ReleaseTooltip(tooltip)
    end
end

return AuraTooltipHelper
