--[[
    ObjectPool Integration Examples and Best Practices
    
    This file demonstrates how to use IndicatorPoolManager for temporary indicators.
    Not loaded by default - included for documentation and reference.
]]

local addon = SimpleUnitFrames
local IndicatorPoolManager = addon.IndicatorPoolManager

-- =========================================================================
-- Example 1: Using Threat Glow
-- =========================================================================

--[[
    In a threat-monitoring function on unit frame updates:
]]

local function UpdateThreatIndicator(self, unit)
    if not IndicatorPoolManager then return end
    
    local element = self.ThreatIndicator
    local feedbackUnit = element.feedbackUnit or unit
    
    local threatStatus = UnitThreatSituation(feedbackUnit, unit)
    
    if threatStatus and threatStatus > 0 then
        -- Apply threat glow
        IndicatorPoolManager:ApplyThreatGlow(self, threatStatus)
        element:Show()
    else
        -- Release threat glow when threat drops
        IndicatorPoolManager:Release(self, "threat_glow")
        element:Hide()
    end
end

-- =========================================================================
-- Example 2: Using Highlight Overlay for Target
-- =========================================================================

--[[
    Highlight the player's current target with a custom color:
]]

local function HighlightIfPlayerTarget(frame, unit)
    if not IndicatorPoolManager then return end
    
    if UnitIsUnit(unit, "player") then
        IndicatorPoolManager:ApplyHighlight(frame, {1, 0.5, 0.2, 0.4})  -- orange highlight
    else
        IndicatorPoolManager:Release(frame, "highlight_overlay")
    end
end

-- =========================================================================
-- Example 3: Using Dispel Border for Debuffs
-- =========================================================================

--[[
    Add a dispel-type indicator based on aura type:
]]

local function ApplyDispelIndicator(frame, dispelType)
    if not IndicatorPoolManager then return end
    
    if dispelType then
        IndicatorPoolManager:ApplyDispelBorder(frame, dispelType)
    else
        IndicatorPoolManager:Release(frame, "dispel_border")
    end
end

-- =========================================================================
-- Example 4: Using Range Fade for Out-of-Range Units
-- =========================================================================

--[[
    Fade frames based on range from player:
]]

local function UpdateRangeFade(frame, unit)
    if not IndicatorPoolManager then return end
    
    local minRange, maxRange = LibRangeCheck:GetRange(unit, true)
    
    if maxRange then
        -- Convert to distance percentage (0 far, 1 close)
        local rangePercentage = maxRange and (1 - (maxRange / 100)) or 0
        IndicatorPoolManager:ApplyRangeFade(frame, rangePercentage)
    else
        IndicatorPoolManager:Release(frame, "range_fade")
    end
end

-- =========================================================================
-- Example 5: Custom Glow Effect
-- =========================================================================

--[[
    Apply custom glow for specific conditions (e.g., focus target, important unit):
]]

local function ApplyCustomGlowEffect(frame, isImportant)
    if not IndicatorPoolManager then return end
    
    if isImportant then
        -- Bright white glow for important targets
        IndicatorPoolManager:ApplyCustomGlow(frame, 1, 1, 1, 0.9)
    else
        IndicatorPoolManager:Release(frame, "custom_glow")
    end
end

-- =========================================================================
-- Example 6: Cleanup All Frame Indicators
-- =========================================================================

--[[
    When a frame is hidden or destroyed, clean up all pooled indicators:
]]

local function HideFrame(frame)
    if not IndicatorPoolManager then return end
    
    -- This releases all indicator types for this frame
    IndicatorPoolManager:ReleaseAllForFrame(frame)
    
    frame:Hide()
end

-- =========================================================================
-- Best Practices
-- =========================================================================

--[[
    1. **Always check for nil**
       if not IndicatorPoolManager then return end
    
    2. **Release immediately when not needed**
       - Release when unit goes out of range
       - Release when threat drops
       - Release when unit dies or becomes invalid
    
    3. **Use in heavy-update scenarios**
       - Raid frames (40+ frames × multiple threat updates per second = heavy GC)
       - Party frames with dynamic debuff tracking
       - Boss frames with priority highlighting
    
    4. **Pair with event throttling**
       - Use with DirtyFlagManager for batched updates
       - Combine with EventCoalescer for UNIT_* events
    
    5. **Monitor pool statistics**
       - /suf poolstats to check active indicator usage
       - /suf poolstats reset to clear all pools
    
    6. **Performance metrics**
       - Expected: 40-60% GC reduction vs. creating/destroying textures each update
       - Baseline: 5-10 toxtures created/destroyed per frame per update
       - Pooled: texture reused, only position/color updated
]]

--===================================================
-- Integration with Unit Frame Updates
-- ===================================================

--[[
    Here's how you'd integrate into the existing threat indicator system:
    
    In Libraries/oUF/elements/threatindicator.lua:
    
    local function Update(self, event, unit)
        if(unit ~= self.unit) then return end
        local element = self.ThreatIndicator
        if(element.PreUpdate) then element:PreUpdate(unit) end
        
        local feedbackUnit = element.feedbackUnit
        unit = unit or self.unit
        
        local isPlayer = UnitIsPlayer(unit)
        local status
        if(not isPlayer and Private.unitExists(unit)) then
            if(feedbackUnit and feedbackUnit ~= unit and Private.unitExists(feedbackUnit)) then
                status = UnitThreatSituation(feedbackUnit, unit)
            else
                status = UnitThreatSituation(unit)
            end
        end
        
        local color
        if(status and status > 0) then
            color = self.colors.threat[status]
            
            if(element.SetVertexColor and color) then
                element:SetVertexColor(color:GetRGB())
            end
            
            element:Show()
            
            -- NEW: Apply indicator pool glow effect
            if SimpleUnitFrames.IndicatorPoolManager then
                SimpleUnitFrames.IndicatorPoolManager:ApplyThreatGlow(self, status)
            end
        else
            element:Hide()
            
            -- NEW: Release indicator pool glow effect
            if SimpleUnitFrames.IndicatorPoolManager then
                SimpleUnitFrames.IndicatorPoolManager:Release(self, "threat_glow")
            end
        end
        
        if(element.PostUpdate) then
            return element:PostUpdate(unit, status, color)
        end
    end
]]

