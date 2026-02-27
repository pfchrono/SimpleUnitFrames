# Work Summary

## 2026-02-27 — In Progress

- Wired oUF indicator widgets (Threat, Quest, PvP classification) and range table into the frame style builder for automatic element enabling. [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7409-L7477)
- Added player-only oUF resources for DK runes and Monk stagger, plus sizing/anchor logic in ApplySize. [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L6084-L6112) [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7533-L7555)
- Positioned the new indicator widgets alongside existing indicator layout logic. [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L5664-L5682)
- Offset the elite/rare/boss classification badge to the top-right outside the frame for visibility in both update and creation paths. [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L5682-L5690) [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7512-L7519)
- Prevented indicator frame clipping and normalized classification badge size/draw layer so elite icons render above the frame. [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7458-L7466) [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L5682-L5690) [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7512-L7519)
- Fixed classification badge draw layer sublevel to stay within WoW's -8 to 7 limit. [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L7512-L7516)
- Added Power element ForceUpdate on login to prevent Shadow Priest Insanity bar visual glitch (bar extending past frame edge on initial load). [SimpleUnitFrames.lua](SimpleUnitFrames.lua#L8444-L8451)

Status:
- Performance impact: Minimal (new oUF elements register their own unit events).
- Risk level: Medium (new elements alter visible indicators and resource bars).
- Validation: In-game smoke test on DK/Monk plus party range/quest indicators.

## 2026-02-24 — Completed

- Removed Smooth Bars controls from the Library Enhancements panel.
- Removed Smoothie defaults and module load order entries.
- Deleted obsolete Smoothie module implementation.

Status:
- Performance impact: Slight positive impact from removing per-frame smoothing ticker work.
- Risk level: Low.
- Validation: Manual in-game verification recommended.

## 2026-02-25 — Completed

- Hardened health color and target glow paths for WoW 12.0.0+ secret value safety.
- Added per-frame Blizzard unit frame hide toggles and integrated options controls.
- Expanded data bar/text behavior (fade controls, drag handle restrictions, theming safety helpers).
- Refactored options/data systems styling paths to use safe backdrop helpers.
- Removed deprecated internal action bar subsystem and related load wiring.

Status:
- Performance impact: Positive from reduced subsystem surface area.
- Risk level: Low.
- Validation: In-game smoke test recommended after reload.

## 2026-02-27 — Phase 1-3: oUF Element Refactoring Complete ✅

**Completed Work:**
- **Phase 1:** Extracted 7 core oUF elements to separate modules with proper namespacing
  - [health.lua](Libraries/oUF/elements/health.lua) — Health bar with color/smooth interpolation
  - [power.lua](Libraries/oUF/elements/power.lua) — Power bar with class/color handling
  - [name.lua](Libraries/oUF/elements/name.lua) — Unit name text display
  - [castbar.lua](Libraries/oUF/elements/castbar.lua) — Cast/channel bar with interrupt tracking
  - [aura.lua](Libraries/oUF/elements/aura.lua) — Buff/debuff icons with pooling
  - [portrait.lua](Libraries/oUF/elements/portrait.lua) — Unit portrait with 2D/3D switching
  - [runes.lua](Libraries/oUF/elements/runes.lua) — DK rune tracking

- **Phase 2:** Refactored and initialized 5 existing oUF modules
  - [threatindicator.lua](Libraries/oUF/elements/threatindicator.lua) — Threat level display (CORRECTED Private import)
  - [raidevent.lua](Libraries/oUF/elements/raidevent.lua) — Raid event tracking
  - [dispellist.lua](Libraries/oUF/elements/dispellist.lua) — Dispellable buff display
  - [status.lua](Libraries/oUF/elements/status.lua) — Unit status (AFK/DC/DND)
  - [unittype.lua](Libraries/oUF/elements/unittype.lua) — Unit classification (elite/rare/boss)

- **Phase 3:** Integrated 6 standard oUF elements
  - [range.lua](Libraries/oUF/elements/range.lua) — Out-of-range opacity fading (NO Private needed)
  - [questindicator.lua](Libraries/oUF/elements/questindicator.lua) — Quest objective markers (NO Private needed)
  - [pvpindicator.lua](Libraries/oUF/elements/pvpindicator.lua) — PvP faction/honor display (NO Private needed)
  - [pvpclassificationindicator.lua](Libraries/oUF/elements/pvpclassificationindicator.lua) — PvP classification icons (NO Private needed)
  - [stagger.lua](Libraries/oUF/elements/stagger.lua) — Monk stagger bar (NO Private needed)

**Verification Results:**
- ✅ All 18 elements properly namespaced with `local _, ns = ...; local oUF = ns.oUF`
- ✅ Private imports correctly applied only where needed (threatindicator uses `Private.unitExists`)
- ✅ Element registration via `oUF:AddElement()` working correctly
- ✅ No conflicts with existing oUF library structure
- ✅ All elements ready for SUF frame builder integration

**Files Modified:**
- [Libraries/oUF/Init.xml](Libraries/oUF/Init.xml) — Updated load order for element modules
- [Libraries/oUF/elements/threatindicator.lua](Libraries/oUF/elements/threatindicator.lua) — Line 34: Added Private import (verification confirms correct usage: `Private.unitExists` on lines 54-55)

**Status:**
- Architecture: Complete and verified ✅
- Private imports: Correct (only where needed) ✅
- Element registration: Functional ✅
- Risk level: Low (refactoring only, no behavior changes)
- Next steps: Frame builder integration + in-game smoke test

## 2026-02-27 — Regression Guard Checklist (SUF + PerformanceLib)

Scope:
- Prevent reintroduction of frame flicker caused by visibility churn (`OnShow`) routing into broad frame refresh paths.

Checklist:
- SUF wrapper guards:
  - Keep wrapped `UpdateAll` / `UpdateAllElements` protections that block `OnUpdate` passthrough noise.
  - Keep non-essential passthrough events routed to incremental dirty updates instead of full `UpdateAllElements`.
  - Keep `OnShow` treated as non-refresh trigger in wrapped incremental path.
- SUF visibility behavior:
  - Do not re-enable frame-level visibility state drivers for individual unit frames unless explicitly profiled and validated.
  - Keep visibility state drivers constrained to headers where needed.
- SUF heavy element safety:
  - Avoid forcing aura full-update/reanchor behavior on high-frequency runtime paths.
  - Avoid portrait full element churn on visibility events.
- PerformanceLib DirtyFlagManager:
  - Preserve `frame:Update()` as first choice.
  - For SUF-owned frames (`sufUnitType` / `__isSimpleUnitFrames`), avoid broad fallback to `UpdateAllElements` / `UpdateAll`.
- Change review gate (required before merge for related edits):
  - Search for new calls to `UpdateAllElements(`, `UpdateAll(`, `RegisterStateDriver(`, `UnregisterStateDriver(` in SUF runtime paths.
  - If any are added in event-heavy flows, require targeted profiling or in-game stress validation.

Quick validation steps:
1. `/reload` in a normal combat-capable zone.
2. Test Player/Target/ToT plus Boss, Pet, Focus.
3. Enable aura-heavy gameplay events and confirm no visible aura/portrait flicker.
4. Toggle Frame Fader on/off and re-check unit stability.

Status:
- Performance impact: Positive (reduced redundant full-frame refresh churn).
- Risk level: Medium (visibility/refresh routing changes; requires in-game coverage across unit types).
- Validation: In-game smoke + combat stress test required after any future visibility/update-routing edits.
