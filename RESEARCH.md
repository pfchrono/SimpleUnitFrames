# RESEARCH.md - Fresh QUI Analysis for SUF Enhancements (v2)

**Date:** 2026-03-03  
**Status:** Comprehensive analysis complete; implementation in progress  
**Scope:** Midnight (12.0.x) compatible UI improvements + low/medium/high risk enhancements  

**Progress Update (2026-03-03):**
- Task 1.1 removed from roadmap (project now focused only on Midnight API 12.0.x)
- Task 1.2 complete (safe helper wrappers refined and documented)
- Task 1.3 complete (SafeReload implementation active)
- Task 1.4 complete (iterative profile import tree validation integrated into core import path)

---

## Executive Summary

This comprehensive analysis examines QUI (QuaziiUI Community Edition) for SUF enhancement opportunities across:
- **Options UI/UX Improvements** (best practice in UI organization and theming)
- **Low-Risk Enhancements** (pure additions, zero breaking changes)
- **Medium-Risk Enhancements** (moderate refactoring, validated approaches)
- **High-Risk Enhancements** (architectural changes, significant complexity)

QUI's strengths for SUF:
- Modular options architecture (sidebar tabs + delegated page builders vs 3624-line monolith)
- Systematic secret value handling (7 safe wrappers vs scattered SafeNumber/SafeText)
- Pixel-perfect scaling for UI rendering
- UIKit factory functions eliminating boilerplate
- Advanced theming system with color derivation
- Profile migration patterns for schema management

---

## SECTION A: OPTIONS UI/UX IMPROVEMENTS

### Current SUF Options Situation

**OptionsWindow.lua:** 3624 lines  
**OptionsV2/:** 6 files (Bootstrap, Layout, Registry, Renderer, Search, Theme)  

**Current Issues:**
- Single large file makes navigation difficult
- Tab definitions spread across multiple files
- Search functionality exists but could be enhanced
- Color theming exists but lacks advanced derivation
- No accent color system for consistent theme customization
- Scroll-to-section navigation not implemented
- Action buttons (Edit Mode, etc.) not as prominent

### A.1: Adopt Sidebar Tab UI Architecture (MEDIUM Risk, HIGH Value)

**What QUI Does:**
- Vertical sidebar (150px wide) with scrollable tabs
- Main content area (800px wide)
- Bottom action buttons (Edit Mode, CDM Settings, etc.)
- Search tab at bottom with section separator

**Benefits for SUF:**
- Cleaner mental model for users (sidebar like WoW options)
- Delegates tab builders to separate modules (easier maintenance)
- Sticky sub-tab bar support (currently: Bars, Auras, Health, each have subs)
- Space-efficient for 15+ option pages

**Implementation Approach:**
1. Refactor OptionsV2/Layout.lua to create sidebar (vertical tab buttons vs horizontal)
2. Delegate each current page to a builder module (e.g., BarsBuild.lua, AurasBuilder.lua, GlobalBuilder.lua)
3. Integrate bottom action buttons (Reload, Edit Mode, CDM Settings)
4. Update search to highlight sidebar section from results

**Files to Create:**
- Modules/UI/OptionsV2/SidebarLayout.lua (new - replaces horizontal grid with vertical sidebar)
- Modules/UI/OptionsV2/PageBuilders.lua (new - delegates to individual builders)
- Modules/UI/OptionsV2/BarSections/ (new dir) - individual page builders

**Files to Modify:**
- Modules/UI/OptionsV2/Layout.lua (use sidebar instead of grid)
- Modules/UI/OptionsV2/Bootstrap.lua (integrate bottom buttons)
- SimpleUnitFrames.toc (new file loading)

**Estimated Effort:** 6-8 hours (moderate refactoring)

**Risk Level:** 🟡 MEDIUM
- Breaking change: UI appearance will shift (good change, but users notice)
- Validation: Test all tabs accessible, search navigation works
- Rollback: Revert to horizontal tabs (Layout.lua reload)

**Value:** 🟢🟢 HIGH
- Better UX (familiar sidebar pattern)
- Easier maintenance (delegated builders)
- Visually cleaner

