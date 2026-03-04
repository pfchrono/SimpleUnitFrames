# Phase 1 In-Game Test Runbook
**Date:** March 3, 2026 | **Phase:** 1 (Tasks 1.2–1.4) | **Target:** Midnight 12.0.x

---

## Pre-Test Setup
1. **Load addon:**
   ```
   /suf
   ```
2. **Open options window:**
   ```
   /suf options
   ```
3. **Have profile export ready:** Export current profile to clipboard for testing
   ```
   /suf export
   ```

---

## Test 1: Valid Profile Import
**Objective:** Verify normal profile imports validate and apply correctly  
**Expected:** Profile loads, settings apply, no errors in chat

**Steps:**
1. Export current profile: `/suf export`
2. Open options → Profiles tab
3. Click "Import Profile"
4. Paste export string
5. Click "Import"
6. **Verify:** Settings applied, no validation errors, profile name appears in list

**Pass Criteria:** ✅ Profile imports, settings visible, no chat errors

---

## Test 2: Malformed Import (Invalid JSON)
**Objective:** Verify validator rejects corrupted payloads  
**Expected:** Clear error message, original profile unchanged

**Steps:**
1. Open options → Profiles tab
2. Click "Import Profile"
3. Paste truncated/invalid export string (e.g., first 50 chars only)
4. Click "Import"
5. **Verify:** Error displayed, original profile untouched, can still open options

**Pass Criteria:** ✅ Error shown, addon remains stable, no crash

---

## Test 3: Deep Nesting Validation (Cycle Detection)
**Objective:** Verify validator catches circular references  
**Expected:** Validation fails gracefully with error

**Steps:**
1. **Chat command (requires debug mode):**
   ```
   /run local t = {}; t.self = t; SUF:ValidateImportTree(t)
   ```
2. **Verify:** No infinite loop, no crash, debug output shows cycle detection

**Pass Criteria:** ✅ Cycle detected, no hang or crash

---

## Test 4: Node Limit Validation
**Objective:** Verify validator enforces max node count (50,000)  
**Expected:** Large tables rejected before unpacking

**Steps:**
1. **Chat command (creates large table structure):**
   ```
   /run local t = {}; for i=1,60000 do t[i] = i end; SUF:ValidateImportTree(t)
   ```
2. **Verify:** Validation completes quickly (no hang), rejects due to node count

**Pass Criteria:** ✅ Completes <1s, fails gracefully with error

---

## Test 5: Depth Limit Validation
**Objective:** Verify validator enforces max depth (20 levels)  
**Expected:** Deeply nested tables rejected

**Steps:**
1. **Chat command (creates 25-level deep nesting):**
   ```
   /run local t = {}; local cur = t; for i=1,25 do local new = {}; cur.next = new; cur = new end; SUF:ValidateImportTree(t)
   ```
2. **Verify:** Validation rejects due to depth limit

**Pass Criteria:** ✅ Rejects deep nesting, no crash or hangs

---

## Test 6: Profile Reload (SafeReload)
**Objective:** Verify reload button uses safe reload path  
**Expected:** Profile reloads without UI glitches or errors

**Steps:**
1. Open options window
2. Make a setting change (e.g., toggle status bar)
3. Click "Reload Profile" button (or `/suf reload`)
4. **Verify:** Settings revert to saved state, UI updates smoothly
5. **Check:** Chat shows "Profile reloaded" or similar confirmation

**Pass Criteria:** ✅ Reload completes, UI stable, settings reset

---

## Test 7: Safe Helper Activation (Settings)
**Objective:** Verify safe helpers active via normal UI flow  
**Expected:** No crashes when toggling settings with secret values (instances)

**Steps:**
1. Load addon in **Dungeon/Raid Instance** (where secret values active)
2. Open options window
3. Toggle 3–4 settings (health bar color, power bar visibility, nameplate mode)
4. **Verify:** Settings apply, no "attempt to perform arithmetic" errors in chat

**Pass Criteria:** ✅ No secret value errors, settings apply correctly

---

## Test 8: Profile Export/Import Round-Trip
**Objective:** Verify export→import cycle preserves all settings  
**Expected:** Re-imported profile identical to original

**Steps:**
1. Export profile: `/suf export`
2. Create new profile (e.g., "Test Copy")
3. Import exported string into new profile
4. **Compare:** Check 5–6 key settings (colors, visibility, font) match original
5. Delete test profile

**Pass Criteria:** ✅ Round-trip successful, all settings preserved

---

## Failure Escalation
| Scenario | Action |
|----------|--------|
| **Chat shows error** (not a validation error) | Check `/suf debug` output; report with error message + steps |
| **UI freezes/hangs** | Force quit (in-game: `/run` commands hang forever) or alt-tab, report with last action |
| **Addon disabled after test** | Check `Interface/AddOns` folder, check for taint/segfault in WoW logs |
| **Settings don't persist** | Test profile export/import round-trip; verify SavedVariables not corrupted |

---

## Quick Pass/Fail Summary
```
[ ] Test 1: Valid Import
[ ] Test 2: Malformed Import
[ ] Test 3: Cycle Detection
[ ] Test 4: Node Limit
[ ] Test 5: Depth Limit
[ ] Test 6: Profile Reload
[ ] Test 7: Safe Helpers (Instance)
[ ] Test 8: Round-Trip

PHASE 1 STATUS: ☐ PASS (all 8 tests) | ☐ FAIL (list failures above)
```

---

## Diagnostics Commands (if needed)
```lua
-- Check validator is loaded:
/run print(SUF:ValidateImportTree and "Validator loaded ✓" or "Validator MISSING ✗")

-- Check safe helpers exported:
/run print(SUF.SafeCompare and "SafeCompare ✓" or "SafeCompare MISSING ✗")
/run print(SUF._core and SUF._core.SafeArithmetic and "SafeArithmetic ✓" or "SafeArithmetic MISSING ✗")

-- Test a simple import validation:
/run local ok, err = SUF:ValidateImportTree({a = 1, b = 2}); print(ok and "Validation OK" or ("Validation FAIL: " .. (err or "unknown")))

-- Check reload handler:
/run local btn = _G["SUFOptionsReloadButton"]; print(btn and "Reload button found ✓" or "Reload button MISSING ✗")
```

---

**Duration:** ~20 minutes (all 8 tests + diagnostics)  
**Environment:** Live retail test realm (Midnight 12.0.x)  
**Tester Notes:** Tests 3–5 require `/run` command execution (console access needed)
