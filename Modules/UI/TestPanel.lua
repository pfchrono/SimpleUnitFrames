local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then
    return
end

local core = addon._core or {}
local addonName = core.addonName or "SimpleUnitFrames"

-- Test output storage
addon.testOutput = addon.testOutput or {}
local testOutput = addon.testOutput

-- Color codes for output
local COLORS = {
	SUCCESS = "|cff00ff00",   -- Green
	ERROR = "|cffff0000",     -- Red
	INFO = "|cff87ceeb",      -- Blue
	HEADER = "|cffffaa00",    -- Orange
	RESET = "|r",
}

local function AddTestOutput(msg)
	table.insert(testOutput, msg)
	if addon.testPanelRefresh then
		addon:testPanelRefresh()
	end
end

local function ClearTestOutput()
	testOutput = {}
	addon.testOutput = testOutput
	if addon.testPanelRefresh then
		addon:testPanelRefresh()
	end
end

-- Test Functions
local function TestPhase1()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== PHASE 1: Addon Load & Initialization ===" .. COLORS.RESET)
	AddTestOutput("")
	
	-- Test: Reload (inform user)
	AddTestOutput(COLORS.INFO .. "[1/4] Addon loaded and ready" .. COLORS.RESET)
	
	-- Test: PerformanceLib
	if addon and addon.performanceLib then
		AddTestOutput(COLORS.SUCCESS .. "[2/4] [OK] PerformanceLib LOADED" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[2/4] [FAIL] PerformanceLib NOT LOADED" .. COLORS.RESET)
		AddTestOutput("       Make sure PerformanceLib addon is enabled")
		return
	end
	
	-- Test: DirtyFlagManager
	if addon.performanceLib.DirtyFlagManager then
		AddTestOutput(COLORS.SUCCESS .. "[3/4] [OK] DirtyFlagManager READY" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[3/4] [FAIL] DirtyFlagManager NOT INITIALIZED" .. COLORS.RESET)
		return
	end
	
	-- Test: Frame Visibility
	local playerFrame = _G["SUF_Player"]
	local targetFrame = _G["SUF_Target"]
	if playerFrame and targetFrame then
		AddTestOutput(COLORS.SUCCESS .. "[4/4] [OK] Player/Target frames visible" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[4/4] [FAIL] Frames not found (player=" .. tostring(playerFrame ~= nil) .. 
			", target=" .. tostring(targetFrame ~= nil) .. ")" .. COLORS.RESET)
		return
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "[PASS] PHASE 1 PASSED - Ready for gameplay testing" .. COLORS.RESET)
end

local function TestPhase2()
	AddTestOutput(COLORS.HEADER .. "=== PHASE 2: Performance Profiler Setup ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Starting performance profiler..." .. COLORS.RESET)
	AddTestOutput("Command: /SUFprofile start")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "📊 INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Execute: /SUFprofile start")
	AddTestOutput("2. Play solo for 2 minutes (walk, target NPCs, cast spells)")
	AddTestOutput("3. Execute: /SUFprofile stop")
	AddTestOutput("4. Execute: /SUFprofile analyze")
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Record these metrics:" .. COLORS.RESET)
	AddTestOutput("  • Average FPS")
	AddTestOutput("  • Frame time P50 (target: ~16.68ms)")
	AddTestOutput("  • Frame time P99 (target: <20ms)")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "✅ Then proceed to PHASE 3" .. COLORS.RESET)
end

