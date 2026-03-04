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

-- Test Functions (Phase 1 Validation)
local function TestDiagnostics()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Phase 1 Diagnostics ===" .. COLORS.RESET)
	AddTestOutput("")
	
	-- Check validator loaded
	if addon.ValidateImportTree then
		AddTestOutput(COLORS.SUCCESS .. "[OK] Validator loaded" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] Validator MISSING" .. COLORS.RESET)
	end
	
	-- Check safe helpers exported
	if addon.SafeCompare then
		AddTestOutput(COLORS.SUCCESS .. "[OK] SafeCompare loaded" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] SafeCompare MISSING" .. COLORS.RESET)
	end
	
	if addon._core and addon._core.SafeArithmetic then
		AddTestOutput(COLORS.SUCCESS .. "[OK] SafeArithmetic loaded" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] SafeArithmetic MISSING" .. COLORS.RESET)
	end
	
	-- Test simple validation
	local ok, err = addon:ValidateImportTree({a = 1, b = 2})
	if ok then
		AddTestOutput(COLORS.SUCCESS .. "[OK] Validation test passed" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] Validation test failed: " .. tostring(err) .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Memory Usage: " .. string.format("%.1f MB", collectgarbage("count") / 1024) .. COLORS.RESET)
	AddTestOutput(COLORS.INFO .. "Active Frames: " .. #(addon.frames or {}) .. COLORS.RESET)
end

local function TestValidProfileImport()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 1: Valid Profile Import ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Export current profile: /suf export")
	AddTestOutput("2. Open options → Profiles tab")
	AddTestOutput("3. Click 'Import Profile'")
	AddTestOutput("4. Paste export string")
	AddTestOutput("5. Click 'Import'")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "EXPECTED:" .. COLORS.RESET)
	AddTestOutput("  • Profile loads successfully")
	AddTestOutput("  • Settings apply correctly")
	AddTestOutput("  • No validation errors in chat")
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS CRITERIA: Settings applied, no chat errors" .. COLORS.RESET)
end

local function TestMalformedImport()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 2: Malformed Import ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Open options → Profiles tab")
	AddTestOutput("2. Click 'Import Profile'")
	AddTestOutput("3. Paste truncated/invalid string (first 50 chars of export)")
	AddTestOutput("4. Click 'Import'")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "EXPECTED:" .. COLORS.RESET)
	AddTestOutput("  • Clear error message shown")
	AddTestOutput("  • Original profile unchanged")
	AddTestOutput("  • Addon remains stable")
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS CRITERIA: Error shown, no crash, addon stable" .. COLORS.RESET)
end

local function TestCycleDetection()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 3: Cycle Detection ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Running automated test..." .. COLORS.RESET)
	AddTestOutput("")
	
	-- Create circular reference
	local t = {}
	t.self = t
	
	local ok, err = addon:ValidateImportTree(t)
	if not ok and err and (err:match("cycl") or err:match("repeated")) then
		AddTestOutput(COLORS.SUCCESS .. "[PASS] Cycle detected correctly" .. COLORS.RESET)
		AddTestOutput("  Error: " .. err)
	elseif ok then
		AddTestOutput(COLORS.ERROR .. "[FAIL] Cycle NOT detected (returned OK)" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] Unexpected error: " .. tostring(err) .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS: No infinite loop, no crash" .. COLORS.RESET)
end

local function TestNodeLimit()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 4: Node Limit Validation ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Creating large nested structure (51,000 table nodes)..." .. COLORS.RESET)
	
	local t = {}
	for i = 1, 51000 do
		t[i] = {}  -- Create nested tables, not primitives
	end
	
	AddTestOutput(COLORS.INFO .. "Running validation..." .. COLORS.RESET)
	local startTime = GetTime()
	local ok, err = addon:ValidateImportTree(t)
	local elapsed = GetTime() - startTime
	
	AddTestOutput("")
	if not ok and err and (err:match("node") or err:match("large")) then
		AddTestOutput(COLORS.SUCCESS .. "[PASS] Node limit enforced" .. COLORS.RESET)
		AddTestOutput("  Error: " .. err)
	elseif ok then
		AddTestOutput(COLORS.ERROR .. "[FAIL] Large table accepted (should reject)" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] Unexpected error: " .. tostring(err) .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Elapsed: " .. string.format("%.3fs", elapsed) .. COLORS.RESET)
	if elapsed < 1.0 then
		AddTestOutput(COLORS.SUCCESS .. "[PASS] Completes quickly (<1s)" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] Too slow (>1s)" .. COLORS.RESET)
	end
end

local function TestDepthLimit()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 5: Depth Limit Validation ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "Creating 25-level deep nesting..." .. COLORS.RESET)
	
	local t = {}
	local cur = t
	for i = 1, 25 do
		local new = {}
		cur.next = new
		cur = new
	end
	
	AddTestOutput(COLORS.INFO .. "Running validation..." .. COLORS.RESET)
	local ok, err = addon:ValidateImportTree(t)
	
	AddTestOutput("")
	if not ok and err and err:match("depth") then
		AddTestOutput(COLORS.SUCCESS .. "[PASS] Depth limit enforced" .. COLORS.RESET)
		AddTestOutput("  Error: " .. err)
	elseif ok then
		AddTestOutput(COLORS.ERROR .. "[FAIL] Deep nesting accepted (should reject)" .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[FAIL] Unexpected error: " .. tostring(err) .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS: No crash or hang" .. COLORS.RESET)
end

