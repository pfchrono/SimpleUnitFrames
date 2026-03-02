---
--- LibQTipHelper: Helper module for LibQTip-2.0 integration in SimpleUnitFrames
--- Provides common patterns and utilities for multi-column tooltips
---

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    -- Store globally for access after addon initialization
    _G["SimpleUnitFrames_LibQTipHelper"] = {}
    return _G["SimpleUnitFrames_LibQTipHelper"]
end

-- Public module
local LibQTipHelper = {}

-- Attach to addon for easy access
addon.LibQTipHelper = LibQTipHelper

--- Get the LibQTip-2.0 library
--- @return LibQTip-2.0|nil
local function GetQTip()
    return LibStub:GetLibrary("LibQTip-2.0")
end

--- Create a frame stats tooltip showing health, power, and performance data
--- @param frames table Array of unit frames to display
--- @return LibQTip-2.0.Tooltip|nil The created tooltip, or nil if LibQTip unavailable
function LibQTipHelper:CreateFrameStatsTooltip(frames)
    local QTip = GetQTip()
    if not QTip then
        return nil
    end
    
    -- Create tooltip with 4 columns: Frame name, Health %, Power, Update Time
    local tooltip = QTip:AcquireTooltip("SUF_FrameStats", 4, "LEFT", "CENTER", "CENTER", "CENTER")
    if not tooltip then
        return nil
    end
    
    -- Configure appearance (use string font names to avoid nil references)
    tooltip:SetDefaultFont("GameFontNormalSmall")
    tooltip:SetDefaultHeadingFont("GameFontNormalSmall")
    tooltip:SetCellMarginH(3)
    tooltip:SetCellMarginV(2)
    
    -- Add header row
    tooltip:AddHeadingRow("Frame Name", "Health", "Power", "Status")
    
    -- Validate frames table
    if not frames or type(frames) ~= "table" then
        tooltip:AddRow("No frames", "—", "—", "Invalid")
        return tooltip
    end
    
    -- Add frame data rows
    local frameCount = 0
    for i, frame in ipairs(frames) do
        if frame then
            frameCount = frameCount + 1
            
            -- Get unit frame type name
            local frameName = frame.sufUnitType or frame:GetName() or ("Frame " .. i)
            
            -- Get health info
            local healthPercent = "—"
            if frame.Health and frame.Health.Value then
                local val = tonumber(frame.Health.Value)
                if val and val >= 0 then
                    healthPercent = format("%.0f%%", val * 100)
                end
            end
            
            -- Get power info
            local powerValue = "—"
            if frame.Power and frame.Power.Value then
                local val = tonumber(frame.Power.Value)
                if val and val >= 0 then
                    powerValue = format("%.0f", val)
                end
            end
            
            -- Get visibility status
            local status = frame:IsVisible() and "Visible" or "Hidden"
            
            -- Add row to tooltip
            tooltip:AddRow(frameName, healthPercent, powerValue, status)
        end
    end
    
    -- If no frames, add placeholder row
    if frameCount == 0 then
        tooltip:AddRow("No frames loaded", "—", "—", "Waiting")
    end
    
    -- Add summary separator and count
    tooltip:AddSeparator()
    tooltip:AddRow("Total", frameCount .. " frames", "—", "Active")
    
    return tooltip
end

--- Release all active frame stat tooltips
--- @return nil
function LibQTipHelper:ReleaseFrameStatsTooltip()
    local QTip = GetQTip()
    if not QTip then
        return
    end
    
    local key = "SUF_FrameStats"
    if QTip:IsAcquiredTooltip(key) then
        QTip:ReleaseTooltip(string.format("SUF_FrameStats"))
    end
end

--- Release all tooltips owned by LibQTipHelper
--- @return nil
function LibQTipHelper:ReleaseAllTooltips()
    local QTip = GetQTip()
    if not QTip then
        return
    end
    
    -- Iterate and release known tooltips
    for key, tooltip in QTip:TooltipPairs() do
        if key and key:match("^SUF_") then
            QTip:ReleaseTooltip(tooltip)
        end
    end
end

return LibQTipHelper
