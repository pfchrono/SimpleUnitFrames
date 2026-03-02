# LibQTip-2.0 Integration Plan - SimpleUnitFrames

**Status:** Research & Planning  
**Date Created:** 2026-03-01  
**Priority:** MEDIUM (UI Enhancement)  
**Effort Estimate:** 2-4 hours (basic integration + sample implementation)

## Executive Summary

LibQTip-2.0 is a multi-column, highly-configurable tooltip library for WoW addons. This document outlines integration opportunities in SimpleUnitFrames to enhance UI feedback and debug information display using LibQTip's superior multi-column capabilities over GameTooltip.

**Key Benefits:**
- Multi-column layouts (GameTooltip is single-column)
- Custom cell providers for rich content
- Built-in scrolling for large datasets
- Better visual control (colors, fonts, spacing)
- Efficient pooling and memory management

## Current Tooltip Usage in SimpleUnitFrames

### Existing Patterns
1. **Aura Tooltips** (`SimpleUnitFrames.lua:7057-7081`)
   - Uses `GameTooltip:SetUnitAuraByAuraInstanceID()`
   - Displayed on hover of aura buttons
   - Existing implementation: standard WoW tooltip

2. **Unit Frame Tooltips** (`SimpleUnitFrames.lua:7744-7768`)
   - `SUF_UpdateTooltip()` - Shows unit info
   - Uses `GameTooltip_SetDefaultAnchor()`
   - Standard tooltip for player/target/party frames

3. **Configuration**
   - `Auras.tooltipAnchor` - Anchor point
   - `tooltipOffsetX/Y` - Positioning
   - Configured in defaults (`SimpleUnitFrames.lua:5524-5526`)

### Pain Points Addressed by LibQTip
- ❌ GameTooltip is single-column (limited info density)
- ❌ No built-in scrolling for large datasets
- ❌ Limited visual customization
- ❌ No easy multi-row/column layouts
- ✅ LibQTip: Solves all of above

## Integration Points (Priority Order)

### Phase 1: Debug Window Enhancements (HIGHEST VALUE)
**File:** `Modules/UI/DebugWindow.lua`  
**Use Case:** Display frame performance metrics in multi-column format

**Current State:**
- Text-based debug output
- Single-column layout
- Limited information density

**Proposed LibQTip Usage:**
```lua
-- Example: Frame performance tooltip
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("SUF_DebugFrameStats", 4, "LEFT", "CENTER", "CENTER", "CENTER")
tooltip:AddHeadingRow("Frame", "Health", "Power", "Time (ms)")
tooltip:AddRow("Player", "100%", "95 mana", "2.5")
tooltip:AddRow("Target", "78%", "45 mana", "1.8")
tooltip:AddRow("Pet", "92%", "--", "0.3")
tooltip:SmartAnchorTo(debugWindow)
tooltip:Show()
```

**Benefits:**
- 4-column layout shows frame name, health, power, update time simultaneously
- Easier to scan performance metrics
- Scrollable for many frames
- Color-coded rows possible

**Effort:** 45 minutes
**Files Changed:** DebugWindow.lua (40 lines added/modified)

---

### Phase 2: Performance Dashboard Stats (HIGH VALUE)
**File:** `Modules/UI/DebugWindow.lua` or new `PerformanceTooltip.lua`  
**Use Case:** Display EventCoalescer and DirtyFlagManager statistics

**Current State:**
- Stats printed to chat via `/run` commands
- Not easily viewable in UI

**Proposed LibQTip Usage:**
```lua
-- Example: Event coalescing stats
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("SUF_EventCoalescingStats", 5)
tooltip:AddHeadingRow("Event Type", "Total", "Coalesced", "Efficiency %", "Avg Batch")
tooltip:AddRow("UNIT_HEALTH", "4521", "4250", "94%", "3.2")
tooltip:AddRow("UNIT_AURA", "1823", "1647", "90%", "2.8")
tooltip:AddSeparator()
tooltip:AddRow("TOTAL", "22847", "21234", "92.9%", "3.0")
tooltip:SmartAnchorTo(performanceButton)
```

**Benefits:**
- Real-time stats visibility
- Color-coded efficiency percentages
- Scrollable datasets (10+ events)
- Comparison at a glance

**Effort:** 50 minutes
**Files Changed:** DebugWindow.lua or new PerformanceTooltip.lua (60 lines)

---

### Phase 3: Enhanced Aura Tooltips (MEDIUM VALUE)
**File:** `SimpleUnitFrames.lua` (AttachAuraTooltipScripts function)  
**Use Case:** Show aura details + stacking info in multi-column format

