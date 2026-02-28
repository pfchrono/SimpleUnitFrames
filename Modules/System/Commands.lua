local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
	return
end

local core = addon._core or {}
local defaults = core.defaults or {}
local addonName = core.addonName or "SimpleUnitFrames"
local CopyTableDeep = core.CopyTableDeep

function addon:TogglePerformanceDashboard()
	if self.SyncThemeFromOptionsV2 then
		self:SyncThemeFromOptionsV2()
	end
	if self.performanceLib then
		if self.performanceLib.ToggleDashboard then
			self.performanceLib:ToggleDashboard()
			if self.ApplyThemeToPerformanceWindows then
				self:ApplyThemeToPerformanceWindows()
			end
			return
		end
		if self.performanceLib.ShowDashboard then
			self.performanceLib:ShowDashboard()
			if self.ApplyThemeToPerformanceWindows then
				self:ApplyThemeToPerformanceWindows()
			end
			return
		end
	end
	self:Print(addonName .. ": PerformanceLib dashboard is unavailable.")
end

function addon:ShowLauncherHelp()
	self:Print(addonName .. ": /suf (open options)")
	self:Print(addonName .. ": /suf ui v2|legacy|toggle|status")
	self:Print(addonName .. ": /suf minimap show|hide|toggle|reset")
	self:Print(addonName .. ": /suf perflib")
	self:Print(addonName .. ": /sufperf (performance dashboard)")
	self:Print(addonName .. ": /libperf (alias -> /sufperf)")
	self:Print(addonName .. ": /suf debug")
	self:Print(addonName .. ": /suf status")
	self:Print(addonName .. ": /suf protected (see also: /SUFprotected help)")
	self:Print(addonName .. ": /suf absorbdebug on|off|toggle|status")
	self:Print(addonName .. ": /sufabsorbdebug on|off|toggle|status")
	self:Print(addonName .. ": /suf skinreport (Blizzard skin coverage report)")
	self:Print(addonName .. ": /suf install")
	self:Print(addonName .. ": /suf tutorial")
	self:Print(addonName .. ": /sufskinreport (direct alias)")
	self:Print(addonName .. ": /suf reload")
	self:Print(addonName .. ": /suf resources")
	self:Print(addonName .. ": /suf help")
end

function addon:StartInstallFlow()
	self:ShowOptions()
	if self.optionsV2Frame and self.optionsV2Frame.SetPage then
		self.optionsV2Frame:SetPage("importexport")
	end
	if self.optionsFrame and self.optionsFrame.BuildTab then
		self.optionsFrame:BuildTab("importexport")
	end
	self.db.profile.optionsUI = self.db.profile.optionsUI or CopyTableDeep(defaults.profile.optionsUI)
	self.db.profile.optionsUI.installFlowSeen = true
end

function addon:ShowTutorialOverview(forceShow)
	self.db.profile.optionsUI = self.db.profile.optionsUI or CopyTableDeep(defaults.profile.optionsUI)
	if not forceShow and self.db.profile.optionsUI.tutorialSeen == true then
		return
	end
	self.db.profile.optionsUI.tutorialSeen = true
	self:EnsurePopupDialog("SUF_TUTORIAL_OVERVIEW", {
		text = "SimpleUnitFrames Quick Start\n\n1) /suf to open options\n2) Use Import / Export tab for installer + profile import\n3) /suf status for runtime snapshot\n4) /suf debug for diagnostics",
		button1 = "Open Options",
		button2 = "Later",
		OnAccept = function()
			if addon then
				addon:ShowOptions()
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	})
	self:ShowPopup("SUF_TUTORIAL_OVERVIEW")
end

