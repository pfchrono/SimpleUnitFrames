# Project Guidelines

## API Verification Workflow
**CRITICAL: Always verify WoW APIs against the local wow-ui-source repository before planning or implementing any code changes.**

### Before Any Code Planning or Changes:
1. **Check Local Reference:** Review the latest API implementation in `d:\Games\World of Warcraft\_retail_\Interface\_Working\wow-ui-source`
   - File path: `wow-ui-source/Interface/AddOns/Blizzard_*/` (Blizzard reference UI code)
   - Verify C_* namespace functions, widget types, and event payloads
   - Look for undocumented parameters, return values, or behavioral changes

2. **Update Repository if Outdated:**
   - Run: `/run SUF.DebugOutput:Output("APICheck", "Checking wow-ui-source for updates...", 1)`
   - Navigate to: `d:\Games\World of Warcraft\_retail_\Interface\_Working\wow-ui-source`
   - Check git status: `git status`
   - Get latest: `git fetch origin && git pull` (uses branch: live)
   - Verify update: `git log --oneline -5` (should show current date if updated)

3. **Cross-Reference Before Implementation:**
   - Compare proposed API usage against `wow-ui-source/Interface/AddOns/Blizzard_*/` code
   - Verify parameter order, return value unpacking, availability in current patch
   - Check for secret values (WoW 12.0.0+) that require special handling
   - Note any deprecated or renamed functions

4. **Document API Findings:**
   - Record function signature and parameters from wow-ui-source references
   - Note any version-specific behavior or restrictions
   - Link to specific Blizzard reference UI file and line numbers in code comments
   - Example comment: `-- Per Blizzard_CastingBar line 142: UnitChannelInfo returns 8 values in this order: name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID`

### Why This Matters:
- **Accuracy:** Blizzard reference UI is the source of truth for WoW API behavior
- **Unpacking Errors:** Wrong parameter order causes "attempt to perform arithmetic on boolean" type errors
- **Version Compatibility:** API changes between patches must be caught early
- **Secret Values:** Some return values are secret in 12.0.0+ and need special handling
- **Undocumented Features:** Many Blizzard APIs have quirks only visible in reference code

### Common Pitfalls Fixed by This Workflow:
- ❌ UnitChannelInfo unpacking with wrong underscore count (causes boolean arithmetic error)
- ❌ Using deprecated C_* apis without checking wow-ui-source
- ❌ Assuming parameter order without verifying in Blizzard code
- ❌ Missing return value unpacking (only taking first value when multiple available)
- ❌ Not handling secret values in 12.0.0+ properly

## Code Style
- **Lua 5.1 ONLY:** WoW uses Lua 5.1 - do NOT use Lua 5.2+ syntax (no `goto`, no `\z`, no `0x` hex floats, no `//` comments)
  - ❌ FORBIDDEN: `goto label`, `::label::`, `\z` escape sequences, hexadecimal floats (`0x1.8p3`)
  - ❌ FORBIDDEN: `//` comments (use `--` for single-line, `--[[ ]]` for multi-line)
  - ✅ ALLOWED: Standard Lua 5.1 control flow (`while`, `repeat`, `for`, nested `if/elseif/else`, early `return`, `break` in loops)
  - ✅ Loop control: Use `if not condition then goto skip_iteration end` pattern is INVALID - use `if not condition then [skip code] elseif another then [process] end` instead
  - ✅ Early exit: Use early `return` statements instead of complex nesting or goto patterns
  - Reference: See WoWAddonAPIAgents/.github/skills/wow-lua-api/SKILL.md for complete Lua 5.1 reference
  - Reference: See WoWAddonAPIAgents/.github/skills for available skills and best practices for Lua coding in WoW addons