local function TestPhase3A()
	AddTestOutput(COLORS.HEADER .. "=== PHASE 3a: Party Testing ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Running validation checks..." .. COLORS.RESET)
	
	-- Check party frames
	local partyFrames = 0
	for i = 1, 4 do
		if _G["SUF_PartyUnitButton" .. i] then
			partyFrames = partyFrames + 1
		end
	end
	
	AddTestOutput("")
	AddTestOutput("Party frames found: " .. COLORS.SUCCESS .. partyFrames .. "/4" .. COLORS.RESET)
	
	if partyFrames > 0 then
		AddTestOutput(COLORS.SUCCESS .. "[OK] Party frames available" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] No party frames detected" .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "📊 INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Join party with 4 others (5 total, or use alts)")
	AddTestOutput("2. Execute: /SUFprofile start")
	AddTestOutput("3. Move between party members for 3 minutes")
	AddTestOutput("4. Change targets frequently")
	AddTestOutput("5. Execute: /SUFprofile stop")
	AddTestOutput("6. Execute: /SUFprofile analyze")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "✅ Check metrics and proceed to PHASE 3b" .. COLORS.RESET)
end

local function TestPhase3B()
	AddTestOutput(COLORS.HEADER .. "=== PHASE 3b: Raid Testing ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Raid validation..." .. COLORS.RESET)
	
	-- Check raid frames
	local raidFrames = 0
	for i = 1, 40 do
		if _G["SUF_Raid_" .. i] or _G["SUF_RaidUnitButton" .. i] then
			raidFrames = raidFrames + 1
		end
	end
	
	AddTestOutput("")
	AddTestOutput("Raid frames found: " .. COLORS.SUCCESS .. raidFrames .. "/40" .. COLORS.RESET)
	
	if raidFrames > 0 then
		AddTestOutput(COLORS.SUCCESS .. "[OK] Raid frames available" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.INFO .. "[INFO] Not in raid group currently" .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "📊 INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Join raid (10+ players preferred)")
	AddTestOutput("2. Execute: /SUFprofile start")
	AddTestOutput("3. Engage in combat for 3-5 minutes")
	AddTestOutput("4. Move around and change targets")
	AddTestOutput("5. Execute: /SUFprofile stop")
	AddTestOutput("6. Execute: /SUFprofile analyze")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "Success Criteria:" .. COLORS.RESET)
	AddTestOutput("  [OK] P50 frame time ≤16.68ms (60 FPS)")
	AddTestOutput("  [OK] P99 frame time <25ms (raid is acceptable)")
	AddTestOutput("  [OK] No visual glitches or slowdowns")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "[PASS] Check metrics and finish testing" .. COLORS.RESET)
end

local function TestPhase3C()
	AddTestOutput(COLORS.HEADER .. "=== PHASE 3c: Edge Cases ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "System Status:" .. COLORS.RESET)
	
	-- Check PerformanceLib fallback
	local perfLibLoaded = addon.performanceLib and true or false
	AddTestOutput("")
	
	if perfLibLoaded then
		AddTestOutput(COLORS.SUCCESS .. "[OK] PerformanceLib active (fallback not needed)" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.INFO .. "[INFO] PerformanceLib inactive (synchronous mode)" .. COLORS.RESET)
	end
	
	-- Check memory usage
	local memBefore = collectgarbage("count") / 1024
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Memory Usage: " .. COLORS.RESET .. string.format("%.1f MB", memBefore))
	
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "📊 EDGE CASE TESTS:" .. COLORS.RESET)
	AddTestOutput("1. Disable PerformanceLib and reload")
	AddTestOutput("   • Edit: PerformanceLib.toc, set ## LoadOnDemand: 1")
	AddTestOutput("   • Execute: /reload")
	AddTestOutput("   • Verify: SUF still works (fallback to sync mode)")
	AddTestOutput("")
	AddTestOutput("2. Rapid frame changes")
	AddTestOutput("   • Join/leave party repeatedly")
	AddTestOutput("   • Watch for errors or stuck frames")
	AddTestOutput("")
	AddTestOutput("3. Memory stability")
	AddTestOutput("   • Play for 30 minutes")
	AddTestOutput("   • Record memory at start and end")
	AddTestOutput("   • Should not grow unbounded")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "[PASS] Complete all tests for full validation" .. COLORS.RESET)
end

