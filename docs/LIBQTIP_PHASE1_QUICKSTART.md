# Phase 1 LibQTip Integration - Quick Start Guide

**Status:** ✅ Implementation Complete  
**Test Duration:** 5-10 minutes  
**Difficulty:** Easy

---

## What Was Changed

### New Files
- ✅ `Modules/UI/LibQTipHelper.lua` — Helper module for LibQTip tooltips

### Modified Files
- ✅ `Modules/UI/DebugWindow.lua` — Added "Frame Stats" button
- ✅ `SimpleUnitFrames.toc` — Added load order for LibQTipHelper

### Summary
- **Total Lines Added:** 151 lines of code
- **Total Lines Removed:** 0 lines
- **Backward Compatible:** ✅ Yes (graceful fallback)
- **Breaking Changes:** ❌ None

---

## How to Test (5 minutes)

### Step 1: Reload UI
```
/reload
```
*Wait for World of Warcraft to reload. Check for any error messages (there should be none).*

### Step 2: Open Debug Console
```
/suf debug
```
*The debug console window should open. You'll see text output in a scroll area.*

### Step 3: Find Frame Stats Button
**Location:** Bottom toolbar of debug console window  
**Appearance:** Blue button labeled "Frame Stats" (appears after "Analyze" button)  
**Size:** ~75px wide, normal button height

**Button sequence:** [Enabled] [Clear] [Export] [Settings] [Start] [Stop] [Analyze] **[Frame Stats]**

### Step 4: Hover Over Button
**Move mouse over "Frame Stats" button**

**Expected Result:**
A 4-column tooltip should appear with this format:
```
┌─────────────────┬────────┬────────────┬─────────┐
│ Frame Name      │ Health │ Power      │ Status  │
├─────────────────┼────────┼────────────┼─────────┤
│ Player          │ 100%   │ 95 mana    │ Visible │
│ Target          │ 78%    │ 45 mana    │ Visible │
│ Pet             │ 92%    │ —          │ Visible │
│ Focus           │ —      │ —          │ Hidden  │
│ [other frames]  │ ...    │ ...        │ ...     │
├─────────────────┼────────┼────────────┼─────────┤
│ Total           │ 4 fram │ —          │ Active  │
└─────────────────┴────────┴────────────┴─────────┘
```

### Step 5: Test Mouse Leave
**Move mouse away from button and tooltip**

**Expected Result:**
- Tooltip disappears immediately
- No errors in console
- Clean shutdown

### Step 6: Test Repeat
**Hover over button again (repeat 5+ times)**

**Expected Result:**
- Tooltip appears each time
- Performance is snappy (<1ms per creation)
- No console errors
- No memory growth (tooltip is pooled by LibQTip)

---

## Success Criteria

✅ **PASS if ALL of these are true:**
- [ ] No console errors on `/reload`
- [ ] Button appears in debug toolbar
- [ ] Tooltip appears on hover
- [ ] Tooltip has 4 columns (Frame Name, Health, Power, Status)
- [ ] Frame data is visible (Player name, health %, power values)
- [ ] Tooltip disappears on mouse leave
- [ ] No errors on repeated hover (5+ times)  
- [ ] Performance is responsive

❌ **FAIL if ANY of these occur:**
- Console error on load
- Button missing from toolbar
- Tooltip doesn't appear
- Tooltip has wrong format/columns
- Frame data missing or all "—"
- Tooltip stays on-screen after mouse leave
- Console errors on hover
- UI lag/freeze

---

## Troubleshooting

### Issue: Button doesn't appear
**Solution:**
```lua
-- Check if Button created successfully
/run print(addon.debugPanel.frameStatsBtn and "Button exists" or "Button missing")

-- Check if LibQTipHelper loaded
/run print(addon.LibQTipHelper and "✅ Loaded" or "❌ Not loaded")
```

### Issue: Tooltip appears blank/empty
**Solution:**
```lua
-- Check if LibQTip-2.0 is available
/run print(LibStub:GetLibrary("LibQTip-2.0") and "✅ LibQTip available" or "❌ LibQTip missing")

-- Check frame count
/run print(format("Frames loaded: %d", #addon.frames))
```

### Issue: Tooltip appears but shows all "—"
**Solution:**
- This is expected for hidden frames
- Active/visible frames should show values
- If ALL are "—", frames may not be initialized yet
- Solution: Play for a few seconds, then try again

