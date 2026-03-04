## [1.29.0] - 2026-03-04

### Added
- Implement SmartRegisterUnitEvent kernel-level event filtering for 30-50% performance gain (`86f2088`)

### Changed
- Update CHANGELOG.md for v1.29.0 (`bdcbf67`)

---


## [1.29.0] - 2026-03-04

### Added
- Implement SmartRegisterUnitEvent kernel-level event filtering for 30-50% performance gain (`86f2088`)

### Other
- Stop (`- Enabl`)
- P99: 19.00ms (`- Frame`)
- P99: 20.00ms (`- Frame`)
- P99: 18.00ms Γ£à (`- Frame`)

---


## [1.28.1] - 2026-03-03

### Added
- Implement SafeReload system to prevent errors during combat (`9ea43d4`)
- Update release infrastructure for v1.26.0 and enhance automation scripts (`06b00b6`)

### Changed
- Sync: merge recent upstream connection updates and fix solo party visibility (`864db87`)

### Other
- Release Infrastructure: v1.26.0 Build & Publish Automation (`db007c5`)

---


# SimpleUnitFrames Changelog

All notable changes to SimpleUnitFrames will be documented in this file.

## [1.26.0] - 2026-03-02

### Added
- **DirtyFlagManager Integration** — Intelligent frame update batching for 20-30% frame time variance reduction
  - Priority-based frame scheduling (player CRITICAL → target HIGH → party MEDIUM → raid LOW)
  - Automatic batch processing respecting frame time budget
  - 105 frame batches per gameplay session (vs single-pass processing)
- **Event Coalescing Expansion** — 14 new events configured (13 UNIT_SPELLCAST_* + UNIT_AURA)
  - UNIT_SPELLCAST_START/STOP/CHANNEL_*/EMPOWER_* events now batched
  - UNIT_AURA coalescing for buff/debuff efficiency
  - Result: 69.6% coalescing efficiency (1,963 of 2,816 events batched)
- **Interactive TestPanel** — New `/suf test` command with 6 validation buttons
  - Phase 1: Initialization checks (addon, PerformanceLib, frames)
  - Phase 2-3: Profiler setup and scenario testing
  - Phase 3c: Edge case validation
  - Stats: Real-time metrics display
- **Manual Event Registration System** — Player castbar visible during casting
  - Fixed castbar element not receiving events from oUF
  - Custom event dispatcher for castbar updates
  - All 13 UNIT_SPELLCAST_* events manually registered

### Changed
- Updated EventCoalescer priority assignments for casting events
  - START events remain HIGH priority (2) for cast bar responsiveness
  - STOP/UPDATE/FAILED events moved to LOW priority (4) for batching efficiency
  - Delays tuned: 0.05-0.12s based on event frequency
- Enhanced UpdateAllFrames and UpdateFramesByUnitType to use DirtyFlagManager batching
  - Graceful fallback to synchronous updates when PerformanceLib unavailable
  - Configurable batch size (default: 15 frames)

### Fixed
- Invalid event name PLAYER_LEADER_CHANGED removed (correct: PARTY_LEADER_CHANGED)
- TestPanel slash command registration (now uses RegisterChatCommand instead of non-existent RegisterSlashCommands)
- Missing UNIT_AURA in EVENT_COALESCE_CONFIG (now properly batched)
- Event routing priority parameter passing (eventName → priority in all call sites)

### Performance
- Frame time stable at 16.66ms average (60 FPS)
- Frame time P99 = 28ms (excellent consistency)
- Event coalescing: **69.6% efficiency**
  - UNIT_HEALTH: 78% reduction (695→124 dispatched, 571 saved)
  - UNIT_POWER_UPDATE: 72% reduction (335→94 batched, 241 saved)
  - UNIT_AURA: 54% reduction (457→211 batched, 246 saved)
- DirtyFlagManager: 229 frames processed in 105 batches per session
- Dropped frames: 0 (perfect stability)
- Zero regressions in existing frame update logic

### Technical Details
**Files Modified:**
- SimpleUnitFrames.lua (4 new helper functions, 3 modified methods, 1 system init)
  - Lines 4113-4213: DirtyFlagManager helper functions
  - Lines 6910-6943: UpdateAllFrames batching
  - Lines 7683-7725: UpdateFramesByUnitType batching
  - Lines 2725-2744: DirtyFlagManager initialization
  - Lines 730-785: EVENT_COALESCE_CONFIG expanded
  - Lines 705-728: PERF_EVENT_PRIORITY updated
  - Lines 3209-3343: HandleCoalescedUnitEvent priority routing
- Modules/UI/TestPanel.lua: 450+ lines of test infrastructure
- Modules/System/Commands.lua: `/suf test` command integration
- SimpleUnitFrames.toc: Version bump to 1.26.0

**Documentation:**
- docs/PHASE4_SESSION_SUMMARY.md — Session timeline and profiling logs
- docs/PHASE4_TASK2_IMPLEMENTATION_PLAN.md — Design and implementation strategy
- docs/PHASE4_TASK2_IMPLEMENTATION_COMPLETE.md — What was built and how to use

