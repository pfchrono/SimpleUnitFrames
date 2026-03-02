# LibQTip-2.0 Quick Reference - SimpleUnitFrames

**Last Updated:** 2026-03-01  
**For:** SimpleUnitFrames Integration

## Quickstart

### 1. Get LibQTip Instance
```lua
local QTip = LibStub("LibQTip-2.0")
```

### 2. Create Tooltip
```lua
-- 3 columns: left, center, right
local tooltip = QTip:AcquireTooltip("UniqueKey", 3, "LEFT", "CENTER", "RIGHT")
```

### 3. Add Content
```lua
tooltip:AddHeadingRow("Name", "Value", "Amount")
tooltip:AddRow("Item 1", "5", "100 gold")
tooltip:AddRow("Item 2", "3", "75 gold")
```

### 4. Show & Position
```lua
tooltip:SmartAnchorTo(anchorFrame)  -- Auto-positions on-screen
tooltip:Show()
```

### 5. Clean Up
```lua
QTip:ReleaseTooltip(tooltip)
-- OR
tooltip:Release()
```

## Complete Example: Frame Stats Tooltip

```lua
local function OnDebugButtonEnter(button)
    local QTip = LibStub("LibQTip-2.0")
    
    -- Create tooltip
    local tooltip = QTip:AcquireTooltip("SUF_FrameStats", 4, "LEFT", "CENTER", "CENTER", "CENTER")
    
    -- Configure appearance
    tooltip:SetDefaultFont(GameFontNormal)
    tooltip:SetDefaultHeadingFont(GameFontNormalBold)
    tooltip:SetCellMarginH(3)
    tooltip:SetCellMarginV(2)
    
    -- Add content
    tooltip:AddHeadingRow("Frame", "Health", "Power", "Updates")
    
    local addon = LibStub("AceAddon-3.0"):GetAddon("SimpleUnitFrames")
    for _, frame in ipairs(addon.frames) do
        tooltip:AddRow(
            frame.sufUnitType or "Unknown",
            "100%",
            "95 mana",
            "1.2ms"
        )
    end
    
    -- Position and show
    tooltip:SmartAnchorTo(button)
    tooltip:Show()
    
    -- Store reference for cleanup
    button.__activeTooltip = tooltip
end

local function OnDebugButtonLeave(button)
    if button.__activeTooltip then
        LibStub("LibQTip-2.0"):ReleaseTooltip(button.__activeTooltip)
        button.__activeTooltip = nil
    end
end

myButton:SetScript("OnEnter", OnDebugButtonEnter)
myButton:SetScript("OnLeave", OnDebugButtonLeave)
```

## Common Methods

### Content Methods
| Method | Example | Purpose |
|--------|---------|---------|
| `AddRow()` | `tooltip:AddRow("A", "B", "C")` | Add standard row |
| `AddHeadingRow()` | `tooltip:AddHeadingRow("Header1", "Header2")` | Add header row |
| `AddSeparator()` | `tooltip:AddSeparator(1, 1, 1, 1)` | Add divider line |
| `Clear()` | `tooltip:Clear()` | Remove all rows (keep columns) |

### Configuration Methods
| Method | Example | Purpose |
|--------|---------|---------|
| `SetColumnLayout()` | `tooltip:SetColumnLayout(3, "LEFT", "CENTER")` | Define columns |
| `SetDefaultFont()` | `tooltip:SetDefaultFont(GameFontNormal)` | Set row font |
| `SetDefaultHeadingFont()` | `tooltip:SetDefaultHeadingFont(GameFontNormalBold)` | Set header font |
| `SetCellMarginH()` | `tooltip:SetCellMarginH(2)` | Horizontal cell padding |
| `SetCellMarginV()` | `tooltip:SetCellMarginV(1)` | Vertical cell padding |
| `SetMaxHeight()` | `tooltip:SetMaxHeight(400)` | Enable scrolling |
| `SetScrollStep()` | `tooltip:SetScrollStep(3)` | Scroll amount |