- Prefer `addon:` namespaced functions with locals declared near the top of each file; keep style compact like existing code in [SimpleUnitFrames.lua](../SimpleUnitFrames.lua) and [Modules/UI/OptionsWindow.lua](../Modules/UI/OptionsWindow.lua).
- Use **PERF LOCALS** pattern: localize frequently-called globals at module load (e.g., `local GetTime, UnitExists = GetTime, UnitExists`)
- Configuration UI uses AceGUI widgets and shared helper wrappers in [Modules/UI/OptionsWidgets.lua](../Modules/UI/OptionsWidgets.lua); follow patterns in [Modules/UI/OptionsWindow.lua](../Modules/UI/OptionsWindow.lua).
- Defaults live in AceDB tables in [SimpleUnitFrames.lua](../SimpleUnitFrames.lua) lines 45-350; update defaults whenever adding new settings.
- **Safe Value Handling (WoW 12.0.0+ Secret Values):**
  - Use `SafeNumber(value, fallback)` for numeric API returns (lines ~820-835 in SimpleUnitFrames.lua)
  - Use `SafeText(value, fallback)` for string API returns (lines ~780-790)
  - Use `SafeAPICall(fn, ...)` for protected function calls (lines ~770-780)
  - Use `IsSecretValue(value)` to check if value is secret (lines ~765-770)
  - Example: `local health = SafeNumber(UnitHealth(unit), 0)` instead of raw `UnitHealth(unit)`
- **Theming Helpers:** Use `addon:ApplySUFBackdropColors()` for safe backdrop/texture styling before calling `SetBackdropColor` directly. ([Modules/UI/Theme.lua](../Modules/UI/Theme.lua))
- **Frame Storage Patterns:**
  - Frames stored in `addon.frames[]` array (indexed sequentially)
  - Frame event index in [Modules/System/FrameIndex.lua](../Modules/System/FrameIndex.lua) provides lookup by unit/type
  - oUF spawned frames accessible via oUF global: `_G["SUF_Player"]`, `_G["SUF_Target"]`, etc.
- **Helper Functions in SimpleUnitFrames.lua:**
  - Core: `addon._core.RoundNumber()`, `CopyTableDeep()`, `MergeDefaults()`, `FormatCompactValue()`
  - Unit Config: `GetUnitSettings()`, `GetUnitCastbarSettings()`, `GetUnitPluginSettings()`
  - Profile: `GetAvailableProfiles()`, `GetSavedProfileByName()`
  - Module Copy/Reset: `CopyModuleIntoCurrent()`, `ResetModuleForUnit()`, `BuildModuleChangePreview()`
- **Debug Output:**
  - Core debug: `addon:DebugLog(system, message, tier)` method in [SimpleUnitFrames.lua](../SimpleUnitFrames.lua)
  - Debug panel: [Modules/UI/DebugWindow.lua](../Modules/UI/DebugWindow.lua) accessible via `/suf debug`
  - PerformanceLib debug: Uses PerformanceLib.DebugOutput if available (lines ~2295-2310 in SimpleUnitFrames.lua)

## Architecture
- **SimpleUnitFrames Core Structure:**
  - **SimpleUnitFrames.lua (8219 lines):** Main addon core with AceAddon initialization, defaults, profile management, unit configuration accessors, custom oUF tags, performance integration hooks
  - **Modules/System/:** Core system modules
    - FrameIndex.lua: Frame indexing by unit and type
    - Movers.lua: Frame positioning and movement system
    - FrameDrag.lua: Drag-and-drop frame positioning
    - Enhancements.lua: UI enhancements (sticky windows, transliteration, animations)
    - Commands.lua: Slash command handlers (/suf, /SUFperf, /SUFdebug)
    - Launcher.lua: Addon initialization orchestration
  - **Modules/UI/:** Configuration and debug UI
    - OptionsWindow.lua (3537+ lines): Main options window with tab navigation, search, module copy/reset, profile management
    - OptionsTabs.lua: Tab definitions and metadata
    - OptionsWidgets.lua: AceGUI widget helpers (Check, Slider, Color, Dropdown)
    - Theme.lua: UI theming and styling
    - DataSystems.lua: Data bar and data text systems
    - DebugWindow.lua: Debug panel UI
  - **Units/:** oUF unit frame spawning (Player, Target, Pet, Focus, ToT, Party, Raid, Boss)
  - **Libraries/:** External dependencies (oUF, Ace3, LibSharedMedia, LibDualSpec, LibDeflate, LibDispel, LibTranslit, LibCustomGlow, LibRangeCheck, LibStub)

- **PerformanceLib Integration (Optional Dependency):**
  - SimpleUnitFrames integrates with PerformanceLib addon via `addon.performanceLib` references
  - PerformanceLib provides: EventBus, FramePoolManager, EventCoalescer, FrameTimeBudget, DirtyFlagManager, ReactiveConfig, PerformanceProfiler, PerformancePresets, DebugOutput, DebugPanel, DirtyPriorityOptimizer, MLOptimizer
  - Integration setup in SimpleUnitFrames.lua:SetupPerformanceLib() (line ~2300)
  - Conditional integration: All PerformanceLib features gracefully degrade if addon not present
  - Performance commands route through Commands.lua to PerformanceLib APIs

