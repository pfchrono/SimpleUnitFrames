# LibQTip Phase 2: Performance Metrics Tooltip

**Date:** 2026-03-01  
**Status:** Planning → Implementation  
**Effort Estimate:** 50 minutes  
**Dependencies:** Phase 1 (✅ Complete), PerformanceLib addon (must be present)

---

## Overview

Phase 2 extends the LibQTip integration by adding a **Performance Metrics Tooltip** button to the debug window. This displays real-time EventCoalescer and PerformanceLib statistics in a multi-column format.

### Current State
- EventCoalescer stats printed to chat via: `/run SUF.EventCoalescer:PrintStats()`
- Hard to read in-game; requires scrolling chat
- No visual comparison across events
- Stats not immediately visible while debugging

### Target State
- **New Button:** "Perf Stats" in debug window toolbar
- **Hover Tooltip:** 5-column EventCoalescer breakdown
- **Display:**
  | Event Type | Total | Coalesced | Efficiency % | Avg Batch |
  |---|---|---|---|---|
  | UNIT_HEALTH | 4521 | 4250 | 94% | 3.2 |
  | UNIT_AURA | 1823 | 1647 | 90% | 2.8 |
  | ... | ... | ... | ... | ... |
  | **TOTAL** | **22847** | **21234** | **92.9%** | **3.0** |
- **Color Coding:** Efficiency % cells color-coded (green ≥90%, yellow 70-90%, red <70%)

---

## Implementation Plan

### Step 1: Create PerformanceMetricsHelper.lua (NEW MODULE)
**File:** `Modules/UI/PerformanceMetricsHelper.lua` (~150 lines)

Purpose: Query PerformanceLib stats and format into LibQTip tooltip

#### Functions:
```lua
-- Get EventCoalescer stats formatted for tooltip
function PerformanceMetricsHelper:GetEventCoalescerStats()
    -- Returns: { events: [{name, total, coalesced, efficiency, avgBatch}, ...], summary: {...} }
end

-- Create performance stats tooltip
function PerformanceMetricsHelper:CreatePerformanceStatsTooltip()
    -- Creates 5-column LibQTip tooltip with stats
    -- Returns: tooltip object or nil
end

-- Get display color based on efficiency %
local function GetEfficiencyColor(percent)
    if percent >= 90 then return { 0, 1, 0 }       -- Green
    elseif percent >= 70 then return { 1, 1, 0 }   -- Yellow
    else return { 1, 0, 0 } end                     -- Red
end
```

#### Implementation Details:
```lua
local PerformanceMetricsHelper = {}
addon.PerformanceMetricsHelper = PerformanceMetricsHelper

function PerformanceMetricsHelper:CreatePerformanceStatsTooltip()
    local QTip = LibStub:GetLibrary("LibQTip-2.0")
    if not QTip or not addon.performanceLib then
        return nil
    end

    local tooltip = QTip:AcquireTooltip("SUF_PerformanceStats", 5, "LEFT", "CENTER", "CENTER", "CENTER", "CENTER")
    if not tooltip then return nil end

    -- Configure appearance
    tooltip:SetDefaultFont("GameFontNormalSmall")
    tooltip:SetDefaultHeadingFont("GameFontNormalSmall")
    tooltip:SetCellMarginH(3)
    tooltip:SetCellMarginV(2)

    -- Header row
    tooltip:AddHeadingRow("Event Type", "Total", "Coalesced", "Efficiency %", "Avg Batch")

    -- Get EventCoalescer stats
    local eventCoalescer = addon.performanceLib.EventCoalescer
    if not eventCoalescer or not eventCoalescer:GetStats then
        tooltip:AddRow("ERROR", "—", "—", "—", "PerformanceLib not ready")
        return tooltip
    end

    local stats = eventCoalescer:GetStats()
    if not stats then
        tooltip:AddRow("No stats", "—", "—", "—", "Not yet recorded")
        return tooltip
    end

    -- Add rows for each event (sorted by efficiency)
    local rows = {}
    for eventName, eventStats in pairs(stats.byEvent or {}) do
        local efficiency = eventStats.coalesced > 0 
            and math.floor((eventStats.coalesced / eventStats.total) * 100) 
            or 0
        table.insert(rows, {
            name = eventName,
            total = eventStats.total or 0,
            coalesced = eventStats.coalesced or 0,
            efficiency = efficiency,
            avgBatch = eventStats.avgBatch or 0,
        })
    end

    -- Sort by efficiency descending
    table.sort(rows, function(a, b) return a.efficiency > b.efficiency end)

    -- Add rows
    for i, row in ipairs(rows) do
        local efficiencyStr = format("%.0f%%", row.efficiency)
        local effColor = GetEfficiencyColor(row.efficiency)
        
        tooltip:AddRow(
            row.name,
            row.total,
            row.coalesced,
            efficiencyStr,
            format("%.1f", row.avgBatch)
        )
        
        -- Color the efficiency % cell
        if i <= #rows then
            local cellRow = tooltip:GetRowCount()
            tooltip:SetCellTextColor(cellRow, 4, effColor[1], effColor[2], effColor[3])
        end
    end

    -- Separator and totals
    tooltip:AddSeparator()
    local totalCoalesced = stats.totalCoalesced or 0
    local totalEvents = stats.totalEvents or 0
    local totalEfficiency = totalEvents > 0 
        and math.floor((totalCoalesced / totalEvents) * 100) 
        or 0
    
    local totalRow = format("TOTAL: %d events, %.1f%% efficiency", 
        #rows, totalEfficiency)
    
    tooltip:AddRow(
        totalRow,
        totalEvents,
        totalCoalesced,
        format("%.0f%%", totalEfficiency),
        format("%.1f", stats.avgBatchSize or 0)
    )

    return tooltip
end

local function GetEfficiencyColor(percent)
    if percent >= 90 then
        return { 0, 1, 0 }       -- Green
    elseif percent >= 70 then
        return { 1, 1, 0 }       -- Yellow
    else
        return { 1, 0, 0 }       -- Red
    end
end

return PerformanceMetricsHelper
```