local function TestProfileReload()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 6: Profile Reload (SafeReload) ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Open options window (/suf)")
	AddTestOutput("2. Make a setting change (e.g., toggle status bar)")
	AddTestOutput("3. Click 'Reload Profile' button OR type: /suf reload")
	AddTestOutput("4. Verify settings revert to saved state")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "EXPECTED:" .. COLORS.RESET)
	AddTestOutput("  • Profile reloads without UI glitches")
	AddTestOutput("  • Settings reset to saved values")
	AddTestOutput("  • Chat shows confirmation message")
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS CRITERIA: Reload completes, UI stable, settings reset" .. COLORS.RESET)
end

local function TestSafeHelpersInstance()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 7: Safe Helpers (Instance Test) ===" .. COLORS.RESET)
	AddTestOutput("")
	
	-- Check if in instance
	local inInstance, instanceType = IsInInstance()
	if inInstance then
		AddTestOutput(COLORS.INFO .. "Currently in instance: " .. (instanceType or "unknown") .. COLORS.RESET)
	else
		AddTestOutput(COLORS.ERROR .. "[Note] Not in instance - secret values may not be active" .. COLORS.RESET)
	end
	
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Enter a Dungeon/Raid Instance (where secret values active)")
	AddTestOutput("2. Open options window (/suf)")
	AddTestOutput("3. Toggle 3-4 settings:")
	AddTestOutput("   • Health bar color")
	AddTestOutput("   • Power bar visibility")
	AddTestOutput("   • Nameplate mode")
	AddTestOutput("4. Watch for errors in chat")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "EXPECTED:" .. COLORS.RESET)
	AddTestOutput("  • Settings apply correctly")
	AddTestOutput("  • No 'attempt to perform arithmetic' errors")
	AddTestOutput("  • No secret value comparison errors")
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS CRITERIA: No secret value errors, settings apply" .. COLORS.RESET)
end

local function TestRoundTrip()
	ClearTestOutput()
	AddTestOutput(COLORS.HEADER .. "=== Test 8: Export/Import Round-Trip ===" .. COLORS.RESET)
	AddTestOutput("")
	AddTestOutput(COLORS.INFO .. "INSTRUCTIONS:" .. COLORS.RESET)
	AddTestOutput("1. Export current profile: /suf export")
	AddTestOutput("2. Create new profile (e.g., 'Test Copy')")
	AddTestOutput("3. Import exported string into new profile")
	AddTestOutput("4. Compare 5-6 key settings with original:")
	AddTestOutput("   • Colors (health, power)")
	AddTestOutput("   • Visibility toggles")
	AddTestOutput("   • Font settings")
	AddTestOutput("5. Delete test profile when done")
	AddTestOutput("")
	AddTestOutput(COLORS.HEADER .. "EXPECTED:" .. COLORS.RESET)
	AddTestOutput("  • Re-imported profile identical to original")
	AddTestOutput("  • All settings preserved")
	AddTestOutput("  • No data loss")
	AddTestOutput("")
	AddTestOutput(COLORS.SUCCESS .. "PASS CRITERIA: Round-trip successful, all settings preserved" .. COLORS.RESET)
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
		title:SetText("SUF Test Panel (Phase 1 Validation)")

		-- Button Panel (top)
		local buttonPanel = CreateFrame("Frame", nil, frame)
		buttonPanel:SetSize(580, 135)
		buttonPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)

		-- Test Buttons (3 columns, 3 rows)
		local buttons = {
			{ text = "Diagnostics", func = TestDiagnostics, col = 1, row = 1 },
			{ text = "1: Valid Import", func = TestValidProfileImport, col = 2, row = 1 },
			{ text = "2: Malformed Import", func = TestMalformedImport, col = 3, row = 1 },
			{ text = "3: Cycle Detection", func = TestCycleDetection, col = 1, row = 2 },
			{ text = "4: Node Limit", func = TestNodeLimit, col = 2, row = 2 },
			{ text = "5: Depth Limit", func = TestDepthLimit, col = 3, row = 2 },
			{ text = "6: Profile Reload", func = TestProfileReload, col = 1, row = 3 },
			{ text = "7: Safe Helpers", func = TestSafeHelpersInstance, col = 2, row = 3 },
			{ text = "8: Round-Trip", func = TestRoundTrip, col = 3, row = 3 },
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

		-- Output Text with ScrollFrame
		local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -170)
		scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

		local textFrame = CreateFrame("Frame", nil, scroll)
		textFrame:SetSize(560, 1)  -- Height will be adjusted dynamically
		scroll:SetScrollChild(textFrame)

		local messagesText = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		messagesText:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 0, 0)
		messagesText:SetWidth(550)
		messagesText:SetJustifyH("LEFT")
		messagesText:SetJustifyV("TOP")
		messagesText:SetText("Welcome to SUF Phase 1 Test Panel!\n\nClick 'Diagnostics' to verify components, then run tests 1-8.\n\nAutomated tests (3-5) run immediately.\nManual tests (1,2,6-8) show instructions.")
		messagesText:SetNonSpaceWrap(true)  -- Enable word wrapping

		frame.messagesText = messagesText
		frame.textFrame = textFrame
		frame.scrollFrame = scroll

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
	
	-- Wait for text to render, then update height
	C_Timer.After(0.01, function()
		if not self.testPanel or not self.testPanel.messagesText or not self.testPanel.textFrame then
			return
		end
		
		local height = self.testPanel.messagesText:GetStringHeight()
		local scrollHeight = self.testPanel.scrollFrame:GetHeight()
		
		-- Set textFrame height to content height (minimum is scroll frame height)
		self.testPanel.textFrame:SetHeight(math.max(height + 20, scrollHeight))
		
		-- Scroll to bottom if content is long
		if height > scrollHeight - 20 then
			self.testPanel.scrollFrame:SetVerticalScroll(height - scrollHeight + 40)
		end
	end)
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