function addon:HandleProtectedOpsSlash(msg)
	local input = (msg or ""):match("^%s*(.-)%s*$")
	if input == "" or input == "stats" then
		if self.ProtectedOperations then
			self:Print(self.ProtectedOperations:ExportStatsForChat())
		else
			self:Print(addonName .. ": ProtectedOperations system not available.")
		end
		return
	end

	local command = input:lower()
	
	if command == "reset" then
		if self.ProtectedOperations then
			self.ProtectedOperations:ResetStats()
			self:Print(addonName .. ": Protected operations statistics reset.")
		end
		return
	end
	
	if command == "queue" then
		if self.ProtectedOperations then
			local queue = self.ProtectedOperations._queue
			self:Print(string.format("|cffFFD700Queue Contents (%d items):|r", #queue))
			if #queue == 0 then
				self:Print("  (empty)")
			else
				for i, op in ipairs(queue) do
					self:Print(string.format("  [%d] type=%s priority=%s key=%s", 
						i, 
						op.type or "unnamed", 
						op.priority or "NORMAL",
						op.key or "none"))
				end
			end
		end
		return
	end
	
	if command == "help" then
		if self.ProtectedOperations then
			self:Print(self.ProtectedOperations:GetHelpText())
		end
		return
	end

	-- Default: show stats
	if self.ProtectedOperations then
		self:Print(self.ProtectedOperations:ExportStatsForChat())
	end
end

function addon:HandleAbsorbDebugSlash(msg)
	local mode = (msg or ""):match("^%s*(.-)%s*$")
	mode = mode and mode:lower() or ""
	mode = mode:match("^(%S+)") or mode

	self:EnsureDebugConfig()
	local dbg = self.db.profile.debug
	dbg.systems = dbg.systems or {}

	local function PrintStatus()
		local enabled = dbg.systems.AbsorbEvents == true
		local tagsEnabled = dbg.absorbTags == true
		self:Print(addonName .. ": AbsorbEvents debug is " .. (enabled and "ON" or "OFF") .. ".")
		self:Print(addonName .. ": AbsorbTags debug is " .. (tagsEnabled and "ON" or "OFF") .. ".")
		
		-- Print call counts if available
		if self._absorbTagCallCount and next(self._absorbTagCallCount) then
			self:Print(addonName .. ": Tag call counts:")
			for k, v in pairs(self._absorbTagCallCount) do
				self:Print(("  %s: %d"):format(tostring(k), tonumber(v) or 0))
			end
		else
			self:Print(addonName .. ": No tag calls recorded yet.")
		end
	end

	if mode == "" or mode == "status" or mode == "stats" then
		PrintStatus()
		return
	end

	if mode == "on" or mode == "enable" or mode == "1" then
		dbg.enabled = true
		dbg.systems.AbsorbEvents = true
		dbg.absorbTags = true
		self:Print(addonName .. ": AbsorbEvents and AbsorbTags debug enabled.")
		return
	end

	if mode == "off" or mode == "disable" or mode == "0" then
		dbg.systems.AbsorbEvents = false
		dbg.absorbTags = false
		self:Print(addonName .. ": AbsorbEvents and AbsorbTags debug disabled.")
		return
	end

	if mode == "toggle" then
		dbg.enabled = true
		local newState = not (dbg.systems.AbsorbEvents == true)
		dbg.systems.AbsorbEvents = newState
		dbg.absorbTags = newState
		PrintStatus()
		return
	end

	if mode == "help" then
		self:Print(addonName .. ": /suf absorbdebug on|off|toggle|status")
		self:Print(addonName .. ": /sufabsorbdebug on|off|toggle|status")
		return
	end

	self:Print(addonName .. ": Unknown absorbdebug command. Use /suf absorbdebug help")
end

function addon:HandleSUFSlash(msg)
	local input = (msg or ""):match("^%s*(.-)%s*$")
	if input == "" then
		self:ShowOptions()
		return
	end

	local command, rest = input:match("^(%S+)%s*(.-)$")
	command = command and command:lower() or ""
	rest = rest and rest:lower() or ""

	if command == "help" then
		self:ShowLauncherHelp()
		return
	end

	if command == "debug" then
		self:ToggleDebugPanel()
		return
	end
	if command == "reload" or command == "rl" then
		self:PromptReloadUI("Reload SUF/UI now?")
		return
	end
	if command == "status" or command == "report" then
		self:PrintStatusReport()
		return
	end
	if command == "install" or command == "installer" then
		self:StartInstallFlow()
		return
	end
	if command == "tutorial" or command == "tips" then
		self:ShowTutorialOverview(true)
		return
	end

	if command == "resources" or command == "resource" or command == "classpower" then
		self:PrintClassResourceAudit()
		return
	end

	if command == "perflib" or command == "perf" then
		self:TogglePerformanceDashboard()
		return
	end

	if command == "protected" then
		self:HandleProtectedOpsSlash(rest)
		return
	end

	if command == "absorbdebug" or command == "absdebug" then
		self:HandleAbsorbDebugSlash(rest)
		return
	end

	if command == "skinreport" or command == "skincoverage" or command == "blizzskin" then
		if self.PrintBlizzardSkinCoverageReport then
			self:PrintBlizzardSkinCoverageReport()
		elseif self.PrintBlizzardSkinReport then
			self:PrintBlizzardSkinReport()
		else
			self:Print(addonName .. ": Blizzard skin report is unavailable.")
		end
		return
	end

	if command == "ui" then
		local mode = (rest:match("^(%S+)") or ""):lower()
		if mode == "" or mode == "help" then
			self:Print(addonName .. ": /suf ui v2|legacy|toggle|status")
			return
		end
		if mode == "v2" then
			if self.SetOptionsV2Enabled then
				self:SetOptionsV2Enabled(true, true)
			end
			if self.ShowOptionsV2 then
				self:ShowOptionsV2()
			else
				self:Print(addonName .. ": OptionsV2 is unavailable in this build.")
			end
			return
		end
		if mode == "legacy" then
			if self.SetOptionsV2Enabled then
				self:SetOptionsV2Enabled(false, true)
			end
			self:ShowOptions()
			return
		end
		if mode == "toggle" then
			local enabled = false
			if self.IsOptionsV2Enabled then
				enabled = self:IsOptionsV2Enabled() and true or false
			end
			if self.SetOptionsV2Enabled then
				self:SetOptionsV2Enabled(not enabled, true)
			end
			if not enabled then
				if self.ShowOptionsV2 then
					self:ShowOptionsV2()
				else
					self:ShowOptions()
				end
			else
				self:ShowOptions()
			end
			return
		end
		if mode == "status" then
			local enabled = self.IsOptionsV2Enabled and self:IsOptionsV2Enabled()
			self:Print(addonName .. ": Options UI mode is " .. (enabled and "V2" or "legacy") .. ".")
			return
		end
		self:Print(addonName .. ": /suf ui v2|legacy|toggle|status")
		return
	end

	if command == "minimap" or command == "icon" then
		self.db.profile.minimap = self.db.profile.minimap or CopyTableDeep(defaults.profile.minimap)
		if rest == "show" then
			self.db.profile.minimap.hide = false
			self:InitializeLauncher()
			self:Print(addonName .. ": Minimap icon shown.")
			return
		elseif rest == "hide" then
			self.db.profile.minimap.hide = true
			self:ApplyLauncherVisibility()
			self:Print(addonName .. ": Minimap icon hidden.")
			return
		elseif rest == "toggle" then
			self.db.profile.minimap.hide = not self.db.profile.minimap.hide
			self:ApplyLauncherVisibility()
			self:Print(addonName .. ": Minimap icon " .. (self.db.profile.minimap.hide and "hidden." or "shown."))
			return
		elseif rest == "reset" then
			self.db.profile.minimap.hide = false
			self.db.profile.minimap.minimapPos = defaults.profile.minimap.minimapPos
			self:InitializeLauncher()
			self:Print(addonName .. ": Minimap icon reset.")
			return
		else
			self:Print(addonName .. ": /suf minimap show|hide|toggle|reset")
			return
		end
	end

	self:ShowOptions()
end
