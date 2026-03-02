# LibQTip-2.0 Implementation Checklist

**Start Date:** [Your date]  
**Target Completion:** [3 days from start]

---

## Pre-Implementation Verification

- [ ] Verify LibQTip-2.0 is present in `Libraries/LibQTip-2.0/`
- [ ] Verify KStub and CallbackHandler-1.0 are embedded
- [ ] Read LIBQTIP_RESEARCH_SUMMARY.md for overview
- [ ] Read LIBQTIP_QUICK_REFERENCE.md for API basics

---

## Phase 1: Debug Window Frame Stats (Primary Focus)

### Documentation
- [ ] Read LIBQTIP_INTEGRATION_PLAN.md Section "Phase 1"
- [ ] Review example in LIBQTIP_QUICK_REFERENCE.md "Pattern: Frame Stats Tooltip"

### Implementation
- [ ] Create `Modules/UI/LibQTipHelper.lua`
  - [ ] Function: `GetQTip()` - Get LibQTip-2.0 instance
  - [ ] Function: `CreateFrameStatsTooltip(frames)` - Build tooltip
  - [ ] Function: `ReleaseFrameTooltips()` - Cleanup helper
  - [ ] Test file syntax changes

- [ ] Modify `Modules/UI/DebugWindow.lua`
  - [ ] Import LibQTipHelper: `local LibQTipHelper = ...`
  - [ ] Add "Frame Stats" button to debug panel
  - [ ] Connect OnEnter script to show tooltip
  - [ ] Connect OnLeave script to release tooltip
  - [ ] Test rendering

### Testing
- [ ] Open debug window (`/suf debug`)
- [ ] Click "Frame Stats" button
- [ ] Verify 4-column tooltip appears (Frame | Health | Power | Time)
- [ ] Verify multiple frames listed (Player, Target, Party, etc.)
- [ ] Mouse leave - tooltip disappears
- [ ] Mouse leave - memory cleaned up (no errors in console)
- [ ] Test near screen edges - tooltip repositions
- [ ] Test with many frames (15+) - scrollbar appears
- [ ] No performance regression (<1ms overhead)

### Validation Checklist
- [ ] Tooltip renders with correct column layout
- [ ] Data displays accurately
- [ ] SmartAnchorTo() positions tooltip on-screen
- [ ] Release removes tooltip from memory
- [ ] No errors in console
- [ ] No memory leaks on repeated show/hide

---

## Phase 2: Performance Dashboard Stats (Optional)

### Documentation
- [ ] Read LIBQTIP_INTEGRATION_PLAN.md Section "Phase 2"
- [ ] Review EventCoalescer API in PerformanceLib

### Implementation
- [ ] Extend LibQTipHelper with `CreateEventCoalescingStatsTooltip()`
- [ ] Extend DebugWindow with "Event Stats" button
- [ ] Query EventCoalescer stats via PerformanceLib API
- [ ] Build tooltip with event breakdown
  - [ ] Column layout: Event Type | Total | Coalesced | Efficiency % | Avg Batch Size
  - [ ] Add separator line
  - [ ] Add totals row

### Testing
- [ ] Play for 60 seconds in combat
- [ ] Click "Event Stats" button
- [ ] Verify stats tooltip shows event breakdown
- [ ] Verify efficiency percentages calculate correctly
- [ ] Verify total row shows overall statistics
- [ ] Verify scrolling works for 10+ events

---

## Phase 3: Enhanced Aura Tooltips (Deferred Option)

### Decision Point
Before implementing, decide:
- [ ] Is replacing GameTooltip for auras worth the complexity?
- [ ] Will users notice the 2-column layout improvement?
- [ ] Can we afford the Forbidden() fallback complexity?

**Recommendation:** Defer to Phase 4+ unless explicitly requested.

### If Proceeding
- [ ] Read LIBQTIP_INTEGRATION_PLAN.md Section "Phase 3"
- [ ] Implement hybrid pattern (LibQTip + GameTooltip fallback)
- [ ] Test in dungeons (where GameTooltip is Forbidden)
- [ ] Validate stack counts display correctly

---

## Documentation Updates

- [ ] Update `copilot-instructions.md`
  - [ ] Add LibQTip-2.0 section to "Integration Points"
  - [ ] Document LibQTipHelper patterns
  - [ ] Add code style notes for tooltip usage

- [ ] Update `WORK_SUMMARY.md`
  - [ ] Add new session entry
  - [ ] Document files modified
  - [ ] Note effort spent
  - [ ] Link to LIBQTIP_RESEARCH_SUMMARY.md

- [ ] Update `TODO.md`
  - [ ] Mark Phase 1 complete (if applicable)
  - [ ] Set next steps for Phase 2/3
  - [ ] Link to implementation documents

---

## Code Quality Checks

- [ ] Lua syntax validation (no errors in console)
- [ ] No nil reference errors
- [ ] No globals created (all local)
- [ ] Consistent indentation (4 spaces per copilot-instructions.md)
- [ ] Comments for non-obvious code
- [ ] No debug print() statements left in code

