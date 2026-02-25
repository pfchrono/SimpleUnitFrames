--[[
    ProtectedOperations - Unified protected-operation queueing system.
    
    Combines SUF's keyed deduplication + batching with UUF's event-driven flush
    to provide a robust, general-purpose system for queueing frame mutations that
    must be deferred during combat lockdown.
    
    PLAYER_REGEN_DISABLED → Set inCombat flag
    Any operation queued → Check combat; defer if needed
    PLAYER_REGEN_ENABLED → Flush all queued operations in batches (48/window)
    
    Features:
    - Event-driven flushing (zero polling overhead)
    - Keyed deduplication (prevent redundant operations)
    - Priority ordering (CRITICAL/HIGH/NORMAL/LOW)
    - Batched processing (48 ops per safe-flush window)
    - Per-operation-type analytics
    - Backward compatible with addon:QueueOrRun(func, key)
]]

local AceAddon = LibStub("AceAddon-3.0")
local addon = AceAddon and AceAddon:GetAddon("SimpleUnitFrames", true)
if not addon then return end

---------------------------------------------------------------------------
-- PRIORITY ORDERING
---------------------------------------------------------------------------

local PRIORITY_ORDER = {
    CRITICAL = 1,
    HIGH     = 2,
    MEDIUM   = 3,
    NORMAL   = 4,
    LOW      = 5,
}

---------------------------------------------------------------------------
-- PROTECTED OPERATIONS STATE
---------------------------------------------------------------------------

local ProtectedOperations = {
    --- Queue and dedup tracking ---
    _queue = {},           -- Array of {key, func, priority, type, queuedAt} objects
    _index = {},           -- Dedup lookup: key → true
    _inCombat = false,     -- Combat lockdown state
    
    --- Config ---
    _batchSize = 48,       -- Max operations per safe-flush window
    _flushInterval = 0.20, -- Fallback polling interval if event misses (200ms)
    
    --- Diagnostics ---
    _stats = {
        totalQueued = 0,
        totalFlushed = 0,
        totalSkipped = 0,
        byType = {},        -- {type → count}
        byPriority = {},    -- {priority → count}
        lastFlushTime = 0,
        lastFlushOpsCount = 0,
    },
    
    --- Event frame ---
    _eventFrame = nil,
    _ticker = nil,  -- Fallback ticker (should rarely trigger)
}

addon.ProtectedOperations = ProtectedOperations

---------------------------------------------------------------------------
-- COMBAT STATE TRACKING
---------------------------------------------------------------------------

function ProtectedOperations:_OnCombatState(inCombat)
    self._inCombat = inCombat
    if addon.DebugLog then
        addon:DebugLog("ProtectedOps", "Combat state: " .. (inCombat and "IN COMBAT" or "OUT OF COMBAT"), 3)
    end
end

---------------------------------------------------------------------------
-- MAIN API: QueueOrRun
---------------------------------------------------------------------------

