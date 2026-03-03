# TODO.md - SUF Enhancement Implementation Roadmap

**Last Updated:** 2026-03-06  
**Current Phase:** Planning & prioritization (RESEARCH complete)  
**Status:** Ready to start Phase 1 quick wins  

---

## PHASE 1: Quick Wins (2-3 hours total)

Low-effort, high-confidence enhancements. Start here.

### Task 1.1: API Version Compatibility Pattern (30 min) ⭐ START HERE

**Objective:** Cache `tocVersion` and add future-proof API version checks

**What to Do:**
1. Add `local tocVersion = tonumber((select(4, GetBuildInfo()))) or 0` to SimpleUnitFrames.lua line ~50
2. Create version checks for APIs that changed in 12.01+:
   - UnitHealthPercent (now supports curve parameter)
   - UnitPowerPercent (likewise)
3. Wrap tag handlers with version checks
4. Document pattern for future API changes

**Files to Modify:**
- SimpleUnitFrames.lua (add tocVersion, update tag handlers)

**Validation:**
- [ ] `/reload` and verify no errors
- [ ] Test on WoW build 120000+ (12.0)
- [ ] Test on WoW build 124025+ (12.0.1+) if available

**Time Estimate:** 30 min  
**Difficulty:** Easy  
**Risk:** 🟢 LOW

---

### Task 1.2: Expand Safe Value Helpers (45 min)

**Objective:** Add 4 missing safe value wrappers (SafeCompare, SafeArithmetic, SafeToNumber, SafeToString)

**What to Do:**
1. Open SimpleUnitFrames.lua safe value section (lines ~765-835)
2. Add functions:
   ```lua
   SafeCompare(a, b)              -- Compare values without arithmetic
   SafeArithmetic(val, op, fall)  -- Safe arithmetic (+, -, *, /, %)
   SafeToNumber(val, fall)        -- Convert to number with pcall
   SafeToString(val, fall)        -- Convert to string with pcall
   ```
3. Add to addon helper exports (_core)
4. Document pattern (comment block at top)

**Files to Modify:**
- SimpleUnitFrames.lua (safe helpers section, ~30 new lines)

**Validation:**
- [ ] `/reload` and verify no errors
- [ ] Check each function in debug console (`/run print(SafeCompare(...))`)

**Time Estimate:** 45 min  
**Difficulty:** Easy  
**Risk:** 🟢 LOW

---

### Task 1.3: SafeReload System (1 hour)

**Objective:** Prevent "addon action forbidden" when reloading during combat

**What to Do:**
1. Create `Core/SafeReload.lua` with:
   ```lua
   function addon:SafeReload()
       if InCombatLockdown() then
           addon:QueueOrRun(function()
               ReloadUI()
               -- Show confirmation popup
           end, {
               key = "SafeReload",
               type = "UI_RELOAD",
               priority = "NORMAL"
           })
       else
           ReloadUI()
       end
   end
   ```
2. Register in SimpleUnitFrames.lua
3. Call from OptionsWindow.lua reload buttons
4. Add to SimpleUnitFrames.toc load order

**Files to Create:**
- Core/SafeReload.lua (60-80 lines)

**Files to Modify:**
- SimpleUnitFrames.lua (register SafeReload method)
- Modules/UI/OptionsWindow.lua (call SafeReload on reload buttons)
- SimpleUnitFrames.toc (add Core/SafeReload.lua)

**Validation:**
- [ ] `/reload` in safe zone (should reload immediately)
- [ ] Try reload during combat scenario (should queue for after combat)
- [ ] Verify no "addon action forbidden" errors

**Time Estimate:** 1 hour  
**Difficulty:** Easy-Medium  
**Risk:** 🟢 LOW (only called from option buttons)

---

### Task 1.4: Profile Import Validation (1 hour)

**Objective:** Prevent crashes from malformed profile import strings

**What to Do:**
1. Create `Modules/UI/ProfileValidator.lua` with ValidateImportTree function
2. Check for:
   - Correct data types (no functions, threads, userdata)
   - Depth limits (max 20 levels deep)
   - Node count limits (max 50k nodes)
3. Integrate into profile import handler (OptionsWindow.lua)
4. Show user-friendly error messages on failure

**Files to Create:**
- Modules/UI/ProfileValidator.lua (80-120 lines)

