## Current Priorities
- Validate all code changes against current WoW API/runtime constraints before shipping.
- Keep Lua 5.1 compatibility and avoid unsupported language features.
- Maintain combat-lockdown-safe frame updates via protected operation queues.
- Add/update regression checks for unit frames, castbar, auras, and options UI after major refactors.

# SUF QUI Integration Implementation Checklist

## Phase 1 - Should Implement (High Value)

### 1. Custom Trackers UX Polish
- [ ] Add entries search/filter box in Custom Trackers -> Entries.
- [ ] Add duplicate entry highlighting and duplicate warning copy.
- [ ] Add bulk actions: clear all entries, remove duplicates, sort by name, sort by ID.
- [ ] Add per-bar "Reset to defaults" action (bar settings only, not global DB).
- [ ] Add optional "Show source type badge" (spell/item) next to each entry row.
- [ ] Add "Lock edit mode" toggle to prevent accidental tracker edits.

### 2. Profile Parity + Migration Safety
- [ ] Extend import/export validation for custom tracker fields and new options.
- [ ] Add import preview diff summary (what changes before apply).
- [ ] Add import scope options: all settings, module-only, unit-only.
- [ ] Add migration pass for legacy/customTrackers edge cases on load.
- [ ] Add user-facing migration/report messages in options debug/report area.

### 3. Visibility State Editor
- [ ] Create shared condition model for visibility (combat, target exists, instance, role, spec).
- [ ] Add reusable visibility presets for Trackers/Fader/Aura-related modules.
- [ ] Add options UI for building and saving visibility conditions.
- [ ] Add fallback behavior when invalid/empty rule sets are detected.

### 4. Performance Presets by Gameplay Context
- [ ] Add one-click presets: Raid, Mythic+, Open World, Arena.
- [ ] Include event coalescing + dirty update tuning bundles per preset.
- [ ] Add "Show changed settings" preview before applying preset.
- [ ] Add "Restore previous preset" rollback action.

## Phase 2 - Maybe Implement (Needs Validation)

### 5. Tracker Rule Engine
- [ ] Evaluate design for auto-routing learned spells/items by class/spec/category.
- [ ] Prototype low-risk rule matchers (class + spec only).
- [ ] Validate runtime/performance overhead before enabling by default.

### 6. Advanced Cooldown Text Formatting
- [ ] Add per-bar countdown formatting options (thresholds/decimals/compact).
- [ ] Add safety guards for locale and secret-value handling.
- [ ] Validate readability against existing duration text styling.

### 7. Anchor Graph Editor
- [ ] Prototype visual anchor map for tracker bars to SUF frames.
- [ ] Validate UX complexity vs maintenance cost.
- [ ] Decide go/no-go after prototype feedback.

### 8. Contextual Option Unlocking
- [ ] Dynamically hide/show advanced options based on mode/features.
- [ ] Ensure discoverability with hints/tooltips for hidden sections.
- [ ] Validate no regression in current OptionsV2 page rendering.

## Phase 3 - Skip / Out of Scope
- [ ] Do not pursue full QUI visual parity; maintain SUF design language.
- [ ] Do not add hard dependencies on non-SUF QUI ecosystem modules.
- [ ] Do not implement automation that risks protected-frame/taint regressions in combat.

## Delivery Order (When Work Starts)
- [ ] Milestone A: Finish Custom Trackers UX polish + bulk actions.
- [ ] Milestone B: Add gameplay performance presets + diff/rollback.
- [ ] Milestone C: Build shared visibility state editor + presets.
- [ ] Milestone D: Re-evaluate rule engine/advanced options based on usage feedback.

## Global Done Criteria
- [ ] `/reload` clean with no Lua errors/warnings.
- [ ] No taint/protected call regressions in combat scenarios.
- [ ] Options changes apply live and persist after relog.
- [ ] Existing unit frame/castbar/aura behaviors remain stable.
- [ ] Syntax check (`luac -p`) passes for all touched Lua files.
