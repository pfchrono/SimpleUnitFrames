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
	self:Print(addonName .. ": /suf (options)")
	self:Print(addonName .. ": /suf minimap show|hide|toggle|reset")
	self:Print(addonName .. ": /suf perflib")
	self:Print(addonName .. ": /suf debug")
	self:Print(addonName .. ": /suf status")
	self:Print(addonName .. ": /suf protected (see also: /SUFprotected help)")
	self:Print(addonName .. ": /suf install")
	self:Print(addonName .. ": /suf tutorial")
	self:Print(addonName .. ": /suf reload")
	self:Print(addonName .. ": /suf resources")
	self:Print(addonName .. ": /suf help")
end

function addon:StartInstallFlow()
	self:ShowOptions()
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