### Issue: Console error on hover
**Cause:** Likely a Lua syntax issue or nil reference  
**Solution:**
```lua
-- Test manual tooltip creation
/run local t = LibStub("LibQTip-2.0"):AcquireTooltip("manual_test", 2); t:AddRow("Test", "Works!"); t:SmartAnchorTo(UIParent); t:Show()

-- This should display a 2-column tooltip
```

### Issue: Performance is slow (tooltip takes >100ms)
**Cause:** Unusual system configuration or many frames loaded  
**Workaround:** This is non-critical UI code, performance delay acceptable for now

---

## File Structure Reference

```
SimpleUnitFrames/
└── Modules/UI/
    ├── LibQTipHelper.lua              ← NEW (125 lines)
    └── DebugWindow.lua                ← MODIFIED (+25 lines)
    
SimpleUnitFrames.toc                    ← MODIFIED (+1 line, load order)
```

---

## Expected In-Game Behavior

| Action | Expected Behavior |
|--------|------------------|
| `/reload` | No errors, addon loads normally |
| `/suf debug` | Debug window opens as usual |
| Hover "Frame Stats" button | 4-column tooltip appears near button |
| Move mouse away | Tooltip disappears immediately |
| Hover again | Tooltip reappears, data current |
| Hover 10x fast | No lag, performance responsive |
| Check console | No errors in message log |

---

## Next Steps

If testing passes:
- ✅ Phase 1 implementation is verified
- 📋 See [LIBQTIP_PHASE1_IMPLEMENTATION_COMPLETE.md](docs/LIBQTIP_PHASE1_IMPLEMENTATION_COMPLETE.md) for detailed notes
- 🎯 Plan Phase 2 (Performance metrics tooltip)

If testing fails:
- ❌ Check troubleshooting section above
- 📖 Review [LIBQTIP_INTEGRATION_PLAN.md](docs/LIBQTIP_INTEGRATION_PLAN.md) for architecture details
- 💬 Check console for specific error messages

---

## Command Reference

```lua
-- Test commands to verify implementation

-- Check addon health
/run print(addon and "Addon loaded ✅" or "Addon missing ❌")

-- Check LibQTipHelper
/run print(addon.LibQTipHelper and "Helper loaded ✅" or "Helper missing ❌")

-- Check LibQTip-2.0
/run print(LibStub:GetLibrary("LibQTip-2.0") and "LibQTip ✅" or "LibQTip missing ❌")

-- Force open debug window
/run addon:ShowDebugPanel()

-- Create manual test tooltip
/run local q = LibStub("LibQTip-2.0"); local t = q:AcquireTooltip("test", 2); t:AddHeadingRow("Test", "Works?"); t:AddRow("Yes", "✅"); t:SmartAnchorTo(UIParent); t:Show()

-- Release test tooltip
/run LibStub("LibQTip-2.0"):ReleaseTooltip("test")

-- Get active frames
/run for i, f in ipairs(addon.frames) do print(format("%d: %s (%s)", i, f.sufUnitType or "?", f:GetName() or "?")) end
```

---

## Performance Baseline

For reference, expected performance:

| Operation | Time | Notes |
|-----------|------|-------|
| Addon load | <100ms | Negligible |
| Button render | <1ms | Instant |
| Tooltip create (1st) | 2-5ms | Pool allocation |
| Tooltip create (2nd+) | <1ms | Reused from pool |
| OnLeave cleanup | <1ms | Instant |
| Repeat hover 10x | <15ms | Very responsive |

If slower than above, system may be CPU-bound or loading other addons.

---

## Support

**Documentation:**
- [LIBQTIP_QUICK_REFERENCE.md](docs/LIBQTIP_QUICK_REFERENCE.md) — API reference
- [LIBQTIP_INTEGRATION_PLAN.md](docs/LIBQTIP_INTEGRATION_PLAN.md) — Design docs
- [LIBQTIP_RESEARCH_SUMMARY.md](docs/LIBQTIP_RESEARCH_SUMMARY.md) — Overview

**For Issues:**
1. Check troubleshooting section above
2. Verify file changes via git diff
3. Review console errors with `/run ReloadUI()`
4. Check copilot-instructions.md for conventions

---

**Total Test Time:** 5-10 minutes  
**Difficulty:** Easy  
**Expected Outcome:** ✅ Passing tests confirm Phase 1 success