**Current State:**
```lua
GameTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)
```

**Proposed LibQTip Alternative:**
```lua
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("SUF_AuraTooltip_" .. unit, 2, "LEFT", "CENTER")
local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)

tooltip:AddHeadingRow("Aura Info", "")
tooltip:AddRow("Name", auraData.name)
tooltip:AddRow("Type", auraData.dispelName)
tooltip:AddRow("Stacks", auraData.applications or "—")
if auraData.duration and auraData.duration > 0 then
    tooltip:AddRow("Duration", SecondsToTime(auraData.duration))
end
tooltip:SmartAnchorTo(auraButton)
```

**Benefits:**
- 2-column format (label + value) cleaner than default tooltip
- Shows stack count clearly
- Custom formatting per field
- Consistent styling across all auras

**Considerations:**
- Must maintain backward-compatible with GameTooltip fallback
- Test with Forbidden() restrictions in instances
- Performance: Pre-cache aura data to avoid repeated API calls

**Effort:** 30 minutes (simple 2-column layout)
**Files Changed:** SimpleUnitFrames.lua (30 lines added/modified)

---

### Phase 4: Frame Info Tooltips (OPTIONAL)
**File:** `SimpleUnitFrames.lua` (SUF_UpdateTooltip function)  
**Use Case:** Show multi-column frame metadata on hover

**Proposed LibQTip Usage:**
```lua
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("SUF_FrameTooltip_" .. frame:GetName(), 2)
tooltip:AddHeadingRow("Property", "Value")
tooltip:AddRow("Unit", frame.sufUnitType or "—")
tooltip:AddRow("Position", format("%.0f, %.0f", frame:GetLeft(), frame:GetTop()))
tooltip:AddRow("Size", format("%.0f×%.0f", frame:GetWidth(), frame:GetHeight()))
tooltip:AddRow("Visibility", frame:IsVisible() and "Visible" or "Hidden")
tooltip:AddRow("Opacity", format("%.1f%%", frame:GetAlpha() * 100))
tooltip:SmartAnchorTo(frame)
```

**Benefits:**
- Consistent layout for all frame diagnostics
- Easy to extend with new properties
- Scrollable for complex frames

**Effort:** 20 minutes
**Files Changed:** SimpleUnitFrames.lua (15 lines added/modified)

---

## LibQTip-2.0 API Reference

### Core Methods

#### Acquire/Release
```lua
-- Acquire a tooltip with 3 columns
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("MyKey", 3, "LEFT", "CENTER", "RIGHT")

-- Release when done
LibStub("LibQTip-2.0"):ReleaseTooltip(tooltip)
-- OR
tooltip:Release()
```

#### Adding Content
```lua
-- Set column layout (call before adding rows)
tooltip:SetColumnLayout(4, "LEFT", "CENTER", "LEFT", "RIGHT")

-- Add rows
tooltip:AddRow("Name", "Value1", "Value2", "Value3")
tooltip:AddHeadingRow("Header1", "Header2", "Header3")
tooltip:AddSeparator(1, 1, 1, 1)  -- height, r, g, b

-- Clear content
tooltip:Clear()  -- Clears rows, keeps columns
```

#### Positioning
```lua
-- Smart anchor (auto-positions to stay on-screen)
tooltip:SmartAnchorTo(anchorFrame)

-- Manual positioning
tooltip:ClearAllPoints()
tooltip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
```

#### Customization
```lua
-- Fonts
tooltip:SetDefaultFont(GameFontNormal)
tooltip:SetDefaultHeadingFont(GameFontNormalBold)

-- Cell spacing
tooltip:SetCellMarginH(2)
tooltip:SetCellMarginV(1)

-- Highlight texture
tooltip:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

-- Auto-hide
tooltip:SetAutoHideDelay(0.5)  -- Hide after 0.5 sec

-- Max height (with scrollbar)
tooltip:SetMaxHeight(400)
```

#### Scripting
```lua
-- Add hover script
tooltip:SetScript("OnEnter", function(self) print("Hovering") end)

-- Scroll step
tooltip:SetScrollStep(3)
```

#### Querying
```lua
tooltip:GetColumnCount()
tooltip:GetRowCount()
tooltip:GetRow(1)
tooltip:GetColumn(1)
```

### Advanced: Custom Cell Providers

For complex content (e.g., embedded frames, textures):

