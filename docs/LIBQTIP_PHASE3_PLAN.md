# LibQTip Phase 3: Enhanced Aura Tooltips

**Date:** 2026-03-01  
**Status:** Planning → Implementation  
**Effort Estimate:** 30 minutes  
**Dependencies:** Phase 1 (✅ Complete), Phase 2 (✅ Complete), C_UnitAuras API

---

## Overview

Phase 3 enhances the in-game aura tooltips displayed when hovering over buff/debuff buttons. Instead of relying solely on GameTooltip (which has limited functionality in instances), we'll use LibQTip to create clean, custom 2-column tooltips showing:
- Aura name and type
- Stack count (if applicable)
- Duration (if timed)
- Dispel type (if applicable)
- Aura description text

### Current State
```lua
GameTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)
-- Displays generic Blizzard tooltip format
-- Limited customization in instances (Forbidden zones)
```

### Target State
```lua
-- Custom LibQTip format:
┌──────────────────────────────┐
│ Aura Name                    │
├──────────────────────────────┤
│ Type: Buff/Debuff            │
│ Stacks: 3                    │
│ Duration: 5min 23s           │
│ Dispel: Magic                │
├──────────────────────────────┤
│ Absorbs incoming damage.     │
└──────────────────────────────┘
```

---

## Implementation Plan

### Step 1: Create AuraTooltipHelper.lua (NEW MODULE)
**File:** `Modules/UI/AuraTooltipHelper.lua` (~180 lines)

Purpose: Query C_UnitAuras data and format into LibQTip tooltip

#### Functions:
```lua
-- Get aura data by aura instance ID
function AuraTooltipHelper:GetAuraData(unit, auraInstanceID)
    -- Returns: { name, type, stacks, duration, expirationTime, dispelName, ... }
end

-- Create enhanced aura tooltip
function AuraTooltipHelper:CreateAuraTooltip(unit, auraInstanceID)
    -- Creates 1-column LibQTip tooltip with formatted aura details
    -- Returns: tooltip object or nil
end

-- Get formatted duration string
local function FormatDuration(duration, expirationTime)
    if not duration or duration == 0 then return "Permanent" end
    if expirationTime then
        return SecondsToTime(expirationTime - GetTime())
    end
    return SecondsToTime(duration)
end

-- Get display type (Buff vs Debuff)
local function GetAuraTypeText(auraType)
    if auraType == "BUFF" then return "|cFF00FF00Buff|r" end
    if auraType == "DEBUFF" then return "|cFFFF0000Debuff|r" end
    return auraType or "Unknown"
end
```

#### Implementation Details:
```lua
local AuraTooltipHelper = {}
addon.AuraTooltipHelper = AuraTooltipHelper

function AuraTooltipHelper:CreateAuraTooltip(unit, auraInstanceID)
    if not unit or not auraInstanceID then
        return nil
    end

    local QTip = LibStub:GetLibrary("LibQTip-2.0")
    if not QTip then
        return nil
    end

    -- Get aura data
    local auraData
    if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
    end

    if not auraData then
        return nil
    end

    -- Create 2-column tooltip for aura details
    local tooltip = QTip:AcquireTooltip("SUF_AuraTooltip_" .. unit .. "_" .. auraInstanceID, 2, "LEFT", "LEFT")
    if not tooltip then
        return nil
    end

    -- Configure appearance
    tooltip:SetDefaultFont("GameFontNormalSmall")
    tooltip:SetDefaultHeadingFont("GameFontNormalSmall")
    tooltip:SetCellMarginH(3)
    tooltip:SetCellMarginV(2)

    -- Add aura name as header
    tooltip:AddHeadingRow(auraData.name or "Unknown Aura", "")

    -- Add aura details
    if auraData.dispelName then
        tooltip:AddRow("Type:", auraData.dispelName)
    end

    if auraData.applications and auraData.applications > 1 then
        tooltip:AddRow("Stacks:", tostring(auraData.applications))
    end

    if auraData.duration and auraData.duration > 0 then
        local durationStr = FormatDuration(auraData.duration, auraData.expirationTime)
        tooltip:AddRow("Duration:", durationStr)
    elseif auraData.duration == 0 then
        tooltip:AddRow("Duration:", "Permanent")
    end

    if auraData.isBuff ~= nil then
        local typeStr = auraData.isBuff and "|cFF00FF00Buff|r" or "|cFFFF0000Debuff|r"
        tooltip:AddRow("Type:", typeStr)
    end

    return tooltip
end

local function FormatDuration(duration, expirationTime)
    if not duration or duration == 0 then return "Permanent" end
    if expirationTime then
        local remaining = expirationTime - GetTime()
        if remaining > 0 then
            return SecondsToTime(remaining)
        end
    end
    return SecondsToTime(duration)
end
```