### Display Methods
| Method | Example | Purpose |
|--------|---------|---------|
| `SmartAnchorTo()` | `tooltip:SmartAnchorTo(frame)` | Auto-position on-screen |
| `SetAutoHideDelay()` | `tooltip:SetAutoHideDelay(0.5)` | Hide after mouse leave |
| `Show()` | `tooltip:Show()` | Display tooltip |
| `Hide()` | `tooltip:Hide()` | Hide tooltip |

### Query Methods
| Method | Example | Purpose |
|--------|---------|---------|
| `GetColumnCount()` | `local count = tooltip:GetColumnCount()` | Number of columns |
| `GetRowCount()` | `local count = tooltip:GetRowCount()` | Number of rows |
| `GetRow()` | `local row = tooltip:GetRow(1)` | Get row by index |
| `GetColumn()` | `local col = tooltip:GetColumn(1)` | Get column by index |
| `Release()` | `tooltip:Release()` | Release tooltip |

### Library Methods
| Method | Example | Purpose |
|--------|---------|---------|
| `AcquireTooltip()` | `QTip:AcquireTooltip("Key", 3)` | Create/get tooltip |
| `ReleaseTooltip()` | `QTip:ReleaseTooltip(tooltip)` | Release tooltip |
| `IsAcquiredTooltip()` | `QTip:IsAcquiredTooltip("Key")` | Check if acquired |
| `TooltipPairs()` | `for k, t in QTip:TooltipPairs()` | Iterate tooltips |

## Column Justifications

```lua
"LEFT"      -- Align text to left
"CENTER"    -- Align text to center
"RIGHT"     -- Align text to right
```

## Fonts Available

```lua
GameFontNormal              -- Regular UI font
GameFontNormalBold          -- Bold UI font
GameFontSmall               -- Smaller UI font
GameFontHighlight           -- Highlighted font
GameTooltipText             -- Tooltip default font
WorldMapTextFont            -- Map font
```

## Architecture Hints

### When to Use LibQTip Instead of GameTooltip
| Scenario | GameTooltip | LibQTip |
|----------|-------------|---------|
| Single-column info | ✅ | ✅ |
| Multi-column layout | ❌ | **✅** |
| Large datasets | ❌ (no scroll) | **✅** |
| Custom styling | ⚠️ Limited | **✅** |
| Performance tooltips | ❌ | **✅** |
| Debug display | ❌ | **✅** |
| Aura info | ✅ | ⚠️ (need fallback) |