---

## Performance Validation

- [ ] Measure FPS before/after
  - [ ] Showtooltip time: <1ms (measured via FrameTimeBudget)
  - [ ] Memory stable: No delta per tooltip create/release cycle
  - [ ] No frame spikes (P99 <33ms)

- [ ] Test with high frame count
  - [ ] 50+ frames listed
  - [ ] Scrollbar renders
  - [ ] Scroll performance smooth

---

## Backward Compatibility

- [ ] Addon loads without LibQTip integration active
- [ ] GameTooltip still works for auras
- [ ] DebugWindow functions without LibQTipHelper (graceful fallback)
- [ ] No hard dependency introduced

---

## Testing Scenarios

### Scenario 1: Fresh Load
- [ ] Addon loads
- [ ] No console errors
- [ ] LibQTipHelper loads successfully
- [ ] DebugWindow opens without issues

### Scenario 2: Debug Window
- [ ] `/suf debug` opens debug window
- [ ] Frame Stats button visible
- [ ] Hover - tooltip appears
- [ ] Move mouse - tooltip stays positioned to current button
- [ ] Leave button - tooltip hidden immediately

### Scenario 3: Performance
- [ ] Repeat show/hide 10x fast - no lag
- [ ] 100+ rows in tooltip - scrolls smoothly
- [ ] Memory stable (check with /script GetTotalMemoryUsage())

### Scenario 4: Edge Cases
- [ ] Empty frame list - tooltip shows "No frames"
- [ ] Frame with nil name - shows "Unknown"
- [ ] Tooltip at screen edge - repositions to stay visible
- [ ] Tooltip near top-left - good positioning
- [ ] Tooltip near bottom-right - good positioning

---

## Git Workflow

- [ ] Create feature branch: `git checkout -b feature/libqtip-integration`
- [ ] Commit LibQTipHelper creation
- [ ] Commit DebugWindow modifications
- [ ] Commit documentation updates
- [ ] Create Pull Request (if applicable)
- [ ] Generate commit message: `/run SUF.DebugOutput:Output("Commit", "LibQTip integration phase 1 complete")`

---

## Sign-Off Checklist

- [ ] Phase 1 implementation complete
- [ ] All tests passed
- [ ] Documentation updated
- [ ] No console errors
- [ ] Performance acceptable (<1ms overhead)
- [ ] Code review passed (if applicable)
- [ ] Ready to merge

---

## Deferred Tasks (Phase 2+)

- [ ] Phase 2: Performance metrics tooltip
- [ ] Phase 3: Enhanced aura tooltips
- [ ] Phase 4: Frame info tooltips
- [ ] Phase 5: Custom cell providers (advanced)

---

## Known Issues & Workarounds

### Issue: Tooltip appears but text is black
- **Cause:** Font color not set
- **Fix:** `tooltip:SetDefaultFont(GameFontNormal)` - sets color implicitly

### Issue: Tooltip stays on-screen after leaving button
- **Cause:** Forgot to release in OnLeave
- **Fix:** Always call `ReleaseTooltip()` in OnLeave handler

### Issue: Memory growing every show/hide
- **Cause:** Not storing reference or not releasing
- **Fix:** Store `button.__tooltip = tooltip` and release it in OnLeave

### Issue: Tooltip positioning weird at screen edges
- **Fix:** Use `SmartAnchorTo()` instead of manual SetPoint()

---

## Quick Command Reference

```lua
-- Load library
local QTip = LibStub("LibQTip-2.0")

-- Create tooltip
local tooltip = QTip:AcquireTooltip("Key", 3, "LEFT", "CENTER", "RIGHT")

-- Add content
tooltip:AddHeadingRow("A", "B", "C")
tooltip:AddRow("1", "2", "3")

-- Show
tooltip:SmartAnchorTo(button)
tooltip:Show()

-- Cleanup
QTip:ReleaseTooltip(tooltip)
```

---

## Support Resources

- **Quick Reference:** `docs/LIBQTIP_QUICK_REFERENCE.md`
- **Integration Plan:** `docs/LIBQTIP_INTEGRATION_PLAN.md`
- **Research Summary:** `docs/LIBQTIP_RESEARCH_SUMMARY.md`
- **API Source:** `Libraries/LibQTip-2.0/LibQTip-2.0/QTip.lua`
- **Tooltip Methods:** `Libraries/LibQTip-2.0/LibQTip-2.0/Components/Tooltip.lua`

---

## Notes

```
Session Start: [Date/Time]
Session End: [Date/Time]
Total Time: [Duration]

Key Decisions Made:
- 

Issues Encountered:
- 

Solutions Applied:
- 

Next Steps:
- 
```

---

**Status:** ⏳ Ready for Implementation  
**Last Updated:** 2026-03-01  
**Owner:** [Your Name]
