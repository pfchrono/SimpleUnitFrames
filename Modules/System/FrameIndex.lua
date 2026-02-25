local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

-- Clears the cached frame event index so it can be safely rebuilt by EnsureFrameEventIndex().
-- Per system guidelines, call this after any frame spawn/removal, or whenever a frame's
-- unit-related identity changes (i.e., when frame.unit or frame.sufUnitType are modified).
function addon:InvalidateFrameEventIndex()
	self._frameEventIndex = nil
end

function addon:EnsureFrameEventIndex()
	local cached = self._frameEventIndex
	if cached and cached.valid then
		return cached
	end

	local byUnit = {}
	local byType = {}
	local all = {}
	for i = 1, #(self.frames or {}) do
		local frame = self.frames[i]
		if frame then
			all[#all + 1] = frame
			if frame.unit then
				byUnit[frame.unit] = byUnit[frame.unit] or {}
				byUnit[frame.unit][#byUnit[frame.unit] + 1] = frame
			end
			if frame.sufUnitType then
				byType[frame.sufUnitType] = byType[frame.sufUnitType] or {}
				byType[frame.sufUnitType][#byType[frame.sufUnitType] + 1] = frame
			end
		end
	end

	self._frameEventIndex = {
		valid = true,
		byUnit = byUnit,
		byType = byType,
		all = all,
	}

	return self._frameEventIndex
end
