# SimpleUnitFrames (SUF)

SimpleUnitFrames is a modular unit frame replacement for World of Warcraft Retail, built on `oUF` with Ace3 configuration and optional `PerformanceLib` integration for event coalescing, dirty batching, profiling, and diagnostics.

## Features

### Core Unit Frame System
- Player, Target, Target of Target, Focus, Pet, Party, Raid, and Boss frames
- Tag-driven text rendering for name, level, health, and power
- Per-unit sizing, media, font sizing, portrait, castbar, and heal prediction settings
- Aura support with configurable icon sizing
- Edit Mode-safe behavior and Blizzard frame visibility handling

### Options & UX
- Movable, resizable custom `/suf` options window
- Tabbed configuration for global and per-unit settings
- Import/export profile tools
- Minimap/LDB launcher support:
  - Left click: open SUF options
  - Right click: quick actions (SUF options, PerfLib UI, SUF debug)

### Performance & Diagnostics
- Optional `PerformanceLib` runtime integration
- SUF EventBus bridge for coalesced event workflows
- ML/coalescer adaptive hooks when available
- `/sufdebug` panel with:
  - Real-time logs
  - System filters
  - Exportable diagnostics text
- PerformanceLib output sink routing into SUF debug logs for easier sharing

## Quick Start

### 1. Install
- Place `SimpleUnitFrames` in your AddOns folder.
- Optional: install `PerformanceLib` for advanced performance systems and diagnostics.

### 2. Open Options
```text
/suf
```

### 3. Open Debug Console
```text
/sufdebug
```

### 4. Optional PerfLib UI/Analysis
```text
/perflib ui
/perflib analyze
/perflib profile start
/perflib profile stop
```

## Slash Commands

```text
/suf
  Open SUF options UI

/sufdebug
  Toggle SUF debug console

/sufdebug on|off|clear|export|settings|help
  Debug controls and export tools
```

When `PerformanceLib` is installed:

```text
/perflib ui
/perflib stats
/perflib analyze [all|eventbus|frame|dirty|pool|profile]
/perflib profile start|stop|analyze [scope]
```

## API Reference (Addon Integration)

If you are extending SUF internally/modules:

```lua
addon:GetUnitSettings(unitType)
addon:GetUnitFontSizes(unitType)
addon:GetUnitStatusbarTexture(unitType)
addon:GetUnitCastbarSettings(unitType)
addon:GetUnitLayoutSettings(unitType)
addon:GetUnitHealPredictionSettings(unitType)
addon:GetUnitCastbarColors(unitType)
addon:GetUnitAuraSize(unitType)

addon:SetPerformanceIntegrationEnabled(enabled[, silent])
addon:QueuePerformanceEvent(eventName, ...)

addon:SerializeProfile()
addon:DeserializeProfile(input)
addon:ApplyImportedProfile(data)
```

## Libraries Used

### Framework & UI
- `oUF`
- `AceAddon-3.0`
- `AceDB-3.0`
- `AceGUI-3.0`
- `AceConsole-3.0`
- `AceEvent-3.0`
- `AceSerializer-3.0`

### Media & Data
- `LibSharedMedia-3.0`
- `LibSerialize`
- `LibDeflate`
- `LibDualSpec-1.0`

### Optional/Integration
- `PerformanceLib` (optional dependency)
- `LibDataBroker-1.1` (optional, if present)
- `LibDBIcon-1.0` (optional, if present)

### Included Utility
- `TaintLess`
- `LibDispel-1.0`

## Compatibility

- WoW Retail interface versions: `120000`, `120001`
- Saved variables: `SimpleUnitFramesDB`

## Credits

- **Grevin** - SimpleUnitFrames author and project lead
- **Grevin** **PerformanceLib** - performance systems leveraged by SUF integration
- **Ace3/oUF/Lib authors** - foundational framework and library ecosystem

## License

SimpleUnitFrames follows the project repository license.  
`PerformanceLib` integration remains under its own library license terms.

