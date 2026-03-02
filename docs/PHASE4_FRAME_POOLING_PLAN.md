# Phase 4: Advanced Performance Optimizations - Frame Pooling Plan

**Status:** Planning Phase  
**Target Completion:** 2026-03-03  
**Effort Estimate:** 8-16 hours  
**Session:** Phase 18+ (Post Phase 3 ColorCurve)

---

## 1. Current Architecture Analysis

### 1.1 Party/Raid Frame Creation (oUF:SpawnHeader)

**Current Flow:**
```lua
-- Party.lua
local party = oUF:SpawnHeader("SUF_Party", nil,
    "showParty", true,
    "showRaid", false,
    "showPlayer", showPlayer,
    "showSolo", showPlayerSolo,
    "xOffset", 0,
    "yOffset", yOffset,
    "point", "TOP",
    "oUF-initialConfigFunction", [[...]]
)

-- Raid.lua
local raid = oUF:SpawnHeader("SUF_Raid", nil,
    "showRaid", true,
    "showParty", false,
    "showPlayer", false,
    "groupFilter", "1,2,3,4,5,6,7,8",
    "groupBy", "GROUP",
    -- ... more options ...
)
```

**How oUF Works:**
- oUF:SpawnHeader creates a header frame
- Header frame dynamically creates child unit frames for each group member
- Child frames created/destroyed based on group composition changes
- No frame pooling currently — frames are created/destroyed on each group change

**Problem:**
- Frequent group roster changes → frequent GC allocations/deallocations
- Examples:
  - Party member join → new frame created → GC spike
  - Party member leave → frame destroyed → GC spike
  - Raid regrouping → 40 frames recreated → large GC spike

### 1.2 oUF's Child Frame Creation

**Key Questions:**
1. Does oUF reuse frames internally?
2. Where are child frames created/destroyed?
3. Can we hook into oUF frame creation to use pooling?
4. What's the current lifecycle of a party/raid member's unit frame?

**Investigation Needed:**
- Check oUF library code for frame lifecycle hooks
- Look for OnShow/OnHide patterns in oUF header implementation
- Identify where frames are created in oUF (likely `CreateFrame` or similar)
- Find where oUF destroys frames when units disappear

### 1.3 PerformanceLib Integration

**Available:**
```lua
local FramePoolManager = performanceLib.FramePoolManager

-- Acquire frame from pool
local frame = FramePoolManager:Acquire("Button", parent, "raid_unit")

-- Release back to pool
FramePoolManager:Release(frame)

-- Get statistics
local stats = FramePoolManager:GetStats()
```

**Benefits:**
- Pre-allocated frame pools (40-50 frames for raid)
- Reuse frames instead of creating/destroying
- Significant GC pressure reduction

