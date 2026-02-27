# RegisterUnitEvent Implementation Checklist

Quick reference for tracking implementation progress. Track each phase and mark completion as you go.

---

## ✓ Phase 1: Foundation & High-Impact Elements (~1.5 hours)

### Task 1.1: Add Helper Function
- [ ] Edit `Libraries/oUF/events.lua`
- [ ] Add SmartRegisterUnitEvent function (after RegisterEvent implementation)
- [ ] Document purpose: "Backwards-compatible RegisterUnitEvent wrapper"
- [ ] Verify file saves without errors

### Task 1.2: Convert health.lua
- [ ] Edit `Libraries/oUF/elements/health.lua`
- [ ] Find `Enable` function
- [ ] Replace: `self:RegisterEvent('UNIT_HEALTH', Path)` → `Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH', self.unit, Path)`
- [ ] Replace: `self:RegisterEvent('UNIT_MAXHEALTH', Path)` → `Private.SmartRegisterUnitEvent(self, 'UNIT_MAXHEALTH', self.unit, Path)`
- [ ] Replace: `self:RegisterEvent('UNIT_CONNECTION', Path)` → `Private.SmartRegisterUnitEvent(self, 'UNIT_CONNECTION', self.unit, Path)`
- [ ] Verify file saves without errors
- [ ] Load addon: `/reload`
- [ ] Check: Player frame health bar updates correctly
- [ ] Check: No Lua errors in chat

### Task 1.3: Convert power.lua
- [ ] Edit `Libraries/oUF/elements/power.lua`
- [ ] Find `Enable` function
- [ ] Replace: `self:RegisterEvent('UNIT_POWER_UPDATE', Path)` → `Private.SmartRegisterUnitEvent(self, 'UNIT_POWER_UPDATE', self.unit, Path)`
- [ ] Replace: `self:RegisterEvent('UNIT_MAXPOWER', Path)` → `Private.SmartRegisterUnitEvent(self, 'UNIT_MAXPOWER', self.unit, Path)`
- [ ] Reload addon: `/reload`
- [ ] Check: Power bar updates on unit changes
- [ ] Check: No Lua errors

### Task 1.4: Convert auras.lua
- [ ] Edit `Libraries/oUF/elements/auras.lua` (high-impact — many events in raids)
- [ ] Find `Enable` function (around line 850)
- [ ] Replace: `self:RegisterEvent('UNIT_AURA', UpdateAuras)` → `Private.SmartRegisterUnitEvent(self, 'UNIT_AURA', self.unit, UpdateAuras)`
- [ ] Reload addon: `/reload`
- [ ] Switch targets multiple times: `/target [target name]`
- [ ] Check: Auras appear/disappear on unit change
- [ ] Check: No Lua errors

### Task 1.5: Convert castbar.lua
- [ ] Edit `Libraries/oUF/elements/castbar.lua`
- [ ] Find `Enable` function
- [ ] Replace all 6 UNIT_SPELLCAST_* and UNIT_SPELLCAST_CHANNEL_* events with SmartRegisterUnitEvent
  - UNIT_SPELLCAST_START → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_START', self.unit, ...)
  - UNIT_SPELLCAST_STOP → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_STOP', self.unit, ...)
  - UNIT_SPELLCAST_FAILED → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_FAILED', self.unit, ...)
  - UNIT_SPELLCAST_INTERRUPTED → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_INTERRUPTED', self.unit, ...)
  - UNIT_SPELLCAST_CHANNEL_START → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_CHANNEL_START', self.unit, ...)
  - UNIT_SPELLCAST_CHANNEL_STOP → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_CHANNEL_STOP', self.unit, ...)
- [ ] Reload addon: `/reload`
- [ ] Cast a spell on yourself or target
- [ ] Check: Castbar appears and fills correctly
- [ ] Check: No Lua errors

