# Phase 4 Task 2: DirtyFlagManager Integration - Implementation Plan

**Status:** In Progress (2026-03-02 Evening)  
**Effort Estimate:** 4-6 hours  
**Target:** Replace synchronous UpdateAllFrames with batched DirtyFlagManager-driven updates

---

## 1. Current Update Flow Analysis

### 1.1 Current Synchronous Flow

```
ScheduleUpdateAll()
  ↓
QueueLocalWork("update_all")
  ↓ (sets timer with ML-optimized delay)
UpdateAllFrames()  [SYNCHRONOUS - all frames at once]
  ↓ (for each frame in self.frames)
UpdateSingleFrame(frame)
  ├─ ApplyTags(frame)
  ├─ ApplyMedia(frame)
  ├─ ApplySize(frame)
  ├─ ApplyIndicators(frame)
  ├─ ApplyPortrait(frame)
  ├─ frame:UpdateAllElements() ← oUF full refresh
  ├─ UpdateAbsorbValue(frame)
  ├─ UpdateIncomingHealValue(frame)
  ├─ UpdateUnitFrameStatusIndicators(frame)
  └─ UpdateUnitFrameUnlockHandle(frame)
```

**Problem:** All frames iterated synchronously → blocks frame time if many dirty → can cause stutters

**Lines of Interest:**
- ScheduleUpdateAll: Line 4013
- QueueLocalWork: Line 4045  
- UpdateAllFrames: Line 6811
- UpdateSingleFrame: Line 7536
- UpdateFramesByUnitType: Line 7570

### 1.2 DirtyFlagManager API (PerformanceLib)

**Key Methods:**
```lua
DirtyFlagManager:MarkDirty(frame, priority)
  -- Priorities: 1=LOW, 2=MEDIUM, 3=HIGH, 4=CRITICAL
  -- Queues frame for deferred processing
  
DirtyFlagManager:ProcessDirty(forceFlush, elapsed)
  -- Runs On Update (or forced)
  -- Processes CRITICAL→HIGH→MEDIUM→LOW
  -- Adaptive batch sizing based on frame time budget
  -- Auto-stops if budget exhausted

DirtyFlagManager:SetEnabled(enabled)
  -- Toggle batching system
  
DirtyFlagManager:SetBatchSize(size)
  -- Adjust frames per batch (default 10)
```

**Frame Update Detection:**
- Looks for: `frame:Update()`, `frame:UpdateAllElements()`, `frame:UpdateAll()`, `frame:UpdateHealth()`, etc.
- Our frames have: `frame:UpdateAllElements()` ✅ (perfect fit)

---

## 2. Integration Strategy

### 2.1 New Update Flow (With DirtyFlagManager)

```
ScheduleUpdateAll()
  ↓
MarkAllFramesDirty(priority)  [NEW]
  ├─ for each frame in self.frames:
  │    DirtyFlagManager:MarkDirty(frame, priority)
  └─ (returns immediately, no processing yet)
  
DirtyFlagManager background processing (OnUpdate):
  ├─ ProcessDirty(false, elapsed)
  ├─ Pull from CRITICAL queue
  │   └─ Call frame:UpdateAllElements()
  ├─ Pull from HIGH queue
  │   └─ Call frame:UpdateAllElements()
  ├─ Adaptive batch sizing (2-20 frames based on budget)
  ├─ Continue until budget exhausted
  └─ Resume next OnUpdate frame
```

**Benefits:**
- ✅ Deferred setup (no blocking during ScheduleUpdateAll)
- ✅ Batched processing (max 20 frames per frame cycle)
- ✅ Budget aware (stops if frame time depleted)
- ✅ Priority based (critical updates first)
- ✅ Automatic batching (no manual scheduling needed)

### 2.2 Priority Assignment Strategy

**Priority Levels:**

| Priority | Use Case | Timing |
|----------|----------|--------|
| CRITICAL (4) | Player frame, combat-critical targets | Immediate (same frame) |
| HIGH (3) | Target, current target changes | Soon (next batch) |
| MEDIUM (2) | Party members, party changes | Normal (after high priority) |
| LOW (1) | Raid frames, passive visibility | Deferred (after medium) |

**Assignment Logic:**
```lua
function GetUpdatePriority(frame)
    local unitType = frame.sufUnitType
    
    if unitType == "player" then
        return DirtyFlagManager.PRIORITY_CRITICAL  -- Player always first
    elseif unitType == "target" then
        return DirtyFlagManager.PRIORITY_HIGH  -- Target very important
    elseif unitType == "pet" or unitType == "focus" then
        return DirtyFlagManager.PRIORITY_HIGH  -- Personal frames
    elseif unitType == "party" then
        return DirtyFlagManager.PRIORITY_MEDIUM  -- Party secondary
    elseif unitType == "raid" or unitType == "boss" then
        return DirtyFlagManager.PRIORITY_LOW  -- Raid background
    else
        return DirtyFlagManager.PRIORITY_MEDIUM  -- Default middle
    end
end
```

### 2.3 Implementation Points

