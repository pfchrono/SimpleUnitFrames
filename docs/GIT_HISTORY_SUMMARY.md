# Git History Summary

This document condenses the major repository milestones from the first commit through the current `v1.33.1` release so future work can start from the existing architectural context instead of reconstructing it from raw git history.

## Timeline

### 2026-02-22 to 2026-02-23 — Foundation and Runtime Modernization
- `0349d18` imported Ace3, oUF, supporting libraries, and addon assets.
- `cb50eca` added castbar configuration and early castbar enhancements.
- `ac73c47` overhauled config/debug UX and integrated performance tooling.
- `7b2919a` modernized runtime behavior, synced framework pieces to newer oUF patterns, and hardened safer execution paths.
- `8eb4820` added class resource auditing and commands.
- `a61dfd0` improved oUF plugin compatibility and refreshed contributor-facing docs.

### 2026-02-24 to 2026-02-26 — UI Systems, Protected Operations, and Security Hardening
- `23d5df0` hardened frame fader behavior.
- `c161346` fixed ProtectedOperations early initialization and solo-party tooltip display regressions.
- `5802b02` removed the Action Bars subsystem after secure-frame/taint constraints made the old approach unsafe in WoW 12.0.0+, while also improving Blizzard XP/Reputation fade controls and safe-value handling.
- `ac95af6` introduced OptionsV2 search and theming support.
- `1702c4a` expanded CustomTrackers with auto-learn, inline actions, and stability/performance fixes.
- `49a3563` improved Blizzard skinning and import/export readability.

### 2026-02-27 to 2026-03-03 — oUF Event Model and Performance Architecture
- `a039dce`, `6ec7f6c`, and `787a1ba` migrated oUF elements toward unit-scoped registration and then SmartRegisterUnitEvent-based filtering.
- `fd5cb72` added mixin-based component architecture for unit frames.
- `a177701` fixed absorb/secret handling edge cases.
- `c561e50` introduced IndicatorPoolManager across multiple indicator types.
- `09d2d35` fixed party tags not updating until combat.
- `02b6529` and `86f2088` established SmartRegisterUnitEvent as a core performance primitive for 30-50% event filtering gains.
- `0fc5250` completed ColorCurve integration and LibQTip rollout.
- `7f21061` integrated DirtyFlagManager batching.
- `9ea43d4` added SafeReload for combat-safe reload workflows.
- `864db87` synced recent upstream oUF connection fixes and resolved solo-party visibility issues.

### 2026-03-04 to 2026-03-05 — Validation, Layout, and Phase 4 Expansion
- `8c7f3f7` added ProfileValidator for import-tree validation.
- `b1e0894` implemented pixel-perfect scaling.
- `edab41b` delivered a major Phase 4 update: castbars for all supported units, the OptionsV2 sidebar, and profile migration support.

### 2026-03-12 — DataText Enhancement Track, Low-Risk Coalescer Pilot, and Release 1.33.1
- `2944249` expanded DataText layouts and slot/display options, added the low-risk non-unit coalescer pilot and slash diagnostics, and introduced EditMode/TotemBar related system work.
- `1909d99` and `d95a117` finalized release preparation and synchronized release metadata for `v1.33.1`.
- Release `v1.33.1` shipped with validated DataText Step 3, Step 5, Step 5b, and Step 5c work plus the validated low-risk coalescer pilot.

## Major Features Added Over Time

- Protected operations queue for combat-safe deferred mutations.
- OptionsV2 search, theming, and sidebar navigation.
- SmartRegisterUnitEvent integration and DirtyFlagManager batching.
- IndicatorPoolManager and per-frame indicator instantiation fixes.
- ColorCurve secret-safe smooth health gradients.
- SafeReload and release automation scripts.
- Castbars for all major unit types with profile migration support.
- DataText/DataBar expansion:
  - upgraded `Currencies` and `Reputation` providers,
  - `Spec` and `LootSpec` providers,
  - 3-slot, 5-slot, and 7-slot layouts,
  - per-slot LDB display modes,
  - improved tooltip/click refresh behavior.
- Low-risk non-unit coalescer pilot for `SPELL_UPDATE_COOLDOWN` + `SPELL_UPDATE_CHARGES` and `BAG_UPDATE`.

## Repeated Issues and Their Resolutions

### Secret-Value and Midnight Restrictions
- Problem: direct boolean/arithmetic use of secret-returning APIs caused runtime failures and taint escalation.
- Resolution: standardize on `SafeNumber`, `SafeText`, `SafeAPICall`, `IsSecretValue`, ColorCurve, and Blizzard-native systems where possible.

### Secure-Frame / Action Bar Constraints
- Problem: the old action bar subsystem could not be made safe under WoW 12.0.0+ secure restrictions.
- Resolution: remove the subsystem rather than carry an unsafe implementation forward; future protected-frame work must use template inheritance and attribute-driven state.

### Party/Raid Castbar Initialization Failures
- Problem: castbars existed but did not reliably receive events after spawn.
- Resolution: do not manually register oUF element events in `Style()`, and use the spawn-time disable→enable rebind workaround for castbars until the underlying lifecycle timing issue is fully understood.

### Group Header Visibility and Solo-Party Edge Cases
- Problem: `/reload` and delve/follower contexts could leave group headers spawned but stale or hidden.
- Resolution: treat `oUF:Factory(...)` as async, apply visibility inside the callback, and re-register state drivers when cached visibility state is stale.

### Shared Indicator Texture/Frame Bugs
- Problem: cached textures/frames were reparented to the last frame and broke party/raid indicators.
- Resolution: create new indicator textures/frames per unit frame and never cache them across frames.

### Datatext Provider Crash and Layout Bleed
- Problem: `Spec`/`LootSpec` paths used missing APIs or wrong identifiers, and dense layouts could bleed text or duplicate tooltip rows.
- Resolution: use specialization index APIs plus `GetLootSpecialization()`, clear tooltip lines before rebuild, and constrain label width/word wrap by slot width.

### oUF Upstream Audit Status
- As of 2026-03-12, the bundled oUF copy already contains the recent upstream `13.3.1` fixes for portrait secret GUID handling, connection updates, private aura `ForceUpdate`, aura harmful detection, ready check script binding, PvP classification `pcall`, and AdditionalPower prediction support.
- Remaining drift from upstream is largely intentional SUF customization, especially around SmartRegisterUnitEvent and local UI behavior. Do not replace the bundled oUF tree wholesale without a targeted review.