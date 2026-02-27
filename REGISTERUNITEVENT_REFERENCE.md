# RegisterUnitEvent Implementation Reference

Quick copy/paste reference for implementing the RegisterUnitEvent optimization.

---

## SmartRegisterUnitEvent Helper Function

### Add this to `Libraries/oUF/events.lua`

Find the RegisterEvent implementation (around line 30-50) and add this helper after it:

```lua
-- ============================================================================
-- SmartRegisterUnitEvent Helper
-- ============================================================================
-- Backwards-compatible wrapper for RegisterUnitEvent (WoW 10.0+)
-- Uses unit-scoped event registration when available, falls back to global
-- registration for older versions or non-unit-scoped events.
-- 
-- Benefits: 30-50% reduction in UNIT_* event handler calls
-- 
-- @param frame Frame object
-- @param event Event name (e.g., "UNIT_HEALTH")
-- @param unit Unit ID (e.g., "player", "target")
-- @param handler Handler function
-- @return boolean Success
-- ============================================================================
local function SmartRegisterUnitEvent(frame, event, unit, handler)
    if frame.RegisterUnitEvent and unit and unit ~= '' then
        -- Modern API (WoW 10.0+): Register for specific unit only
        return frame:RegisterUnitEvent(event, unit, handler)
    else
        -- Fallback: Register for all units (old behavior)
        return frame:RegisterEvent(event, handler)
    end
end

-- Export for use by elements
Private.SmartRegisterUnitEvent = SmartRegisterUnitEvent
```

**Location in file:** After the RegisterEvent implementation comments

**Line count:** ~15 lines including documentation

---

## Element Enable Function Conversion Pattern

### Template: Before → After

**BEFORE (Global registration):**
```lua
local function Enable(self)
    if(self.Health) then
        self:RegisterEvent('UNIT_HEALTH', Path)
        self:RegisterEvent('UNIT_MAXHEALTH', Path)
        self:RegisterEvent('UNIT_CONNECTION', Path)
        -- ... rest of Enable function ...
    end
end
```

**AFTER (Unit-scoped registration):**
```lua
local function Enable(self)
    if(self.Health) then
        Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH', self.unit, Path)
        Private.SmartRegisterUnitEvent(self, 'UNIT_MAXHEALTH', self.unit, Path)
        Private.SmartRegisterUnitEvent(self, 'UNIT_CONNECTION', self.unit, Path)
        -- ... rest of Enable function (unchanged) ...
    end
end
```

### Critical Points

✅ **DO:**
- Replace `self:RegisterEvent('UNIT_*', handler)` with `Private.SmartRegisterUnitEvent(self, 'UNIT_*', self.unit, handler)`
- Keep the exact event name (e.g., 'UNIT_HEALTH')
- Keep the exact handler function (e.g., Path, UpdateAuras)
- Use `self.unit` for the unit parameter
- Apply to ALL UNIT_* events in Enable function

❌ **DON'T:**
- Replace non-UNIT events (e.g., PLAYER_ENTERING_WORLD remains RegisterEvent)
- Modify the handler function
- Change event names
- Add extra parameters beyond event, unit, handler

---

## Common Element Conversions

### health.lua
```lua
-- Original (in Enable):
self:RegisterEvent('UNIT_HEALTH', Path)
self:RegisterEvent('UNIT_MAXHEALTH', Path)
self:RegisterEvent('UNIT_CONNECTION', Path)

-- Convert to:
Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_MAXHEALTH', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_CONNECTION', self.unit, Path)
```

### auras.lua
```lua
-- Original (in Enable):
self:RegisterEvent('UNIT_AURA', UpdateAuras)

-- Convert to:
Private.SmartRegisterUnitEvent(self, 'UNIT_AURA', self.unit, UpdateAuras)
```

### power.lua
```lua
-- Original (in Enable):
self:RegisterEvent('UNIT_POWER_UPDATE', Path)
self:RegisterEvent('UNIT_MAXPOWER', Path)

-- Convert to:
Private.SmartRegisterUnitEvent(self, 'UNIT_POWER_UPDATE', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_MAXPOWER', self.unit, Path)
```

### castbar.lua
```lua
-- Original (in Enable):
self:RegisterEvent('UNIT_SPELLCAST_START', Start)
self:RegisterEvent('UNIT_SPELLCAST_STOP', Stop)
self:RegisterEvent('UNIT_SPELLCAST_FAILED', Fail)
self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED', Interrupted)
self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START', ChannelStart)
self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP', ChannelStop)

-- Convert to:
Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_START', self.unit, Start)
Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_STOP', self.unit, Stop)
Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_FAILED', self.unit, Fail)
Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_INTERRUPTED', self.unit, Interrupted)
Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_CHANNEL_START', self.unit, ChannelStart)
Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_CHANNEL_STOP', self.unit, ChannelStop)
```