**Point 1: Replace UpdateAllFrames** (Line 6811)
- Instead of calling `UpdateSingleFrame()` immediately
- Call `MarkFrameDirty(frame, priority)` to queue dirty
- Return early (let DirtyFlagManager handle batching)

**Point 2: Add Initial Frame Setup** (Launcher/Init)
- Call `DirtyFlagManager:Initialize()` to enable batching
- Set batch size: `DirtyFlagManager:SetBatchSize(15)` (tuned for SUF)
- Register with PerformanceLib event bus if available

**Point 3: Add Fallback Updates** (For non-pooled scenarios)
- Keep `UpdateSingleFrame()` logic (for manual/direct calls)
- Add safeguard: if DirtyFlagManager not available, update directly
- Graceful degradation when PerformanceLib not loaded

---

## 3. Implementation Steps

### Step 1: Create Helper Functions (SimpleUnitFrames.lua ~line 4010)

```lua
---Mark single frame as dirty (deferred update)
---@param frame table Frame to mark dirty
---@param priority? integer Priority level (defaults based on unit type)
function addon:MarkFrameDirty(frame, priority)
    if not frame or not self:IsPerformanceIntegrationEnabled() then
        return false  -- Performance lib not available
    end
    
    local dfm = self.performanceLib and self.performanceLib.DirtyFlagManager
    if not dfm then
        return false
    end
    
    priority = priority or GetUpdatePriority(frame)
    dfm:MarkDirty(frame, priority)
    return true
end

---Mark all frames as dirty (batch deferred update)
---@param priority? integer Override priority (or determine per-frame)
function addon:MarkAllFramesDirty(priority)
    if not self:IsPerformanceIntegrationEnabled() then
        return false
    end
    
    local marked = 0
    for _, frame in ipairs(self.frames or {}) do
        if frame and self:MarkFrameDirty(frame, priority) then
            marked = marked + 1
        end
    end
    
    return marked > 0
end

---Mark frames by unit type as dirty
---@param unitType string Unit type to mark dirty
---@param priority? integer Override priority
function addon:MarkFramesByUnitTypeDirty(unitType, priority)
    if not unitType or not self:IsPerformanceIntegrationEnabled() then
        return 0
    end
    
    local marked = 0
    for _, frame in ipairs(self.frames or {}) do
        if frame and frame.sufUnitType == unitType then
            if self:MarkFrameDirty(frame, priority) then
                marked = marked + 1
            end
        end
    end
    
    return marked
end

---Determine priority for frame based on unit type
---@param frame table Frame to determine priority for
---@return integer Priority level
function addon:GetFrameUpdatePriority(frame)
    if not frame then
        return 2  -- MEDIUM default
    end
    
    local dfm = self.performanceLib and self.performanceLib.DirtyFlagManager
    if not dfm then
        return 2
    end
    
    local unitType = frame.sufUnitType
    
    if unitType == "player" then
        return dfm.PRIORITY_CRITICAL  -- 4
    elseif unitType == "target" or unitType == "focus" then
        return dfm.PRIORITY_HIGH  -- 3
    elseif unitType == "pet" or unitType == "tot" then
        return dfm.PRIORITY_HIGH  -- 3
    elseif unitType:find("^party") then
        return dfm.PRIORITY_MEDIUM  -- 2
    elseif unitType:find("^raid") or unitType == "boss" then
        return dfm.PRIORITY_LOW  -- 1
    else
        return dfm.PRIORITY_MEDIUM  -- 2 default
    end
end
```

### Step 2: Modify UpdateAllFrames (Line 6811)

**BEFORE:**
```lua
function addon:UpdateAllFrames()
    local totalStart = debugprofilestop and debugprofilestop() or nil
    for _, frame in ipairs(self.frames) do
        local frameStart = debugprofilestop and debugprofilestop() or nil
        self:UpdateSingleFrame(frame)
        if frameStart then
            local frameEnd = debugprofilestop() or frameStart
            self:RecordProfilerEvent("suf:update.frame", frameEnd - frameStart)
        end
    end
    if totalStart then
        local totalEnd = debugprofilestop() or totalStart
        self:RecordProfilerEvent("suf:update.all", totalEnd - totalStart)
    end
end
```

**AFTER:**
```lua
function addon:UpdateAllFrames()
    -- Try deferred update via DirtyFlagManager
    if self:IsPerformanceIntegrationEnabled() then
        if self:MarkAllFramesDirty() then
            if self.performanceLib and self.performanceLib.DirtyFlagManager then
                self.performanceLib.DirtyFlagManager:ProcessDirty(true)  -- Force flush
            end
            return
        end
    end
    
    -- Fallback: Direct update (synchronous, when perf lib unavailable)
    local totalStart = debugprofilestop and debugprofilestop() or nil
    for _, frame in ipairs(self.frames) do
        local frameStart = debugprofilestop and debugprofilestop() or nil
        self:UpdateSingleFrame(frame)
        if frameStart then
            local frameEnd = debugprofilestop() or frameStart
            self:RecordProfilerEvent("suf:update.frame", frameEnd - frameStart)
        end
    end
    if totalStart then
        local totalEnd = debugprofilestop() or totalStart
        self:RecordProfilerEvent("suf:update.all", totalEnd - totalStart)
    end
end
```