**Files to Modify:**
- Modules/UI/OptionsWindow.lua (call ValidateImportTree on import)
- SimpleUnitFrames.toc

**Validation:**
- [ ] `/reload` and test normal profile import (should work)
- [ ] Try importing a corrupted profile string (should show error)
- [ ] Verify error message is clear to user

**Time Estimate:** 1 hour  
**Difficulty:** Medium  
**Risk:** 🟢 LOW (only adds validation, doesn't change success path)

---

**Phase 1 Summary:**
- **Total Time:** 3-3.5 hours
- **Total Risk:** LOW across all items
- **Outcome:** Cleaner codebase, better error handling, future-proof APIs
- **Next:** Move to Phase 2 after validation

---

## PHASE 2: UI/Visual Improvements (8-10 hours total)

Medium-effort, high-value enhancements. Better user experience.

### Task 2.1: Accent Color Theme System (2-3 hours)

**Objective:** Single accent color picker → all UI colors automatically update

**What to Do:**
1. Study QUI's color derivation (framework.lua, lines 60-85)
2. Create color lerp/darkening functions in Theme.lua
3. Add accent color picker to Options (Global/Base section)
4. Cache all derived colors on startup
5. Update Theme.lua to read from cache

**Files to Modify:**
- Modules/UI/Theme.lua (add accent derivation functions + cache)
- Modules/UI/OptionsV2/Registry.lua (add accent color picker widget)
- SimpleUnitFrames.lua (cache colors on UI_SCALE_CHANGED event)

**Validation:**
- [ ] Test accent color picker (should update all UI colors immediately)
- [ ] Try different accent colors (mint, amber, cool, warm)
- [ ] Verify all frames update without flashing/redraws
- [ ] Check performance (`/SUFperf` should show no frame spike)

**Time Estimate:** 2-3 hours  
**Difficulty:** Medium  
**Risk:** 🟡 MEDIUM (colors change immediately, potential visual glitches)

---

### Task 2.2: Search Navigation Enhancement (1-2 hours)

**Objective:** Search results now navigate to correct tab + scroll to section

**What to Do:**
1. Enhance SettingsRegistry in OptionsV2/Registry.lua to include tab/section info
2. Expand NavigationRegistry with category aliases (e.g., "bars" = Bars tab)
3. Update Search.lua to support scroll-to-section behavior
4. Add visual link between search results and source tab

**Files to Modify:**
- Modules/UI/OptionsV2/Registry.lua (add metadata)
- Modules/UI/OptionsV2/Search.lua (add navigation behavior)

**Validation:**
- [ ] Search for setting (e.g., "health color")
- [ ] Click result → should navigate to correct tab and scroll to section
- [ ] Verify existing search still works (no regressions)

**Time Estimate:** 1-2 hours  
**Difficulty:** Medium  
**Risk:** 🟢 LOW (enhancement to existing search, non-breaking)

---

### Task 2.3: Modular Options Page Builders (3-4 hours)

**Objective:** Break up OptionsTabs.lua into separate builder files (code quality)

**What to Do:**
1. Extract each tab into separate builder file:
   - Modules/UI/Builders/GlobalBuilder.lua
   - Modules/UI/Builders/BarBuilder.lua
   - Modules/UI/Builders/AuraBuilder.lua
   - ... (one per existing tab)
2. Register builders in central registry
3. Update OptionsWindow.lua to call builders
4. Update OptionsTabs.lua to keep only metadata

**Files to Create:**
- Modules/UI/Builders/ (new directory)
- Modules/UI/Builders/*.lua (one per existing tab, ~8 files)

**Files to Modify:**
- Modules/UI/OptionsWindow.lua (refactor to call builders)
- Modules/UI/OptionsTabs.lua (remove inline builders)
- SimpleUnitFrames.toc (load new builder files)

**Validation:**
- [ ] All tabs render correctly
- [ ] All settings functional
- [ ] Search still works
- [ ] No visual regressions

**Time Estimate:** 3-4 hours  
**Difficulty:** Hard (large refactor)  
**Risk:** 🟡 MEDIUM (non-breaking, but large change scope)

---

### Task 2.4: Sidebar Tab UI Architecture (6-8 hours) [OPTIONAL - Next Phase]

**Objective:** Adopt vertical sidebar tabs like QUI (visual overhaul)

**Status:** 🔴 DEFER to Phase 3  
**Reason:** Largest change, requires careful UX testing

---

**Phase 2 Summary:**
- **Total Time:** 6-9 hours (or 12-13 with Task 2.4)
- **Total Risk:** LOW to MEDIUM
- **Outcome:** Better UX, client-friendly colors, easier code maintenance
- **Blockers:** None (all items independent)
- **Next:** Phase 3 visual polish after validation

---

## PHASE 3: Visual Polish (5-6 hours total)

High-impact visual improvements.

### Task 3.1: Pixel-Perfect Scaling System (4-5 hours)

**Objective:** Unit frames render cleanly at all UI scales (75%, 100%, 125%)

**What to Do:**
1. Study QUI's implementation (scaling.lua, lines 1-100)
2. Create Core/PixelPerfect.lua with:
   - GetPixelSize(frame) → physical pixel size
   - Pixels(n, frame) → round to nearest pixel
   - PixelRound(value, frame) → utility
3. Cache screen dimensions on UI_SCALE_CHANGED
4. Update all frame sizing in Units/ directory
5. Update Theme.lua border creation
6. Update Movers.lua position tracking

**Files to Create:**
- Core/PixelPerfect.lua (80-120 lines)

**Files to Modify:**
- Units/Player.lua, Units/Target.lua, Units/Pet.lua, Units/Focus.lua, Units/Tot.lua (sizing)
- Modules/UI/Theme.lua (border creation)
- Modules/System/Movers.lua (position tracking)
- SimpleUnitFrames.lua (cache screen dimensions)
- SimpleUnitFrames.toc

**Validation:**
- [ ] Screenshot unit frames at 75% UI scale (borders clean)
- [ ] Screenshot at 100% UI scale (borders consistent)
- [ ] Screenshot at 125% UI scale (no seams/gaps)
- [ ] Test window drag/resize (pixel-perfect positions preserved)

**Time Estimate:** 4-5 hours  
**Difficulty:** Hard (touches many files, many edge cases)  
**Risk:** 🟡 MEDIUM (visual regressions possible)

**Value:** 🟢🟢 HIGH (most visible improvement)

---

**Phase 3 Summary:**
- **Total Time:** 4-5 hours
- **Total Risk:** MEDIUM (visual testing critical)
- **Outcome:** Professional appearance at all UI scales
- **Visual Impact:** HIGH (users immediately notice improvement)
- **Next:** Phase 4 or community feedback

---

## PHASE 4: Infrastructure & Advanced Features (20+ hours - DEFER)

Large features that deserve dedicated sessions.

### Task 4.1: Backwards Compatibility Profile Migrations (3-4 hours)

**Status:** 🟡 OPTIONAL  
**Objective:** Users' profiles continue working across addon updates

**Why Later:**
- Needed only when schema changes happen
- Can add retroactively (no rush)

---

### Task 4.2: Sidebar Tab UI Overhaul (6-8 hours)

**Status:** 🟡 OPTIONAL  
**Objective:** Vertical sidebar tabs like QUI (QUI reference: options/framework.lua, options/options.lua)

**Why Later:**
- Largest change (total UI redesign)
- Requires extensive UX testing
- Can be done after core features solid

---

### Task 4.3 - 4.5: High-Risk Features (20+ hours - DEFER)

- **Task 4.3:** Modular Cooldown System (8-12 hours) - 🔴 LOW PRIORITY
- **Task 4.4:** Advanced Aura Filtering (10-15 hours) - 🔴 LOW PRIORITY
- **Task 4.5:** Frame Preview Mode (6-8 hours) - 🟡 MEDIUM PRIORITY for Phase 5 polish

**Status:** All DEFER unless user demand justifies effort

---

## RECOMMENDED WEEKLY SCHEDULE

### Week 1: Phase 1 Quick Wins (3-4 hours)
```
Monday:  Task 1.1 (API Version Compat - 30 min)
Tuesday: Task 1.2 (Safe Helpers - 45 min) + Task 1.3 (SafeReload - 1 hour)
Wednesday: Task 1.4 (Profile Validation - 1 hour)
Thursday: Validation & Testing
Friday: Code Review & Commit
```
**Time Total:** 3-4 hours  
**Risk:** 🟢 LOW across all tasks

---

### Week 2-3: Phase 2 UI Improvements (6-9 hours)

**Pick Your Path:**

**Path A: UI Quality Focus (6-7 hours)**
```
Week 2 Mon-Wed: Task 2.1 (Accent Colors - 2-3 hours)
Week 2 Thu-Fri: Task 2.2 (Search Nav - 1-2 hours)
Week 3 Mon-Tue: Task 2.3 (Modular Builders - 3-4 hours)
```

**Path B: Defer Builders (2-3 hours)**
```
Week 2: Task 2.1 + Task 2.2 only
(Save Task 2.3 for Phase 4)
```

---

### Week 4: Phase 3 Visual Polish (5-6 hours)

```
Mon-Fri: Task 3.1 (Pixel-Perfect Scaling - 4-5 hours)
+ Testing (extensive screenshots at different UI scales)
```

**Visual Impact:** 🟢 HIGH (users immediately notice)

---

## IMPLEMENTATION CHECKLIST (Per Task)

### Before Starting:
- [ ] Read relevant QUI reference code (links in RESEARCH.md)
- [ ] Create git feature branch (e.g., `feature/api-compat`)
- [ ] Estimate time (add 20% buffer)
- [ ] List all affected files

### During Implementation:
- [ ] Follow existing code style (no reformatting)
- [ ] Add comments for non-obvious logic
- [ ] Test `/reload` frequently
- [ ] Verify no new Lua errors in debug console

### After Completion:
- [ ] `/reload` addon and verify no errors
- [ ] Test in safe zone (no combat)
- [ ] Test in dungeons/raids (if applicable)
- [ ] Run `/SUFperf` (verify no frame time spike)
- [ ] Take screenshots (visual verification)
- [ ] Update WORK_SUMMARY.md
- [ ] Create commit with clear message
- [ ] Merge to main branch

---

## SUCCESS METRICS

### Phase 1 (After Completion):
- ✅ API version caching working
- ✅ Safe helpers added and used (no breaking changes)
- ✅ SafeReload prevents combat lock errors
- ✅ Profile validation prevents import crashes
- ✅ No performance regression

### Phase 2 (After Completion):
- ✅ Accent color system functional (single picker → all UI colors update)
- ✅ Search navigation works (click result → correct tab + scroll section)
- ✅ Modular builders reduce code complexity
- ✅ No visual regressions to options UI

### Phase 3 (After Completion):
- ✅ Frames render cleanly at 75%, 100%, 125% UI scales
- ✅ No blurry borders/lines
- ✅ Window drag/resize preserves pixel-perfect positions
- ✅ No performance regression (frame time budget consistent)

---

## KNOWN RISKS & MITIGATION

| Risk | Mitigation |
|------|-----------|
| Accent color system breaks existing theme | Keep existing Theme.lua functions as fallback |
| Pixel-perfect math incorrect at edge cases | Screenshot-test extensively at all UI scales |
| Search nav scrolls to wrong section | Hard-code section registry entries first |
| Profile validation too strict | Start with lenient checks, tighten gradually |

---

## GIT WORKFLOW

```bash
# Start feature
git checkout -b feature/NAME-FROM-TASK
git commit -m "Task X.Y: Description"

# After testing
git commit -m "Task X.Y: Fix issues from testing"

# Before merge
git diff main -- [affected files]  # Review changes

# Merge to main
git checkout main
git merge feature/NAME-FROM-TASK --no-ff

# Tag release if completing phase
git tag -a v1.24.0 -m "Phase 1 Quick Wins Complete"
```

---

## REFERENCE LINKS

**RESEARCH.md:** Full analysis with effort/value/risk assessments  
**QUI Code:** See RESEARCH.md Section F for file paths  
**SUF Code:** SimpleUnitFrames.lua (main), Modules/UI/ (options), Units/ (frames)  

---

## NOTES

- **Phase 1 is Self-Contained:** All 4 tasks independent, can do in any order
- **Phase 2 Builds on Phase 1:** But not required (can skip Phase 1)
- **Phase 3 Depends on Phase 2:** Especially Task 2.3 (modular builders help with sizing)
- **Phase 4 Deferred:** Only tackle if users specifically request features or addon has time

---

**Ready to start?** Begin with **Task 1.1: API Version Compatibility (30 min)** ← Recommended first task
