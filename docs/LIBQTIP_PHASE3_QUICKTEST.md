# LibQTip Phase 3: Enhanced Aura Tooltips - Quick Test Guide

**Date:** 2026-03-01  
**Duration:** 10 minutes  
**Requires:** WoW instance with visible auras (buffs/debuffs)

---

## Pre-Test Setup

### 1. Get Auras Active

**In-Game Setup:**
- Type `/reload`
- Wait for UI to load
- Cast a buff or debuff on yourself (or target)
  - Example buffs: Blessing, shield spells, consumables
  - Example debuffs: Poison, curse, slow effects

### 2. Verify Files Present

```bash
ls -la Modules/UI/AuraTooltipHelper.lua    # Should show: ~140 lines
ls -la Modules/UI/AuraTooltipManager.lua   # Should show: ~115 lines
```

### 3. Check Load Order

```bash
grep -A4 "LibQTipHelper" SimpleUnitFrames.toc
# Should show:
# Modules/UI/LibQTipHelper.lua
# Modules/UI/PerformanceMetricsHelper.lua
# Modules/UI/AuraTooltipHelper.lua
# Modules/UI/AuraTooltipManager.lua
# Modules/UI/DebugWindow.lua
```

---

## Phase 3 Test Procedure

### Step 1: Verify Components Loaded (2 min)

```lua
/reload
# Wait for reload, check console
# Should see: SimpleUnitFrames loaded (normal)

/run print(addon.AuraTooltipHelper and "✅ AuraTooltipHelper" or "❌ Missing")
/run print(addon.AuraTooltipManager and "✅ AuraTooltipManager" or "❌ Missing")
```

**Expected:** Both show ✅

### Step 2: Test Aura Tooltip in Normal Zone (4 min)

**Setup:**
- Stay in non-instance zone (town, open world)
- Make sure you have at least 1 visible buff or debuff

**Test in-game:**
1. Find your buff/debuff aura button on screen
   - Look at player frame's buff/debuff bars (typically top-right of screen)
   - Or in raid/party frames

2. **Hover over the aura button** (wait 0.5 seconds)

**Expected:**
- LibQTip tooltip appears (NOT generic Blizzard tooltip)
- Format: 2-column list showing:
  - ```
    [Aura Name]
    Type: [Buff/Debuff]
    [Stacks: N] (if multiple)
    [Duration: Xm Ys] (if timed)
    Category: [Buff|Debuff]
    ─────────────────────
    [Aura Description]
    ```
- Colors: Green text for Buff, Red for Debuff, Orange for stacks

**Example:**
```
╔════════════════════════════════╗
║ Shield of Protection           ║
╠════════════════════════════════╣
║ Type: Magic                    ║
║ Duration: Permanent            ║
║ Category: Buff                 ║
║ ────────────────────────────── ║
║ Absorbs damage attacks.        ║
╚════════════════════════════════╝
```

### Step 3: Mouse Away & Repeat (1 min)

Move mouse away from aura button.

**Expected:**
- Tooltip disappears immediately
- Hover button again → tooltip reappears
- No console errors

### Step 4: Test with Stacked Aura (1 min)

If you have a stacked buff/debuff:

**Hover over stacked aura:**

**Expected:**
- Tooltip shows: `Stacks: 3` (or however many)
- Stack count in orange color: `|cFFFFA500`
- Tooltip large enough to display stacks

### Step 5: Test in Instance (Optional, 2 min)

**If available, enter 5-player dungeon:**

**Hover over aura:**

**Expected:**
- Fallback behavior (if GameTooltip Forbidden):
  - Either LibQTip tooltip (if allowed)
  - Or generic GameTooltip (always works)
- No console errors
- No blank/missing tooltip

---

## Success Criteria ✅

- [ ] AuraTooltipHelper loads without errors
- [ ] AuraTooltipManager loads without errors
- [ ] Hovering aura button shows custom tooltip (not generic Blizzard format)
- [ ] Tooltip shows: Name, Type, Duration (if timed)
- [ ] Stacked auras show stack count
- [ ] Tooltip disappears on mouse leave
- [ ] Fallback works in instances (no blank tooltip)
- [ ] No console errors

---

## Troubleshooting

### Modules Not Loading
```lua
/run print(addon.AuraTooltipHelper and "YES" or "NO")
# If NO, check:
# 1. SimpleUnitFrames.toc has AuraTooltipHelper.lua in load order
# 2. File exists at Modules/UI/AuraTooltipHelper.lua
# 3. Check console for syntax errors
```

### Tooltip Not Appearing
```lua
-- Test manual tooltip creation
/run local tooltip = addon.AuraTooltipHelper:CreateAuraTooltip("player", 1)
/run print(tooltip and "✅ Tooltip created" or "❌ Tooltip failed")

-- Check manager status
/run print(addon.AuraTooltipManager:ShowAuraTooltip and "✅ Manager ready")
```

### Generic GameTooltip Still Showing
- This is OK if LibQTip tooltip not created
- GameTooltip fallback means feature working in "safe" mode
- Check console for C_UnitAuras errors

### Console Errors
```lua
-- Check C_UnitAuras availability
/run print(C_UnitAuras and "✅ C_UnitAuras available" or "❌ API missing")

-- Test aura data directly
/run local data = C_UnitAuras.GetAuraDataByAuraInstanceID("player", 1)
/run print(data and "✅ Aura data available" or "❌ No aura data")
```

---

## Comparing Phases 1-3

| Phase | Feature | Button | Tooltip Type |
|-------|---------|--------|--------------|
| Phase 1 | Frame Stats | "Stats" | 4-column frames |
| Phase 2 | Performance Metrics | "Perf" | 5-column event stats |
| Phase 3 | Enhanced Auras | (on-hover) | 2-column aura details |

All work simultaneously. Each independent system.

---

## Next Steps After Phase 3

If all tests pass ✅:
1. **Commit all Phases 1-3:**
   ```bash
   git add -A
   git commit -m "LibQTip Phases 1-3: Complete integration (Frame Stats, Performance Metrics, Aura Tooltips)"
   git tag -a v1.24.0 -m "LibQTip integration complete"
   ```

2. **Optional Phase 4:** Frame Info Tooltips (deferred, not required)

3. **Release:** Deploy to CurseForge/GitHub

---

## Command Reference

```lua
-- Check all modules
/run for k in pairs({"AuraTooltipHelper", "AuraTooltipManager", "AuraTooltipManager"}) do
  print(addon[k] and ("✅ "..k) or ("❌ "..k)) end

-- Test aura data query
/run local data = C_UnitAuras.GetAuraDataByAuraInstanceID("player", 1)
/run print(data.name or "No aura found")

-- Create test tooltip
/run local t = addon.AuraTooltipHelper:CreateAuraTooltip("player", 1)
/run print(t and "✅ Tooltip created" or "❌ Failed")

-- Check if Forbidden
/run print(GameTooltip:IsForbidden() and "Forbidden (fallback)" or "Not forbidden (LibQTip works)")
```

---

## Files Changed Summary

| File | Changes | Purpose |
|------|---------|---------|
| AuraTooltipHelper.lua | +140 lines (NEW) | LibQTip aura tooltip display |
| AuraTooltipManager.lua | +115 lines (NEW) | Manager + GameTooltip fallback |
| SimpleUnitFrames.lua | ~30 lines modified | Updated AttachAuraTooltipScripts() |
| SimpleUnitFrames.toc | +2 lines | Load order for helper modules |

**Total Changes:** ~285 lines
**Time to Test:** ~10 minutes