--[[
    Queue an operation for deferred execution, or run immediately if safe.
    
    PARAMETERS:
        func (function):  Operation to defer or execute
        opts (table):     Optional configuration:
            .key (string):      Deduplication key (prevents duplicate queuing)
            .type (string):     Operation type name (for analytics)
            .priority (string): CRITICAL/HIGH/MEDIUM/NORMAL/LOW (default: NORMAL)
    
    LEGACY PARAMETER SUPPORT:
        addon:QueueOrRun(func, key_string) → opts = {key = key_string}
    
    RETURNS:
        ok (boolean):       true if executed immediately or queued successfully
        immediate (bool):   true if executed immediately
]]
function ProtectedOperations:QueueOrRun(func, opts)
    if type(func) ~= "function" then
        return false, false
    end
    
    --- Support legacy (func, key) signature ---
    if type(opts) == "string" then
        opts = {key = opts}
    end
    opts = opts or {}
    
    local key = opts.key
    local operationType = opts.type or "unnamed"
    local priority = opts.priority or "NORMAL"
    
    --- If currently safe, execute immediately (pcall-protected) ---
    if not InCombatLockdown() then
        local ok, err = pcall(func)
        if not ok and addon.DebugLog then
            addon:DebugLog("ProtectedOps", 
                "Immediate exec failed (type=" .. operationType .. "): " .. tostring(err), 1)
        end
        return ok, true  -- ok, immediate=true
    end
    
    --- Check deduplication ---
    if key and self._index[key] then
        if addon.DebugLog then
            addon:DebugLog("ProtectedOps", 
                "Duplicate key skipped (key=" .. tostring(key) .. "), already queued", 2)
        end
        self._stats.totalSkipped = self._stats.totalSkipped + 1
        return true, false  -- Already queued
    end
    
    --- Queue for deferred execution ---
    self._queue[#self._queue + 1] = {
        key = key,
        func = func,
        type = operationType,
        priority = priority,
        queuedAt = GetTime(),
    }
    
    if key then
        self._index[key] = true
    end
    
    self._stats.totalQueued = self._stats.totalQueued + 1
    self._stats.byType[operationType] = (self._stats.byType[operationType] or 0) + 1
    self._stats.byPriority[priority] = (self._stats.byPriority[priority] or 0) + 1
    
    if addon.DebugLog then
        addon:DebugLog("ProtectedOps", 
            "Queued operation (type=" .. operationType .. ", key=" .. (key or "none") .. 
            ", priority=" .. priority .. ", queueSize=" .. #self._queue .. ")", 3)
    end
    
    return true, false  -- ok=true, immediate=false
end

---------------------------------------------------------------------------
-- QUEUE FLUSHING
---------------------------------------------------------------------------

--[[
    Reorder queue by priority (CRITICAL → HIGH → MEDIUM → NORMAL → LOW).
    Called before flushing to ensure high-priority ops execute first.
]]
function ProtectedOperations:_ReorderByPriority()
    table.sort(self._queue, function(a, b)
        local aPrio = PRIORITY_ORDER[a.priority] or PRIORITY_ORDER.NORMAL
        local bPrio = PRIORITY_ORDER[b.priority] or PRIORITY_ORDER.NORMAL
        return aPrio < bPrio
    end)
end

--[[
    Flush queued operations in batches. Called on PLAYER_REGEN_ENABLED event.
    
    PARAMETERS:
        maxOps (integer):  Max operations to process in this window (default: 48)
    
    RETURNS:
        allFlushed (bool): true if queue completely emptied
]]
function ProtectedOperations:FlushQueue(maxOps)
    if InCombatLockdown() then
        if addon.DebugLog then
            addon:DebugLog("ProtectedOps", "Flush skipped: still in combat lockdown", 2)
        end
        return false
    end
    
    local queue = self._queue
    if not queue or #queue == 0 then
        if addon.DebugLog then
            addon:DebugLog("ProtectedOps", "Flush: queue empty, no-op", 3)
        end
        return true
    end
    
    --- Reorder by priority before flushing ---
    self:_ReorderByPriority()
    
    local limit = math.max(1, maxOps or self._batchSize)
    local flushed = 0
    local flushStartTime = GetTime()
    
    while #queue > 0 and flushed < limit do
        local op = table.remove(queue, 1)
        if not op then break end
        
        --- Clear dedup index ---
        if op.key and self._index[key] then
            self._index[op.key] = nil
        end
        
        --- Execute operation with error protection ---
        local ok, err = pcall(op.func)
        if not ok and addon.DebugLog then
            addon:DebugLog("ProtectedOps", 
                "Protected op failed (type=" .. op.type .. ", key=" .. (op.key or "none") .. 
                ", priority=" .. op.priority .. "): " .. tostring(err), 1)
        end
        
        flushed = flushed + 1
        self._stats.totalFlushed = self._stats.totalFlushed + 1
    end
    
    local flushDuration = (GetTime() - flushStartTime) * 1000  -- Convert to ms
    self._stats.lastFlushTime = GetTime()
    self._stats.lastFlushOpsCount = flushed
    
    if addon.DebugLog then
        local queueRemaining = #queue
        addon:DebugLog("ProtectedOps", 
            "Flushed " .. flushed .. " ops (duration=" .. string.format("%.2f", flushDuration) .. 
            "ms, remaining=" .. queueRemaining .. ")", 2)
    end
    
    return #queue == 0
end

---------------------------------------------------------------------------
-- FALLBACK TICKER (Safety net if event misses)
---------------------------------------------------------------------------

--[[
    Start fallback ticker. Only activates if queue grows and ~1 sec passes
    without PLAYER_REGEN_ENABLED firing. Should rarely/never trigger in normal
    gameplay, but provides a safety net against edge cases.
]]
function ProtectedOperations:_StartFallbackTicker()
    if self._ticker then return end
    
    self._ticker = C_Timer.NewTicker(self._flushInterval, function()
        if not InCombatLockdown() and #self._queue > 0 then
            if addon.DebugLog then
                addon:DebugLog("ProtectedOps", 
                    "Fallback ticker triggering flush (queue=" .. #self._queue .. ")", 2)
            end
            self:FlushQueue()
        end
        
        --- Cancel ticker if queue empty ---
        if #self._queue == 0 and self._ticker then
            self._ticker:Cancel()
            self._ticker = nil
        end
    end)
end

--[[
    Stop fallback ticker.
]]
function ProtectedOperations:_StopFallbackTicker()
    if self._ticker then
        self._ticker:Cancel()
        self._ticker = nil
    end
end

---------------------------------------------------------------------------
-- EVENT SETUP
---------------------------------------------------------------------------

--[[
    Initialize event handling for combat state tracking and queue flushing.
    Called during addon initialization.
]]
function ProtectedOperations:Init()
    if self._eventFrame then return end
    
    self._eventFrame = CreateFrame("Frame")
    self._eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self._eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    
    self._eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            ProtectedOperations:_OnCombatState(true)
            
        elseif event == "PLAYER_REGEN_ENABLED" then
            ProtectedOperations:_OnCombatState(false)
            
            --- Flush all queued operations once safe ---
            if #ProtectedOperations._queue > 0 then
                ProtectedOperations:FlushQueue()
                
                --- If queue still has items, start fallback ticker ---
                if #ProtectedOperations._queue > 0 then
                    ProtectedOperations:_StartFallbackTicker()
                end
            end
        end
    end)
    
    if addon.DebugLog then
        addon:DebugLog("ProtectedOps", "Event system initialized", 2)
    end
end

---------------------------------------------------------------------------
-- DIAGNOSTICS & DEBUG
---------------------------------------------------------------------------

--[[
    Get current queue statistics for monitoring/debugging.
]]
function ProtectedOperations:GetStats()
    return {
        queueSize = #self._queue,
        inCombat = self._inCombat,
        indexSize = self:_CountTableKeys(self._index),
        totalQueued = self._stats.totalQueued,
        totalFlushed = self._stats.totalFlushed,
        totalSkipped = self._stats.totalSkipped,
        lastFlushTime = self._stats.lastFlushTime,
        lastFlushOpsCount = self._stats.lastFlushOpsCount,
        byType = self._stats.byType,
        byPriority = self._stats.byPriority,
        fallbackTickerActive = self._ticker ~= nil,
    }
end

--[[
    Helper: count keys in a table.
]]
function ProtectedOperations:_CountTableKeys(t)
    if not t then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--[[
    Print statistics to chat for diagnostics.
]]
function ProtectedOperations:PrintStats()
    local stats = self:GetStats()
    print("|cffFFD700=== Protected Operations Stats ===|r")
    print(string.format("  Queue Size: %d", stats.queueSize))
    print(string.format("  In Combat: %s", stats.inCombat and "YES" or "NO"))
    print(string.format("  Index Size: %d", stats.indexSize))
    print(string.format("  Total Queued: %d", stats.totalQueued))
    print(string.format("  Total Flushed: %d", stats.totalFlushed))
    print(string.format("  Total Skipped (dedup): %d", stats.totalSkipped))
    print(string.format("  Last Flush: %d ops at %.2f", stats.lastFlushOpsCount, stats.lastFlushTime))
    print(string.format("  Fallback Ticker: %s", stats.fallbackTickerActive and "ACTIVE" or "idle"))
    
    if next(stats.byType) then
        print("  By Type:")
        for opType, count in pairs(stats.byType) do
            print(string.format("    - %s: %d", opType, count))
        end
    end
    
    if next(stats.byPriority) then
        print("  By Priority:")
        for priority, count in pairs(stats.byPriority) do
            print(string.format("    - %s: %d", priority, count))
        end
    end
end

--[[
    Reset statistics.
]]
function ProtectedOperations:ResetStats()
    self._stats = {
        totalQueued = 0,
        totalFlushed = 0,
        totalSkipped = 0,
        byType = {},
        byPriority = {},
        lastFlushTime = 0,
        lastFlushOpsCount = 0,
    }
    if addon.DebugLog then
        addon:DebugLog("ProtectedOps", "Statistics reset", 2)
    end
end

---------------------------------------------------------------------------
-- PERFORMANCE PROFILING INTEGRATION
---------------------------------------------------------------------------

--[[
    Get performance metrics for external profilers (e.g., PerformanceLib).
    Returns table with flush performance data for timeline capture.
]]
function ProtectedOperations:GetPerformanceMetrics()
    return {
        system = "ProtectedOperations",
        queueSize = #self._queue,
        indexSize = self:_CountTableKeys(self._index),
        inCombat = self._inCombat,
        batchSize = self._batchSize,
        totalQueued = self._stats.totalQueued,
        totalFlushed = self._stats.totalFlushed,
        totalSkipped = self._stats.totalSkipped,
        lastFlushTime = self._stats.lastFlushTime,
        lastFlushOpsCount = self._stats.lastFlushOpsCount,
        fallbackTickerActive = self._ticker ~= nil,
        timestamp = GetTime(),
    }
end

--[[
    Export stats for chat display (human-readable format).
    Called by /SUFprotected command.
]]
function ProtectedOperations:ExportStatsForChat()
    local stats = self:GetStats()
    local lines = {
        "|cffFFD700=== SUF Protected Operations Report ===|r",
        "",
        "QUEUE STATUS:",
        string.format("  Current Queue Size: |cff00FF00%d|r operations", stats.queueSize),
        string.format("  Index Entries: %d keys", stats.indexSize),
        string.format("  In Combat: %s", stats.inCombat and "|cffFF0000YES|r" or "|cff00FF00NO|r"),
        "",
        "GLOBAL STATISTICS:",
        string.format("  Total Queued: %d", stats.totalQueued),
        string.format("  Total Flushed: %d", stats.totalFlushed),
        string.format("  Total Skipped (dedup): %d", stats.totalSkipped),
        string.format("  Dedup Efficiency: %.1f%%", stats.totalQueued > 0 and (stats.totalSkipped / stats.totalQueued * 100) or 0),
        "",
        "LAST FLUSH:",
        string.format("  Operations Flushed: %d", stats.lastFlushOpsCount),
        string.format("  Timestamp: %.2f", stats.lastFlushTime),
        "",
        "SYSTEM STATE:",
        string.format("  Fallback Ticker: %s", stats.fallbackTickerActive and "|cffFF6600ACTIVE|r" or "idle"),
        string.format("  Batch Size: %d ops per window", self._batchSize),
        "",
    }
    
    if next(stats.byType) then
        table.insert(lines, "OPERATIONS BY TYPE:")
        local sortedTypes = {}
        for opType, count in pairs(stats.byType) do
            table.insert(sortedTypes, {type = opType, count = count})
        end
        table.sort(sortedTypes, function(a, b) return a.count > b.count end)
        for _, entry in ipairs(sortedTypes) do
            table.insert(lines, string.format("  - %s: %d", entry.type, entry.count))
        end
        table.insert(lines, "")
    end
    
    if next(stats.byPriority) then
        table.insert(lines, "OPERATIONS BY PRIORITY:")
        local priorities = {"CRITICAL", "HIGH", "MEDIUM", "NORMAL", "LOW"}
        for _, priority in ipairs(priorities) do
            local count = stats.byPriority[priority]
            if count and count > 0 then
                table.insert(lines, string.format("  - %s: %d", priority, count))
            end
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "|cffFFD700Command:|r /SUFprotected [stats|reset|help]")
    
    return table.concat(lines, "\n")
