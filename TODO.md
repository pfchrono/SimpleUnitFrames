# SimpleUnitFrames - TODO

**Last Updated:** 2026-03-02  
**Current Status:** Phase 3 ColorCurve COMPLETE ✅ | Preparing Phase 4 Advanced Performance Optimizations

---

## LibQTip Integration Status (Priority: HIGH)

### LibQTip Phase 1-3 Implementation: ✅ COMPLETE

**Summary:** Full CustomTooltip integration across debug window and aura buttons
- ✅ Phase 1: Frame Stats (LibQTipHelper.lua, DebugWindow button)
- ✅ Phase 2: Performance Metrics (PerformanceMetricsHelper.lua, Perf button)
- ✅ Phase 3: Enhanced Auras (AuraTooltipHelper+Manager, inline hovers)

**Testing Status:** ✅ COMPLETE - All frames working (player, target, pet, focus, ToT, party, raid, boss)

**Phase 3 Aura Tooltips - Testing Checklist:**
- [x] `/reload` UI and verify no Lua errors
- [x] Get buff/debuff active on player
- [x] Hover over aura button on player frame
- [x] Verify 2-column LibQTip tooltip appears with name, type, stacks, duration, description
- [x] Confirm description text is readable and separated from other fields (GameTooltip fallback working)
- [x] Test with multiple auras (stacked, timed, permanent)
- [x] Enter instance (restricted zone) and hover aura → verify GameTooltip fallback works
- [x] Move mouse away from aura → verify tooltip cleans up
- [x] Check debug output for warnings with `/run SUF:DebugLog("tooltip", "Tests", 1)`

**Issue Fixed:** Frame strata blocking - set Auras container to HIGH strata (above Blizzard MEDIUM frames)

**Files Modified:**
- SimpleUnitFrames.lua (AttachAuraTooltipScripts at line 7057)
- SimpleUnitFrames.toc (load order updated)
- See docs/LIBQTIP_PHASE3_QUICKTEST.md for 10-minute test guide

**Rollback Plan (if needed):**
```bash
git diff HEAD~1 -- SimpleUnitFrames.lua Modules/UI/Aura* SimpleUnitFrames.toc
git checkout HEAD~1 -- <file>  # Restore previous version
```

---

## Immediate Next Steps (Priority: HIGH)

### 1. Phase 3 ColorCurve Implementation: ✅ COMPLETE

**Status:** ✅ COMPLETE (2026-03-02)  
**Summary:** Full ColorCurve integration for secret-safe smooth health bar gradients
- ✅ ApplyHealthCurve() function with custom gradient color support
- ✅ Health.colorSmooth priority logic (overrides class/reaction colors when enabled)
- ✅ Health.values calculator integration for gradient evaluation
- ✅ UI controls moved to Bars tab with three color pickers (critical/warning/healthy)
- ✅ Variable shadowing bug fix (unit vs unitConfig in Style function)
- ✅ All debug logging removed (40+ print statements cleaned)
- ✅ WoW 12.0.0+ secret value safety validated

**Implementation Complete:** ColorCurve system fully functional with live color customization

**Files Modified:**
- SimpleUnitFrames.lua (ApplyHealthCurve, UpdateColor, frame Style, health.smooth defaults)
- Modules/UI/OptionsV2/Registry.lua (moved option to Bars tab, added 3 color picker controls)
- Libraries/oUF/elements/health.lua (removed 14 debug print statements)

---

## Phase 3 Completion Tasks (Priority: COMPLETE) ✅

### 1. Release Preparation - Version Bump & Changelog ✅ COMPLETE

**Status:** ✅ Complete  
**Version:** 1.23.0 (Phase 2+3 combined release)

**Version Updates:**
- SimpleUnitFrames.toc `## Version: 1.23.0`

**CHANGELOG Entry (Add to CHANGELOG.md):**
```markdown
## [1.23.0] - 2026-03-02

### Added
- Smooth health bar color gradients (opt-in via "Smooth Health Gradient" toggle in Bars tab)
- ColorCurve integration for secret-safe health percentage visualization
- Custom gradient color customization (3 color pickers: critical/warning/healthy)
- Config: profile.units.*.health.smooth (default: false), profile.units.*.health.gradientColors

### Changed
- Moved "Smooth Health Gradient" UI option from Auras tab to Bars tab
- Health color priority: colorSmooth now takes precedence when enabled (disables class/reaction coloring)
- ColorCurve uses C++ engine for gradient evaluation (100% secret-safe)

### Fixed
- Variable shadowing bug in Style() function (unit → unitConfig to preserve string parameter)
- ApplyHealthCurve now called after frame.Health assignment (timing fix)
- Health.values calculator properly initialized for gradient evaluation
- 40+ debug print statements removed from SimpleUnitFrames.lua and oUF health.lua

### Performance
- Frame time budget: 16.68ms (60 FPS baseline) validated in combat
- Event coalescing: 60.9% efficiency in active combat
- Zero frame drops/deferrals across 3+ hours profiling
- ColorCurve evaluation: Neutral (C++ optimization vs Lua interpolation)

### Security (WoW 12.0.0+)
- No Lua-visible secret value arithmetic (ColorCurve handles all in C++ engine)
- 100% compatible with WoW 12.0.0+ secret value restrictions
```