### Step 2: Add "Perf Stats" Button to DebugWindow.lua
**File:** `Modules/UI/DebugWindow.lua` (~40 lines)

#### Location:
- After existing "Stats" button (which shows Frame Stats)
- Before end of button bar

#### Code:
```lua
-- Perf Stats button: Show EventCoalescer performance metrics tooltip
local perfStatsBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
perfStatsBtn:SetSize(60, 24)
perfStatsBtn:SetPoint("LEFT", frameStatsBtn, "RIGHT", 8, 0)
perfStatsBtn:SetText("Perf")
perfStatsBtn:SetScript("OnEnter", function(self)
    if addon.PerformanceMetricsHelper and addon.PerformanceMetricsHelper.CreatePerformanceStatsTooltip then
        local tooltip = addon.PerformanceMetricsHelper:CreatePerformanceStatsTooltip()
        if tooltip then
            tooltip:SmartAnchorTo(self)
            tooltip:Show()
            self.__perfStatsTooltip = tooltip
        end
    end
end)
perfStatsBtn:SetScript("OnLeave", function(self)
    if self.__perfStatsTooltip then
        local QTip = LibStub:GetLibrary("LibQTip-2.0")
        if QTip then
            QTip:ReleaseTooltip(self.__perfStatsTooltip)
        end
        self.__perfStatsTooltip = nil
    end
end)
frame.perfStatsBtn = perfStatsBtn
```

### Step 3: Update SimpleUnitFrames.toc
**File:** `SimpleUnitFrames.toc` (+1 line)

Add load order:
```
Modules/UI/DebugWindow.lua
Modules/UI/PerformanceMetricsHelper.lua   ← NEW (before DebugWindow updates)
```

Wait, actually this needs to load BEFORE DebugWindow tries to reference it. Let me reconsider the order:

```
Modules/UI/LibQTipHelper.lua
Modules/UI/PerformanceMetricsHelper.lua   ← NEW
Modules/UI/DebugWindow.lua
```

Both helpers load before DebugWindow, then DebugWindow adds both buttons.

---

## Implementation Checklist

### Code Changes
- [ ] Create `Modules/UI/PerformanceMetricsHelper.lua` (150 lines)
  - [ ] Module initialization and addon attachment
  - [ ] `CreatePerformanceStatsTooltip()` function
  - [ ] `GetEfficiencyColor()` helper
  - [ ] Error handling for missing PerformanceLib
  - [ ] EventCoalescer stats querying
  - [ ] Color-coded efficiency cells
  - [ ] Totals row with summary

- [ ] Modify `Modules/UI/DebugWindow.lua` (40 lines)
  - [ ] Add "Perf Stats" button creation
  - [ ] Position after "Stats" button
  - [ ] OnEnter script creates tooltip
  - [ ] OnLeave script releases tooltip
  - [ ] Store tooltip reference in button