end

--[[
    Detailed help text for diagnostic commands.
]]
function ProtectedOperations:GetHelpText()
    return [[
|cffFFD700=== SUF Protected Operations Diagnostic Commands ===|r

|cff00FF00/SUFprotected|r                 - Show current queue status and statistics
|cff00FF00/SUFprotected stats|r            - Print full statistics report
|cff00FF00/SUFprotected reset|r            - Reset all statistics counters
|cff00FF00/SUFprotected queue|r            - Show current queue contents (developer)
|cff00FF00/SUFprotected help|r             - Show this help text

QUEUE MECHANICS:
  - Operations that would mutate frames are queued during InCombatLockdown()
  - Queue is flushed automatically on PLAYER_REGEN_ENABLED event
  - Keyed operations prevent duplicate entries in queue
  - Operations are processed in batches (48 per safe window)
  - Fallback ticker (200ms) ensures queue doesn't accumulate if event misses

PRIORITIES:
  - CRITICAL (1):  Flush immediately in next window (highest priority)
  - HIGH (2):      Before NORMAL operations
  - MEDIUM (3):    Before NORMAL operations
  - NORMAL (4):    Standard priority (default)
  - LOW (5):       Last to flush (cosmetic operations)

DIAGNOSTICS:
  Use |cff00FF00/run addon.ProtectedOperations:PrintStats()|r in chat for live metrics
  Check BugGrabber for operation errors / taint propagation
  Monitor queue size during complex bar transitions
    ]]
