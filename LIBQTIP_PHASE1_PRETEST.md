# Phase 1 Implementation - Pre-Test Verification

**Date:** 2026-03-01  
**Purpose:** Verify all implementation files are in place before in-game testing  
**Time to Complete:** 2 minutes

---

## File Verification Checklist

### ✅ New Files Created

- [ ] **LibQTipHelper.lua** exists at: `Modules/UI/LibQTipHelper.lua`
  - File size: ~125 lines
  - Contains: `CreateFrameStatsTooltip()` function
  - Contains: `ReleaseFrameStatsTooltip()` function
  - `addon.LibQTipHelper = LibQTipHelper` assignment present

**Verify:**
```bash
ls -la Modules/UI/LibQTipHelper.lua
# Should show: -rw-r--r-- ... LibQTipHelper.lua
```

---

### ✅ Files Modified

#### 1. DebugWindow.lua
- [ ] File exists at: `Modules/UI/DebugWindow.lua`
- [ ] Line 11: Comment about LibQTipHelper present
- [ ] Lines 435-455: Frame Stats button code added
  - Check for: `frameStatsBtn = CreateFrame(...)`
  - Check for: `frameStatsBtn:SetScript("OnEnter", ...)`
  - Check for: `frameStatsBtn:SetScript("OnLeave", ...)`
  - Check for: `frame.frameStatsBtn = frameStatsBtn`

**Verify:**
```bash
grep -n "frameStatsBtn" Modules/UI/DebugWindow.lua
# Should show ~5 matching lines
```

#### 2. SimpleUnitFrames.toc
- [ ] File exists at: `SimpleUnitFrames.toc`
- [ ] Line with `Modules/UI/LibQTipHelper.lua` present
- [ ] LibQTipHelper.lua listed BEFORE DebugWindow.lua
- [ ] Load order is:
  ```
  Modules/UI/DataSystems.lua
  Modules/UI/LibQTipHelper.lua    ← MUST BE HERE
  Modules/UI/DebugWindow.lua
  ```

**Verify:**
```bash
grep -A2 "DataSystems.lua" SimpleUnitFrames.toc
# Should show LibQTipHelper and DebugWindow in sequence
```

---

## Code Validation Checklist

### LibQTipHelper.lua Content

- [ ] **Imports:**
  - [ ] `local AceAddon = LibStub("AceAddon-3.0")`
  - [ ] `local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)`
  - [ ] Early addon check with graceful return

- [ ] **Module Definition:**
  - [ ] `local LibQTipHelper = {}`
  - [ ] `addon.LibQTipHelper = LibQTipHelper`

- [ ] **GetQTip Function:**
  - [ ] Exists as local function
  - [ ] Returns `LibStub:GetLibrary("LibQTip-2.0")`

- [ ] **CreateFrameStatsTooltip Function:**
  - [ ] Takes `frames` parameter
  - [ ] Validates LibQTip available
  - [ ] Calls `QTip:AcquireTooltip("SUF_FrameStats", 4, ...)`
  - [ ] Sets fonts: `SetDefaultFont()`, `SetDefaultHeadingFont()`
  - [ ] Sets margins: `SetCellMarginH(3)`, `SetCellMarginV(2)`
  - [ ] Adds header row: `AddHeadingRow("Frame Name", "Health", "Power", "Status")`
  - [ ] Iterates addon.frames: `for i, frame in ipairs(frames)`
  - [ ] Adds data for each frame
  - [ ] Adds separator
  - [ ] Adds total row
  - [ ] Returns tooltip

### DebugWindow.lua Content

- [ ] **Frame Stats Button Code (lines ~435-455):**
  - [ ] Button creation: `CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")`
  - [ ] Size: `SetSize(75, 24)`
  - [ ] Positioning: `SetPoint("LEFT", profileAnalyzeBtn, "RIGHT", 8, 0)`
  - [ ] Text: `SetText("Frame Stats")`
  - [ ] OnEnter script present and correct
  - [ ] OnLeave script present and correct
  - [ ] Storing reference: `self.__frameStatsTooltip = tooltip`
  - [ ] Releasing: `QTip:ReleaseTooltip(self.__frameStatsTooltip)`

### SimpleUnitFrames.toc Content

- [ ] **Load order section correct:**
  - [ ] `Modules/UI/DataSystems.lua` present
  - [ ] `Modules/UI/LibQTipHelper.lua` present (after DataSystems)
  - [ ] `Modules/UI/DebugWindow.lua` present (after LibQTipHelper)
  - [ ] No duplicate entries

---

## Syntax Validation

### Quick Lua Syntax Check
```lua
-- Run in WoW console to validate syntax:
/run dofile("Interface/AddOns/SimpleUnitFrames/Modules/UI/LibQTipHelper.lua")
-- Should NOT produce errors
```

If error occurs, check for:
- Missing `local` declarations
- Unmatched parentheses or brackets
- Missing `end` statements
- Invalid function syntax

---

## Library Availability Check

### Pre-Flight Verification
```lua
-- Run these commands BEFORE opening debug window:

/run print(LibStub and "✅ LibStub available" or "❌ LibStub missing")
/run print(LibStub:GetLibrary("LibQTip-2.0") and "✅ LibQTip-2.0 available" or "❌ LibQTip-2.0 missing")
/run print(addon and "✅ Addon initialized" or "❌ Addon missing")
/run print(addon.frames and format("✅ %d frames loaded", #addon.frames) or "❌ No frames")
```