### When to Keep GameTooltip
- Standard unit auras (WoW's builtin format)
- Item links with quality colors
- Spell descriptions (formatted by WoW)
- Compatibility with unknown addons

### Hybrid Approach (Recommended for Phase 3)
```lua
-- Try LibQTip first, fallback to GameTooltip
local function ShowAuraInfo(widget, unit, auraInstanceID)
    if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then
        -- Use GameTooltip fallback (instance restriction)
        GameTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)
        GameTooltip_SetDefaultAnchor(GameTooltip, widget)
    else
        -- Use LibQTip for better display
        local QTip = LibStub("LibQTip-2.0")
        local tooltip = QTip:AcquireTooltip("SUF_Aura", 2)
        -- ... build tooltip ...
        tooltip:SmartAnchorTo(widget)
    end
end
```

## Memory Management

### Proper Cleanup Pattern
```lua
-- ❌ WRONG: Leaves tooltip in memory
local function OnEnter(button)
    local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("Key", 2)
    tooltip:AddRow("A", "B")
    tooltip:SmartAnchorTo(button)
    tooltip:Show()
    -- FORGOT TO RELEASE!
end

-- ✅ CORRECT: Cleans up on leave
local function OnEnter(button)
    local tooltip = LibStub("LibQTip-2.0"):AcquireTooltip("Key", 2)
    tooltip:AddRow("A", "B")
    tooltip:SmartAnchorTo(button)
    tooltip:Show()
    button.__tooltip = tooltip  -- Store reference
end

local function OnLeave(button)
    if button.__tooltip then
        LibStub("LibQTip-2.0"):ReleaseTooltip(button.__tooltip)
        button.__tooltip = nil
    end
end

button:SetScript("OnEnter", OnEnter)
button:SetScript("OnLeave", OnLeave)
```

## Common Patterns

### Pattern: Stats Tooltip
```lua
local tooltip = QTip:AcquireTooltip("stats", 2, "LEFT", "RIGHT")
tooltip:AddHeadingRow("Stat", "Value")
tooltip:AddRow("DPS", "1,234")
tooltip:AddRow("Crit", "25%")
tooltip:AddRow("Haste", "15%")
```

### Pattern: List with Scroll
```lua
local tooltip = QTip:AcquireTooltip("list", 1)
tooltip:SetMaxHeight(300)  -- Enable scrolling
tooltip:SetScrollStep(5)   -- 5 rows per scroll

for i = 1, 50 do
    tooltip:AddRow("Item " .. i)
end
```

### Pattern: Color-Coded Rows
```lua
local row = tooltip:AddRow("Health", "100%")
row:SetBackdropColor(0, 1, 0, 0.5)  -- Green

local row = tooltip:AddRow("Mana", "50%")
row:SetBackdropColor(0, 0.5, 1, 0.5)  -- Blue
```

### Pattern: Dynamic Updates
```lua
local function UpdateTooltip()
    if tooltip and QTip:IsAcquiredTooltip(tooltip.Key) then
        tooltip:Clear()
        
        -- Rebuild with fresh data
        tooltip:AddHeadingRow("Name", "Value")
        tooltip:AddRow("FPS", GetFramerate())
        tooltip:AddRow("Ping", select(3, GetNetStats()))
        
        tooltip:UpdateLayout()  -- Recalculate size
    end
end

-- Update every 0.1 seconds
C_Timer.NewTicker(0.1, UpdateTooltip)
```

## Troubleshooting

### Tooltip not showing
```lua
-- Check:
1. tooltip:Show() was called
2. Anchor frame is visible
3. Tooltip has rows added
4. SmartAnchorTo() worked (try manual SetPoint)
```

### Tooltip stays visible
```lua
-- Always release in OnLeave:
button:SetScript("OnLeave", function(self)
    if self.__tooltip then
        QTip:ReleaseTooltip(self.__tooltip)
        self.__tooltip = nil
    end
end)
```

### Memory leak
```lua
-- Ensure cleanup:
-- ✅ Store reference: button.__tooltip = tooltip
-- ✅ Release in OnLeave: QTip:ReleaseTooltip(button.__tooltip)
-- ✅ Set to nil: button.__tooltip = nil
```

### Wrong text alignment
```lua
-- Specify justification in SetColumnLayout:
tooltip:SetColumnLayout(2, "LEFT", "RIGHT")
--                            ^      ^
--                            |      |-- Right-align column 2
--                            |-- Left-align column 1
```

## Integration Files

### Files to Create
- `Modules/UI/LibQTipHelper.lua` - Helper functions
- `docs/LIBQTIP_INTEGRATION_PLAN.md` - Strategy (done)

### Files to Modify
- `SimpleUnitFrames.lua` - Aura tooltip integration (Phase 3)
- `Modules/UI/DebugWindow.lua` - Frame stats display (Phase 1)
- `Modules/UI/OptionsWindow.lua` - Rich tooltips for options (Phase 2)

### Files to Reference
- `Libraries/LibQTip-2.0/LibQTip-2.0/QTip.lua` - Main API
- `Libraries/LibQTip-2.0/LibQTip-2.0/Components/Tooltip.lua` - Tooltip methods
- `Libraries/LibQTip-2.0/README.md` - Full documentation

## Next Steps

1. **Phase 1:** Create LibQTipHelper.lua with basic frame stats tooltip
2. **Phase 2:** Integrate with DebugWindow for performance metrics
3. **Phase 3:** Enhanced aura tooltip with GameTooltip fallback
4. **Phase 4:** Optional frame info tooltips

See [LIBQTIP_INTEGRATION_PLAN.md](LIBQTIP_INTEGRATION_PLAN.md) for full strategy.