---

### A.2: Advanced Theme Color System with Accent Derivation (MEDIUM Risk, MEDIUM Value)

**What QUI Does (framework.lua lines 60-85):**
```lua
function GUI:ApplyAccentColor(r, g, b)
    local function lerp(a, b, t) return a + (b - a) * t end
    -- Derives light/dark/hover variants from single accent
    C.accentLight[1] = lerp(r, 1, 0.3)      -- 30% toward white
    C.accentLight[2] = lerp(g, 1, 0.3)
    C.accentLight[3] = lerp(b, 1, 0.3)
    C.accentDark[1], C.accentDark[2], C.accentDark[3] = r * 0.5, g * 0.5, b * 0.5
    C.accentHover[1] = lerp(r, 1, 0.15)     -- 15% toward white
    -- ... updates all dependent colors
    RefreshCachedColors()  -- Caches ~10 color tables for hot-path performance
end
```

**Benefits for SUF:**
- Single accent color picker → all UI colors automatically updated
- No more inconsistent theming (currently: colors defined individually per widget)
- Cached color components for performance (unpack colors once, not in loop)
- Mint/Amber/Cool theme presets can be built on top

**Implementation Approach:**
1. Add accent color picker to Base/Global options
2. Create color derivation function (lerp, darkening, lightening)
3. Cache all derived colors on startup
4. Update existing Theme.lua to read from cache
5. Optionally add preset buttons (Mint, Amber, Cool themes)

**Files to Modify:**
- Modules/UI/Theme.lua (add accent derivation)
- Modules/UI/OptionsV2/Registry.lua (add accent color picker widget to Global/Base)
- SimpleUnitFrames.lua (cache colors on load)

**Estimated Effort:** 2-3 hours

**Risk Level:** 🟡 MEDIUM
- Colors will change immediately when picker moved (good, but test perceptually)
- Performance impact: negligible (colors cached)
- Validation: Test all UI elements update, no flashing/redraws

**Value:** 🟢 MEDIUM
- Better UX (single control → all colors)
- Consistent theming
- Professional appearance

---

### A.3: Settings Search with Navigation Index (LOW Risk, MEDIUM Value)

**What QUI Does (framework.lua + options.lua):**
- Settings Registry: Maps setting names to their locations (tab, section, widget type)
- Navigation Registry: Maps category names to tabs (e.g., "anchoring" → AnchoringTab)
- Search results show both: matching settings + matching tabs/sections
- Click result → navigates to correct tab + scrolls to section header

**Benefits for SUF:**
- Current search finds settings but doesn't navigate well
- QUI's approach: search "health color" → highlights Health Settings tab + jumps to Color section
- Better discovery for users with 15+ option pages

**Implementation Approach:**
1. Enhance SettingsRegistry in OptionsV2 to include tab/section info
2. Expand NavigationRegistry to include category aliases (e.g., "bars" = "bars/general")
3. Enhance Search.lua to support scroll-to-section
4. Add visual link between search results and source tab

**Files to Modify:**
- Modules/UI/OptionsV2/Registry.lua (add tab/section metadata)
- Modules/UI/OptionsV2/Search.lua (add navigation behavior)

**Estimated Effort:** 1-2 hours

**Risk Level:** 🟢 LOW
- Non-breaking (search already works, just better)
- No UI changes (only search result behavior)

**Value:** 🟢 MEDIUM
- Better user discoverability
- Supports growing complexity of options

---

## SECTION B: LOW-RISK ENHANCEMENTS

These are pure additions with zero breaking changes.

### B.1: Systematic Secret Value Handling (6 Safe Wrappers)

**What QUI Does (core/utils.lua lines 150-220):**
```lua
-- 6 unsafe-value handlers covering all edge cases
IsSecretValue(value)           → boolean (detects if value = nil/secret)
SafeValue(value, fallback)     → any (returns value or fallback)
SafeCompare(a, b)             → boolean|nil (compares without arithmetic)
SafeArithmetic(val, op, fall)  → number (safe %, *, /, +, -)
SafeToNumber(value, fall)      → number (converts with pcall)
SafeToString(value, fall)      → string (converts with pcall)
```

