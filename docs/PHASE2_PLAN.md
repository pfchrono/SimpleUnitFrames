# Phase 2 Implementation Plan

**Status:** Ready to begin  
**Phase Duration:** 6-9 hours total  
**Target Completion:** Single session or 2-3 sessions  

---

## Task 2.1: Accent Color System (2-3 hours)

### Objective
Single accent color picker → all UI colors automatically update (background, borders, buttons, accents)

### Current State
- Theme.lua has hardcoded colors (lines 10-100+)
- All colors manually edited in theme table
- No dynamic color derivation
- Accent color: {0.74, 0.58, 0.99} (purple/violet)

### Implementation Strategy

**Step 1: Create Color Derivation Functions**
- File: `Modules/UI/Theme.lua` (new section, ~60 lines)
- Functions needed:
  - `DeriveAccentVariants(baseR, baseG, baseB)` → Returns {base, soft, dark, light} RGBA tables
  - `LerpColor(color1, color2, t)` → Interpolate between two colors
  - `DarkenColor(r, g, b, factor)` → Make color darker
  - `LightenColor(r, g, b, factor)` → Make color lighter
  - `SaturateColor(r, g, b, factor)` → Increase/decrease saturation

**Step 2: Build Accent Color Cache**
- Cache all derived colors on startup
- File: `Modules/UI/Theme.lua` (update `GetAccentColors()` function)
- Invalidate cache on theme change
- Keys: `windowBg`, `windowBorder`, `panelBg`, `panelBorder`, `buttons`, `controls`, etc.

**Step 3: Add Accent Color UI Widget**
- File: `Modules/UI/OptionsV2/Registry.lua` (add to Global/Base section)
- Widget type: Color picker
- Options: 
  - Show preset colors (mint, amber, cool, warm, purple, custom)
  - Label: "Accent Color"
  - Description: "Single color that controls all UI colors"
- Callback: Update cache + refresh UI

**Step 4: Add Theme Options to OptionsWindow**
- File: `Modules/UI/OptionsV2/Registry.lua`
- New section: "Appearance" or "Theme"
- Settings:
  - Accent Color picker
  - [Optional] Brightness adjustment slider

**Step 5: Integrate into Reload Flow**
- File: `SimpleUnitFrames.lua`
- On UI_SCALE_CHANGED or theme load: Call `GetAccentColors()` to cache
- Store cache in addon space: `addon.themeCache`

### Files to Modify
1. `Modules/UI/Theme.lua` (add color derivation functions, ~100 lines)
2. `Modules/UI/OptionsV2/Registry.lua` (add accent color widget, ~30 lines)
3. `SimpleUnitFrames.lua` (cache initialization, ~10 lines)

### Testing Checklist
- [ ] Load addon, open options
- [ ] Find accent color picker
- [ ] Change to mint color → verify all UI colors update
- [ ] Change to amber → verify warm tones throughout
- [ ] Change to cool blue → verify cool tones
- [ ] Reload UI → verify colors persist
- [ ] Performance test: `/SUFperf` should show no frame spike on color change
- [ ] Check all UI elements: buttons, panels, borders, text

### Risk Assessment
- 🟡 **MEDIUM**: Colors change immediate, visual glitches possible
- Mitigation: Test all UI elements thoroughly before release
- Rollback: Revert Theme.lua to hardcoded colors

### Success Criteria
- ✅ Single accent picker controls all related colors
- ✅ Color changes apply instantly without reload
- ✅ All UI elements (buttons, panels, borders) use derived colors
- ✅ Performance impact negligible (<1ms per color change)
- ✅ Presets make color selection intuitive

---

## Task 2.2: Search Navigation Enhancement (1-2 hours)

### Objective
Search results navigate to correct tab + scroll to section automatically

### Current State
- `Modules/UI/OptionsV2/Search.lua` exists
- Search finds settings but doesn't navigate
- Manual tab switching required after search

### Implementation Strategy

**Step 1: Enhance Registry Metadata**
- File: `Modules/UI/OptionsV2/Registry.lua`
- Add to each setting:
  - `tab`: Tab name (e.g., "Globals", "Bars", "Auras")
  - `section`: Section within tab (e.g., "General", "Appearance")
  - `scrollTarget`: Element to scroll to (frame name)

**Step 2: Update Search Handler**
- File: `Modules/UI/OptionsV2/Search.lua`
- On result click:
  - Navigate to correct tab
  - Scroll to section
  - Highlight/focus the setting

**Step 3: Add Navigation Aliases**
- File: `Modules/UI/OptionsV2/Search.lua`
- Support common search terms mapping to tabs:
  - "bars" → "Bars" tab
  - "auras" → "Auras" tab
  - "health" → "Bars" tab with health section
  - "appearance" → "Appearance" tab

### Files to Modify
1. `Modules/UI/OptionsV2/Registry.lua` (add metadata, ~50 lines)
2. `Modules/UI/OptionsV2/Search.lua` (enhance navigation, ~60 lines)

### Testing Checklist
- [ ] Search for "health color" → navigates to Bars tab
- [ ] Search for "absorbs" → navigates to correct section
- [ ] Search for "appearance" → correct tab + scroll
- [ ] Verify no search regressions

### Risk Assessment
- 🟢 **LOW**: Non-breaking enhancement to existing search
- Rollback: Revert Search.lua to original behavior

