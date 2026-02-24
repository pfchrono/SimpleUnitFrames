# SUF Migration Notes

## Options/Search Architecture

- Options rendering now uses shared factory-style builders to keep control ordering, spacing, and behavior consistent.
- Unit tabs are split into `General`, `Bars`, `Castbar`, `Auras`, `Plugins`, and `Advanced`.
- Search uses an indexed schema + control registry. Results are grouped by tab and scored by relevance.
- Search supports keyboard navigation: `Alt+Up/Down` cycles grouped hits, `Enter` opens the selected tab.

## Aura Filter UX

- AuraWatch custom spell handling is now managed-list based in both global plugin settings and per-unit plugin overrides.
- Managed list supports:
  - add spell IDs
  - remove rules (`-spellID`)
  - reorder (up/down, sort asc/desc)
  - preset quick actions (`Healer Core`, `Raid Defensives`, `M+ Utility`)

## Import/Export Changes

- Import flow is now explicit: `Validate -> Preview -> Apply`.
- Apply uses adapter-first behavior:
  1. in-place profile table replacement
  2. copy/swap fallback
- If post-apply update fails, SUF rolls back to the previous profile snapshot.
- Import preview includes a reload-impact summary and prompts for reload on successful apply.

## Existing User Impact

- Existing profiles are still merged with defaults at load time.
- `optionsUI` now stores additional keys:
  - `searchShowCounts`
  - `searchKeyboardHints`
- These keys default safely when missing from older profiles.