**Current SUF Situation:**
- Has SafeNumber and SafeText (lines ~765-835 in SimpleUnitFrames.lua)
- Missing: SafeCompare, SafeArithmetic, SafeToNumber, SafeToString
- Scattered usage (not systematic)

**Benefits:**
- Complete toolkit for secret value handling
- Pattern consistency
- Better error messages in debug mode

**Implementation:**
1. Add 4 missing wrappers to SimpleUnitFrames.lua safe value section
2. Add to helper export (addon._core helpers)
3. Update existing code to use where appropriate (non-breaking)

**Files to Modify:**
- SimpleUnitFrames.lua (add 4 new safe functions, ~50 lines)

**Estimated Effort:** 30 minutes

**Risk Level:** 🟢 LOW
- Pure additions (no changes to existing functions)
- No behavioral changes (existing code unchanged)

**Value:** 🟢 MEDIUM
- Future-proofs against secret value issues
- Enables systematic refactoring (not urgent)

---

### B.2: SafeReload System (Prevent Addon Action Forbidden)

**What QUI Does (core/main.lua lines 40-55):**
```lua
-- Check InCombatLockdown before reload
if InCombatLockdown() then
    -- Queue for PLAYER_REGEN_ENABLED
    addon:ScheduleReload("after_combat")
    ShowUIPanel(ReloadConfirmationDialog)  -- User-friendly popup
else
    -- Safe to reload immediately
    ReloadUI()
end
```

**Current SUF Situation:**
- OptionsWindow has reload options on various setting changes
- Users can hit reload during combat → ADDON_ACTION_FORBIDDEN error
- No graceful handling

**Benefits:**
- No more "addon action forbidden" errors
- User-friendly popup shows reload timing
- Works with QueueOrRun protected operations system

**Implementation:**
1. Create Core/SafeReload.lua module
2. Add SafeReload() function with InCombatLockdown check
3. Queue deferred reload via addon:QueueOrRun() if in combat
4. Show confirmation popup after PLAYER_REGEN_ENABLED
5. Call from OptionsWindow.lua reload buttons

**Files to Create:**
- Core/SafeReload.lua (50-80 lines)

**Files to Modify:**
- SimpleUnitFrames.lua (register SafeReload method)
- Modules/UI/OptionsWindow.lua (call SafeReload on reload button clicks)
- SimpleUnitFrames.toc (load SafeReload.lua)

**Estimated Effort:** 1 hour

**Risk Level:** 🟢 LOW
- Non-breaking (only called from option buttons)
- Fallback: normal ReloadUI() if addon error occurs

**Value:** 🟢 MEDIUM
- Better UX (no error messages)
- Professional addon behavior

---

### B.3: Profile Import/Export Validation

**What QUI Does (core/profile_io.lua lines 250-330):**
```lua
function ValidateImportTree(tree, maxDepth, maxNodes)
    -- Prevents crashes from malformed imports
    if type(tree) ~= "table" then return false, "Not a table" end
    if #tree > maxNodes then return false, "Too many nodes" end
    -- Check for unsupported types (functions, threads, userdata)
    for k, v in pairs(tree) do
        if type(v) == "function" or type(v) == "thread" or type(v) == "userdata" then
            return false, "Unsupported type: " .. type(v)
        end
        if type(v) == "table" and maxDepth > 0 then
            return ValidateImportTree(v, maxDepth - 1, maxNodes)
        end
    end
    return true
end
```

**Current SUF Situation:**
- Profiles can be exported as strings
- No validation on import → potential crashes if string malformed
- Error handling exists but not as comprehensive

**Benefits:**
- Prevents crashes from bad import strings
- Clear error messages to user
- Handles edge cases (deep nesting, huge tables)

**Implementation:**
1. Create Modules/UI/ProfileValidator.lua
2. Port QUI's ValidateImportTree function
3. Integrate into profile import handler (OptionsWindow.lua)
4. Show validation errors in UI

**Files to Create:**
- Modules/UI/ProfileValidator.lua (60-100 lines)