## Build and Test
- No build/test commands are documented in this repo.

## Project Conventions
- **Profile and Unit Configuration:**
  - Defaults defined in [SimpleUnitFrames.lua](../SimpleUnitFrames.lua) lines 45-350 (profile.units, profile.castbar, profile.plugins, etc.)
  - Unit settings accessors: `addon:GetUnitSettings(unitType)`, `GetUnitCastbarSettings()`, `GetUnitPluginSettings()`, `GetPluginSettings()`
  - Configuration changes trigger refresh via `addon:ScheduleUpdateAll()` or `addon:SchedulePluginUpdate(unitType)`
- **Unit Frame Spawning:**
  - Units spawned via oUF in Units/ directory (Player.lua, Target.lua, Pet.lua, Focus.lua, Tot.lua, Party.lua, Raid.lua, Boss.lua)
  - Unit builders registered via `addon:RegisterUnitBuilder(unitType, builder)` pattern
  - Frame anchoring uses `addon:HookAnchor(frame, "BlizzardFrameName")` to preserve Edit Mode integration
- **Protected Operations System (Combat Lockdown):**
  - Core: [Core/ProtectedOperations.lua](../Core/ProtectedOperations.lua) — Centralized queue system with automatic flush
  - **Early Initialization:** Addon aliases (`addon:QueueOrRun`, `addon:FlushProtectedOperations`) registered immediately at module load to prevent nil errors during early frame spawning
  - **Lazy Event Frame Init:** Event frame created on first QueueOrRun call if not already initialized
  - **Usage Pattern:** `addon:QueueOrRun(func, {key, type, priority})`
  - **Priority Levels:** CRITICAL (immediate flush) → HIGH → MEDIUM → NORMAL → LOW (batched, 48 ops per flush)
  - **Flush Trigger:** Automatic on PLAYER_REGEN_ENABLED (event-driven, zero polling overhead)
  - **Deduplication:** Pass `key` to prevent duplicate queuing in same batch
  - **When to Use:** Any frame mutation during combat (UpdateFrames, etc.)
  - **Example:**
    ```lua
    addon:QueueOrRun(function()
        addon:ScheduleUpdateAll()
    end, {
        key = "Frames_Refresh",
        type = "FRAMES_REFRESH",
        priority = "NORMAL",
    })
    ```
  - **Diagnostics:** `/SUFprotected` shows queue stats; `/SUFprotected help` for full details
- **Frame Indexing:**
  - Frames tracked in `addon.frames[]` array
  - Frame event index maintained by [Modules/System/FrameIndex.lua](../Modules/System/FrameIndex.lua) with `EnsureFrameEventIndex()` (byUnit, byType, all)
  - Invalidate cache after frame operations via `InvalidateFrameEventIndex()`
- **Custom oUF Tags:**
  - Registered in [SimpleUnitFrames.lua](../SimpleUnitFrames.lua) `RegisterCustomTags()` function (lines ~1800-1850)
  - Tags: `[suf:absorbs]`, `[suf:incoming]`, `[suf:ehp]`, `[suf:missinghp]`, `[suf:missingpp]`, `[suf:status]`, `[suf:health:percent-with-absorbs]`, `[suf:name]`
  - Secret value safe: Uses `SafeNumber()`, `SafeText()`, `SafeAPICall()` wrappers for WoW 12.0.0+ compatibility
- **Media Resolution:**
  - LibSharedMedia (LSM) integration for textures and fonts
  - Accessors: `addon:GetStatusbarTexture()`, `addon:GetFont()`, `addon:GetUnitStatusbarTexture(unitType)`
  - Profile settings: `db.profile.media.statusbar`, `db.profile.media.font`
