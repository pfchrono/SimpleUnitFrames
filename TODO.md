# SUF Modernization TODO

## Phase A: Options Framework Core
- [x] Build SUF option factory helpers (ACH-style wrappers for Label, Check, Slider, Dropdown, Color, Button, Edit).
- [x] Standardize control ordering, widths, spacing, and disabled/hidden handling.
- [x] Migrate Global tab to helper-driven rendering first.

## Phase B: Search Engine v2
- [x] Build recursive options search index cache (labels, values, aliases).
- [x] Add grouped search results with jump links.
- [x] Add cache invalidation only when schema changes.

## Phase C: Unit Tab Modernization
- [x] Split all unit tabs into General, Bars, Castbar, Auras, Plugins, Advanced.
- [x] Normalize section ordering across all units.
- [x] Persist collapse states.
- [x] Adopt NaowhQOL-inspired grouped sidebar (menu/submenu layout + collapsible groups).
- [x] Apply NaowhQOL-inspired visual polish pass (spacing, typography, accents, state colors) across full options UI.

## Phase D: Module Copy/Reset Service
- [x] Extract module copy/reset logic into a reusable service.
- [x] Add dry-run preview for key changes.
- [x] Add optional apply confirmation.

## Phase E: Aura Filter UX Upgrade
- [x] Replace remaining freeform behaviors with managed list workflows.
- [x] Add priority ordering UX improvements.
- [x] Add filter presets and quick actions.

## Phase F: Import/Installer Robustness
- [x] Expand import wizard to validate -> preview -> apply -> rollback on failure.
- [x] Add API-first import adapters + copy fallback.
- [x] Add consolidated reload-required summary prompt.

## Phase G: Performance/Taint Hardening
- [x] Audit combat-safe paths for options, fader, and plugin update flows.
- [x] Add throttles and redundant-update guards where appropriate.
- [x] Gate verbose diagnostics behind debug toggles.

## Phase H: UX Polish + Navigation
- [x] Improve search relevance scoring and optional result counts.
- [x] Add keyboard-friendly search/jump interactions.
- [x] Improve dense-page visual hierarchy.

## Phase I: Docs + Migration Notes
- [x] Update README for options/search/import architecture changes.
- [x] Add migration notes for existing users.
- [x] Add developer notes for safe extension.

## Reference-Inspired Backlog (UUF/ElvUI/OakUI)
- [x] Add step-based installer flow for major migrations (queue + progress + pending indicator + step titles). Reference: `UnhaltedUnitFrames/FEATURES.md`, `ElvUI/Game/Shared/General/PluginInstaller.lua`.
- [x] Add SUF status report panel (loaded plugin summary, build/runtime context, diagnostics snapshot). Reference: `ElvUI/Game/Shared/General/StatusReport.lua`.
- [x] Expand aura filtering controls with draggable priority ordering and special-vs-regular filter grouping. Reference: `ElvUI_Options/Game/Shared/UnitFrames.lua`, `ElvUI_Options/Game/Shared/Auras.lua`.
- [x] Add unit-frame testing helpers (force-show frames, display test state, quick reset/copy actions) for each unit/group type. Reference: `ElvUI_Options/Game/Shared/UnitFrames.lua`.
- [x] Harden import/install pipeline to API-first apply with manual copy fallback and reload prompts. Reference: `OakUI_Installer/Core.lua`.
- [x] Continue performance-safe event handling patterns (queue accepted/fallback + scoped coalescing + pooled indicator widgets). Reference: `UnhaltedUnitFrames/FEATURES_SUMMARY.md`, `UnhaltedUnitFrames/FEATURES.md`.
