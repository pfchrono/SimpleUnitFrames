# SUF Developer Notes

## Safe Extension Rules

- Do not mutate secure frame attributes during combat (`InCombatLockdown()` checks are required).
- Use scheduling helpers instead of direct bulk refresh where possible:
  - `ScheduleUpdateAll()`
  - `ScheduleUpdateUnitType(unitType)`
  - `SchedulePluginUpdate([unitType])`
- Plugin updates are coalesced; prefer queueing over immediate repeated re-apply calls.

## Options UI

- Prefer helper-driven controls via the internal option spec renderer.
- Register searchable labels/keywords through existing builder methods to keep search index quality high.
- Keep tab sections aligned with the normalized unit model:
  - `General`, `Bars`, `Castbar`, `Auras`, `Plugins`, `Advanced`

## Import Pipeline

- Use:
  - `ValidateImportedProfileData(data)`
  - `BuildImportedProfilePreview(data[, report])`
  - `ApplyImportedProfile(data)`
- `ApplyImportedProfile` is transactional with rollback semantics. New apply paths should preserve this behavior.

## Diagnostics

- Gate verbose diagnostics through debug settings (`/sufdebug` systems filters).
- Performance dashboard commands: `/sufperf` (primary) and `/libperf` (alias).
- When adding windows, use theme sync path so active Options V2 preset is reflected (`SyncThemeFromOptionsV2` + SUF skin helpers).
- Avoid unconditional spam in hot paths (events, plugin flush, frame updates).

## Extension Checklist

- Confirm combat-safe behavior.
- Confirm options-driven changes rebuild/update through scheduled paths.
- Confirm import/export compatibility with defaults merge and profile normalization.
- Confirm no hard dependency is introduced for optional libraries.