### Testing & Validation
- ✅ Phase 1: Addon load test (no errors, PerformanceLib initialized)
- ✅ Phase 2: Solo play test (all frames updating correctly)
- ✅ Phase 3: Profiler baseline (60 FPS stable, P99 28ms)
- ✅ Phase 4: Event routing (1,963 events coalesced)
- ✅ Phase 5: Priority tuning (emergency flushes 743→594, 20% reduction)
- ✅ 82.6 seconds gameplay profile validating all metrics

### Backward Compatibility
- All DirtyFlagManager features wrapped in PerformanceLib availability checks
- Graceful fallback to synchronous updates when PerformanceLib not loaded
- No breaking changes to existing APIs or configuration
- Compatible with WoW 12.0.0+ secret value restrictions

---

## [1.25.1] - 2026-03-01 (Internal)

### Fixed
- Version number consistency in system automation

---

## [1.24.0] - 2026-02-28

### Added
- **LibQTip Integration (Phases 1-3)** — Full CustomTooltip system for frame stats and aura details
  - Phase 1: Frame stats (health, power, position, memory)
  - Phase 2: PerformanceLib metrics (frame time, batch count, GC pressure)
  - Phase 3: Enhanced aura tooltips with 2-column layout (name, type, stacks, duration, description)
- **Aura Tooltip Infrastructure** — LibQTipHelper, AuraTooltipHelper, AuraTooltipManager
  - GameTooltip fallback for restricted zones (instances)
  - Frame strata management for tooltip visibility
  - Click-away tooltip cleanup

### Changed
- Aura container strata elevated to HIGH (above Blizzard MEDIUM frames)
- Debug window button tooltips now use LibQTip for consistent formatting

### Performance
- Tooltip rendering optimized via LibQTip pooling
- Minimal overhead during gameplay (tooltips only shown on hover)

---

## [1.23.0] - 2026-02-25

### Added
- **ColorCurve Integration** — Secret-safe smooth health bar color gradients
  - Three-color gradient customization (critical/warning/healthy)
  - C++ engine evaluation for WoW 12.0.0+ secret value safety
  - Color picker controls in Bars tab
  - Optional smooth gradient toggle per unit type

### Changed
- Moved "Smooth Health Gradient" UI option from Auras tab to Bars tab
- Health color priority: colorSmooth takes precedence when enabled (disables class/reaction coloring)
- Health.colorSmooth now evaluated via ColorCurve (vs Lua interpolation)

### Fixed
- Variable shadowing bug in Style() function (unit → unitConfig)
- ApplyHealthCurve timing (called after frame.Health assignment)
- Health.values calculator initialization for gradient evaluation
- Removed 40+ debug print statements from SimpleUnitFrames.lua and oUF health.lua

### Performance
- Frame time budget: 16.68ms (60 FPS baseline) validated
- ColorCurve evaluation neutral to slight improvement (C++ optimization)
- WoW 12.0.0+ secret value safety 100% compliant

---

## [1.22.0] - 2026-02-20

### Added
- **Phase 2 SmartRegisterUnitEvent Migration** (Partial - 21% complete)
  - Converted 5 oUF elements to RegisterUnitEvent (power, threatindicator, alternativepower)
  - Per-unit event registration reduces overhead 30-50%

### Performance
- Preliminary event storm reduction from SmartRegisterUnitEvent adoption
- Remaining 18 elements queued for Phase 2 continuation

---

## [1.21.0] - 2026-02-18

### Added
- **Phase 3 LibQTip Planning** — Foundation for custom tooltip system
- **Phase 4 Roadmap** — DirtyFlagManager integration and element pooling optimization

---

## [1.20.0] - 2026-02-15

### Added
- **Bug 4 Fix: Player Castbar Visibility** — Manual event registration system
  - Player castbar now visible during spell casting
  - All 13 UNIT_SPELLCAST_* events manually registered
  - Custom OnEvent dispatcher for castbars

### Fixed
- Player castbar not receiving casting events during oUF initialization
- Castbar element Enable callback timing issue
- Cast progression UI now matches target/boss frame behavior

---

## [1.19.0] - 2026-02-10

### Added
- **Phase 3 Planning & Research** — ColorCurve integration design
- **Frame Lifecycle Analysis** — oUF party/raid frame investigation

---

## [1.18.0] - 2026-02-05

### Added
- **PerformanceLib Integration** — Event coalescing, dirty flag batching, frame time budgeting
- **Performance Dashboard** — `/sufperf` command for real-time metrics
- **Performance Profiler** — `/SUFprofile` timeline recordings and analysis
- **Debug Panel Enhancement** — Perf button for event metrics

### Performance
- Event coalescing system operational (basis for Phase 4 DirtyFlagManager)
- Baseline frame profiling infrastructure in place

---

## [1.0.0] - 2025-01-01 (Baseline)

### Added
- Initial SimpleUnitFrames addon release
- Core unit frame system (Player, Target, Pet, Focus, ToT, Party, Raid, Boss)
- oUF integration and customization
- Ace3 configuration framework
- Basic performance monitoring