- [ ] Update `SimpleUnitFrames.toc` (1 line)
  - [ ] Add PerformanceMetricsHelper to load order
  - [ ] Ensure loads before DebugWindow.lua

### Testing
- [ ] **No PerformanceLib:** Button shows "PerformanceLib not ready" gracefully
- [ ] **PerformanceLib active:** Tooltip shows event breakdown
- [ ] **Color coding:** Green (≥90%), Yellow (70-90%), Red (<70%)
- [ ] **Tooltip behavior:** Appears on hover, disappears on leave
- [ ] **Memory:** No leaks (tooltip pooled by LibQTip)
- [ ] **UI:** Button fits in toolbar (may need to widen again if needed)

### Documentation
- [ ] Update [TODO.md](../TODO.md) with Phase 2 completion
- [ ] Update [WORK_SUMMARY.md](../WORK_SUMMARY.md) with Phase 2 entry
- [ ] Create Phase 2 quickstart guide

---

## Expected Result

### Debug Window (After Phase 2)
```
[SUF Debug Console]
┌─────────────────────────────────────────────────────────┐
│ Console output...                                       │
├─────────────────────────────────────────────────────────┤
│ [Enabled] [Clear] [Export] [Settings] [Start] [Stop]   │
│ [Analyze] [Stats] [Perf]                               │
└─────────────────────────────────────────────────────────┘
```

### Performance Stats Tooltip (On Hover)
```
╔════════════════╦═══════╦════════════╦═════════════╦════════════╗
║ Event Type     ║ Total ║ Coalesced  ║ Efficiency% ║ Avg Batch  ║
╠════════════════╬═══════╬════════════╬═════════════╬════════════╣
║ UNIT_HEALTH    ║ 4521  ║ 4250       ║ 94% (🟢)   ║ 3.2        ║
║ UNIT_AURA      ║ 1823  ║ 1647       ║ 90% (🟢)   ║ 2.8        ║
║ UNIT_MAXHEALTH ║ 892   ║701         ║ 78% (🟡)   ║ 2.1        ║
║ UNIT_POWER     ║ 3421  ║ 2984       ║ 87% (🟢)   ║ 3.5        ║
╠════════════════╬═══════╬════════════╬═════════════╬════════════╣
║ TOTAL          ║ 22847 ║ 21234      ║ 92.9% (🟢) ║ 3.0        ║
╚════════════════╩═══════╩════════════╩═════════════╩════════════╝
```

---

## Performance Impact

- **Button Creation:** ~0.5ms (one-time at debug window creation)
- **Tooltip Creation:** ~2-5ms (on first hover, cached by LibQTip)
- **Tooltip Display:** Instant (pooled widget reuse)
- **Stats Query:** ~1-3ms (PerformanceLib stats already computed)

**Total Budget Impact:** Negligible (debug feature, only shown on hover)

---

## Known Limitations

1. **PerformanceLib Dependency:** Feature requires PerformanceLib addon to be active
   - Graceful fallback if missing
   - Button still appears, shows "PerformanceLib not ready"

2. **Stats Accuracy:** Stats reflect accumulated data from session start
   - Reset via `/run SUF.EventCoalescer:ResetStats()`
   - No issue for typical 1-2 hour sessions

3. **Color Display:** Terminal/console color support varies
   - Tooltip uses SetCellTextColor() for accuracy
   - Fallback to white if colors unsupported

---

## Rollback Plan

If issues arise:
1. Remove PerformanceMetricsHelper.lua button code from DebugWindow.lua
2. Remove PerformanceMetricsHelper.lua from load order
3. Delete `Modules/UI/PerformanceMetricsHelper.lua` file
4. `/reload` to verify rollback

**Clean rollback:** Changes are isolated, no core systems affected.

---

## Next Steps After Phase 2

1. **Phase 3:** Enhanced Aura Tooltips (optional, 30 min)
2. **Phase 4:** Frame Info Tooltips (optional, 40 min)
3. **Commit & Release:** Create release tag with all LibQTip features

---

## Questions?

Refer to:
- [LIBQTIP_INTEGRATION_PLAN.md](LIBQTIP_INTEGRATION_PLAN.md) — Full context vs other phases
- [LIBQTIP_QUICK_REFERENCE.md](LIBQTIP_QUICK_REFERENCE.md) — LibQTip API quick lookup
- PerformanceLib source: `d:\Games\World of Warcraft\_retail_\Interface\_Working\PerformanceLib\`