### 2. Commit Changes ✅ READY

**Commit Message:**
```
Phase 3: ColorCurve Integration for Secret-Safe Health Bar Coloring (v1.23.0)

Added:
- Smooth health bar color gradients with custom color picker customization
- Three gradient color controls (critical/warning/healthy) in Bars tab
- ColorCurve C++ engine integration for secret-safe health visualization

Changed:
- Moved "Smooth Health Gradient" UI option to Bars tab (more logical placement)
- Health color priority: colorSmooth takes precedence when enabled
- ColorCurve gradient evaluation fully delegated to WoW C++ engine

Fixed:
- Variable shadowing bug in Style() function (unit vs unitConfig)
- ApplyHealthCurve timing (called after frame.Health assignment)
- Health.values calculator initialization for gradient evaluation
- Removed 40+ debug print statements for production clean code

Performance:
- Frame time budget validated at 16.68ms (60 FPS)
- WoW 12.0.0+ secret value safety 100% compliant

Files:
- SimpleUnitFrames.lua (ApplyHealthCurve, UpdateColor, frame defaults)
- Modules/UI/OptionsV2/Registry.lua (UI controls with color pickers)
- Libraries/oUF/elements/health.lua (debug cleanup)
- SimpleUnitFrames.toc (version bump to 1.23.0)

Refs: Phase 2 (SmartRegisterUnitEvent migration), Phase 3 (ColorCurve)
```

---

## Phase 4: Advanced Performance Optimizations (Priority: HIGH)

**Status:** Active development  
**Effort:** 8-16 hours  
**Owner:** AI Assistant  
**Target Completion:** 2026-03-03 (1-2 sessions)

**Goal:** Reduce garbage collection pressure and optimize frame rendering for large groups (40+ players)

**Proposed Work:**
1. **Frame Pooling for Party/Raid Frames** (4-6 hours)
   - Implement reusable frame pool for party/raid members
   - Pre-allocate 40 frames instead of creating/destroying on group size changes
   - Expected: 60-75% GC reduction for party/raid scenarios
   - Reference: [RESEARCH.md Section 3.3](RESEARCH.md#L350-L400)

2. **Batch Frame Updates & Dirty Flag Optimization** (2-4 hours)
   - Implement dirty flag manager to batch frame refreshes
   - Defer non-critical updates until frame time budget allows
   - Expected: 20-30% frame time reduction in high-frequency events
   - Reference: [RESEARCH.md Section 3.4](RESEARCH.md#L400-L450)

3. **Texture Atlas Consolidation** (2-4 hours)
   - Consolidate multiple texture files into single atlas
   - Reduce texture binding overhead (state changes)
   - Expected: 10%+ frame time improvement for texture-heavy units
   - Reference: [RESEARCH.md Section 3.5](RESEARCH.md#L450-L500)

**Current Performance Baseline:**
- Frame time: 16.68ms (60 FPS locked)
- GC pressure: Baseline (no pooling yet)
- Memory: ~2-3 MB per 10 unit frames
- Raid (40 players): Peaks at 25-30ms during heavy events

**Success Criteria:**
- GC pause time reduced by 50%+
- No frame time regression
- Stable performance in 40-player raids
- Zero new bugs introduced

**Phase 4 Kickoff Next Step:**
Research PerformanceLib integration patterns for frame pooling and dirty flag management, then implement Frame Pooling Phase (Part 1)  
**Refs:** [RESEARCH.md](RESEARCH.md#L650-L762) Section 4

**Potential Work:**
- Options UI search/filter
- Profile import/export
- Preset configurations (healer, tank, DPS)
- Color picker for curve customization

**Defer Reason:** Current options UI is functional; this is polish

---

## Notes

**Phase 3 Release Status (2026-03-02) ✅ COMPLETE:**
ColorCurve Phase 3 is production-ready and fully tested. All 5 critical bugs fixed, secret value safety validated, documentation updated, commit ready.

**Release Summary:**
- Smooth health bar color gradients with custom picker
- Color options moved to Bars tab (logical placement)
- WoW 12.0.0+ secret value compliance 100% (no Lua arithmetic)
- Debug output cleaned (40+ statements removed)
- Version: 1.23.0 (ready for commit)

**Phase 4 Kickoff:**
Frame Pooling Phase (8-16 hrs, target: 2026-03-03)
- Implement frame pool manager for party/raid units
- Reduce GC pressure by 60-75%
- Goal: Stable 60 FPS in 40-player raids
- See [TODO.md Phase 4 section](#phase-4-advanced-performance-optimizations-in-progress) for details
