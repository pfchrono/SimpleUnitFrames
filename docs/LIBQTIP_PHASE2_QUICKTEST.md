# LibQTip Phase 2: Quick Test Guide

**Date:** 2026-03-01  
**Duration:** 5 minutes

---

## Pre-Test Verification

### 1. Files Present ✓

Verify all Phase 2 files created:

```bash
ls -la Modules/UI/PerformanceMetricsHelper.lua      # Should show: 172 bytes
ls -la Modules/UI/DebugWindow.lua                   # Should show: modified today
ls -la SimpleUnitFrames.toc                         # Should show: modified today
```

### 2. Load Order Correct ✓

```bash
grep -A2 "LibQTipHelper" SimpleUnitFrames.toc
# Should show:
# Modules/UI/LibQTipHelper.lua
# Modules/UI/PerformanceMetricsHelper.lua
# Modules/UI/DebugWindow.lua
```

### 3. Verify Dependencies ✓

```lua
/reload
# Wait for UI reload, check console for errors
# Should see:
# [SimpleUnitFrames] Addon loaded (normal message)
# [PerformanceLib] Performance integration enabled (if installed)
```

---

## Phase 2 Test Procedure

### Step 1: Open Debug Console (1 min)

```lua
/suf debug
```

**Expected:**
- Debug window opens
- Button toolbar visible at bottom
- Should see buttons: Enabled, Clear, Export, Settings, Start, Stop, Analyze, Stats, Perf

### Step 2: Verify "Perf" Button Visible (1 min)

Look for red "Perf" button after "Stats" button.

**Expected:**
- Button appears after "Stats" button
- Button size: 60px wide
- Button text: "Perf"

### Step 3: Test Hover Behavior (2 min)

**If PerformanceLib is NOT active:**
```lua
/hover Perf button
# Tooltip should NOT appear (graceful fallback)
```

**If PerformanceLib IS active:**
```lua
/hover Perf button
# Wait 0.5 seconds
```

**Expected Tooltip Content:**
```
Event Type       | Total | Coalesced | Efficiency % | Avg Batch
─────────────────┼───────┼───────────┼──────────────┼───────────
(Event rows here with color-coded efficiency)
─────────────────┼───────┼───────────┼──────────────┼───────────
TOTAL            | (stats)
```

### Step 4: Test Tooltip Cleanup (1 min)

Move mouse away from Perf button.

**Expected:**
- Tooltip disappears immediately
- No console errors
- Hover button again → tooltip reappears

---

## Success Criteria ✅

- [ ] Debug window opens without errors
- [ ] "Perf" button visible after "Stats" button
- [ ] Button responds to hover (appears to highlight/press)
- [ ] If PerformanceLib present: Tooltip appears with 5-column layout
- [ ] If PerformanceLib absent: No tooltip (graceful fallback)
- [ ] Tooltip disappears on mouse leave
- [ ] No console errors (check `/run` output)

---

## Troubleshooting

### Button Not Visible
```lua
/run print(addon.debugPanel and addon.debugPanel.perfStatsBtn and "✅ Button exists" or "❌ Button missing")
# If shows ❌, verify DebugWindow.lua modified correctly at lines 461-494
```

### Module Not Loading
```lua
/run print(addon.PerformanceMetricsHelper and "✅ Helper loaded" or "❌ Helper missing")
# If shows ❌, check SimpleUnitFrames.toc load order
```

### PerformanceLib Not Found
```lua
/run print(addon.performanceLib and "✅ PerformanceLib available" or "❌ PerformanceLib not loaded")
# If shows ❌, Phase 2 works but in fallback mode (expected if PerformanceLib addon not installed)
```

### Tooltip Not Appearing (with PerformanceLib)
```lua
/run local t = addon.PerformanceMetricsHelper:CreatePerformanceStatsTooltip(addon.performanceLib)
/run print(t and "✅ Tooltip created" or "❌ Tooltip failed")
# Check console for error message
```

---

## Next Step After Testing

If all tests pass ✅:
- Proceed to Phase 3: Enhanced Aura Tooltips (optional, 30 min)
- OR commit and release if all features satisfied

If issues found ❌:
- Check troubleshooting steps above
- Verify file syntax with: `/run dofile("...path.../PerformanceMetricsHelper.lua")`
- Review console errors

---

## Command Reference

```lua
-- Check addon status
/run print(addon and "✅ Addon loaded" or "❌ Addon missing")

-- Check all Phase 2 components
/run print("=== Phase 2 Components ===")
/run print(addon.PerformanceMetricsHelper and "✅ PerformanceMetricsHelper" or "❌ PerformanceMetricsHelper")
/run print(addon.debugPanel.perfStatsBtn and "✅ Perf button" or "❌ Perf button")
/run print(addon.performanceLib and "✅ PerformanceLib" or "⚠️  PerformanceLib (optional)")

-- Create test tooltip manually (requires PerformanceLib)
/run local t = addon.PerformanceMetricsHelper:CreatePerformanceStatsTooltip(addon.performanceLib)
/run print(t and "✅ Tooltip object created" or "❌ Tooltip creation failed")

-- Check EventCoalescer stats directly
/run print(addon.performanceLib.EventCoalescer:GetStats() and "✅ Stats available" or "❌ No stats")
```

---

## Files Changed Summary

| File | Changes | Purpose |
|------|---------|---------|
| PerformanceMetricsHelper.lua | +172 lines (NEW) | Display EventCoalescer stats tooltip |
| DebugWindow.lua | +38 lines | Add Perf button with hover/leave scripts |
| SimpleUnitFrames.toc | +1 line | Add load order for PerformanceMetricsHelper |

**Total Lines Added:** 211 lines
**Total Time to Test:** ~5 minutes
