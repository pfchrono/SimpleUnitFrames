# SUF General Integration TODO

## Engineering Rule
- [x] Keep third-party library files stock when possible; implement SUF-specific behavior through base addon overrides/adapters (for example, `SimpleUnitFrames.lua` health overrides) to avoid author-library drift.
- [ ] Validate all code changes against the current WoW API first (Widget/API docs and runtime constraints) before finalizing implementation.
- [ ] If local WoW API references are out of date, run a git update (`git fetch`/`git pull`) to refresh tracked API references, then continue implementation/review.
- [ ] Use available local skills for code decisions, planning, and major overhauls/improvements when the task matches a skill scope.
- [ ] Keep Lua calls/functions compatible with Lua 5.1 and WoW API/runtime behavior (no unsupported language features).

## QUI Audit + Port Plan
- [x] Set canonical QUI upstream to `https://github.com/zol-wow/QUI` (current: `v2.41.1`, commit `600522342b085ba1d7ecd5fad701c3c71ba738f5`).
- [x] Verified local QUI working copy at `D:\Games\World of Warcraft\_retail_\Interface\_Working\QUI` matches upstream content for core port-target files (actionbars/unitframes/castbar/auras/tooltips/schema).
- [x] Deep-audited QUI settings schema in `core/main.lua` for `tooltip`, `actionBars`, and `quiUnitFrames` (including target health direction behavior).
- [x] Extended function inventory audit across `modules/frames`, `modules/combat`, and `skinning/system` for concrete SUF port targets.
- [x] Created dedicated SUF import-track docs per feature (`ActionBars`, `Tooltips`, `Castbar`, `Auras`) under `docs/QUI_PORT/`.
- [ ] Gate every QUI-derived port behind SUF config toggles and combat-safe checks (no raw copy into core file).
- [ ] On each new QUI tag/release, run targeted delta audit before merging new port slices into SUF.

### Phase 1 Readiness Gate (Planning)
- [x] ActionBars import-track finalized: `docs/QUI_PORT/ActionBars.md`.
- [x] Tooltips import-track finalized: `docs/QUI_PORT/Tooltips.md`.
- [x] Castbar import-track finalized: `docs/QUI_PORT/Castbar.md`.
- [x] Auras import-track finalized: `docs/QUI_PORT/Auras.md`.
- [x] QUI schema migration fields for ActionBars/Tooltip mapped to SUF profile targets.
- [x] SUF integration touchpoints identified (`defaults`, `.toc`, `OnInitialize`, `OnEnable`, options/search wiring).
- [x] Combat-safe + Lua 5.1 constraints documented for Phase 1 implementation.
- [x] Phase 1 planning state: READY TO START IMPLEMENTATION.

### Phase 1: Actionbar System (Primary)
- [x] Build `Modules/ActionBars/Core.lua` (new SUF subsystem entrypoint and lifecycle hooks).
- [x] Build `Modules/ActionBars/Skinning.lua` (button skin/text/icon pipeline and per-bar overrides).
- [x] Build `Modules/ActionBars/Layout.lua` (bar scale, lock, hidden-empty-slot behavior, page-arrow visibility).
- [x] Build `Modules/ActionBars/Fade.lua` (mouseover/combat fade engine with linked-bar support).
- [x] Build `Modules/ActionBars/Extras.lua` (Extra Action Button + Zone Ability holders, movers, Edit Mode hooks).
- [x] Build `Modules/ActionBars/Bindings.lua` (LibKeyBound integration and Midnight-safe binding patch layer).
- [x] Wired `actionBars` defaults into `OnInitialize` and `InitializeActionBars` call into `OnEnable` in `SimpleUnitFrames.lua`.
- [x] Registered all 6 ActionBars module files in `SimpleUnitFrames.toc` load order.
- [ ] Add options under SUF Actionbar UI for Actionbar styles/fading/visibility and profile persistence.

### Phase 2: Castbar + Aura Design Imports
- [ ] Import castbar channel-tick and empower visuals as optional enhancements (player/target/focus/boss).
- [ ] Import aura icon styling/anchor behaviors as opt-in profile presets (without replacing SUF native aura pipeline).

### Phase 3: UI/UX Systems
- [ ] Import tooltip skin framework as a standalone optional skin module (font scaling, health bar visibility, dynamic border/color).
- [ ] Import viewer/icon skinning concepts for consistent icon borders/gloss/count text across SUF debug/options/data windows.
- [ ] Import combat/QoL widgets selectively (only low-taint, low-overhead pieces that complement SUF scope).

### Phase 4: Validation + Migration
- [ ] Add migration path for new Actionbar + UI skin profiles and safe defaults for existing SUF users.
- [ ] Add in-game regression checklist for Actionbar paging, keybind display, cooldown text, fades, and extra-button movers.
- [ ] Add combat lockdown tests for all secure frame mutations (layout, visibility, bindings, mover saves).