local function TestShowStats()
	AddTestOutput(COLORS.HEADER .. "=== Performance & System Stats ===" .. COLORS.RESET)
	AddTestOutput("")
	
	-- DirtyFlagManager stats
	if addon.performanceLib and addon.performanceLib.DirtyFlagManager then
		AddTestOutput(COLORS.INFO .. "[DirtyFlagManager Stats]" .. COLORS.RESET)
		local stats = addon.performanceLib.DirtyFlagManager.stats or {}
		AddTestOutput("  Frames processed: " .. (stats.framesProcessed or 0))
		AddTestOutput("  Batches: " .. (stats.batchCount or 0))
		AddTestOutput("  Invalid frames skipped: " .. (stats.invalidFrames or 0))
		AddTestOutput("")
	end
	
	-- EventCoalescer stats
	if addon.performanceLib and addon.performanceLib.EventCoalescer then
		AddTestOutput(COLORS.INFO .. "[EventCoalescer Stats]" .. COLORS.RESET)
		AddTestOutput("(Execute: /run SUF.performanceLib.EventCoalescer:PrintStats())")
		AddTestOutput("")
	end
	
	-- Memory usage
	local memory = collectgarbage("count") / 1024
	AddTestOutput(COLORS.INFO .. "[Memory Usage]" .. COLORS.RESET)
	AddTestOutput("  Current: " .. string.format("%.1f MB", memory))
	AddTestOutput("")
	
	-- Frame count
	local frameCount = #(addon.frames or {})
	AddTestOutput(COLORS.INFO .. "[Frame Count]" .. COLORS.RESET)
	AddTestOutput("  Active frames: " .. frameCount)
	AddTestOutput("")
	
	AddTestOutput(COLORS.SUCCESS .. "[OK] Stats updated successfully" .. COLORS.RESET)
end

-- Create Test Panel UI
function addon:ShowTestPanel()
	if not self.testPanel then
		local frame = CreateFrame("Frame", "SUFTestPanel", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(600, 500)
		frame:SetPoint("CENTER")
		self:EnableMovableFrame(frame, true, "test_panel", { "CENTER", "UIParent", "CENTER", 0, 0 })
		frame:SetFrameStrata("DIALOG")

		-- Title
		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", frame, "TOP", 0, -10)
		title:SetText("SUF Test Panel (Phase 4 DirtyFlagManager)")

		-- Button Panel (top)
		local buttonPanel = CreateFrame("Frame", nil, frame)
		buttonPanel:SetSize(580, 120)
		buttonPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)

		-- Test Buttons (3 columns, 2 rows for better visibility)
		local buttons = {
			{ text = "Phase 1: Load Test", func = TestPhase1, col = 1, row = 1 },
			{ text = "Phase 2: Profiler Setup", func = TestPhase2, col = 2, row = 1 },
			{ text = "Phase 3a: Party", func = TestPhase3A, col = 3, row = 1 },
			{ text = "Phase 3b: Raid", func = TestPhase3B, col = 1, row = 2 },
			{ text = "Phase 3c: Edge Cases", func = TestPhase3C, col = 2, row = 2 },
			{ text = "Stats", func = TestShowStats, col = 3, row = 2 },
		}

		for _, btnData in ipairs(buttons) do
			local btn = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
			btn:SetSize(180, 28)
			
			local col = btnData.col or 1
			local row = btnData.row or 1
			local xOffset = (col - 1) * 190 + 5
			local yOffset = (row - 1) * 35 + 5
			
			btn:SetPoint("TOPLEFT", buttonPanel, "TOPLEFT", xOffset, -yOffset)
			
			-- Improve text visibility
			btn:SetText(btnData.text)
			btn:GetFontString():SetTextColor(1, 0.82, 0, 1)  -- Gold color for visibility
			btn:GetFontString():SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
			
			btn:SetScript("OnClick", function()
				btnData.func()
				self:testPanelRefresh()
			end)
		end

		-- Control buttons
		local clearBtn = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
		clearBtn:SetSize(70, 28)
		clearBtn:SetPoint("BOTTOMRIGHT", buttonPanel, "BOTTOMRIGHT", -5, 0)
		clearBtn:SetText("Clear")
		clearBtn:GetFontString():SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
		clearBtn:SetScript("OnClick", function()
			ClearTestOutput()
			self:testPanelRefresh()
		end)

		local exportBtn = CreateFrame("Button", nil, buttonPanel, "UIPanelButtonTemplate")
		exportBtn:SetSize(70, 28)
		exportBtn:SetPoint("RIGHT", clearBtn, "LEFT", -5, 0)
		exportBtn:SetText("Export")
		exportBtn:GetFontString():SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
		exportBtn:SetScript("OnClick", function()
			self:ShowTestExportDialog()
		end)

		-- Output Text
		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -155)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

		local textFrame = CreateFrame("Frame", nil, scroll)
		textFrame:SetSize(560, 300)
		scroll:SetScrollChild(textFrame)

		local messagesText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		messagesText:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 0, 0)
		messagesText:SetWidth(550)
		messagesText:SetHeight(300)
		messagesText:SetJustifyH("LEFT")
		messagesText:SetJustifyV("TOP")
		messagesText:SetText("Welcome to SUF Test Panel!\n\nClick a test phase to begin.\nResults will appear here.")

		frame.messagesText = messagesText
		frame.textFrame = textFrame

		self.testPanel = frame

		-- Apply theming
		if self.ApplySUFBackdropColors then
			self:ApplySUFBackdropColors(frame, "window")
		end
	end

	self:PrepareWindowForDisplay(self.testPanel)
	self.testPanel:Show()
	self:PlayWindowOpenAnimation(self.testPanel)