```lua
-- Create custom cell provider based on default
local result = LibStub("LibQTip-2.0"):CreateCellProvider()
local customProvider = result.newCellProvider
local customCellProto = result.newCellPrototype

-- Register it
LibStub("LibQTip-2.0"):RegisterCellProvider("MyCustomCells", customProvider)

-- Use in tooltip
tooltip:SetDefaultCellProvider(customProvider)
```

**Not needed for Phase 1-2** (default provider sufficient)

## Implementation Strategy

### Step 1: Verify LibQTip Loading
- ✅ LibQTip-2.0 already embedded in Libraries/
- ✅ Dependencies (LibStub, CallbackHandler-1.0) available
- Verify TOC includes or ensure it's loaded

### Step 2: Create LibQTip Wrapper Module
**File:** `Modules/UI/LibQTipHelper.lua` (NEW)

Purpose: Centralized LibQTip initialization and common patterns

```lua
local addon = LibStub("AceAddon-3.0"):GetAddon("SimpleUnitFrames")

local LibQTipHelper = {}

-- Get LibQTip instance
local function GetQTip()
    return LibStub("LibQTip-2.0")
end

-- Create a debug stats tooltip
function LibQTipHelper:CreateFrameStatsTooltip(frames)
    local QTip = GetQTip()
    local tooltip = QTip:AcquireTooltip("SUF_FrameStats", 4, "LEFT", "CENTER", "CENTER", "CENTER")
    
    tooltip:SetDefaultFont(GameFontNormal)
    tooltip:SetDefaultHeadingFont(GameFontNormalBold)
    tooltip:SetCellMarginH(2)
    tooltip:SetCellMarginV(1)
    
    tooltip:AddHeadingRow("Frame", "Health %", "Power", "Update (ms)")
    
    for _, frame in ipairs(frames) do
        tooltip:AddRow(
            frame.sufUnitType or "Unknown",
            format("%.0f%%", (frame.Health and frame.Health.Value and frame.Health.Value >= 0) and frame.Health.Value * 100 or 0),
            frame.Power and format("%.0f", frame.Power.Value or 0) or "—",
            "0.0"  -- TODO: Get actual update time if available
        )
    end
    
    return tooltip
end

-- Add more helper functions as needed

return LibQTipHelper
```

**Effort:** 30 minutes

### Step 3: Integrate with Debug Window
**File:** `Modules/UI/DebugWindow.lua`

```lua
-- Add LibQTip import
local LibQTip = LibStub("LibQTip-2.0")
local LibQTipHelper = addon:GetModule("UI"):GetLibQTipHelper()

-- In debug panel creation
local frameStatsButton = CreateFrame("Button", nil, debugPanel)
frameStatsButton:SetText("Frame Stats")
frameStatsButton:SetScript("OnEnter", function()
    local tooltip = LibQTipHelper:CreateFrameStatsTooltip(addon.frames)
    tooltip:SmartAnchorTo(frameStatsButton)
    tooltip:Show()
end)
frameStatsButton:SetScript("OnLeave", function()
    LibQTip:ReleaseTooltip(...) -- Release all active tooltips
end)
```

**Effort:** 20 minutes

### Step 4: Test and Validate
- ✅ Frame stats tooltip appears on button hover
- ✅ Multi-column layout visible
- ✅ Scrolling works for 20+ frames
- ✅ Auto-positioning works near screen edges
- ✅ Release on hide clears resources
- ✅ Performance impact minimal (<1ms tooltip creation)

**Effort:** 30 minutes

## Phased Implementation Timeline

| Phase | Module | Effort | Risk | Value |
|-------|--------|--------|------|-------|
| 1 | Debug Window (frame stats) | 45m | LOW | HIGH |
| 2 | Performance stats tooltip | 50m | LOW | HIGH |
| 3 | Enhanced aura tooltips | 30m | MEDIUM | MEDIUM |
| 4 | Frame info tooltips | 20m | LOW | OPTIONAL |
| **Total** | | **2-3 hours** | LOW | **GOOD** |

## Risk Assessment

### Low-Risk Areas
- ✅ Debug window enhancements (non-critical UI)
- ✅ Performance tooltips (informational only)
- ✅ Frame info tooltips (hover-based, non-invasive)

### Medium-Risk Areas
- ⚠️ Replacing GameTooltip with LibQTip for auras
  - **Risk:** Forbidden() restrictions in instances
  - **Mitigation:** Provide GameTooltip fallback
  - **Test:** Validate in 5-player dungeon (instances restrict shared APIs)

### Compatibility
- ✅ LibQTip is embedded (no external dependency)
- ✅ Works with WoW 10.0+ (addon targets 12.0.0+)
- ✅ No conflicts with existing GameTooltip usage
- ✅ Safe to have both active simultaneously