### Success Criteria
- ✅ Search results navigate to correct tab
- ✅ Automatic scroll to section
- ✅ No search regressions
- ✅ Navigation aliases work

---

## Task 2.3: Modular Options Builders (3-4 hours)

### Objective
Break up OptionsTabs.lua into separate builder files (code quality improvement)

### Current State
- `Modules/UI/OptionsTabs.lua` (large monolithic file)
- Each tab defined inline (~200-300 lines per tab)
- Hard to maintain, difficult to test individual tabs

### Implementation Strategy

**Step 1: Create Builders Directory**
- Directory: `Modules/UI/Builders/`
- Files:
  - `GlobalBuilder.lua` (Global/Base settings)
  - `BarBuilder.lua` (Health/Power bar settings)
  - `AuraBuilder.lua` (Aura display settings)
  - `RaidBuilder.lua` (Raid frame settings)
  - `CastbarBuilder.lua` (Castbar settings)
  - `PartyBuilder.lua` (Party frame settings)
  - ...etc (one per existing tab)

**Step 2: Extract Tab Builders**
- Each builder file exports single function: `BuildTabName()`
- Pattern:
  ```lua
  local function BuildHealthBars()
      return {
          name = "Health Bars",
          icon = "...",
          order = 1,
          children = { ... }
      }
  end
  return BuildHealthBars
  ```
- File size: ~150-200 lines each
- Copy content from OptionsTabs.lua per tab

**Step 3: Create BuilderRegistry**
- File: `Modules/UI/Builders/BuilderRegistry.lua` (~50 lines)
- Central registry:
  ```lua
  local builders = {
      global = require("Modules.UI.Builders.GlobalBuilder"),
      health = require("Modules.UI.Builders.BarBuilder"),
      auras = require("Modules.UI.Builders.AuraBuilder"),
      ...
  }
  ```
- Function: `GetTabByName(name)` → Returns built tab

**Step 4: Update OptionsWindow**
- File: `Modules/UI/OptionsWindow.lua`
- Replace tab inline definitions with builder calls
- Loop: `for tabName, builder in pairs(BuilderRegistry) do tabs[tabName] = builder.Build() end`

**Step 5: Deprecate OptionsTabs.lua**
- File: `Modules/UI/OptionsTabs.lua`
- Keep only metadata (tab names, icons, order)
- Remove inline builders

**Step 6: Update Load Order**
- File: `SimpleUnitFrames.toc`
- Load `Modules/UI/Builders/*.lua` before `OptionsWindow.lua`

### Files to Create
- `Modules/UI/Builders/GlobalBuilder.lua` (~200 lines)
- `Modules/UI/Builders/BarBuilder.lua` (~200 lines)
- `Modules/UI/Builders/AuraBuilder.lua` (~200 lines)
- `Modules/UI/Builders/RaidBuilder.lua` (~200 lines)
- `Modules/UI/Builders/CastbarBuilder.lua` (~150 lines)
- `Modules/UI/Builders/PartyBuilder.lua` (~150 lines)
- `Modules/UI/Builders/BuilderRegistry.lua` (~50 lines)
- Total: ~1150 lines across 7 files (currently ~1150 lines in 1 file)

### Files to Modify
1. `Modules/UI/OptionsTabs.lua` (remove builders, keep metadata)
2. `Modules/UI/OptionsWindow.lua` (call builders instead of inline definitions)
3. `SimpleUnitFrames.toc` (load order)

### Testing Checklist
- [ ] Load addon, open options
- [ ] All tabs render identically to before refactor
- [ ] All settings functional
- [ ] Search still works
- [ ] No visual regressions
- [ ] Reload tab still works
- [ ] Auto-expand first tab on open

### Risk Assessment
- 🟡 **MEDIUM**: Large refactor, potential regressions
- Mitigation: Test all tabs thoroughly, compare screenshots before/after
- Rollback: Keep original OptionsTabs.lua backed up, revert toc/OptionsWindow

### Success Criteria
- ✅ All tabs render correctly (pixel-perfect match to original)
- ✅ All settings remain functional
- ✅ Code more maintainable (easier to add new tabs)
- ✅ No search regressions
- ✅ Load time similar or faster

---

## Overall Phase 2 Summary

| Task | Duration | Difficulty | Risk | Value | Priority |
|------|----------|-----------|------|-------|----------|
| 2.1: Accent Colors | 2-3h | Medium | 🟡 MEDIUM | 🟢🟢 HIGH | 1st |
| 2.2: Search Nav | 1-2h | Medium | 🟢 LOW | 🟢 MEDIUM | 2nd |
| 2.3: Modular Builders | 3-4h | Hard | 🟡 MEDIUM | 🟢 MEDIUM | 3rd |
| **Total** | **6-9h** | **Mixed** | **🟡 LOW-MEDIUM** | **🟢 HIGH** | - |

---

## Recommended Execution Order

1. **Task 2.1 (Accent Colors)** — Highest user impact, most visible improvement
2. **Task 2.2 (Search Nav)** — Quick win, low risk
3. **Task 2.3 (Modular Builders)** — Code quality, not user-facing

---

## Next Steps

1. Choose Task 2.1 to begin, or ask for clarification
2. Prepare codebase with file backups
3. Execute with incremental testing
4. Document changes in WORK_SUMMARY.md after each task

Ready to proceed with Task 2.1?