### Task 1.6: Test Phase 1
- [ ] Load addon: `/reload`
- [ ] Create test raid: `/run CreateRaid()`
- [ ] Spawn raid party (or join actual raid)
- [ ] Verify all unit frames present and visible
- [ ] Check: Player health/power updates
- [ ] Check: Target switching works (auras update)
- [ ] Check: Castbar shows casting
- [ ] Run performance profiling:
  ```
  /SUFprofile start
  -- (Play 5-10 minutes in combat/dungeons)
  /SUFprofile stop
  /SUFprofile analyze
  ```
- [ ] Record metrics: Event handler call reduction %
- [ ] Check: No regressions (all tests pass)

**Phase 1 Status:** ☐ Not Started | ☐ In Progress | ☐ Complete

---

## ✓ Phase 2: Medium-Impact Elements (~1 hour)

### Task 2.1: Convert healthprediction.lua
- [ ] Edit `Libraries/oUF/elements/healthprediction.lua`
- [ ] Find `Enable` function
- [ ] Convert UNIT_HEALTH, UNIT_MAXHEALTH, UNIT_ABSORB_AMOUNT_CHANGED events to SmartRegisterUnitEvent
- [ ] Reload addon: `/reload`
- [ ] Check: Healing predictions appear on health bars

### Task 2.2: Convert powerprediction.lua
- [ ] Edit `Libraries/oUF/elements/powerprediction.lua`
- [ ] Find `Enable` function
- [ ] Convert UNIT_POWER_UPDATE, UNIT_MAXPOWER, UNIT_POWER_PREDICTION events
- [ ] Reload addon: `/reload`
- [ ] Check: Power predictions work

### Task 2.3: Convert portrait.lua
- [ ] Edit `Libraries/oUF/elements/portrait.lua`
- [ ] Find `Enable` function
- [ ] Convert UNIT_PORTRAIT_UPDATE, UNIT_MODEL_CHANGED events
- [ ] Reload addon: `/reload`
- [ ] Switch targets
- [ ] Check: Portraits update on unit change

### Task 2.4: Convert additionalpower.lua
- [ ] Edit `Libraries/oUF/elements/additionalpower.lua`
- [ ] Find `Enable` function
- [ ] Convert UNIT_POWER_UPDATE, UNIT_MAXPOWER events
- [ ] Reload addon: `/reload`
- [ ] Check: Alternate power bars update correctly

### Task 2.5: Convert Remaining Tier 2 Elements
- [ ] classpower.lua (combo points, eclipse, runes, etc.)
- [ ] runes.lua (death knight runes)
- [ ] totems.lua (shaman totems)
- [ ] And any other medium-use elements
- [ ] Reload after each: `/reload`

### Task 2.6: Test Phase 2
- [ ] Load addon: `/reload`
- [ ] Create test raid with specialized classes (DK, Shaman, etc.)
- [ ] Verify class-specific mechanics:
  - [ ] Death Knight runes update
  - [ ] Shaman totems display
  - [ ] Class power (combo points, etc.) updates
  - [ ] All power bars responsive
- [ ] Run performance profiling again:
  ```
  /SUFprofile start
  -- (Play 5-10 minutes)
  /SUFprofile stop
  /SUFprofile analyze
  ```
- [ ] Record metrics: Sustained improvement?
- [ ] Check: No new regressions

**Phase 2 Status:** ☐ Not Started | ☐ In Progress | ☐ Complete

---

## ✓ Phase 3: Completion & Tier 3 Elements (~1 hour)

### Task 3.1: Convert All Remaining Elements
- [ ] stagger.lua (Monk stagger)
- [ ] phase.lua (Phase events)
- [ ] threat.lua (Threat indicators)
- [ ] raidmark.lua (Raid marks)
- [ ] grouproleindicator.lua (Group role display)
- [ ] raidroleindicator.lua (Raid role display)
- [ ] leaderindicator.lua (Leader indicator)
- [ ] pvpspecicon.lua (PvP spec display)
- [ ] All remaining `.lua` files in `Libraries/oUF/elements/`
- [ ] For each: Find Enable function → Convert unit-scoped events → `RegisterEvent('UNIT_*'` → `SmartRegisterUnitEvent(...)`
- [ ] Test after every 2-3 files: `/reload` → verify no errors