- **PerformanceLib Integration Patterns (when PerformanceLib addon is present):**
  - **Event Coalescing:** Use EventCoalescer for high-frequency events with priorities (CRITICAL/HIGH/MEDIUM/LOW)
    - CRITICAL (1): UNIT_HEALTH, UNIT_POWER_UPDATE, PLAYER_REGEN_ENABLED/DISABLED (immediate flush)
    - HIGH (2): UNIT_MAXHEALTH, UNIT_MAXPOWER, UNIT_AURA (minimal batching)
    - MEDIUM (3): UNIT_THREAT, PLAYER_TOTEM_UPDATE, RUNE_POWER_UPDATE (standard coalescing)
    - LOW (4): UNIT_PORTRAIT_UPDATE, UNIT_MODEL_CHANGED (aggressive batching, cosmetic)
    - Event priority config: `PERF_EVENT_PRIORITY` table in SimpleUnitFrames.lua (lines ~550-570)
    - Coalesce config: `EVENT_COALESCE_CONFIG` table in SimpleUnitFrames.lua (lines ~580-605)
  - **Frame Time Budgeting:** FrameTimeBudget tracks frame time, defers non-critical updates (target: 16.67ms for 60 FPS)
  - **Frame Pooling:** FramePoolManager for aura buttons and indicators (60-75% GC reduction when used)
  - **Dirty Flag Batching:** DirtyFlagManager batches frame updates with adaptive sizing
  - **ML Optimization:** DirtyPriorityOptimizer learns from gameplay (5-minute windows, 4 weighted factors)
  - **Performance Monitoring:**
    - `/SUFperf` - Toggle real-time performance dashboard
    - `/SUFprofile start|stop|analyze|export` - Timeline profiling
    - `/SUFpreset low|medium|high|ultra` - Adjust performance presets
    - `/run SUF.PerformanceDashboard:PrintStats()` - Stats to chat
    - `/SUFdebug` - Open debug panel
- **Conditional frame handling:**
  - PLAYER frame: Always exists, always visible (mandatory)
  - TARGET, PET, FOCUS, TARGETTARGET, FOCUSTARGET: Exist via oUF:Spawn but hidden when units not present
  - Use RegisterUnitWatch to auto show/hide conditional frames
  - Validation: Check frame exists but don't require IsVisible() for conditional frames
  - **Frame access patterns:**
    - Array storage: `addon.frames[]` (indexed, iterate via `ipairs(addon.frames)`)
    - Global names: `_G["SUF_Player"]`, `_G["SUF_Target"]`, `_G["SUF_Pet"]`, etc. (oUF spawn names)
    - Frame event index: [Modules/System/FrameIndex.lua](../Modules/System/FrameIndex.lua) provides byUnit/byType/all lookups
- **Performance profiling workflow:**
  - Start: `/SUFprofile start` (begins timeline recording, max 10000 events)
  - Play: 5-10 minutes of normal gameplay (combat, movement, UI interaction)
  - Stop: `/SUFprofile stop` (ends recording)
  - Analyze: `/SUFprofile analyze` (shows FPS metrics, frame time percentiles, coalesced event breakdown, bottlenecks)
  - Export: `/SUFprofile export` (copies timeline data to clipboard)
  - Expected results: P50=16.7ms (60 FPS), P99<25ms, zero HIGH severity spikes (>33ms)
  - Bottleneck interpretation: HIGH severity = frames >33ms (below 30 FPS), event_coalesced is false positive (optimization working)

## Integration Points
- oUF for frame spawning and colors (see [Libraries/oUF](../Libraries/oUF) and Units/ directory).
- Ace3 (AceAddon/AceDB/AceGUI), LibSharedMedia, LibDualSpec, LibDeflate, LibDispel (see [Libraries/](../Libraries/)).
- **Protected Operations System Integration:**
  - Core system: [Core/ProtectedOperations.lua](../Core/ProtectedOperations.lua) — Unified combat lockdown handling
  - API method: `addon:QueueOrRun(func, opts={key, type, priority})` — Deferred execution during combat
  - Priority levels: CRITICAL (immediate flush), HIGH, MEDIUM, NORMAL, LOW (batched)
  - Auto-flush: Triggered on PLAYER_REGEN_ENABLED event (event-driven, zero polling overhead)
  - Deduplication: Keyed operations prevent duplicate queuing in the same batch
  - Diagnostics: `/SUFprotected` command for queue statistics and debugging
  - Module integration: Unit Frames (refresh callbacks), UI (option changes)
