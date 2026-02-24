![SimpleUnitFrames Banner](Media/SUFBanner.png)

# SimpleUnitFrames (SUF)

SimpleUnitFrames is a modular unit frame replacement for World of Warcraft Retail, built on `oUF` with Ace3 configuration and optional `PerformanceLib` integration for event coalescing, dirty batching, profiling, and diagnostics.
Why I created this was to learn a bit about addons, using Codex to help me. Never did like Lua much during my Mangos and Ascent developement days with GameScript they used for scripting. Yeah privateserver days but thats been a long time ago back during WoTLK days.

## Recent Updates

- Synced SUF framework behavior with newer `oUF` changes and element refinements
- Added broad plugin compatibility shims for newer Retail/oUF environments:
  - aura iteration fallback when `oUF.AuraFiltered` is unavailable
  - aura unpack fallback when `oUF:UnpackAuraData` is unavailable
  - secret-value helper fallbacks when `oUF:NotSecretValue` / `oUF:IsSecretValue` are unavailable
- Expanded performance tooling integration and SUF-side diagnostics workflow
- Improved event relevance filtering and coalesced update routing for frame pacing
- Added additional plugin/runtime libraries for UI polish and extensibility
- Incoming-heal value text feature is currently disabled by default for stability in secret-value contexts; incoming heal bars remain active
- Added dedicated `IncomingText` debug channel (off by default) in SUF Debug Settings

## Screenshots

### SUF Screen UI
![SUF Screen UI](Media/Screenshots/suf-screen-ui.png)

### SUF Performance Stats
![SUF Performance Stats](Media/Screenshots/suf-stats.png)

### SUF Options
![SUF Options](Media/Screenshots/suf-options.png)

### SUF Debug Console
![SUF Debug Console](Media/Screenshots/suf-debug.png)

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
- Tags reference tab with grouped oUF tags + SUF custom tags
- Per-unit tag preset system (compact/healer/tank/dps/minimal styles)
- Credits tab and Performance tab inside SUF options
- Import/export profile tools
- Minimap/LDB launcher support:
  - Left click: open SUF options
  - Right click: quick actions (SUF options, PerfLib UI, SUF debug)

### Performance & Diagnostics
- Optional `PerformanceLib` runtime integration
- SUF EventBus bridge for coalesced event workflows
- ML/coalescer adaptive hooks when available
- Relevance-gated unit event queueing to reduce unnecessary event pressure
- Tuned coalescing priorities/delays for noisy combat events
- `/sufdebug` panel with:
  - Real-time logs
  - System filters
  - Exportable diagnostics text
- Dedicated `IncomingText` debug filter for prediction-value trace output
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

SUF options also include a **PerformanceLib** tab with:
- active preset selection
- snapshot metrics
- shortcuts to PerfLib and SUF debug tools

## SUF Custom Tags

Available custom tags:

```text
[suf:absorbs]
[suf:absorbs:abbr]
[suf:incoming]
[suf:incoming:abbr]
[suf:healabsorbs]
[suf:healabsorbs:abbr]
[suf:ehp]
[suf:ehp:abbr]
```

Note: incoming-heal numeric display can be restricted by Blizzard secret-value handling depending on client/runtime state. SUF currently prioritizes stable, taint-safe behavior.

## Known Limitations

- Incoming-heal value text is currently disabled by default while we harden secret-value-safe display paths.
- Blizzard secret-value handling can block reliable numeric access for some prediction APIs, even when bars visually update.
- Some advanced performance diagnostics are only available when `PerformanceLib` is installed and enabled.
- Minimap/LDB behavior depends on optional broker/icon libraries being present in the addon environment.

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
- `UTF8`
- `LibAceConfigHelper`
- `LibSimpleSticky`
- `LibTranslit-1.0`
- `LibAnim`
- `LibCustomGlow-1.0`
- `LibActionButton-1.0`

## Compatibility

- WoW Retail interface version: `120001`
- Saved variables: `SimpleUnitFramesDB`

## Credits

- **Grevin** - SimpleUnitFrames author and project lead
- **PerformanceLib authors/contributors** - performance systems leveraged by SUF integration
- **UnhaltedUnitFrames (UUF)** - architecture and feature-reference source, plus SUF-specific custom ports and personal changes beyond UUF mainline
- **Ace3/oUF/library authors** - foundational framework and ecosystem support

## License

SimpleUnitFrames follows the project repository license.  
`PerformanceLib` integration remains under its own library license terms.