## Code Patterns

### Pattern 1: Simple Multi-Column Tooltip
```lua
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("MyKey", 2)
tooltip:AddHeadingRow("Label", "Value")
tooltip:AddRow("Property", "Value1")
tooltip:AddRow("Property", "Value2")
tooltip:SmartAnchorTo(anchorFrame)
tooltip:Show()
```

### Pattern 2: Tooltip with Cleanup
```lua
-- In OnEnter
local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("MyKey", 3)
-- ... add rows ...
tooltip:SmartAnchorTo(frame)
tooltip:Show()
frame.__activeTooltip = tooltip

-- In OnLeave
if frame.__activeTooltip then
    LibStub("LibQTip-2.0"):ReleaseTooltip(frame.__activeTooltip)
    frame.__activeTooltip = nil
end
```

### Pattern 3: Dynamic Data Updates
```lua
-- Store active tooltips for updating
local activeTooltips = {}

function UpdateStats()
    for frame, tooltip in pairs(activeTooltips) do
        if tooltip and LibStub("LibQTip-2.0"):IsAcquiredTooltip(tooltip.Key) then
            tooltip:Clear()
            -- Rebuild with new data
            tooltip:AddRow(...) 
        end
    end
end

-- Hook to refresh events
addon:RegisterMessage("SUF_FrameUpdated", UpdateStats)
```

## Migration Path from GameTooltip

For aura tooltips, maintain backward compatibility:

```lua
local function ShowAuraTooltip(widget, unit, auraInstanceID)
    local useLibQTip = not (GameTooltip.IsForbidden and GameTooltip:IsForbidden())
    
    if useLibQTip then
        -- LibQTip version
        local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("SUF_AuraInfo", 2)
        -- ... build tooltip ...
        tooltip:SmartAnchorTo(widget)
    else
        -- Fallback to GameTooltip
        GameTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)
        GameTooltip_SetDefaultAnchor(GameTooltip, widget)
    end
end
```

## Documentation Updates Needed

### 1. Update copilot-instructions.md
Add to "Project Conventions" section:
```markdown
- **LibQTip-2.0 Integration:**
  - Multi-column tooltips for UI enhancements (debug display, frame stats, performance metrics)
  - Usage: Debug window (frame stats), performance dashboard, aura tooltips
  - Helper module: Modules/UI/LibQTipHelper.lua
  - Patterns: Hover acquistion/release, auto-anchoring, scrollable datasets
  - Backward compatibility: GameTooltip fallback for Forbidden() instances
```

### 2. Create LibQTipHelper.lua documentation
Include usage examples for each helper function

### 3. Add to WORK_SUMMARY.md
Document completion once implemented

## Validation Checklist

- [ ] LibQTip loads without errors
- [ ] Frame stats tooltip appears on debug button hover
- [ ] Multi-column layout displays correctly
- [ ] Scrolling works for 20+ rows
- [ ] Auto-anchoring positions tooltip on-screen
- [ ] Tooltip releases on mouse leave
- [ ] Memory usage stable (no leaks)
- [ ] Performance impact <1ms per tooltip
- [ ] Works in dungeons/raids (Forbidden() handling)
- [ ] No conflicts with GameTooltip usage

## Future Enhancements

1. **Color-Coded Rows** (Phase 3+)
   - Red for low health, yellow for mid, green for full
   - Uses row:SetBackdropColor()

2. **Custom Cell Providers** (Phase 4+)
   - Embedded status bars showing percentages
   - Icon cells for aura types
   - Progress bars for cooldowns

3. **Interactive Cells** (Phase 5+)
   - Click-to-copy statistics
   - Right-click menus
   - Cell-level hover scripts

4. **Persistent Performance Dashboard** (Phase 6+)
   - Docked LibQTip tooltip in corner
   - Real-time stats updates
   - Expandable/collapsible sections

## References

- **LibQTip-2.0 README:** Libraries/LibQTip-2.0/README.md
- **GitHub Wiki:** https://github.com/WoWAddonArchitect/LibQTip-2.0/wiki
- **API Documentation:** Full inline JSDoc annotations in QTip.lua
- **WoW Font Objects:** GameFontNormal, GameFontNormalBold, GameFontSmall

## Summary

LibQTip-2.0 integration is straightforward and low-risk. Phase 1 (debug window) provides immediate UI value. Phases 2-3 extend benefits to performance metrics and aura tooltips. Total effort: 2-3 hours. Recommend starting with Phase 1 as incremental enhancement.