- **PerformanceLib Integration (Optional Dependency):**
  - Architecture systems in PerformanceLib addon: EventBus, FramePoolManager, EventCoalescer, FrameTimeBudget, DirtyFlagManager, ReactiveConfig
  - Integration setup: [SimpleUnitFrames.lua](../SimpleUnitFrames.lua) `SetupPerformanceLib()` function (lines ~2295-2350)
  - Graceful degradation: All PerformanceLib features optional, checks `addon.performanceLib` before use
  - PerformanceProfiler (timeline recording, bottleneck analysis)
  - PerformancePresets (4 presets: Low/Medium/High/Ultra + auto-optimization)
  - PerformanceDashboard (`/SUFperf` for real-time metrics via Commands.lua)
  - DebugOutput & DebugPanel (non-intrusive debug routing)
  - DirtyPriorityOptimizer (ML-based priority learning with 4 weighted factors)
  - **MLOptimizer** (PerformanceLib/ML/MLOptimizer.lua): Advanced ML system
    - **Neural Network:** 7 inputs → 5 hidden neurons → 3 outputs (priority, coalesceDelay, preloadLikelihood)
    - **Combat Pattern Recognition:** Tracks event sequences, learns patterns from gameplay
    - **Predictive Pre-loading:** Pre-marks frames when prediction confidence >70%
    - **Adaptive Coalescing Delays:** Learns optimal delay per event per content type
    - **Training:** Backpropagation with gradient descent (0.01 learning rate), Sigmoid activation
    - **Integration:** Hooks DirtyFlagManager:MarkDirty and EventCoalescer:QueueEvent
- **Performance Feature Commands:**
  - `/SUFperf` - Toggle performance dashboard (real-time FPS/latency/memory overlay)
  - `/SUFprofile start|stop|analyze|export` - Performance profiling (timeline recording, 10000 event max)
    - analyze: Shows FPS metrics (min/avg/max), frame time percentiles (P50/P95/P99), coalesced event breakdown (top 10 WoW events), bottlenecks (ignores event_coalesced false positive)
  - `/SUFpreset low|medium|high|ultra` - Change performance preset
  - `/SUFpreset auto on|off` - Toggle auto-optimization based on hardware
  - `/SUFpreset recommend` - Get preset recommendations based on current performance
  - `/SUFml patterns|delays|stats|predict|help` - MLOptimizer commands (Phase 5b)
    - patterns: Show learned combat patterns with prediction probabilities
    - delays: Show adaptive coalescing delays per event/content type
    - stats: Statistics (patterns learned, delays optimized, current sequence, context)
    - predict: Current predictions based on recent event sequence
  - `/run SUF.Validator:RunFullValidation()` - System health check (11 tests: Architecture, EventBus, ConfigResolver, FramePoolManager, GUILayout, MLOptimizer, FramesSpawning, EventBusDispatch, FramePoolAcquisition, ConfigResolution, GuiBuilder)
  - `/run SUF.DirtyPriorityOptimizer:PrintRecommendations()` - ML-based priority recommendations (frequency, combat ratio, recency analysis)
  - `/run SUF.MLOptimizer:GetStats()` - MLOptimizer statistics (patterns, delays, sequence length, context)
  - `/run SUF.PerformanceDashboard:PrintStats()` - Print comprehensive stats to chat (FPS, latency, memory, frame pool stats, event coalescing stats)
  - `/run SUF.FrameTimeBudget:PrintStatistics()` - Frame time budget stats (avg/P50/P95/P99, histogram distribution, deferred queue size, dropped callbacks)
  - `/run SUF.FrameTimeBudget:ResetStatistics()` - Reset frame time tracking (clears percentile history)
  - `/run SUF.EventCoalescer:PrintStats()` - Event coalescing detailed stats (total coalesced/dispatched, CPU savings %, per-event breakdown with batch sizes min/avg/max, budget defers, emergency flushes)
  - `/run SUF.EventCoalescer:ResetStats()` - Reset coalescing statistics
  - `/run SUF.DirtyFlagManager:PrintStats()` - Dirty flag stats (frames processed, batches, invalid frames skipped, priority decays, processing blocks)
  - `/SUFdebug` - Toggle debug panel (non-intrusive diagnostic messages, system-specific toggles, export to clipboard)

## Performance Profiling Integration
**When to Profile:**
- Before/after optimization work to measure improvements
- During gameplay to identify bottlenecks (combat, dungeons, raids, world events)
- Before committing code changes that affect frame updates or event handling
- When investigating FPS drops or performance regressions

**Profiling Workflow:**
1. **Start Recording:** `/SUFprofile start` (captures timeline, max 10000 events)
2. **Normal Gameplay:** Play for 5-10 minutes (combat, movement, UI interaction, content variation)
3. **Stop Recording:** `/SUFprofile stop` (ends timeline capture)
4. **Analyze Results:** `/SUFprofile analyze` (shows metrics and bottleneck breakdown)
5. **Export Data:** `/SUFprofile export` (copies timeline JSON to clipboard for external analysis)

