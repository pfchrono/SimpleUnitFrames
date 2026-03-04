local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

-- PerformanceBuilder: Constructs the spec for the "performance" options page

-- Helper functions (copied from Registry.lua for self-containment)
local function BuildClassResourceStatusText()
	local data = addon.GetClassResourceAuditData and addon:GetClassResourceAuditData() or {}
	local statusText = "IDLE"
	if not data.hasPlayerFrame then
		statusText = "NOT SPAWNED"
	elseif data.active and data.classPowerVisible and (tonumber(data.visibleSlots) or 0) > 0 then
		statusText = "HEALTHY"
	elseif data.active and not data.classPowerVisible then
		statusText = "CONTEXT ACTIVE / BAR HIDDEN"
	elseif (not data.active) and data.classPowerVisible then
		statusText = "CONTEXT INACTIVE / BAR VISIBLE"
	end
	local lines = {
		("Status: %s"):format(statusText),
		("Class: %s | SpecID: %s | PowerType: %s"):format(
			tostring(data.classTag or "UNKNOWN"),
			tostring(data.specID or "n/a"),
			tostring(data.powerToken or "n/a")
		),
		("Expected: %s | Active Context: %s"):format(
			tostring(data.expected or "None"),
			tostring(data.active and true or false)
		),
		("Player Frame: %s | Resource Visible: %s | Visible Slots: %s"):format(
			tostring(data.hasPlayerFrame and true or false),
			tostring(data.classPowerVisible and true or false),
			tostring(data.visibleSlots or 0)
		),
	}
	return table.concat(lines, "\n")
end

local function BuildPerformanceSnapshotText()
	local frameStats = addon.performanceLib and addon.performanceLib.GetFrameTimeStats and addon.performanceLib:GetFrameTimeStats() or {}
	local eventStats = addon.performanceLib and addon.performanceLib.EventCoalescer and addon.performanceLib.EventCoalescer.GetStats and addon.performanceLib.EventCoalescer:GetStats() or {}
	local dirtyStats = addon.performanceLib and addon.performanceLib.DirtyFlagManager and addon.performanceLib.DirtyFlagManager.GetStats and addon.performanceLib.DirtyFlagManager:GetStats() or {}
	local poolStats = addon.performanceLib and addon.performanceLib.FramePoolManager and addon.performanceLib.FramePoolManager.GetStats and addon.performanceLib.FramePoolManager:GetStats() or {}
	local profilerStats = addon.performanceLib and addon.performanceLib.PerformanceProfiler and addon.performanceLib.PerformanceProfiler.GetStats and addon.performanceLib.PerformanceProfiler:GetStats() or {}
	local preset = addon.GetPerformanceLibPreset and addon:GetPerformanceLibPreset() or "Medium"
	local isRecording = profilerStats.isRecording and "Yes" or "No"
	return ("Preset: %s\nFrame: avg %.2fms | p95 %.2f | p99 %.2f\nEventBus: coalesced=%d dispatched=%d queued=%d savings=%.1f%%\nDirty: processed=%d batches=%d queued=%d\nPools: created=%d reused=%d released=%d\nProfiler: recording=%s events=%d"):format(
		tostring(preset),
		tonumber(frameStats.avg or 0) or 0,
		tonumber(frameStats.P95 or 0) or 0,
		tonumber(frameStats.P99 or 0) or 0,
		tonumber(eventStats.totalCoalesced or 0) or 0,
		tonumber(eventStats.totalDispatched or 0) or 0,
		tonumber(eventStats.queuedEvents or 0) or 0,
		tonumber(eventStats.savingsPercent or 0) or 0,
		tonumber(dirtyStats.framesProcessed or 0) or 0,
		tonumber(dirtyStats.batchesRun or 0) or 0,
		tonumber(dirtyStats.currentDirtyCount or 0) or 0,
		tonumber(poolStats.totalCreated or 0) or 0,
		tonumber(poolStats.totalReused or 0) or 0,
		tonumber(poolStats.totalReleased or 0) or 0,
		isRecording,
		tonumber(profilerStats.eventCount or 0) or 0
	)
end

