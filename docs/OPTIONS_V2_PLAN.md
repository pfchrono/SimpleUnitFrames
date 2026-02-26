# SUF OptionsV2 Plan

## 1) Goals
- Replace the current `/suf` options UI with a maintainable, theme-first GUI.
- Preserve all existing configuration capability with clearer navigation and better discoverability.
- Keep the system robust in combat-lockdown-sensitive environments (no protected operations from options UI).
- Support SUF banner styling with configurable button, background, border, and text theming.

## 2) Non-Goals (Phase 1)
- No broad rewrite of runtime frame logic (`Units/`, render/update pipeline).
- No hard dependency on external addon UIs (QUI as dependency is out).
- No forced migration of saved variables schema in first cut.

## 3) Library Strategy
- `Ace3`:
  - Keep `AceAddon`, `AceDB`, existing Ace libs already in project.
  - Use `AceGUI-3.0` selectively for stable controls where it reduces boilerplate.
- `LibSharedMedia-3.0`:
  - Primary source for fonts/statusbars/backgrounds.
- Native WoW widgets:
  - Use `ScrollFrame`/`UIPanelScrollFrameTemplate` and plain `CreateFrame` for high-control layout regions.
- `QUI`:
  - Treat as visual inspiration only, not a runtime dependency.

## 4) Target Architecture
- `Modules/UI/OptionsV2/Theme.lua`
  - Design tokens and style application helpers (`ApplyPanelStyle`, `ApplyButtonStyle`, `ApplyBorderStyle`).
- `Modules/UI/OptionsV2/Layout.lua`
  - Window shell, header, left navigation tree, right content panel, footer actions.
- `Modules/UI/OptionsV2/Registry.lua`
  - Declarative registration of pages/sections/controls.
- `Modules/UI/OptionsV2/Renderer.lua`
  - Renders controls from registry definitions and binds get/set callbacks to DB.
- `Modules/UI/OptionsV2/Search.lua`
  - Indexes labels/help text/keywords and routes to pages.
- `Modules/UI/OptionsV2/Bootstrap.lua`
  - Public entrypoint (`addon:ShowOptionsV2()`), feature-flag gating, fallback to legacy UI.

## 5) UX Design Baseline
- Left navigation:
  - Collapsible groups (`General`, `Units`, `Plugins`, `Advanced`), always scrollable.
- Right content:
  - Section cards with clear titles, short descriptions, and aligned controls.
- Header:
  - SUF banner, global search, profile indicator, quick actions (`Test Mode`, `Reset Unit`, `Import/Export`).
- Theming:
  - Tokenized colors for `bg`, `panel`, `accent`, `button`, `border`, `text`.
  - Support intensity/contrast presets (`Classic`, `Soft`, `High Contrast`).

## 6) Theming Model (DB)
- Add `db.profile.optionsUIV2.theme`:
  - `preset` (`classic|soft|high_contrast|custom`)
  - `colors`:
    - `windowBg`, `panelBg`, `panelBorder`, `buttonBg`, `buttonHover`, `buttonActive`, `text`, `textMuted`, `accent`
  - `media`:
    - `font`, `statusbar`, `background`
  - `border`:
    - `style`, `size`, `inset`

## 7) Migration Plan
- Phase 0: Scaffold only
  - Add `OptionsV2` modules and a slash switch (`/suf ui v2`).
  - Keep legacy `/suf` behavior default.
- Phase 1: Global pages parity
  - Implement `Global`, `Performance`, `Import/Export`, `Tags`, `Credits`.
- Phase 2: Unit pages parity
  - `Player/Target/TOT/Focus/Pet/Party/Raid/Boss` with sub-sections.
- Phase 3: Theming editor
  - Live preview for button/background/border tokens; reset-to-preset flow.
- Phase 4: Cutover
  - Make V2 default, keep legacy behind `/suf ui legacy` for one release cycle.

## 8) Implementation Milestones
- M1: Shell + Nav + Scroll + Empty pages
  - Acceptance: Stable open/close/resize; nav scroll always works; no Lua errors.
- M2: Registry + Renderer
  - Acceptance: Declarative page registration renders labels/toggles/sliders/dropdowns.
- M3: Theme tokens + skin helpers
  - Acceptance: Changing theme updates all controls in current frame.
- M4: Data binding + parity
  - Acceptance: All existing options can be modified and persisted.
- M5: Search + keyboard navigation
  - Acceptance: Relevant page jumps and focus behavior are reliable.

## 9) Risk Controls
- Feature flag:
  - `db.profile.optionsUIV2.enabled` to safely switch between legacy and V2.
- Combat safety:
  - UI writes only DB/state values and queues any protected operations via existing safe pathways.
- Regression safety:
  - Keep legacy options callable until parity checklist is complete.

## 10) Current Status
- `OptionsV2` shell/nav/scroll/section-tabs implemented and active.
- `/suf` now opens V2 by default (legacy remains accessible via `/suf ui legacy`).
- Search is wired in header and can jump to specific page sections.
- Core parity pages are implemented: `Global`, `Performance`, `Import / Export`, `Tags`, unit pages, `Credits`.
- Media dropdowns support texture previews for statusbar/background selections.
- Active V2 preset now propagates to debug/performance support windows.

## 11) Finalization Checklist
- Full in-game parity audit against remaining legacy behaviors.
- Combat-lockdown interaction validation for all controls.
- UI polish pass (focus cues, spacing, tab affordances, validation copy).
- Documentation pass (`README` and user commands/help text examples).
