---
--- AuraTooltipManager: Manager for aura tooltips with LibQTip + GameTooltip fallback
--- Integrates enhanced LibQTip aura tooltips with fallback to GameTooltip in restricted zones
---

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    _G["SimpleUnitFrames_AuraTooltipManager"] = {}
    return _G["SimpleUnitFrames_AuraTooltipManager"]
end

-- Public module
local AuraTooltipManager = {}

-- Attach to addon for easy access
addon.AuraTooltipManager = AuraTooltipManager

-- State tracking for current tooltip
local currentAuraTooltip = nil
local currentAuraUnit = nil
local currentAuraInstanceID = nil

--- Show aura tooltip (LibQTip or GameTooltip fallback)
--- @param widget Button The aura button widget
--- @param anchorType string Anchor type (e.g., "ANCHOR_BOTTOMRIGHT")
--- @param offsetX number X offset
--- @param offsetY number Y offset
--- @return boolean True if tooltip shown, false otherwise
function AuraTooltipManager:ShowAuraTooltip(widget, anchorType, offsetX, offsetY)
    if not widget or not widget.auraInstanceID then
        return false
    end
    
    local parent = widget:GetParent()
    if not parent or not parent.__owner or not parent.__owner.unit then
        return false
    end
    
    local unit = parent.__owner.unit
    local auraInstanceID = widget.auraInstanceID
    
    -- Try LibQTip first (if AuraTooltipHelper available)
    if addon.AuraTooltipHelper and addon.AuraTooltipHelper.CreateAuraTooltip then
        local tooltip = nil
        local success = pcall(function()
            tooltip = addon.AuraTooltipHelper:CreateAuraTooltip(unit, auraInstanceID)
        end)
        
        if success and tooltip then
            -- Store state for cleanup
            if currentAuraTooltip and addon.AuraTooltipHelper then
                pcall(function()
                    addon.AuraTooltipHelper:ReleaseAuraTooltip(currentAuraTooltip)
                end)
            end
            
            currentAuraTooltip = tooltip
            currentAuraUnit = unit
            currentAuraInstanceID = auraInstanceID
            
            -- Position and show
            tooltip:SmartAnchorTo(widget)
            tooltip:Show()
            
            return true
        end
    end
    
    -- Fallback to GameTooltip (always works)
    return self:ShowGameTooltipFallback(unit, auraInstanceID, widget, anchorType, offsetX, offsetY)
end

--- Fallback to GameTooltip for restricted zones
--- @param unit string UnitID
--- @param auraInstanceID number Aura instance ID
--- @param widget Button Anchor widget
--- @param anchorType string Anchor type
--- @param offsetX number X offset
--- @param offsetY number Y offset
--- @return boolean True if shown successfully
function AuraTooltipManager:ShowGameTooltipFallback(unit, auraInstanceID, widget, anchorType, offsetX, offsetY)
    if not GameTooltip then
        return false
    end
    
    -- Check if GameTooltip is forbidden
    if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then
        return false
    end
    
    local success = pcall(function()
        GameTooltip:SetOwner(widget, anchorType, offsetX, offsetY)
        GameTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)
    end)
    
    if success then
        -- Clear LibQTip state
        currentAuraTooltip = nil
        currentAuraUnit = nil
        currentAuraInstanceID = nil
        return true
    end
    
    return false
end

--- Hide aura tooltip (both LibQTip and GameTooltip)
function AuraTooltipManager:HideAuraTooltip()
    -- Hide LibQTip tooltip if active
    if currentAuraTooltip and addon.AuraTooltipHelper then
        pcall(function()
            addon.AuraTooltipHelper:ReleaseAuraTooltip(currentAuraTooltip)
        end)
        currentAuraTooltip = nil
        currentAuraUnit = nil
        currentAuraInstanceID = nil
    end
    
    -- Hide GameTooltip as fallback
    if GameTooltip and (not GameTooltip.IsForbidden or not GameTooltip:IsForbidden()) then
        pcall(function()
            GameTooltip:Hide()
        end)
    end
end

return AuraTooltipManager