**Files to Modify:**
- Modules/UI/OptionsWindow.lua (profile import section - call ValidateImportTree)
- SimpleUnitFrames.toc

**Estimated Effort:** 1.5-2 hours

**Risk Level:** 🟢 LOW
- Non-breaking (only adds validation)
- Prevents errors, doesn't change success path

**Value:** 🟢 MEDIUM
- Better error handling
- Professional-grade robustness

---

### B.4: API Version Compatibility Patterns

**What QUI Does (core/main.lua lines 20-40):**
```lua
local tocVersion = tonumber((select(4, GetBuildInfo()))) or 0

function GetHealthPct(unit, usePredicted)
    if tocVersion >= 120000 and type(UnitHealthPercent) == "function" then
        -- 12.01+ supports UnitHealthPercent with curve parameter
        ok, pct = pcall(UnitHealthPercent, unit, usePredicted, CurveConstants)
    else
        -- Fallback for older builds
        local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
        pct = maxHealth > 0 and health / maxHealth or 0
    end
    return pct
end
```

**Current SUF Situation:**
- Doesn't cache tocVersion
- Uses GetBuildInfo every time
- Limited API version compatibility checks

**Benefits:**
- Future-proof for API changes (12.01, 12.1, etc.)
- Performance (cached version, no string parsing per call)
- Systematic pattern for all version-dependent code

**Implementation:**
1. Cache tocVersion in SimpleUnitFrames.lua (line 1)
2. Create version-aware wrapper functions for common APIs
3. Document pattern for future changes

**Files to Modify:**
- SimpleUnitFrames.lua (add tocVersion cache, update tag handlers)

**Estimated Effort:** 30 minutes

**Risk Level:** 🟢 LOW
- Pure additions (no breaking changes)
- Better performance (cached vs repeated parsing)

**Value:** 🟢 MEDIUM
- Future-proofs against WoW API changes
- Performance improvement

---

## SECTION C: MEDIUM-RISK ENHANCEMENTS

These require moderate refactoring but use proven patterns.

### C.1: Pixel-Perfect Scaling System (4-5 hours)

**What QUI Does (core/scaling.lua lines 1-100):**
```lua
-- Calculate physical pixel size at current UI scale
function GetPixelSize(frame)
    local pixelHeight = 768 / (GetPhysicalScreenSize() * frame:GetEffectiveScale())
    return pixelHeight  -- e.g., 1.5 physical pixels = 1 virtual pixel needed
end

-- Round values to nearest pixel
function Pixels(n, frame)
    return math.floor(GetPixelSize(frame) * n + 0.5)
end

-- Use when setting frame sizes/positions
frame:SetHeight(Pixels(20, frame))  -- Exact 20 physical pixels at any UI scale
```

**Benefits:**
- Borders render cleanly at all UI scales (75%, 100%, 125%)
- No more 1.5px borders rendering as fuzzy
- Consistent appearance across all screen resolutions

**Current SUF:**
- Uses fixed pixel values
- Borders can appear blurry at non-100% UI scales

**Implementation:**
1. Create Core/PixelPerfect.lua with GetPixelSize, Pixels, PixelRound
2. Cache screen dimensions on UI_SCALE_CHANGED
3. Update frame sizing in all unit frame builders
4. Update theme border creation
5. Update Movers.lua to preserve pixel-perfect offsets

**Files to Create:**
- Core/PixelPerfect.lua (80-120 lines)

**Files to Modify:**
- Units/Player.lua, Units/Target.lua, Units/Pet.lua, Units/Focus.lua, Units/Tot.lua (sizing)
- Modules/UI/Theme.lua (border creation)
- Modules/System/Movers.lua (position tracking)
- SimpleUnitFrames.lua (cache screen dimensions)
- SimpleUnitFrames.toc

**Estimated Effort:** 4-5 hours

**Risk Level:** 🟡 MEDIUM
- Non-breaking (default sizes unchanged)
- Validation: Visual inspection at 75%, 100%, 125% UI scales
- Rollback: Revert Core/PixelPerfect.lua changes