-- Main builder function
local function BuildPerformancePageSpec()
	local function GetPerformanceSection()
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.performance = cfg.sectionState.performance or "integration"
		return tostring(cfg.sectionState.performance)
	end
	local function SetPerformanceSection(key)
		local cfg = addon:EnsureOptionsV2Config()
		cfg.sectionState.performance = tostring(key or "integration")
	end
	return {
		sectionTabs = {
			{ key = "integration", label = "Integration" },
			{ key = "actions", label = "Actions" },
			{ key = "resources", label = "Resources" },
			{ key = "snapshot", label = "Snapshot" },
			{ key = "status", label = "Status" },
			{ key = "all", label = "All" },
		},
		getActiveSection = GetPerformanceSection,
		setActiveSection = SetPerformanceSection,
		sections = {
			{
				tab = "integration",
				title = "PerformanceLib",
				desc = "Tune presets, launch tools, and control snapshot behavior.",
				controls = {
					{
						type = "check",
						label = "Enable PerformanceLib Integration",
						get = function()
							return addon.db.profile.performance and addon.db.profile.performance.enabled ~= false
						end,
						set = function(v)
							addon:SetPerformanceIntegrationEnabled(v and true or false)
						end,
						disabled = function()
							return not addon.performanceLib
						end,
					},
					{
						type = "dropdown",
						label = "Active Preset",
						options = function()
							return {
								{ value = "Low", text = "Low" },
								{ value = "Medium", text = "Medium" },
								{ value = "High", text = "High" },
								{ value = "Ultra", text = "Ultra" },
							}
						end,
						get = function()
							return addon.GetPerformanceLibPreset and addon:GetPerformanceLibPreset() or "Medium"
						end,
						set = function(v)
							if addon.performanceLib and addon.performanceLib.SetPreset then
								addon.performanceLib:SetPreset(v)
							end
						end,
						disabled = function()
							return not (addon.performanceLib and addon.performanceLib.SetPreset)
						end,
					},
					{
						type = "check",
						label = "Auto-refresh Snapshot (1s)",
						get = function()
							return addon.db.profile.performance.optionsAutoRefresh ~= false
						end,
						set = function(v)
							addon.db.profile.performance.optionsAutoRefresh = v and true or false
						end,
					},
				},
			},
			{
				tab = "actions",
				title = "Actions",
				desc = "Common PerformanceLib and diagnostic actions.",
				controls = {
					{ type = "button", label = "Open SUF Performance UI", onClick = function() if addon.performanceLib and addon.performanceLib.ToggleDashboard then addon.performanceLib:ToggleDashboard() end end },
					{ type = "button", label = "Open SUF Debug", onClick = function() addon:ShowDebugPanel() end },
					{ type = "button", label = "Profile Start", onClick = function() if addon.StartPerformanceProfileFromUI then addon:StartPerformanceProfileFromUI() end end },
					{ type = "button", label = "Profile Stop", onClick = function() if addon.StopPerformanceProfileFromUI then addon:StopPerformanceProfileFromUI() end end },
					{ type = "button", label = "Profile Analyze", onClick = function() if addon.AnalyzePerformanceProfileFromUI then addon:AnalyzePerformanceProfileFromUI() end end },
					{ type = "button", label = "Print Status Report", onClick = function() addon:PrintStatusReport() end },
					{ type = "button", label = "Refresh Snapshot", onClick = function() if addon.optionsV2Frame and addon.optionsV2Frame.SetPage then addon.optionsV2Frame:SetPage("performance") end end },
				},
			},
			{
				tab = "resources",
				title = "Class Resource Status",
				desc = "Current class resource context as seen by SUF.",
				controls = {
					{ type = "paragraph", getText = BuildClassResourceStatusText },
				},
			},
			{
				tab = "snapshot",
				title = "Current Snapshot",
				desc = "Current performance snapshot from PerformanceLib components.",
				controls = {
					{ type = "paragraph", getText = BuildPerformanceSnapshotText },
				},
			},
			{
				tab = "status",
				title = "SUF Status Report",
				desc = "High-level addon status summary.",
				controls = {
					{
						type = "paragraph",
						getText = function()
							return addon.BuildStatusReportText and addon:BuildStatusReportText() or "Status report unavailable."
						end,
					},
				},
			},
		},
	}
end

-- Register builder
addon._optionsV2Builders = addon._optionsV2Builders or {}
addon._optionsV2Builders["performance"] = BuildPerformancePageSpec