### QUI Settings Schema Migration Checklist (QUI -> SUF)
- [ ] Map `profile.actionBars.global` fields to SUF `db.profile.actionBars.global` (skin, text, layout, usability/range, tooltip).
- [ ] Map `profile.actionBars.fade` fields to SUF `db.profile.actionBars.fade` (durations, alpha, delay, combat/max-level/linking behavior).
- [ ] Map `profile.actionBars.bars.bar1..bar8` per-bar overrides (enabled, fade override, alwaysShow, text offsets, style overrides).
- [ ] Map `profile.actionBars.bars.extraActionButton` and `profile.actionBars.bars.zoneAbility` (scale, artwork hide, position, fadeEnabled).
- [ ] Map `profile.tooltip` controls to a standalone SUF tooltip-skin profile block (anchor/cursor, combat hiding, border/font/healthbar rules).
- [ ] Map selected `profile.quiUnitFrames.general` and per-unit visual fields only where SUF has direct equivalents (no destructive override).
- [ ] Add explicit migration step for `target.invertHealthDirection` to SUF target health fill-direction setting.

### QUI Feature Parity Matrix (Audit Result)
| Feature | QUI Source | SUF Target | Port Status | Notes |
|---|---|---|---|---|
| Actionbar skin/layout/fade | `modules/frames/actionbars.lua` | `Modules/ActionBars/*` | **Implemented** | In-game acceptance testing pending |
| Extra/Zone action button movers | `modules/frames/actionbars.lua` | `Modules/ActionBars/Extras.lua` | **Implemented** | In-game acceptance testing pending |
| Actionbar keybind patching | `modules/frames/actionbars.lua` | `Modules/ActionBars/Bindings.lua` | **Implemented** | In-game acceptance testing pending |
| Castbar channel ticks/empower visuals | `modules/frames/castbar.lua` | Existing SUF castbar + module helpers | Partial | SUF already has enhancements; import deltas only |
| Aura icon/bar styling behaviors | `modules/frames/unitframe_auras.lua`, `modules/frames/buffbar.lua` | Existing SUF aura pipeline | Partial | Preserve native SUF/oUF architecture |
| Target health direction logic | `modules/frames/unitframes.lua` | SUF target health bar updater | Planned | Explicitly map invert/deplete direction settings |
| Tooltip skin system | `skinning/system/tooltips.lua` | New optional SUF tooltip skin module | Planned | Keep independent from frame logic |
| Viewer icon skinning | `core/viewer_skinning.lua`, `modules/cooldowns/effects.lua` | Shared SUF icon-skin helpers | Candidate | Good cross-window visual consistency |
| Combat text widget | `modules/combat/combattext.lua` | Optional SUF QoL module | Candidate | Low risk, lower priority than actionbars |
| Rotation assist logic | `modules/combat/rotationassist.lua` | N/A (defer) | Deferred | Out of scope for SUF core role |
| Game menu skin/injection | `skinning/system/gamemenu.lua` | N/A (defer) | Deferred | Cosmetic but outside SUF core mission |

### QUI Components To Defer / Do Not Port (Current Scope)
- [ ] Do port rotation recommendation pipeline from `modules/combat/rotationassist.lua` into SUF core.
- [ ] Do port Game Menu injection path (`InjectQUIButton`) into SUF core.
- [ ] Do port full QUI global dark-mode state model as a hard dependency for SUF frame rendering.
- [ ] Do port combat-unsafe direct secure-frame mutations; keep all secure changes behind SUF protected queue wrappers.