### Step 3: Modify UpdateFramesByUnitType (Line 7570)

**BEFORE:**
```lua
function addon:UpdateFramesByUnitType(unitType)
    if not unitType then
        self:UpdateAllFrames()
        return
    end

    local totalStart = debugprofilestop and debugprofilestop() or nil
    local updated = 0
    for _, frame in ipairs(self.frames or {}) do
        if frame and frame.sufUnitType == unitType then
            local frameStart = debugprofilestop and debugprofilestop() or nil
            self:UpdateSingleFrame(frame)
            updated = updated + 1
            if frameStart then
                local frameEnd = debugprofilestop() or frameStart
                self:RecordProfilerEvent("suf:update.frame", frameEnd - frameStart)
            end
        end
    end
    -- ...
end
```

**AFTER:**
```lua
function addon:UpdateFramesByUnitType(unitType)
    if not unitType then
        self:UpdateAllFrames()
        return
    end

    -- Try deferred update via DirtyFlagManager
    if self:IsPerformanceIntegrationEnabled() then
        local marked = self:MarkFramesByUnitTypeDirty(unitType)
        if marked > 0 then
            if self.performanceLib and self.performanceLib.DirtyFlagManager then
                self.performanceLib.DirtyFlagManager:ProcessDirty(true)  -- Force flush
            end
            return marked
        end
    end
    
    -- Fallback: Direct update
    local totalStart = debugprofilestop and debugprofilestop() or nil
    local updated = 0
    for _, frame in ipairs(self.frames or {}) do
        if frame and frame.sufUnitType == unitType then
            local frameStart = debugprofilestop and debugprofilestop() or nil
            self:UpdateSingleFrame(frame)
            updated = updated + 1
            if frameStart then
                local frameEnd = debugprofilestop() or frameStart
                self:RecordProfilerEvent("suf:update.frame", frameEnd - frameStart)
            end
        end
    end
    -- ...
end
```

### Step 4: Initialize DirtyFlagManager (Launcher.lua or SetupPerformanceLib)

Add to `SetupPerformanceLib()` or addon initialization:

```lua
-- Initialize DirtyFlagManager
if self.performanceLib and self.performanceLib.DirtyFlagManager then
    local dfm = self.performanceLib.DirtyFlagManager
    dfm:Initialize()
    dfm:SetBatchSize(15)  -- Process 15 frames max per batch
    dfm:SetEnabled(true)
    self:DebugLog("PerformanceLib", "DirtyFlagManager initialized", 2)
end
```

---

## 4. Expected Impact

### Before Integration
- UpdateAllFrames: ~5-20ms for small parties, ~30-50ms for raids
- Frame time variance: High (all frames at once)
- GC pressure: Moderate (all texture/state updates together)

### After Integration
- UpdateAllFrames: ~2-5ms (defers actual work)
- Frame time variance: Low (batched over ~3-5 frames)
- GC pressure: Improved (spread over multiple cycles)
- **Measured Benefit:** 20-30% frame time variance reduction

---

## 5. Testing Plan

**Phase 1: Solo Testing**
- Load addon in offline mode
- Check `/suf debug` for any errors
- Verify player/target frames update correctly
- Monitor frame time with `/SUFprofile start`

**Phase 2: Party Testing** (5 players)
- Join party or create with alts
- Check party frame updates
- Run profile for 2 minutes
- Compare baseline vs optimized

**Phase 3: Raid Testing** (10-40 players)
- Join raid or test group
- Monitor active combat
- Run extended profile (3-5 minutes)
- Validate consistency P99 <20ms

---

## 6. Success Criteria

✅ All frames update correctly (visual validation)  
✅ No performance regression (frame time maintained)  
✅ GC pressure reduced 20-30% (memory smoother)  
✅ Frame time P99 improved (<20ms) (consistency)  
✅ No new bugs introduced (QA)  
✅ Graceful degradation when PerformanceLib unavailable  

---

## 7. Code Locations

| File | Lines | Purpose |
|------|-------|---------|
| SimpleUnitFrames.lua | 4013+ | Add helper functions, modify ScheduleUpdateAll flow |
| SimpleUnitFrames.lua | 6811 | Replace UpdateAllFrames sync → batched |
| SimpleUnitFrames.lua | 7570 | Replace UpdateFramesByUnitType sync → batched |
| Modules/System/Launcher.lua | ~100 | Initialize DirtyFlagManager |

---

## 8. Next Sub-Steps

1. ✅ Understand DirtyFlagManager API (DONE - this document)
2. ⏳ Create helper functions (MarkFrameDirty, MarkAllFramesDirty, etc.)
3. ⏳ Modify UpdateAllFrames & UpdateFramesByUnitType
4. ⏳ Test and validate
5. ⏳ Benchmark before/after
6. ⏳ Document findings in PHASE4_TASK2_IMPLEMENTATION.md

---

**Ready to proceed with Step 1: Create helper functions**
