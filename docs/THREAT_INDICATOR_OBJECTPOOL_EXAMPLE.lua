--[[
    EXAMPLE: Threat Indicator with ObjectPool Integration
    
    This is a SAMPLE showing how to integrate IndicatorPoolManager with the existing
    oUF threat indicator element. Not meant to be loaded directly.
    
    To apply this integration:
    1. Copy the Update() function into Libraries/oUF/elements/threatindicator.lua
    2. Replace the existing Update function
    3. Verify no syntax errors: /suf reload
    4. Monitor performance: /suf poolstats
]]

local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local unitExists = Private.unitExists

-- =========================================================================
-- INTEGRATED UPDATE FUNCTION WITH OBJECTPOOL
-- =========================================================================

local function UpdateWithObjectPool(self, event, unit)
	if(unit ~= self.unit) then return end

	local element = self.ThreatIndicator
	--[[ Callback: ThreatIndicator:PreUpdate(unit)
	Called before the element has been updated.

	* self - the ThreatIndicator element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then element:PreUpdate(unit) end

	local feedbackUnit = element.feedbackUnit
	unit = unit or self.unit

	-- Don't show threat indicator for player units
	local isPlayer = UnitIsPlayer(unit)
	
	local status
	-- BUG: Non-existent '*target' or '*pet' units cause UnitThreatSituation() errors
	if(not isPlayer and unitExists(unit)) then
		if(feedbackUnit and feedbackUnit ~= unit and unitExists(feedbackUnit)) then
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
		
		-- Apply visual threat glow effect using Object Pool
		local addon = _G.SimpleUnitFrames
		if addon and addon.IndicatorPoolManager then
			addon.IndicatorPoolManager:ApplyThreatGlow(self, status)
		end
	else
		element:Hide()
		
		-- Release threat glow when threat drops (returns texture to pool)
		local addon = _G.SimpleUnitFrames
		if addon and addon.IndicatorPoolManager then
			addon.IndicatorPoolManager:Release(self, "threat_glow")
		end
	end

	--[[ Callback: ThreatIndicator:PostUpdate(unit, status, color)
	Called after the element has been updated.

	* self   - the ThreatIndicator element
	* unit   - the unit for which the update has been triggered (string)
	* status - the unit's threat status (see [UnitThreatSituation](https://warcraft.wiki.gg/wiki/API_UnitThreatSituation))
	* color  - the used ColorMixin-based object (table?)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, status, color)
	end
end

-- =========================================================================
-- USAGE INSTRUCTIONS
-- =========================================================================

--[[
    STEP 1: Verify ObjectPool is loaded
    - /suf poolstats should print pool statistics
    
    STEP 2: Apply this integration to threatindicator.lua
    - Replace the entire Update function with the code above
    
    STEP 3: Reload UI and test
    - /suf reload
    - Enter combat with hostile units
    - Observe threat glow effects appear/disappear with threat changes
    
    STEP 4: Monitor performance
    - /suf poolstats — shows active indicators and reuse stats
    - Look for: "Created: X | Reused: Y | Acquired: Z | Released: W"
    - Higher reuse counts = better GC efficiency
    
    EXAMPLE OUTPUT:
    |cFF00FF00Indicator Pool Manager Stats:|r
      Created: 1 | Reused: 47 | Acquired: 50 | Released: 49
    |cFFFFFF00Pool Breakdown:|r
      threat_glow: 1 acquired, 0 available (total: 1)
    
    This means:
    - First threat threat indicator created 1 glow texture
    - That 1 texture reused 47 times for threat updates
    - Total 50 acquires, 49 releases (1 still in use)
    - Zero GC allocations after initial texture creation!
]]

--===================================================
-- PERFORMANCE OPTIMIZATION TIPS
-- ===================================================

--[[
    1. Light Combat (1v1, small groups)
       - Save: ~5 texture allocations per threat change
       - Expected reuse count: 5-10x per combat session
    
    2. Medium Combat (5-player dungeons)
       - Save: ~50-100 texture allocations per threat wave
       - 5 party frames × 10-20 threat flickers = 50-100 saved allocations
       - Expected reuse count: 50-100x per combat session
    
    3. Heavy Combat (Raid, 20-40 frames)
       - Save: 1000+ texture allocations per combat encounter
       - 40 raid frames × 25+ threat updates per wave = 1000+ saved allocations
       - Expected reuse count: 1000x+ per encounter
       - Expected GC reduction: 40-60% during threat-heavy phases
    
    4. Extended Combat (Mythic+ affix waves)
       - Save: 5000+ texture allocations per affix phase
       - 40 frames × 30 waves × 10 threat updates = 12,000 saved allocations
       - Expected reuse count: 10,000x+ per keystone run
]]

--===================================================
-- DEBUGGING THREATS
-- ===================================================

--[[
    If threat glows aren't appearing:
    1. Check addon is loaded: /suf status
    2. Verify IndicatorPoolManager exists: /suf poolstats
    3. Confirm threat indicator enabled: /suf options → Indicators → Threat
    4. Verify threat detection: UnitThreatSituation returning valid status
    
    If you see "Created: N | Reused: 0":
    - Means textures are being created but not reused
    - Check if Release() is being called when threat drops
    - Verify frame cleanup on unit changes/death
    
    If pool becomes full (many "acquired"):
    - Check for missing Release() calls on frame hide/death
    - Use /suf pool reset to clear all pools (testing only)
    - Monitor frameIndicators table for leaks (debug-only)
]]