**Reading Analysis Output:**
- **FPS Metrics:** min/avg/max (aim for avg ≥60, min ≥30)
- **Frame Time Percentiles:** P50/P95/P99 (aim for P50≤16.7ms, P99<25ms for 60 FPS target)
- **Coalesced Events:** Top 10 WoW events with batch sizes (shows which events benefit most from coalescing)
- **Bottlenecks:** Frames >33ms (below 30 FPS) marked as HIGH severity (note: event_coalesced=true is not a bottleneck, it's optimization working)

**Code Instrumentation for Profiling:**
- Use PerformanceLib's EventCoalescer for high-frequency events (CRITICAL/HIGH/MEDIUM/LOW priorities)
- Queue frame updates via `addon:QueueOrRun()` with appropriate priority for combat lockdown safety
- Use `addon.PerformanceProfiler:MarkEvent(eventName)` to annotate timeline (if PerformanceLib available)
- Avoid blocking operations — defer non-critical work with DirtyFlagManager batching

**Expected Performance Baselines:**
- **Idle (no combat):** P50<5ms, P95<10ms (cosmetic updates deferred aggressively)
- **Light Combat (1v1):** P50≤16.7ms, P99<25ms (event coalescing active, frame pooling reduces GC)
- **Heavy Combat (raid/alt+tab):** P95<33ms target (deferral queue active, budget throttling engaged)
- **GC Impact:** 60-75% GC reduction with frame pooling + event deferral (vs. naive implementation)

## Security

### Secure Frame Patterns (WoW 12.0.0+ ActionBar Taint Lessons Learned)

Through comparative analysis of Dominos vs SimpleUnitFrames ActionBars system, the following architectural patterns MUST be followed when modifying secure frames (action buttons, secure templates, etc.) in WoW 12.0.0+:

**Pattern 1: Template Inheritance Over Custom Implementation**
- ✅ **DO:** Use existing Blizzard secure templates via frame creation: `CreateFrame(..., "ActionBarButtonTemplate")` or inherit from parent templates
- ❌ **DON'T:** Invent custom button classes or reimplements secure properties (impossible to do safely with addon taint)
- **Why:** Blizzard templates bake all secure event handlers, attribute systems, and click routing. Addon code cannot replicate this safely.
- **Impact in 12.0.0+:** Once buttons acquire secret state marks, addon code cannot safely modify their attributes. Only pre-fabricated secure templates remain untainted.
- **Reference:** WoW 12.0.0 ActionButton system uses secure templates inherited from Blizzard_ActionBar/SecureTemplates.lua

**Pattern 2: Attribute-Driven State Over Method Calls**
- ✅ **DO:** Mutate secure frame visibility via attributes: `frame:SetAttribute("statehidden", not shouldShow)` → WoW's secure system triggers Show/Hide internally
- ❌ **DON'T:** Call `frame:SetShown()`, `frame:Hide()`, or other methods directly during combat/instance gameplay
- **Why:** Method calls violate combat lockdown (forbidden during combat). Attribute mutations are safe; WoW's secure system handles the actual show/hide via secure handlers.
- **Impact in 12.0.0+:** Combat lockdown restrictions are STRICTER; method calls on secure frames are blocked entirely across instance boundaries.
- **Pattern Example:**
  ```lua
  -- WRONG: Direct method call (combat lockdown violation)
  if shouldShow then button:Show() else button:Hide() end
  
  -- RIGHT: Attribute-driven (safe during combat)
  button:SetAttribute("statehidden", not shouldShow)
  ```
- **Example:** Dominos uses secure state drivers to update visibility; SUF ActionBars tried direct method calls during combat

**Pattern 3: Action-Based APIs Over Unit-Based APIs**
- ✅ **DO:** Query action button state via `C_ActionBar.*` functions (HasAction, GetActionTexture, GetActionText, GetActionInfo, IsUsableAction, etc.)
- ❌ **DON'T:** Read unit-based APIs (UnitCasting, UnitHealth, UnitName, UnitIsUnit, etc.) to inform button updates or styling
- **Why:** Action-based APIs return action data (non-secret). Unit-based APIs return secretly-guarded values in combat/instances, causing comparisons to fail.
- **Impact in 12.0.0+:** Every UnitCasting(), UnitHealth(), UnitName() call on a non-player unit in an instance returns secret values. Any arithmetic or comparison crashes the addon.
- **Critical Difference:** `C_ActionBar.GetActionText()` (safe, returns spell/item name) vs UnitName() (secret in instances, returns unreadable value)
- **Example:** Dominos queries ONLY action slot data; SUF ActionBars likely read unit state for dynamic button updates

**Pattern 4: Secure Wrapping Over Direct Hooks**
- ✅ **DO:** Use `WrapScript()` (secure method on button controller frames) to insert addon logic into secure event handlers
- ❌ **DON'T:** Call `hooksecurefunc()` on secure event handlers, or `SetScript()` directly on secure buttons during initialization
- **Why:** WrapScript creates a sandboxed execution layer between addon code and original secure handlers. Direct hooks taint the button immediately.
- **Impact in 12.0.0+:** Tainted frames cannot acquire new attributes in instances. WrapScript-wrapped frames remain untainted because the original frame is never modified.
- **Alternative for Methods:** Use `hooksecurefunc()` ONLY on pure Lua methods (e.g., `hooksecurefunc(button, 'UpdateHotkeys', customUpdate)`), never on secure event handlers
- **Example:** Dominos uses WrapScript to hook handlers; SUF ActionBars used direct HookScript calls that immediately tainted buttons

**When to Break the Rules (Rare Cases):**
- If modifying Blizzard's own secure code via hooksecurefunc on methods → safe (pure Lua)
- If using PerformanceLib's EventCoalescer for high-frequency events → event-driven, not combat-restricted
- If deferring frame changes via addon:QueueOrRun() with combat lockdown checks → protected operations system handles it

**Impact Summary:**
- **Before 12.0.0:** These patterns were "nice to have"; addons could get away with direct hooks and method calls
- **12.0.0+:** These patterns are MANDATORY; violation causes taint errors, secret value crashes, and combat lockdown blocks
- **Real-world consequence:** SimpleUnitFrames ActionBars removed entirely (6 modules, 2 libraries) because the patterns couldn't be salvaged mid-combat

**For Future Frame Modification Work:**
If SUF needs to provide UI overrides for protected frames (e.g., custom button theming, rare item alerts):
1. Defer to third-party addon (Dominos for action bars, Masque for theming)
2. OR integrate via secure theming system (Masque skinsets) that doesn't modify frame logic
3. OR use the 4 patterns above religiously, tested in 5-player dungeons (where secret values are active)

See [SECURE_FRAME_SAFETY_CHECKLIST.md](../docs/SECURE_FRAME_SAFETY_CHECKLIST.md) for verification points and debugging workflow.

- **Protected Operations System (Unified Combat Lockdown Handling):**
  - **Location:** [Core/ProtectedOperations.lua](../Core/ProtectedOperations.lua) (event-driven queue system with early init)
  - **API:** `addon:QueueOrRun(func, opts)` — Queue operation for deferred execution during combat
  - **Options:** `{key: string, type: string, priority: "CRITICAL"|"HIGH"|"MEDIUM"|"NORMAL"|"LOW"}`
  - **Early Initialization:** Addon aliases registered at module load via `RegisterAddonAliasesEarly()` to prevent nil errors during frame spawning
  - **Lazy Event Frame:** Event frame (PLAYER_REGEN_ENABLED/DISABLED listeners) created on first QueueOrRun call if needed
  - **Flush Trigger:** Automatic flush on `PLAYER_REGEN_ENABLED` event (event-driven, zero polling)
  - **Deduplication:** Keyed operations prevent duplicate queuing; use `key: "OperationName"` to prevent redundant work
  - **Priority Ordering:** Operations sorted before flush (CRITICAL → HIGH → MEDIUM → NORMAL → LOW)
  - **Batch Processing:** 48 operations per safe-flush window prevents runaway processing
  - **Fallback Ticker:** 200ms fallback ticker if queue remains after flush (edge case handling)
  - **Diagnostics:** `/SUFprotected` command shows queue stats; `/SUFprotected help` for full details
  - **Example:** Queue a protected refresh during combat:
    ```lua
    addon:QueueOrRun(function()
        addon:ScheduleUpdateAll()
    end, {
        key = "Frames_Refresh",
        type = "FRAMES_REFRESH",
        priority = "NORMAL",
    })
    ```
  - **Usage in Modules:** Any module needing protected frame mutations
  - **Performance:** Event-driven with no polling overhead; fallback ticker (200ms) for edge cases
- **WoW 12.0.0+ Secret Values:** Use `SafeNumber()`, `SafeText()`, `SafeAPICall()`, `IsSecretValue()` wrappers (defined in [SimpleUnitFrames.lua](../SimpleUnitFrames.lua) lines ~760-835)
- **PerformanceLib Safety (when present):**
  - EventCoalescer: Flushes CRITICAL priority events immediately, emergency flush tracking
  - DirtyFlagManager: Processing lock prevents re-entry, combat state forces flush
  - FrameTimeBudget: pcall() protection for deferred callbacks, overflow protection (MAX_DEFERRED_QUEUE=200)
  - Frame Validation: `_ValidateFrame()` checks before processing, skips invalid/dead frames
  - Pool Safety: FramePoolManager tracks acquired frames, prevents double-release
  - ML Safety: DirtyPriorityOptimizer/MLOptimizer learn passively without blocking gameplay
- **Error Handling:**
  - All API calls wrapped in `SafeAPICall()` with pcall() protection
  - ProtectedOperations errors logged via `addon:DebugLog()` (integrated error tracking)
  - Debug output uses pcall() to prevent errors from stopping execution
  - Module initialization failures logged via `addon:DebugLog()` with tier 1 (critical)

## Change Documentation
After completing any bug fix, feature work, or development change, update project documentation:

### Work Summary Updates ([WORK_SUMMARY.md](../WORK_SUMMARY.md))
- Add a new session section with the date and status
- Document files modified with specific line ranges and descriptions
- Include performance impact estimates where applicable
- List risk level and validation approach
- Summarize overall status of the session (e.g., "All errors resolved ✅")
- For feature additions, include a brief user-facing description of the new functionality unless the feature needs detailed explanation (in which case, add a new section describing the feature in detail)
- Do not include updates if the user supplys a bug report Containing [ERROR] in the message, as those should be reserved for actual bug fixes. Instead, focus on documenting new features, architectural changes, or other development work that does not directly relate to fixing a reported error.

### Self-Updating Documentation Guidelines
When introducing new features, systems, libraries, or architectural changes, **automatically update this copilot-instructions.md file** to reflect the changes:

**Update Code Style section if:**
- New code patterns introduced (e.g., SUF.Units table pattern, frame validation patterns)
- New utility functions added to common use (e.g., new Utilities helpers, new DebugOutput methods)
- New best practices established (e.g., priority constants, frame storage patterns)

**Update Architecture section if:**
- New core systems added (e.g., EventCoalescer, FrameTimeBudget, DirtyFlagManager)
- Existing systems significantly enhanced (e.g., O(1) averaging, percentile tracking, priority levels)
- Load order changes (update Core/Init.xml load sequence)
- New performance metrics achieved (update improvement percentages, benchmarks)

**Update Project Conventions section if:**
- New workflow patterns established (e.g., frame validation before processing, conditional frame handling)
- New commands or slash commands added (e.g., /SUFprofile, /SUFpreset)
- New monitoring/diagnostic approaches (e.g., performance profiling workflow)
- New integration patterns (e.g., event priority assignment, adaptive batching)

**Update Security section if:**
- New safety mechanisms added (e.g., processing locks, overflow protection, frame validation)
- Combat handling patterns change (e.g., emergency flush for CRITICAL events)
- New error handling approaches (e.g., pcall() wrappers, graceful degradation)

**Update Integration Points section if:**
- New libraries or external systems integrated
- New internal systems with public APIs (e.g., EventCoalescer:PrintStats(), FrameTimeBudget:CanAfford())
- New slash commands or user-facing features
- System APIs change significantly (parameter additions, behavior changes)

**Format for updates:**
- Keep entries concise but complete (1-3 lines per bullet)
- Include relevant file paths with markdown links
- Mention key performance metrics where applicable (e.g., "60%+ GC reduction", "ZERO HIGH frame spikes")
- Reference line numbers for critical code sections
- Use technical accuracy (e.g., "O(1) incremental averaging" not just "faster averaging")
- Update improvement percentages when benchmarks change (e.g., "45-85% total improvement")

**When in doubt:**
- Check ARCHITECTURE_GUIDE.md for detailed system documentation
- Review WORK_SUMMARY.md for recent session changes
- Validate against existing patterns in the codebase

This ensures future AI assistants and developers have accurate, up-to-date guidance reflecting the current state of the addon architecture and best practices.
