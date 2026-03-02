---
--- PerformanceMetricsHelper: Helper module for displaying PerformanceLib EventCoalescer stats
--- Provides tooltip integration for real-time performance metrics
---

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    _G["SimpleUnitFrames_PerformanceMetricsHelper"] = {}
    return _G["SimpleUnitFrames_PerformanceMetricsHelper"]
end

-- Public module
local PerformanceMetricsHelper = {}

-- Attach to addon for easy access
addon.PerformanceMetricsHelper = PerformanceMetricsHelper

--- Get the LibQTip-2.0 library
--- @return LibQTip-2.0|nil
local function GetQTip()
    return LibStub:GetLibrary("LibQTip-2.0")
end

--- Get efficiency-based color (green >= 90%, yellow 70-89%, red < 70%)
--- @param percent number Efficiency percentage 0-100
--- @return table RGB color table {r, g, b}
local function GetEfficiencyColor(percent)
    if percent >= 90 then
        return { 0.2, 1, 0.2 }           -- Green
    elseif percent >= 70 then
        return { 1, 0.9, 0 }             -- Yellow
    else
        return { 1, 0.2, 0.2 }           -- Red
    end
end

--- Create a performance stats tooltip showing EventCoalescer data
--- @param performanceLib table Reference to PerformanceLib addon
--- @return LibQTip-2.0.Tooltip|nil The created tooltip, or nil if unavailable
function PerformanceMetricsHelper:CreatePerformanceStatsTooltip(performanceLib)
    local QTip = GetQTip()
    if not QTip then
        return nil
    end
    
    -- Check if PerformanceLib is available
    if not performanceLib or not performanceLib.EventCoalescer then
        return nil
    end
    
    -- Create tooltip with 5 columns: Event Type, Total, Coalesced, Efficiency %, Avg Batch
    local tooltip = QTip:AcquireTooltip("SUF_PerformanceStats", 5, "LEFT", "CENTER", "CENTER", "CENTER", "CENTER")
    if not tooltip then
        return nil
    end
    
    -- Configure appearance (use string font names to avoid nil references)
    tooltip:SetDefaultFont("GameFontNormalSmall")
    tooltip:SetDefaultHeadingFont("GameFontNormalSmall")
    tooltip:SetCellMarginH(3)
    tooltip:SetCellMarginV(2)
    
    -- Add header row
    tooltip:AddHeadingRow("Event Type", "Total", "Coalesced", "Efficiency %", "Avg Batch")
    
    -- Get EventCoalescer stats
    local eventCoalescer = performanceLib.EventCoalescer
    if not eventCoalescer or not eventCoalescer.GetStats then
        tooltip:AddRow("Error", "—", "—", "—", "EventCoalescer unavailable")
        return tooltip
    end
    
    local stats = eventCoalescer:GetStats()
    if not stats or not stats.byEvent then
        tooltip:AddRow("No Data", "—", "—", "—", "Not yet recorded")
        return tooltip
    end
    
    -- Collect and sort event stats by efficiency
    local rows = {}
    for eventName, eventStats in pairs(stats.byEvent) do
        if eventStats and eventStats.total and eventStats.total > 0 then
            local coalesced = eventStats.coalesced or 0
            local total = eventStats.total
            local efficiency = math.floor((coalesced / total) * 100)
            local avgBatch = total > 0 and (coalesced > 0 and coalesced / (total - coalesced) or 0) or 0
            
            table.insert(rows, {
                name = eventName,
                total = total,
                coalesced = coalesced,
                efficiency = efficiency,
                avgBatch = avgBatch,
            })
        end
    end
    
    -- Sort by efficiency descending
    table.sort(rows, function(a, b) return a.efficiency > b.efficiency end)
    
    -- Add data rows with color-coded efficiency
    for i, row in ipairs(rows) do
        local efficiencyStr = format("%.0f%%", row.efficiency)
        local effColor = GetEfficiencyColor(row.efficiency)
        
        tooltip:AddRow(
            row.name,
            tostring(row.total),
            tostring(row.coalesced),
            efficiencyStr,
            format("%.1f", row.avgBatch)
        )
        
        -- Color code the efficiency percentage cell (4th column)
        local rowIndex = tooltip:GetRowCount()
        tooltip:SetCellTextColor(rowIndex, 4, effColor[1], effColor[2], effColor[3])
    end
    
    -- Add separator
    tooltip:AddSeparator()
    
    -- Calculate and add totals row
    local totalEvents = stats.totalEvents or 0
    local totalCoalesced = stats.totalCoalesced or 0
    local totalEfficiency = totalEvents > 0 
        and math.floor((totalCoalesced / totalEvents) * 100) 
        or 0
    local totalAvgBatch = totalEvents > 0 and totalCoalesced > 0 
        and (totalCoalesced / (totalEvents - totalCoalesced)) 
        or 0
    
    local summaryStr = format("%d events total", #rows)
    local totalEfficiencyStr = format("%.0f%%", totalEfficiency)
    local totalEffColor = GetEfficiencyColor(totalEfficiency)
    
    tooltip:AddRow(
        "TOTAL",
        tostring(totalEvents),
        tostring(totalCoalesced),
        totalEfficiencyStr,
        format("%.1f", totalAvgBatch)
    )
    
    -- Color code the total efficiency cell
    local totalRowIndex = tooltip:GetRowCount()
    tooltip:SetCellTextColor(totalRowIndex, 4, totalEffColor[1], totalEffColor[2], totalEffColor[3])
    
    return tooltip
end

--- Release a performance stats tooltip
--- @param tooltip LibQTip-2.0.Tooltip The tooltip to release
function PerformanceMetricsHelper:ReleasePerformanceStatsTooltip(tooltip)
    if not tooltip then return end
    local QTip = GetQTip()
    if QTip then
        QTip:ReleaseTooltip(tooltip)
    end
end

--- Release all performance tooltips
function PerformanceMetricsHelper:ReleaseAllTooltips()
    local QTip = GetQTip()
    if not QTip then return end
    
    -- Release our specific tooltips
    QTip:ReleaseTooltip("SUF_PerformanceStats")
end

return PerformanceMetricsHelper