**Value:** 🟢🟢 HIGH
- Visual quality improvement (most important to users)
- Professional appearance

---

### C.2: Modular Options Page Builders (Refactoring, 3-4 hours)

**What QUI Does:**
- Each options page built by separate file (GeneralOptions.lua, UnitFramesOptions.lua, etc.)
- Page builder called from central registry
- Each builder responsible for creating its widgets

**Current SUF:**
- OptionsTabs.lua (1800+ lines) defines all tabs
- OptionsWindow.lua builds tabs inline
- Hard to navigate, understand, modify

**Benefits:**
- Each page in own file (easier to find, modify)
- Clear separation of concerns
- Better for team collaboration

**Implementation:**
1. Extract each tab into builder file (Modules/UI/Builders/GlobalBuilder.lua, BarBuilder.lua, etc.)
2. Register builders in central registry
3. Update OptionsWindow.lua to call builders
4. Clean up OptionsTabs.lua (remove inline definitions)

**Files to Create:**
- Modules/UI/Builders/ (new directory)
- Modules/UI/Builders/GlobalBuilder.lua
- Modules/UI/Builders/BarBuilder.lua
- Modules/UI/Builders/AuraBuilder.lua
- ... (one per tab)

**Files to Modify:**
- Modules/UI/OptionsWindow.lua (call builders instead of inline)
- Modules/UI/OptionsTabs.lua (remove inline definitions, keep metadata)
- SimpleUnitFrames.toc (load builders)

**Estimated Effort:** 3-4 hours

**Risk Level:** 🟡 MEDIUM
- Non-breaking (same final UI)
- Validation: All tabs render, all settings work
- Rollback: Revert OptionsWindow.lua, OptionsTabs.lua

**Value:** 🟢 MEDIUM
- Code maintenance (easier to work with)
- Scalability (easier to add/remove tabs)

---

### C.3: Backwards Compatibility Profile Migrations (3-4 hours)

**What QUI Does (core/compatibility.lua):**
```lua
local function BackwardsCompat()
    MigrateDatatextSlots()        -- v1 → v2 datatext format
    MigratePerSlotSettings()      -- v2 → v3 per-slot options
    MigrateMasterTextColors()     -- v3 → v4 color system
    MigrateCooldownSwipeV2()      -- v4 → v5 cooldown format
end

-- Called during ADDON_LOADED
if profile.version < CURRENT_VERSION then
    BackwardsCompat()
    profile.version = CURRENT_VERSION
end
```

**Current SUF:**
- Profiles stored in AceDB
- Schema changes sometimes break old profiles
- No systematic migration support

**Benefits:**
- Users' profiles continue working across addon updates
- No "reset to defaults" required
- Professional addon behavior

**Implementation:**
1. Create Modules/System/ProfileMigrations.lua
2. Define migration functions (one per schema version change)
3. Add version field to profile
4. Call migrations on load if version outdated
5. Document migration pattern for future changes

**Files to Create:**
- Modules/System/ProfileMigrations.lua (100-200 lines)

**Files to Modify:**
- SimpleUnitFrames.lua (call migrations on load)
- SimpleUnitFrames.toc

**Estimated Effort:** 3-4 hours

**Risk Level:** 🟡 MEDIUM
- Breaking: If migration logic wrong, users' profiles break
- Validation: Test with old profile data, verify settings migrate correctly
- Rollback: Revert ProfileMigrations.lua, users can manually re-apply settings