end

function addon:testPanelRefresh()
	if not self.testPanel or not self.testPanel.messagesText then
		return
	end
	
	local text = table.concat(testOutput, "\n")
	self.testPanel.messagesText:SetText(text)
	local height = self.testPanel.messagesText:GetStringHeight()
	self.testPanel.textFrame:SetHeight(math.max(height + 10, 1))
end

function addon:ShowTestExportDialog()
	if not self.testExportFrame then
		local frame = CreateFrame("Frame", "SUFTestExportFrame", UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(520, 420)
		frame:SetPoint("CENTER")
		self:EnableMovableFrame(frame, true, "test_export", { "CENTER", "UIParent", "CENTER", 0, 0 })
		frame:SetFrameStrata("DIALOG")

		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", frame, "TOP", 0, -10)
		title:SetText("Export Test Results")

		local note = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		note:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
		note:SetText("Ctrl+A to select all, Ctrl+C to copy")

		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -56)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

		local editBox = CreateFrame("EditBox", nil, scroll)
		editBox:SetMultiLine(true)
		editBox:SetFontObject(GameFontHighlightSmall)
		editBox:SetWidth(470)
		editBox:SetAutoFocus(false)
		editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
		scroll:SetScrollChild(editBox)
		frame.editBox = editBox

		if self.ApplySUFBackdropColors then
			self:ApplySUFBackdropColors(frame, "window")
		end

		self.testExportFrame = frame
	end

	local title = self.testExportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	if self.testExportFrame.TitleText then
		title = self.testExportFrame.TitleText
	end
	title:SetText("Export Test Results")

	local exportText = table.concat(testOutput, "\n")
	self.testExportFrame.editBox:SetText(exportText)
	self.testExportFrame.editBox:SetCursorPosition(0)
	self.testExportFrame.editBox:HighlightText()

	self:PrepareWindowForDisplay(self.testExportFrame)
	self.testExportFrame:Show()
	self:PlayWindowOpenAnimation(self.testExportFrame)
end

-- Register test panel slash command
addon:RegisterChatCommand("suftest", function()
	addon:ShowTestPanel()
end)