end

---------------------------------------------------------------------------
-- ADDON INTEGRATION (Backward compatibility layer)
---------------------------------------------------------------------------

--[[
    Create convenience aliases on main addon object for backward compatibility.
    Allows existing code to use addon:QueueOrRun() instead of addon.ProtectedOperations:QueueOrRun().
    
    NOTE: RegisterAddonAliasesEarly() is called at module load time.
    This function is a no-op to avoid duplicate registration.
]]
function ProtectedOperations:RegisterAddonAliases()
    -- Already registered by RegisterAddonAliasesEarly() at load time
    if addon and addon.DebugLog then
        addon:DebugLog("ProtectedOps", "Addon integration aliases already registered", 2)
    end
end

---------------------------------------------------------------------------
-- EARLY INITIALIZATION: Register addon aliases immediately to prevent nil errors
---------------------------------------------------------------------------

function ProtectedOperations:RegisterAddonAliasesEarly()
    if not addon then return end
    local self_ref = ProtectedOperations
    
    --- Alias: addon:QueueOrRun(func, opts) with lazy Init() if needed ---
    function addon:QueueOrRun(func, opts)
        -- Lazy initialize if not yet done
        if not self_ref._eventFrame then
            self_ref:Init()
        end
        return self_ref:QueueOrRun(func, opts)
    end
    
    --- Alias: addon:FlushProtectedOperations() (old API name) ---
    function addon:FlushProtectedOperations(maxOps)
        if not self_ref._eventFrame then
            self_ref:Init()
        end
        return self_ref:FlushQueue(maxOps)
    end
end

---------------------------------------------------------------------------
-- EXPORT
---------------------------------------------------------------------------

addon.ProtectedOperations = ProtectedOperations

--- Register early aliases immediately to prevent nil errors during frame spawning ---
ProtectedOperations:RegisterAddonAliasesEarly()