### portrait.lua
```lua
-- Original (in Enable):
self:RegisterEvent('UNIT_PORTRAIT_UPDATE', Path)
self:RegisterEvent('UNIT_MODEL_CHANGED', Path)

-- Convert to:
Private.SmartRegisterUnitEvent(self, 'UNIT_PORTRAIT_UPDATE', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_MODEL_CHANGED', self.unit, Path)
```

### healthprediction.lua
```lua
-- Original (in Enable):
self:RegisterEvent('UNIT_HEALTH', Path)
self:RegisterEvent('UNIT_MAXHEALTH', Path)
self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)

-- Convert to:
Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_MAXHEALTH', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_ABSORB_AMOUNT_CHANGED', self.unit, Path)
Private.SmartRegisterUnitEvent(self, 'UNIT_HEAL_PREDICTION', self.unit, Path)
```

---

## Step-by-Step Conversion Process

### Step 1: Find the Enable Function
Search in element file for:
```lua
local function Enable(self)
```

### Step 2: Locate RegisterEvent Calls
Find all lines starting with `self:RegisterEvent('UNIT_*'`

Example search pattern: `self:RegisterEvent\('UNIT_`

### Step 3: Check Handler Function
Identify the handler function name (e.g., Path, UpdateAuras, Start, Stop)

### Step 4: Do the Replacement
For each `self:RegisterEvent('UNIT_*', handler)` line:

**Find:**
```lua
self:RegisterEvent('UNIT_HEALTH', Path)
```

**Replace with:**
```lua
Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH', self.unit, Path)
```

### Step 5: Keep Non-UNIT Events Unchanged
Events like these stay as RegisterEvent:
```lua
-- These DON'T change:
self:RegisterEvent('PLAYER_ENTERING_WORLD', Initialize)
self:RegisterEvent('UNIT_AURA_APPLIED_DOSE', Update)  -- Has filtering, but not unit-scoped
```

### Step 6: Verify the Change
- Paste the converted code
- Save file
- Load addon: `/reload`
- Check for Lua errors
- Test functionality (switch targets, verify updates)

---

## Verification Checklist Per File

For each element file converted:

- [ ] Found Enable function
- [ ] Located all UNIT_* RegisterEvent calls
- [ ] Converted each to SmartRegisterUnitEvent
- [ ] Kept non-UNIT events unchanged
- [ ] Saved file
- [ ] Loaded addon: `/reload`
- [ ] No Lua errors: Check `/say test` in chat
- [ ] Tested functionality: Switch targets
- [ ] Unit frames update correctly

---

## Quick Reference: All Convertible Events

These UNIT_* events should be converted:

```
UNIT_ABSORB_AMOUNT_CHANGED → Private.SmartRegisterUnitEvent(self, 'UNIT_ABSORB_AMOUNT_CHANGED', self.unit, handler)
UNIT_AURA → Private.SmartRegisterUnitEvent(self, 'UNIT_AURA', self.unit, handler)
UNIT_COMBAT → Private.SmartRegisterUnitEvent(self, 'UNIT_COMBAT', self.unit, handler)
UNIT_CONNECTION → Private.SmartRegisterUnitEvent(self, 'UNIT_CONNECTION', self.unit, handler)
UNIT_HEALTH → Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH', self.unit, handler)
UNIT_HEALTH_FREQUENT → Private.SmartRegisterUnitEvent(self, 'UNIT_HEALTH_FREQUENT', self.unit, handler)
UNIT_HEAL_PREDICTION → Private.SmartRegisterUnitEvent(self, 'UNIT_HEAL_PREDICTION', self.unit, handler)
UNIT_LEVEL → Private.SmartRegisterUnitEvent(self, 'UNIT_LEVEL', self.unit, handler)
UNIT_MAXHEALTH → Private.SmartRegisterUnitEvent(self, 'UNIT_MAXHEALTH', self.unit, handler)
UNIT_MAXPOWER → Private.SmartRegisterUnitEvent(self, 'UNIT_MAXPOWER', self.unit, handler)
UNIT_MODEL_CHANGED → Private.SmartRegisterUnitEvent(self, 'UNIT_MODEL_CHANGED', self.unit, handler)
UNIT_PHASE → Private.SmartRegisterUnitEvent(self, 'UNIT_PHASE', self.unit, handler)
UNIT_PORTRAIT_UPDATE → Private.SmartRegisterUnitEvent(self, 'UNIT_PORTRAIT_UPDATE', self.unit, handler)
UNIT_POWER_FREQUENT → Private.SmartRegisterUnitEvent(self, 'UNIT_POWER_FREQUENT', self.unit, handler)
UNIT_POWER_PREDICTION → Private.SmartRegisterUnitEvent(self, 'UNIT_POWER_PREDICTION', self.unit, handler)
UNIT_POWER_UPDATE → Private.SmartRegisterUnitEvent(self, 'UNIT_POWER_UPDATE', self.unit, handler)
UNIT_RUNE_POWER_UPDATE → Private.SmartRegisterUnitEvent(self, 'UNIT_RUNE_POWER_UPDATE', self.unit, handler)
UNIT_SPELLCAST_CHANNEL_START → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_CHANNEL_START', self.unit, handler)
UNIT_SPELLCAST_CHANNEL_STOP → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_CHANNEL_STOP', self.unit, handler)
UNIT_SPELLCAST_FAILED → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_FAILED', self.unit, handler)
UNIT_SPELLCAST_INTERRUPTED → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_INTERRUPTED', self.unit, handler)
UNIT_SPELLCAST_START → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_START', self.unit, handler)
UNIT_SPELLCAST_STOP → Private.SmartRegisterUnitEvent(self, 'UNIT_SPELLCAST_STOP', self.unit, handler)
UNIT_THREAT_SITUATION_UPDATE → Private.SmartRegisterUnitEvent(self, 'UNIT_THREAT_SITUATION_UPDATE', self.unit, handler)
UNIT_TOTEM_UPDATE → Private.SmartRegisterUnitEvent(self, 'UNIT_TOTEM_UPDATE', self.unit, handler)
UNIT_PET → Private.SmartRegisterUnitEvent(self, 'UNIT_PET', self.unit, handler)
```