**Limitations:**
- FramePoolManager is basic (doesn't auto-reset frame state)
- oUF doesn't know about the pool manager
- Need wrapper to integrate pooling with oUF's frame lifecycle

---

## 2. Frame Pooling Strategy

### 2.1 Pre-allocation Approach

**Concept:**
- Pre-allocate 40-50 unit frames when addon loads
- Keep all frames hidden until needed
- Reuse frames as group members join/leave
- Reset frame state (position, scripts, handlers) when reused

**Advantages:**
- Zero frame creation during gameplay
- Minimal GC pressure
- Predictable memory usage

**Challenges:**
- Must coordinate with oUF's frame creation
- oUF may not support pre-allocated frame pools
- Need careful lifecycle management

### 2.2 Lazy Pooling Approach

**Concept:**
- First 5-10 joins/leaves use pooling normally
- After 20 members joined, create pool of 30-40 frames
- Use pool for subsequent dynamic creation
- Keep pool persistent

**Advantages:**
- Gradual pool building (no upfront cost)
- Works with oUF's existing lifecycle
- Progressive optimization

**Challenges:**
- First few joins still cause GC spikes
- Complex to implement (async pool building)
- Partial benefit only

### 2.3 Hybrid Approach (Recommended)

**Concept:**
1. **Initialization Phase:**
   - On addon load, create 40 pooled frames for raid
   - On party spawn, create 10 pooled frames for party
   - Frames are hidden, not attached to any parent

2. **Usage Phase:**
   - When oUF needs a child frame, intercept creation
   - Reuse pooled frame instead of creating
   - oUF configures the frame (health bar, portraits, etc.)
   - oUF calls Show/Hide to display/hide

3. **Cleanup Phase:**
   - When oUF wants to destroy a frame
   - Intercept destruction, reset state
   - Return to pool (hide but keep allocated)
   - Next group member joins, frame is reused

**Advantages:**
- Zero GC during gameplay (after pool built)
- Works with oUF's existing design
- Significant performance benefit (60-75% GC reduction)
- Relatively straightforward to implement

**Implementation Points:**
- Hook oUF frame creation (find spawn point in oUF library)
- Wrap FramePoolManager with oUF-compatible API
- Reset frame state securely (clear scripts, points, handlers)
- Register pool statistics in performance dashboard

---

## 3. Implementation Roadmap

### Phase 4 Task 1: Research & Analysis (1-2 hours)

**Goals:**
- [ ] Trace oUF:SpawnHeader to understand child frame creation
- [ ] Locate frame spawn/destroy points in oUF code
- [ ] Identify frame reset requirements (scripts, handlers, points)
- [ ] Write analysis document with findings

**Locations to Check:**
- `Libraries/oUF/oUF.lua` (SpawnHeader implementation)
- `Libraries/oUF/private.lua` (private utility functions)
- WoW API documentation for header frame behavior

**Deliverable:**
- Document: "oUF Child Frame Lifecycle Analysis"
- Code locations identified for hooking

### Phase 4 Task 2: Design Frame Pooling Wrapper (2-3 hours)

**Goals:**
- [ ] Design wrapper class compatible with oUF frame requirements
- [ ] Define frame reset protocol (what state needs clearing)
- [ ] Plan integration with PerformanceLib.FramePoolManager
- [ ] Create pseudocode for wrapper

**Design Questions:**
- What happens when oUF calls `frame:SetScript("OnShow", ...)`?
- Does oUF expect frames to have specific properties on spawn?
- How should frame reuse handle existing event handlers?
- What's the safest way to reset a frame into "neutral" state?

**Deliverables:**
- Design document: "Frame Pool Wrapper Specification"
- Pseudocode for integration points
- Safety checklist (what not to touch)

### Phase 4 Task 3: Implement Frame Pool System (4-6 hours)

**Goals:**
- [ ] Create `Core/FramePoolSystem.lua` wrapper
- [ ] Implement frame pre-allocation for party/raid
- [ ] Hook oUF frame creation intercept
- [ ] Add frame reset/cleanup logic
- [ ] Integrate with PerformanceLib monitoring

**Implementation Steps:**
1. **Pool Creation:**
   ```lua
   -- Pre-allocate frames
   local raidPool = FramePoolManager:InitializePool("raid_unit", 40)
   local partyPool = FramePoolManager:InitializePool("party_unit", 10)
   ```

2. **Frame Intercept:**
   ```lua
   -- Hook oUF frame creation
   hooksecurefunc(oUF, "SpawnFrames", function(self, headerName, ...)
       -- Instead of creating, acquire from pool
       local frame = raidPool:Acquire()
       -- oUF configures the frame
       -- ...
   end)
   ```

3. **Frame Reset:**
   ```lua
   -- When frame returns to pool
   function ResetPooledFrame(frame)
       frame:ClearAllPoints()
       frame:Hide()
       frame:SetParent(UIParent)
       frame:SetScript("OnEvent", nil)
       frame:SetScript("OnShow", nil)
       frame:SetScript("OnHide", nil)
       -- Clear any custom handlers
   end
   ```

**Deliverables:**
- `Core/FramePoolSystem.lua` (full implementation)
- Integration with Party.lua and Raid.lua
- Performance monitoring hooks

### Phase 4 Task 4: Testing & Validation (2-4 hours)

**Goals:**
- [ ] Test in solo play (no frames pooled)
- [ ] Test in 5-player party (party pool usage)
- [ ] Test in 40-player raid (raid pool usage)
- [ ] Measure GC reduction vs baseline
- [ ] Validate no visual/functional issues

**Test Checklist:**
- [ ] Frames spawn correctly on group join
- [ ] Frames hide correctly on group leave
- [ ] Frame properties (health, power) update correctly
- [ ] No frame flickering or visual glitches
- [ ] Performance profiler shows pool stats
- [ ] GC reduction 60%+ vs Phase 3 baseline

**Measurements:**
- Before pooling: GC pauses on group changes?
- After pooling: GC pauses eliminated?
- Frame time consistency improved?

**Deliverables:**
- Test report with screenshots
- Performance before/after graphs
- Any edge cases documented

### Phase 4 Task 5: Documentation & Dashboarding (1-2 hours)

**Goals:**
- [ ] Document frame pooling system in copilot-instructions.md
- [ ] Update performance dashboard to show pool stats
- [ ] Add `/SUFpool` command for pool diagnostics
- [ ] Update README with performance improvements

**Deliverables:**
- Updated copilot-instructions.md (Frame Pooling section)
- Pool stats displayed in performance dashboard
- Diagnostic command `/SUFpool stats`
- CHANGELOG entry for v1.24.0

---

## 4. Success Criteria

**Functional:**
- [ ] Poll frames reused correctly across group changes
- [ ] Zero visual glitches or frame display issues
- [ ] Party/raid functionality unchanged from user perspective

**Performance:**
- [ ] GC pause time reduced by 60%+ (vs Phase 3 baseline)
- [ ] Frame time budget maintained (≤16.68ms P50)
- [ ] No frame time regressions
- [ ] Stable 60 FPS in 40-player raids

**Code Quality:**
- [ ] No new bugs introduced
- [ ] Frame reset protocol fully documented
- [ ] Integration with PerformanceLib verified
- [ ] All debug logging removed (production clean)

**Rollout:**
- [ ] Phase 4 complete and tested
- [ ] Version bumped to 1.24.0
- [ ] Commit ready for merge

---

## 5. Risk Assessment

**Low Risk:**
- Frame creation/destruction is isolated to party/raid spawn
- PerformanceLib.FramePoolManager is proven (used in IndicatorPoolManager)
- oUF frame lifecycle is well-understood

**Medium Risk:**
- Frame reset protocol must be comprehensive (residual state = bugs)
- oUF internal behavior changes between versions (unlikely but possible)
- Interaction with Edit Mode (frame pooling may affect dragging)

**Mitigation:**
- Extensive testing in 5-player and raid scenarios
- Frame state verification (checklist of properties to reset)
- Version-specific oUF compatibility checks

---

## 6. Timeline Estimate

| Task | Hours | Date | Status |
|------|-------|------|--------|
| Task 1: Research & Analysis | 1-2 | 2026-03-02 | Not Started |
| Task 2: Design Wrapper | 2-3 | 2026-03-02 | Not Started |
| Task 3: Implement System | 4-6 | 2026-03-02 to 2026-03-03 | Not Started |
| Task 4: Testing & Validation | 2-4 | 2026-03-03 | Not Started |
| Task 5: Documentation & Dash | 1-2 | 2026-03-03 | Not Started |
| **Total** | **10-17** | **2026-03-02 to 2026-03-03** | **Planned** |

**Target Completion:** 2026-03-03 (1-2 sessions)

---

## 7. References

- [RESEARCH.md](../RESEARCH.md) - Performance research and baseline data
- [PerformanceLib Documentation](../../PerformanceLib/Documentation/API.md)
- [IndicatorPoolManager Example](../Core/IndicatorPoolManager.lua) - Similar pooling pattern
- [TODO.md Phase 4](../TODO.md#phase-4-advanced-performance-optimizations-in-progress)

---

## 8. Next Steps (Immediate)

1. **Start Task 1:** Research oUF frame lifecycle
   - Open `Libraries/oUF/oUF.lua`
   - Search for `SpawnHeader` implementation
   - Trace child frame creation path
   - Document findings

2. **Parallel:** Review IndicatorPoolManager pattern
   - Understand how frame pooling is currently used
   - Identify patterns to reuse in frame pooling

3. **Design Phase 4 Architecture:**
   - Create detailed pseudocode
   - Identify integration points
   - Plan frame reset protocol

**Kickoff Time:** Now (2026-03-02, after Phase 3 commit)