**Value:** 🟢 MEDIUM
- User satisfaction (profiles don't break)
- Professional quality

---

## SECTION D: HIGH-RISK ENHANCEMENTS

Large architectural changes with potential for significant impact.

### D.1: Modular Cooldown System Port (8-12 hours)

**What QUI Has:**
- Modular Cooldown Manager (separate from action bars)
- Configurable cooldown target (action buttons, pet skills, runes)
- Rich UI for customization (position, scale, count format)

**SUF Current:**
- No built-in cooldown system
- Relies on oUF elements (basic)
- Users use third-party addons (Oui Damage Numbers, GoldpawUI, etc.)

**Benefits:**
- POV of SUF users: Option for built-in cooldown visuals
- Reduces dependency on third-party addons
- Integrated with SUF's theming

**Risk:**
- Complex feature with many edge cases
- Potential conflicts with third-party cooldown addons
- Maintenance burden (requires cooldown sprite sheet management)

**Implementation Scope:**
1. Study QUI's cooldown system (modules/cooldowns/)
2. Port to SUF as optional module
3. Add to options (toggle, positioning, styling)
4. Test for conflicts with popular addons

**Estimated Effort:** 8-12 hours (high uncertainty)

**Risk Level:** 🔴 HIGH
- Complex feature (many edge cases)
- Potential addon conflicts
- Maintenance burden
- Users may not need (third-party alternatives exist)

**Value:** 🟡 MEDIUM
- Nice-to-have feature (not essential)
- Reduces addon count for users who want cooldowns in SUF
- Better integration with SUF theme

**Recommendation:** 🔴 DEFER for now
- Focus on core functionality improvements first
- Revisit if users specifically request integrated cooldoms

---

### D.2: Advanced Aura Filtering System (10-15 hours)

**What QUI Has:**
- Whitelist/blacklist auras by name
- Filter by type (buff, debuff, both)
- Filter by application (player, targets, both)
- Regex pattern matching for dynamic filtering

**SUF Current:**
- Auras display with basic options (max count, time format)
- No built-in filtering
- Users customize via oUF's aura settings

**Benefits:**
- Users can hide irrelevant auras (e.g., all buffs, specific debuffs)
- Better UI clarity (show only important auras)
- Competitive advantage vs other frame addons

**Risk:**
- Complex configuration UI
- Many edge cases (regex behavior, buff/debuff distinction)
- Maintenance burden (aura list updates)

**Implementation Scope:**
1. Study QUI's aura filtering (modules/frames/auras.lua)
2. Port filter system to oUF's aura element
3. Add filter management UI (whitelist/blacklist tabs)
4. Add regex pattern support
5. Test with common aura scenarios

**Estimated Effort:** 10-15 hours

**Risk Level:** 🔴 HIGH
- Complex feature with many permutations
- UI complexity (filter management page alone is substantial)
- Edge cases (boss debuffs, special effects, buffs from other players)

**Value:** 🟡 MEDIUM
- Power users appreciate aura filtering
- General users may not use heavily
- Niche feature

**Recommendation:** 🔴 DEFER for now
- Medium ROI given complexity
- Revisit if user demand justifies effort

---

### D.3: Frame Preview/Builder Mode (6-8 hours)

**What QUI Lacks but SUF Could Add:**
- Preview mode showing frame layout without combat/real resources
- Renders fake health, power, auras for UI testing
- Helpful for customizing appearances

**SUF Current:**
- Options affect live frames
- Users must enter combat or manually edit settings to see changes
- Difficult to design optimal layout

**Benefits:**
- Users can design frames without combat
- See appearance changes in real-time
- Better UX for theme customization

**Risk:**
- Significant new feature (not critical)
- Edge cases (what if player health/power out of sync with preview?)
- Performance impact (rendering fake data)

**Implementation Scope:**
1. Create preview data generator (fake health %, power, auras)
2. Add preview toggle to options
3. Update frame rendering to use preview data when active
4. Test for UI glitches (tooltips showing fake data, etc.)

**Estimated Effort:** 6-8 hours

**Risk Level:** 🔴 HIGH
- New feature with uncertain UX implications
- Performance considerations
- Testing complexity

**Value:** 🟡 MEDIUM
- Nice-to-have (not essential)
- Power users appreciate
- Better first-time setup experience

**Recommendation:** 🟡 CONSIDER in Phase 5 (polish phase)
- Not urgent, but good for user experience
- Implement after core features stable

---

## SECTION E: QUICK WIN IMPLEMENTATION ORDER

### Recommended Phase Breakdown:

**Phase 1: Low-Effort Quick Wins (2-3 hours total)**
1. ✅ B.1: Safe Helpers (30 min)
2. ✅ B.2: SafeReload System (1 hour)
3. 🔜 B.3: Profile Validation (1 hour)
4. ⛔ B.4: API Version Compatibility (removed for 12.0.x-only scope)

**Phase 2: UI Improvements (8-10 hours total)**
1. A.2: Accent Color System (2-3 hours) — Quick win for theming
2. A.3: Search Navigation (1-2 hours) — Enhances existing search
3. C.2: Modular Builders (3-4 hours) — Code quality improvement

**Phase 3: Visual Polish (5-6 hours total)**
1. C.1: Pixel-Perfect Scaling (4-5 hours) — Highest visual impact

**Phase 4 (Optional): Advanced Features (20+ hours - DEFER)**
1. A.1: Sidebar Tabs (6-8 hours) — Major UI refactor
2. C.3: Profile Migrations (3-4 hours) — Infrastructure
3. D.* (HIGH-RISK features) — Only if time + demand permits

---

## SECTION F: IMPLEMENTATION RESOURCES

### QUI Reference Code Locations
- [Sidebar UIArchitecture](../QUI/options/framework.lua) — Color system, theme management (5124 lines)
- [Tab System](../QUI/options/options.lua) — Tab registry, page builders (200 lines)
- [Pixel-Perfect Scaling](../QUI/core/scaling.lua) — GetPixelSize, Pixels functions (487 lines)
- [UIKit Factories](../QUI/core/uikit.lua) — Frame primitives (503 lines)
- [Safe Helpers](../QUI/core/utils.lua) — 7 unsafe-value wrappers (976 lines)
- [SafeReload Pattern](../QUI/core/main.lua) — Combat-aware reload (lines 40-55)
- [Profile Validation](../QUI/core/profile_io.lua) — ValidateImportTree (667 lines)
- [Profile Migration](../QUI/core/compatibility.lua) — Backwards compat pattern (180 lines)

### SUF Reference
- [OptionsWindow.lua](./Modules/UI/OptionsWindow.lua) — Current options implementation
- [OptionsV2/](./Modules/UI/OptionsV2/) — Modern options system
- [SimpleUnitFrames.lua](./SimpleUnitFrames.lua) — Main addon (lines 765-835: safe helpers)
- [Theme.lua](./Modules/UI/Theme.lua) — Current theming
- [Units/*.lua](./Units/) — Frame spawning (8 files)

---

## SECTION G: SUCCESS CRITERIA & VALIDATION

### Before Starting Any Phase:
- [ ] Understand the QUI implementation (read reference code)
- [ ] Identity all affected SUF files (create list)
- [ ] Plan rollback strategy (git branch + revert)
- [ ] Estimate time accurately (add 20% buffer)

### After Completing Each Improvement:
- [ ] `/reload` addon and verify no Lua errors
- [ ] Test in safe zone first (no combat)
- [ ] Test in dungeons/raids if applicable
- [ ] Verify no performance regressions (`/SUFperf`)
- [ ] Visually inspect UI appearance (especially Theme.lua changes)
- [ ] Update WORK_SUMMARY.md
- [ ] Commit with clear message

### Risk Mitigation:
- **Low-Risk Items:** Commit directly to main branch
- **Medium-Risk Items:** Create feature branch, test thoroughly, code review before merge
- **High-Risk Items:** Create separate branch, extended testing, community beta before merge

---

## SECTION H: NOTES & DECISIONS

**This Analysis Captured:**
- 8 low/medium/high-risk enhancements from QUI
- 3 options UI/UX improvements
- Clear effort/value/risk assessments
- Specific code references for implementation
- Recommended implementation order

**Not Included (Out of Scope):**
- Advanced ML optimization (D.1 cooldown system unnecessary complexity)
- Custom action bar system (3624 line ClickCasting removal just completed)
- Transmog system port (orthogonal to unit frames)
- Custom tracker implementation (niche feature)

**Future Revisit Points:**
- Cooldom system (D.1): If users request "integrated cooldowns"
- Aura filtering (D.2): If power users ask for advanced aura management
- Preview mode (D.3): After core features stabilized (Phase 5 polish)

---

**Next Steps:** Continue with Phase 2 UI improvements.