### Step 2: Create AuraTooltipManager.lua (WRAPPER)
**File:** `Modules/UI/AuraTooltipManager.lua` (~150 lines)

Purpose: Integrate with existing aura button scripts in SimpleUnitFrames.lua

#### Functions:
```lua
-- Global state for current tooltip
local currentAuraTooltip = nil
local currentAuraUnit = nil
local currentAuraInstanceID = nil

-- Show LibQTip aura tooltip or fallback to GameTooltip
function AuraTooltipManager:ShowAuraTooltip(widget, anchorType, offsetX, offsetY)
    if not widget or not widget.auraInstanceID then
        return false
    end

    local unit = widget:GetParent().__owner and widget:GetParent().__owner.unit
    if not unit then
        return false
    end

    -- Try LibQTip first
    if addon.AuraTooltipHelper then
        local tooltip
        pcall(function()
            tooltip = addon.AuraTooltipHelper:CreateAuraTooltip(unit, widget.auraInstanceID)
        end)

        if tooltip then
            tooltip:SmartAnchorTo(widget)
            tooltip:Show()
            currentAuraTooltip = tooltip
            currentAuraUnit = unit
            currentAuraInstanceID = widget.auraInstanceID
            return true
        end
    end

    -- Fallback to GameTooltip (always works)
    return self:ShowGameTooltip(widget, anchorType, offsetX, offsetY)
end

-- Fallback to GameTooltip
function AuraTooltipManager:ShowGameTooltip(widget, anchorType, offsetX, offsetY)
    if GameTooltip and GameTooltip.IsForbidden and not GameTooltip:IsForbidden() then
        local unit = widget:GetParent().__owner and widget:GetParent().__owner.unit
        if unit and widget.auraInstanceID then
            GameTooltip:SetOwner(widget, anchorType, offsetX, offsetY)
            GameTooltip:SetUnitAuraByAuraInstanceID(unit, widget.auraInstanceID)
            return true
        end
    end
    return false
end

-- Hide aura tooltip
function AuraTooltipManager:HideAuraTooltip()
    if currentAuraTooltip then
        local QTip = LibStub:GetLibrary("LibQTip-2.0")
        if QTip then
            QTip:ReleaseTooltip(currentAuraTooltip)
        end
        currentAuraTooltip = nil
    end

    if GameTooltip and GameTooltip.IsForbidden and not GameTooltip:IsForbidden() then
        GameTooltip:Hide()
    end
end
```

### Step 3: Update AttachAuraTooltipScripts() in SimpleUnitFrames.lua
**File:** `SimpleUnitFrames.lua` (~20 lines modified)

Modify existing AttachAuraTooltipScripts function to use AuraTooltipManager:

```lua
local function AttachAuraTooltipScripts(button)
	button.UpdateTooltip = function(widget)
		-- Now handled by AuraTooltipManager
	end
	button:SetScript("OnEnter", function(widget)
		if widget:IsVisible() and addon.AuraTooltipManager then
			local parent = widget:GetParent()
			local anchorType = (parent and parent.tooltipAnchor) or "ANCHOR_BOTTOMRIGHT"
			local offsetX = (parent and parent.tooltipOffsetX) or 0
			local offsetY = (parent and parent.tooltipOffsetY) or 0
			addon.AuraTooltipManager:ShowAuraTooltip(widget, anchorType, offsetX, offsetY)
		end
	end)
	button:SetScript("OnLeave", function()
		if addon.AuraTooltipManager then
			addon.AuraTooltipManager:HideAuraTooltip()
		end
	end)
end
```

### Step 4: Update SimpleUnitFrames.toc
**File:** `SimpleUnitFrames.toc` (+2 lines)

Add load order:
```
Modules/UI/PerformanceMetricsHelper.lua
Modules/UI/AuraTooltipHelper.lua         ← NEW
Modules/UI/AuraTooltipManager.lua        ← NEW
Modules/UI/DebugWindow.lua
```

Both load BEFORE SimpleUnitFrames.lua references them, ensuring helpers available.

---

## Implementation Checklist

### Code Changes
- [ ] Create `Modules/UI/AuraTooltipHelper.lua` (180 lines)
  - [ ] Module initialization and addon attachment
  - [ ] `CreateAuraTooltip(unit, auraInstanceID)` function
  - [ ] C_UnitAuras data querying
  - [ ] Duration formatting with expirationTime
  - [ ] 2-column tooltip layout
  - [ ] Error handling for missing aura data

- [ ] Create `Modules/UI/AuraTooltipManager.lua` (150 lines)
  - [ ] Module initialization
  - [ ] `ShowAuraTooltip()` with LibQTip + GameTooltip fallback
  - [ ] `HideAuraTooltip()` cleanup
  - [ ] Forbidden() zone safety checks
  - [ ] Tooltip state tracking (currentAuraTooltip, etc.)

