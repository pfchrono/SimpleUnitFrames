# SimpleUnitFrames v1.33.0

This release ships the validated DataText enhancement track together with the first validated low-risk non-unit event coalescer rollout.

## Highlights

- DataText layouts now support validated 3-slot, 5-slot, and 7-slot configurations.
- DataText LDB integration now supports per-slot display modes, tooltip fallback rendering, hover refresh, and click dispatch parity with common broker displays.
- `Currencies`, `Reputation`, `Spec`, and `LootSpec` provider paths have been hardened and validated, with parity between datatext and databar presentation.
- The low-risk coalescer pilot is included in this release:
  - shared `SPELL_UPDATE_COOLDOWN` + `SPELL_UPDATE_CHARGES` bucket
  - debounced `BAG_UPDATE` bucket
  - `/suf coalescer` and `/suf coalescer reset` diagnostics

## Validation Summary

- DataText Step 3, Step 5, Step 5b, and Step 5c all passed in-game validation.
- Low-risk coalescer pilot validated in dungeon gameplay:
  - `SPELL_UPDATE_COOLDOWN+SPELL_UPDATE_CHARGES 6002 -> 2700` (~55.0% reduction)
  - `BAG_UPDATE 38 -> 21` (~44.7% reduction)
- CustomTracker bars remained correct for cooldown, charges, and bag-driven updates during validation.

## User-Facing Changes

- 7-slot DataText support with `outerLeft` and `outerRight` slots
- Per-slot LDB display modes: `AUTO`, `TEXT`, `ICON`, `ICON_TEXT`
- Full-width DataText panel clamping with 40px default panel height
- Better LDB tooltip fallback and live hovered-source refresh
- Improved Spec/LootSpec display stability
- Better currency/reputation tooltip detail and databar parity

## Notes

- This release includes the validated low-risk coalescer work.
- Broader coalescer expansion to additional non-unit buckets is deferred to follow-up work.