---

## Search & Replace Patterns

### Using VS Code Find and Replace

**Pattern 1: Simple event registration**

Find: `self:RegisterEvent\('UNIT_(\w+)', (\w+)\)`  
Replace: `Private.SmartRegisterUnitEvent(self, 'UNIT_$1', self.unit, $2)`

**Pattern 2: With spaces (flexible)**

Find: `self\s*:\s*RegisterEvent\s*\(\s*'UNIT_(\w+)'\s*,\s*(\w+)\s*\)`  
Replace: `Private.SmartRegisterUnitEvent(self, 'UNIT_$1', self.unit, $2)`

**How to use:**
1. Open Find and Replace: `Ctrl+H`
2. Enable Regex: Click `.*` button
3. Paste pattern into Find field
4. Paste replacement into Replace field
5. Review changes before replacing all

---

## Testing After Each Conversion

### Quick Test Sequence
```
1. /reload
2. Look at unit frame (Player)
3. /target [any nearby unit]
4. Look at target frame
5. /cast [any spell]
6. Watch castbar
7. Check chat: No error messages
```

### Performance Check
```lua
/run print("Event count before full test")
-- Play for 2-3 minutes
/SUFprofile start
-- Play for 5 minutes more
/SUFprofile stop
/SUFprofile analyze
-- Note the event handler call count
```

---

## Common Mistakes & Fixes

| Mistake | Fix |
|---------|-----|
| Wrong function name: `SmartRegisterEvent` | Use `SmartRegisterUnitEvent` (includes word `Unit`) |
| Missing `Private.` prefix | Must call: `Private.SmartRegisterUnitEvent(...)` |
| Used wrong unit: `"player"` instead of `self.unit` | Use `self.unit` for frame's assigned unit |
| Forgot to convert a UNIT_* event | Search file for all `RegisterEvent('UNIT_` |
| Converted non-UNIT event like `PLAYER_REGEN_ENABLED` | Only convert UNIT_* events |
| Handler function name wrong | Must match exactly (if was `Path`, use `Path` not `path`) |
| RegisterEvent → SmartRegisterUnitEvent syntax unclear | Pattern: `condition ? RegisterEvent() : SmartRegisterUnitEvent()` |

---

## Performance Baseline Commands

### Before Implementation (Establish Baseline)
```lua
/console scriptProfile 1  -- Enable script profiling
/run print("Starting baseline collection")
/SUFprofile start
-- (Play 5-10 minutes in combat/raid)
/SUFprofile stop
/SUFprofile analyze
-- Record: Event handler calls, frame times P50/P99
/console scriptProfile 0  -- Disable profiling
```

### After Implementation (Compare)
```lua
/console scriptProfile 1
/run print("Starting optimized test")
/SUFprofile start
-- (Play 5-10 minutes in same activity)
/SUFprofile stop
/SUFprofile analyze
-- Compare: Should see 30-50% reduction in event handler calls
/console scriptProfile 0
```

**Expected Improvement:**
- Event handler calls: 30-50% fewer
- Frame time: Slightly improved (P50: 1-2ms improvement typical)
- CPU: Noticeable in raid scenarios

---

**That's it!** Follow this reference to implement the optimization.

For full details, see: IMPLEMENTATION_PLAN_RegisterUnitEvent.md
For tracking progress, use: REGISTERUNITWENT_IMPLEMENTATION_CHECKLIST.md