### Task 3.2: Final Validation
- [ ] Load addon: `/reload`
- [ ] Full UI test:
  - [ ] Player frame functional and responsive
  - [ ] Target frame shows all elements (health, power, auras, castbar, threat, etc.)
  - [ ] Pet frame displays correctly
  - [ ] Focus frame and ToT frame work
  - [ ] Party frames (1-4) all functional
  - [ ] Raid frames (all 40) spawn and update
  - [ ] Boss frames (if applicable) functional
- [ ] Join raid group or run dungeon
- [ ] Extended performance profiling (30 min):
  ```
  /SUFprofile start
  -- (Play 30 minutes in raid/dungeons)
  /SUFprofile stop
  /SUFprofile analyze
  ```
- [ ] Record final metrics:
  - [ ] Event handler call reduction: ___% (target: 30-50%)
  - [ ] FPS improvement: ___ FPS
  - [ ] Frame time improvement: P50: __ms, P99: __ms

### Task 3.3: Documentation
- [ ] Update `WORK_SUMMARY.md`:
  - [ ] Add session entry with date
  - [ ] List all files modified (27+ element files)
  - [ ] Record performance metrics (before/after)
  - [ ] Note: "All unit-scoped events converted to RegisterUnitEvent for 30-50% event reduction"
  - [ ] Risk level: LOW
  - [ ] Validation: All tests pass ✓
  
- [ ] Update `API_VALIDATION_REPORT.md`:
  - [ ] Mark RegisterUnitEvent as ✅ IMPLEMENTED
  - [ ] Update Section 1.1 status from ❌ to ✅
  - [ ] Add implementation date
  - [ ] Add final performance metrics
  - [ ] Add link to this implementation checklist

- [ ] Generate commit message (optional):
  ```bash
  pwsh -ExecutionPolicy Bypass -File scripts/generate-commit-message.ps1 -AllChanges
  ```

**Phase 3 Status:** ☐ Not Started | ☐ In Progress | ☐ Complete

---

## Summary Metrics

### Before Implementation (Baseline)
- Event handler calls per minute: ________
- P50 frame time: ________ms
- P99 frame time: ________ms
- Aura update latency: ________ms

### After Implementation
- Event handler calls per minute: ________
- P50 frame time: ________ms
- P99 frame time: ________ms
- Aura update latency: ________ms

### Improvement
- Event reduction: ________% (target: 30-50%)
- Frame time improvement: ________ms
- Overall: ☑ SUCCESS | ☐ NEEDS WORK | ☐ ROLLBACK REQUIRED

---

## Troubleshooting

**If errors occur:**

1. **Lua Syntax Error:**
   - Check file was saved correctly: /reload
   - Review SmartRegisterUnitEvent function syntax
   - Verify all brackets/parentheses match
   - Check Private table export

2. **Events not firing:**
   - Verify SmartRegisterUnitEvent is accessible as Private.SmartRegisterUnitEvent
   - Check self.unit is not empty string
   - Confirm handler function exists (e.g., Path, UpdateAuras)

3. **Performance worse, not better:**
   - Check: Did you add SmartRegisterUnitEvent helper?
   - Verify: All events converted (not mixing RegisterEvent and SmartRegisterUnitEvent)
   - Run: `/run SUF.EventCoalescer:PrintStats()` to see event counts

4. **Need to rollback:**
   ```bash
   git checkout HEAD -- Libraries/oUF/
   ```

---

## Resources

- **Implementation Plan:** IMPLEMENTATION_PLAN_RegisterUnitEvent.md (full details)
- **API Validation:** API_VALIDATION_REPORT.md (Section 1.1 RegisterUnitEvent)
- **Research:** RESEARCH.md (Section 3.2 RegisterUnitEvent, lines 313-350)
- **Performance Tool:** `/SUFprofile start|stop|analyze` command
- **Event Debugging:** `/run SUF.EventCoalescer:PrintStats()`

---

**Overall Implementation Status:** ☐ Not Started | ☐ Phase 1 Complete | ☐ Phase 2 Complete | ☐ Phase 3 Complete ✅ | ☐ Merged to Master

Last Updated: [Date when checklist is started]  
Completed By: [Your name]
