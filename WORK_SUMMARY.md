# Work Summary

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
