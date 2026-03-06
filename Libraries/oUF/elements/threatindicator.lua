--[[
# Element: Threat Indicator

Handles the visibility and updating of an indicator based on the unit's current threat level.  
The element works by changing the texture's vertex color.

## Widget

ThreatIndicator - A `Texture` used to display the current threat level.

## Notes

A default texture will be applied if the widget is a Texture and doesn't have a texture or a color set.

## Options

.feedbackUnit - The unit whose threat situation is being requested. If defined, it'll be passed as the first argument to
                [UnitThreatSituation](https://warcraft.wiki.gg/wiki/API_UnitThreatSituation).

## Examples

    -- Position and size
    local ThreatIndicator = self:CreateTexture(nil, 'OVERLAY')
    ThreatIndicator:SetSize(16, 16)
    ThreatIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.ThreatIndicator = ThreatIndicator
--]]

local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local unitExists = Private.unitExists

local function Update(self, event, unit)
	local element = self.ThreatIndicator
	local frameUnit = self.unit
	local feedbackUnit = element.feedbackUnit or frameUnit

	if(unit and unit ~= frameUnit and unit ~= feedbackUnit) then return end

	--[[ Callback: ThreatIndicator:PreUpdate(unit)
	Called before the element has been updated.

	* self - the ThreatIndicator element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then element:PreUpdate(unit) end
	unit = unit or feedbackUnit

	local status
	-- Non-existent '*target' or '*pet' units can cause UnitThreatSituation() errors.
	if(unitExists(frameUnit)) then
		-- If using feedback unit (e.g., "target" for party frames), verify it exists before querying
		local feedbackUnitExists = not feedbackUnit or feedbackUnit == frameUnit or unitExists(feedbackUnit)
		
		if(feedbackUnit and feedbackUnit ~= frameUnit and feedbackUnitExists) then
			status = UnitThreatSituation(feedbackUnit, frameUnit)
		elseif feedbackUnit and feedbackUnit ~= frameUnit and not feedbackUnitExists then
			-- Feedback unit (e.g., target) doesn't exist - threat is irrelevant
			-- Force threat to 0 by not setting status at all
			status = nil
		else
			status = UnitThreatSituation(frameUnit)
		end
	end

	-- Debug: Log all threat checks to understand what's happening
	local addon = _G.SimpleUnitFrames
	if addon and addon.DebugLog then
		addon:DebugLog("ThreatIndicator", 
			string.format("Threat update: frame=%s, unit=%s, frameUnit=%s, feedbackUnit=%s, status=%s", 
				self:GetName() or "unnamed", tostring(unit), tostring(frameUnit), tostring(feedbackUnit), tostring(status)), 3)
	end

	local color
	if(status and status > 0) then
		color = self.colors.threat[status]

		if(element.SetVertexColor and color) then
			element:SetVertexColor(color:GetRGB())
		end

		element:Show()
		
		-- Apply visual threat glow effect using ObjectPool only for full threat.
		-- Note: Pass self (the parent frame), not element (the texture)
		-- Check global glow visibility setting before applying
		local glowEnabled = addon and addon.db and addon.db.profile and addon.db.profile.visibility and addon.db.profile.visibility.enableThreatIndicatorGlow ~= false
		if addon and addon.IndicatorPoolManager and status == 3 and glowEnabled then
			addon.IndicatorPoolManager:ApplyThreatGlow(self, status)
			if addon.DebugLog then
				addon:DebugLog("ThreatIndicator", string.format("Applied threat glow for %s (unit=%s, status=%d, frame=%s)", 
					self:GetName() or "unnamed", unit, status, tostring(self)), 3)
			end
		elseif addon and addon.IndicatorPoolManager then
			addon.IndicatorPoolManager:Release(self, "threat_glow")
			if addon.DebugLog then
				addon:DebugLog("ThreatIndicator", string.format("Released threat glow (status=%s) for %s (unit=%s)", 
					tostring(status), self:GetName() or "unnamed", unit), 3)
			end
		end
	else
		element:Hide()
		
		-- Release threat glow when threat drops (returns frame to pool)
		if addon and addon.IndicatorPoolManager then
			addon.IndicatorPoolManager:Release(self, "threat_glow")
			if addon.DebugLog then
				addon:DebugLog("ThreatIndicator", string.format("Released threat glow for %s (unit=%s)", 
					self:GetName() or "unnamed", unit), 3)
			end
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

local function Path(self, ...)
	--[[ Override: ThreatIndicator.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.ThreatIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.ThreatIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		local feedbackUnit = element.feedbackUnit
		if(feedbackUnit and feedbackUnit ~= self.unit and self.RegisterUnitEvent and self.unit) then
			-- For party/raid frames with feedbackUnit (target), register for events from both units
			-- Must set event handler on frame before registering events
			self['UNIT_THREAT_SITUATION_UPDATE'] = Path
			self['UNIT_THREAT_LIST_UPDATE'] = Path
			self:RegisterUnitEvent('UNIT_THREAT_SITUATION_UPDATE', self.unit, feedbackUnit)
			self:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', self.unit, feedbackUnit)
		else
			-- Standard single-unit registration
			Private.SmartRegisterUnitEvent(self, 'UNIT_THREAT_SITUATION_UPDATE', self.unit, Path)
			Private.SmartRegisterUnitEvent(self, 'UNIT_THREAT_LIST_UPDATE', self.unit, Path)
		end

		-- Keep threat visuals synchronized across combat state changes.
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Path, true)
		self:RegisterEvent('PLAYER_REGEN_DISABLED', Path, true)

		-- Party/raid threat indicators using target feedback need refresh on retarget.
		if feedbackUnit == 'target' then
			self:RegisterEvent('PLAYER_TARGET_CHANGED', Path, true)
		end

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\RAIDFRAME\UI-RaidFrame-Threat]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.ThreatIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_THREAT_SITUATION_UPDATE', Path)
		self:UnregisterEvent('UNIT_THREAT_LIST_UPDATE', Path)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Path)
		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Path)
		self:UnregisterEvent('PLAYER_TARGET_CHANGED', Path)
	end
end

oUF:AddElement('ThreatIndicator', Path, Enable, Disable)