- [ ] Modify `SimpleUnitFrames.lua` (20 lines)
  - [ ] Update AttachAuraTooltipScripts to call AuraTooltipManager
  - [ ] Replace GameTooltip direct calls with manager wrapper
  - [ ] Maintain backward compatibility with GameTooltip fallback

- [ ] Update `SimpleUnitFrames.toc` (2 lines)
  - [ ] Add AuraTooltipHelper.lua to load order
  - [ ] Add AuraTooltipManager.lua to load order (before SimpleUnitFrames.lua)

### Testing
- [ ] **Normal Zones:** LibQTip aura tooltip displays correctly
- [ ] **Dungeon/Raid:** Fallback to GameTooltip when Forbidden
- [ ] **Tooltip Display:** Shows: Name, Type, Stacks (if >1), Duration, Dispel Type
- [ ] **Tooltip Cleanup:** Disappears on mouse leave, no memory leaks
- [ ] **Backward Compat:** Still works if LibQTip.AuraTooltipHelper missing
- [ ] **Permanent Auras:** Shows "Permanent" for 0-duration auras
- [ ] **Steak Count:** Only shows stacks if >1
- [ ] **Color Coding:** Buff = green, Debuff = red

### Documentation
- [ ] Update [TODO.md](../TODO.md) with Phase 3 completion
- [ ] Update [WORK_SUMMARY.md](../WORK_SUMMARY.md) with Phase 3 entry
- [ ] Create Phase 3 quicktest guide

---

## Expected Result

### Before (GameTooltip)
```
[Generic Blizzard tooltip, limited in instances]
Buff Name
============
[Standard tooltip info only]
```

### After (LibQTip + Fallback)
```
╔════════════════════════╗ Normal Zones
║ Vigilance             ║  (LibQTip - custom format)
╠════════════════════════╣
║ Type: Buff            ║
║ Duration: 2min 15s    ║
║ Dispel: Magic         ║
╚════════════════════════╝

[GameTooltip fallback]    Instances/Forbidden
╔════════════════════════╗  (automatic fallback)
║ Vigilance             ║
╠════════════════════════╣
║ [Standard info]       ║
╚════════════════════════╝
```

---

## Safety & Compatibility

### Forbidden Zone Handling
- Checks `GameTooltip:IsForbidden()` before attempting LibQTip
- GameTooltip fallback always available
- Zero errors in restricted areas

### API Compatibility
- Uses `C_UnitAuras.GetAuraDataByAuraInstanceID()` (available WoW 10.0+)
- Backward falls back to GameTooltip if helper unavailable
- Tests: `if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then`

### Performance
- Tooltip created on hover (not every frame)
- Pooled by LibQTip (reused for multiple auras)
- C_UnitAuras data already cached by WoW
- **Impact:** Negligible (<1ms per aura hover)

---

## Known Limitations

1. **Instance Restrictions:** GameTooltip is Forbidden in some instances
   - Workaround: Graceful fallback to GameTooltip (always works)
   - User never sees blank/error tooltip

2. **Custom Styling:** Instance tooltips limited to standard format
   - Workaround: Acceptable—GameTooltip still readable

3. **Secret Values:** Aura data not secret in instances (safe to read)
   - No Lua arithmetic needed on instance data

---

## Rollback Plan

If issues arise:
1. Revert AttachAuraTooltipScripts() to use GameTooltip directly
2. Remove AuraTooltipHelper.lua and AuraTooltipManager.lua from load order
3. Delete both helper files
4. Restore SimpleUnitFrames.lua to pre-Phase 3 state
5. `/reload` to verify rollback

**Clean rollback:** Changes isolated to aura tooltips, no core systems affected.

---

## Next Steps After Phase 3

1. **Commit Phases 1-3:** All LibQTip features complete
   ```bash
   git commit -m "LibQTip Phases 1-3: Tooltips for Frame Stats, Performance Metrics, & Auras"
   ```

2. **Tag Release:** Create release tag
   ```bash
   git tag -a v1.24.0 -m "LibQTip integration complete"
   ```

3. **Optional Phase 4:** Frame Info Tooltips (deferred, not required)

4. **Release:** Deploy to CurseForge/GitHub

---

## Questions?

Refer to:
- [LIBQTIP_INTEGRATION_PLAN.md](LIBQTIP_INTEGRATION_PLAN.md) — Full context and design
- [LIBQTIP_QUICK_REFERENCE.md](LIBQTIP_QUICK_REFERENCE.md) — LibQTip API reference
- C_UnitAuras documentation: `wow-ui-source/Interface/AddOns/Blizzard_*/UnitAuras.lua`