**Expected Output:**
```
✅ LibStub available
✅ LibQTip-2.0 available
✅ Addon initialized
✅ N frames loaded
```

If NOT all green:
- [ ] Reload UI: `/reload`
- [ ] Try again

---

## Button Detection Verification

### Verify Button Created
```lua
/run print(addon.debugPanel and addon.debugPanel.frameStatsBtn and "✅ Button exists" or "❌ Button missing")
```

**Expected:** `✅ Button exists`

If button missing:
- [ ] Check DebugWindow.lua line 435 area for button creation
- [ ] Verify frame.frameStatsBtn assignment on last line
- [ ] Look for errors in `/run addon:ShowDebugPanel()`

---

## In-Game Verification (Quick)

Before the full 5-minute test, do this 1-minute check:

1. **Type:** `/reload`
   - Wait for UI to reload
   - Check console for errors (scroll up)
   - Should see: "SimpleUnitFrames loaded" (normal)

2. **Type:** `/suf debug`
   - Debug window should open
   - Scroll down to see button bar
   - Look for blue "Frame Stats" button

3. **Type:** `/run print(addon.debugPanel.frameStatsBtn and "OK" or "FAIL")`
   - Should print: `OK`
   - If prints: `FAIL`, button creation failed

---

## Rollback Verification

If you need to verify rollback works:

```bash
# Verify current state can be reverted
git status
# Should show: modified files and new files

# Preview what would be removed
git clean -nd
# Shows files that would be deleted

# Verify originals available
git log --oneline Modules/UI/DebugWindow.lua
# Should show commit history

git log --oneline SimpleUnitFrames.toc
# Should show commit history
```

---

## Pre-Test Checklist (Complete Before Testing)

### Files Present
- [ ] LibQTipHelper.lua exists (125 lines)
- [ ] DebugWindow.lua modified (+25 lines in button section)
- [ ] SimpleUnitFrames.toc updated (LibQTipHelper in load order)

### Code Valid
- [ ] LibQTipHelper syntax correct (no Lua errors)
- [ ] DebugWindow button code intact
- [ ] TOC load order correct

### Libraries Ready
- [ ] LibStub available (`/run print(LibStub and "OK"`)
- [ ] LibQTip-2.0 available (`/run print(LibStub:GetLibrary("LibQTip-2.0") and "OK"`)
- [ ] Addon loaded (`/run print(addon and "OK"`)

### UI Components Ready
- [ ] Debug window opens (`/suf debug`)
- [ ] Frame Stats button created (`/run print(addon.debugPanel.frameStatsBtn and "OK"`)
- [ ] Addon.frames populated (`/run print(#addon.frames .. " frames"`)

### Ready for Testing
- [ ] All checkboxes above checked ✓
- [ ] Console shows no errors
- [ ] Quick verification commands all returned "OK"
- [ ] Ready to proceed to [LIBQTIP_PHASE1_QUICKSTART.md](LIBQTIP_PHASE1_QUICKSTART.md)

---

## If Any Checkbox Fails ❌

### Step 1: Identify Problem
- Note which checkbox failed
- Run relevant verification command
- Check console for error message

### Step 2: Review Related Code
- Find file mentioned in failed checkbox
- Review that section of code
- Check for typos or missing lines

### Step 3: Common Issues

**Issue: LibQTipHelper.lua not found**
- [ ] File exists at: `Modules/UI/LibQTipHelper.lua`
- [ ] Not in different directory
- [ ] Filename exact case match

**Issue: Button not appearing**
- [ ] Line 435+ in DebugWindow.lua has button code
- [ ] Line contains: `CreateFrame("Button"...`
- [ ] Frame assignment: `frame.frameStatsBtn = frameStatsBtn`

**Issue: LibQTip not available**
- [ ] Reload UI: `/reload`
- [ ] Check Libraries loaded correctly
- [ ] Verify `Libraries/Init.xml` includes LibQTip

---

## You're Ready! ✅

Once all checkboxes above are checked:

1. **Next:** Read [LIBQTIP_PHASE1_QUICKSTART.md](LIBQTIP_PHASE1_QUICKSTART.md)
2. **Test:** Follow 5-minute testing procedure
3. **Verify:** Check against success criteria
4. **Celebrate:** Phase 1 complete! 🎉

---

## Quick Reference Commands

```lua
-- Verify everything is ready to test:

/reload
-- Wait for UI reload, check for errors

/run print("=== VERIFICATION ===")
/run print(LibStub and "✅ LibStub" or "❌ LibStub")
/run print(LibStub:GetLibrary("LibQTip-2.0") and "✅ LibQTip" or "❌ LibQTip")
/run print(addon and "✅ Addon" or "❌ Addon")
/run print(addon.LibQTipHelper and "✅ Helper" or "❌ Helper")
/run print(addon.debugPanel and addon.debugPanel.frameStatsBtn and "✅ Button" or "❌ Button")
/run print(format("✅ %d frames", #addon.frames))

/suf debug
-- Open debug window
-- Look for Frame Stats button
```

If all show ✅, you're ready to test!