## QUI Source Function Map (Port Targets)
- [x] `modules/frames/actionbars.lua` -> port targets:
`AddKeybindMethods`, `PatchLibKeyBoundForMidnight`, `GetEffectiveSettings`, `GetBarButtons`, `CreateExtraButtonHolder`, `ApplyExtraButtonSettings`, `InitializeExtraButtons`, `SkinButton`, `UpdateKeybindText`, `UpdateMacroText`, `UpdateCountText`, `ApplyButtonLock`, `UpdateButtonUsability`, `UpdateUsabilityPolling`, `ApplyBarLayoutSettings`, `StartBarFade`, `SetupBarMouseover`, `ActionBars:Refresh`, `ActionBars:Initialize`, `SetupEditModeHooks`. (All ported to `Modules/ActionBars/` in 6 files; in-game acceptance testing pending.)
- [ ] `modules/frames/unitframes.lua` -> port targets:
`GetHealthPct`, `GetPowerPct`, `IsTargetHealthDirectionInverted`, `ApplyHealthFillDirection`, `UpdateHealth`, `UpdateAbsorbs`, `UpdateHealPrediction`, `UpdatePower`, `UpdateIndicators`, `UpdateTargetMarker`, `CreateUnitFrame`, `CreateCastbar`, `QUI_UF:RefreshAll`.
- [ ] `modules/frames/unitframe_editmode.lua` -> port targets:
`QUI_UF:RegisterEditModeSliders`, `QUI_UF:NotifyPositionChanged`, `QUI_UF:EnableEditMode`, `QUI_UF:DisableEditMode`, `QUI_UF:HookBlizzardEditMode`.
- [ ] `modules/frames/castbar.lua` -> port targets:
`InitializeDefaultSettings`, `NormalizeChannelTickSpellID`, `ResolveChannelTickModel`, `ApplyChannelTickPositions`, `UpdateChannelTicksForCurrentCast`, `UpdateEmpoweredStages`, `UpdateEmpoweredFillColor`, `SetupCastbar`, `RefreshCastbar`, `EnableCastbarEditMode`.
- [ ] `modules/frames/unitframe_auras.lua` -> port targets:
`ApplyAuraIconSettings`, `GetAuraIcon`, `UpdateAuras`, `SetupAuraTracking`, `ShowAuraPreviewForFrame`, `HideAuraPreviewForFrame`.
- [ ] `modules/frames/buffbar.lua` -> port targets:
`ApplyTrackedBarAnchor`, `ApplyBuffIconAnchor`, `ApplyIconStyle`, `ApplyBarStyle`, `CheckIconChanges`, `CheckBarChanges`, `ForcePopulateBuffIcons`.
- [ ] `modules/frames/resourcebars.lua` -> port targets:
`UpdatePowerBar`, `UpdatePowerBarTicks`, `UpdateSecondaryPowerBar`, `CreateFragmentedPowerBars`, `UpdateFragmentedPowerDisplay`, `EnablePowerBarEditMode`.
- [ ] `modules/qol/actiontracker.lua` -> port targets:
`RefreshActionBarSpellCache`, `BuildDisplayEntries`, `CreateTrackerFrame`, `RefreshAppearance`, `RefreshVisibility`, `AddSpellToHistory`, `ResolveCastToSucceeded`, `ResolveCastToFailed`.
- [ ] `modules/cooldowns/effects.lua` + `core/viewer_skinning.lua` -> port targets:
`HideBlizzardGlows`, `ProcessViewer`, `ApplyToAllViewers`, `SkinIcon`, `ApplyViewerLayout`, `RescanViewer`, `ForceReskinAllViewers`.
- [ ] `modules/combat/combattext.lua` -> port targets:
`CreateTextFrame`, `ShowCombatText`, `StartFade`, `RefreshCombatText`.
- [ ] `modules/combat/rotationassist.lua` -> study-only targets (deferred):
`GetKeybindForSpell`, `ReadSpellCooldown`, `UpdateGCDCooldown`, `DoUpdate`, `RefreshRotationAssistIcon`.
- [ ] `skinning/system/tooltips.lua` -> port targets:
`SkinTooltip`, `UpdateTooltipColors`, `ReskinTooltip`, `ApplyTooltipFontSizeToFrame`, `SetupTooltipPostProcessor`, `SetupHealthBarHook`.
- [ ] `skinning/system/gamemenu.lua` -> port targets:
`StyleButton`, `HideBlizzardDecorations`, `CreateDimFrame`, `SkinGameMenu`, `RefreshGameMenuColors`, `InjectQUIButton`.

## In-Game Regression Checklist (Health/Auras High-Risk Pass)
- [ ] Reload cleanly: `/reload` with no Lua errors from `health.lua` or `auras.lua`.
- [ ] Health bars update correctly for player/target/party/raid under damage/heal without stalling or jump loops.
- [ ] NPC frames never show disconnected fallback health when NPC is alive/connected.
- [ ] Player disconnect test: player-unit style frames correctly switch to disconnected coloring fallback.
- [ ] Incoming heals/absorbs: `HealingAll`, `HealingPlayer`, `HealingOther`, `DamageAbsorb`, `HealAbsorb` bars track expected values.
- [ ] Temp health loss (if enabled): bar updates on max-health modifier changes.
- [ ] Aura full refresh: target changes and zone transitions rebuild auras without missing buttons or stale icons.
- [ ] Aura incremental updates: rapid aura add/update/remove (combat burst) produces no nil-index errors and no ghost buttons.
- [ ] Auras with custom `PostProcessAuraData` returning nil are safely ignored (no script errors).
- [ ] Aura sorting modes (`DEFAULT`, `TIME_REMAINING`, `NAME`, `ASC/DESC`) apply correctly for `Auras`, `Buffs`, and `Debuffs`.
- [ ] Aura filters (`onlyShowPlayer`, custom filter callbacks) still gate display as configured.
- [ ] Gap button mode (`Auras.gap`) still inserts separator safely and does not corrupt button indexing.
- [ ] Performance sanity: in a raid/combat scenario, no visible FPS hitching spike tied to `UNIT_AURA` churn.
- [ ] Edit mode/options changes triggering force updates still re-anchor created aura buttons correctly.

## Next Split Candidate
- [x] Move debug UI construction out of `SimpleUnitFrames.lua` into `Modules/UI/DebugWindow.lua` to further reduce core-file size and isolate debug-window responsibilities.
