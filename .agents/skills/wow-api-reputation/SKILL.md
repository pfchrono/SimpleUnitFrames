---
name: wow-api-reputation
description: "Complete reference for WoW Retail Reputation, Faction, Major Factions, Paragon, and Neighborhood Initiative APIs. Covers C_Reputation (faction info, standings, watched faction, headers, friendship reps, paragon), C_MajorFactions (Dragonflight+ renown factions, renown levels, rewards), C_NeighborhoodInitiative (12.0.0 housing neighborhood reputation), faction expansion data, and reputation-related events. Use when working with reputation tracking, faction standings, renown systems, paragon rewards, friendship reputations, or neighborhood initiatives."
---

# Reputation API (Retail â€” Patch 12.0.0)

Comprehensive reference for reputation, faction, major factions, paragon, and neighborhood initiative APIs.

> **Source:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
> **Current as of:** Patch 12.0.0 (Build 65655) â€” January 28, 2026
> **Scope:** Retail only.

---

## Scope

- **C_Reputation** â€” Faction info, standings, watched faction, headers
- **C_MajorFactions** â€” Renown factions (Dragonflight+)
- **Friendship Reputations** â€” Friendship-style rep (Tillers, etc.)
- **Paragon** â€” Paragon reputation (post-max)
- **C_NeighborhoodInitiative** â€” Housing neighborhood rep (12.0.0)

---

## C_Reputation â€” Core Reputation System

### Faction Info

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Reputation.GetNumFactions()` | `numFactions` | Number of factions in list |
| `C_Reputation.GetFactionDataByIndex(index)` | `factionData` | Faction data at index |
| `C_Reputation.GetFactionDataByID(factionID)` | `factionData` | Faction data by ID |
| `C_Reputation.IsFactionActive(factionID)` | `isActive` | Is faction active? |
| `C_Reputation.IsMajorFaction(factionID)` | `isMajor` | Is major faction? |
| `C_Reputation.IsAccountWideReputation(factionID)` | `isAccountWide` | Account-wide rep? |
| `C_Reputation.GetFactionParagonInfo(factionID)` | `currentValue, threshold, questID, hasRewardPending, tooLowLevelForParagon` | Paragon info |
| `C_Reputation.IsFactionParagon(factionID)` | `isParagon` | Has paragon? |
| `C_Reputation.RequestFactionParagonPreloadRewardData(factionID)` | â€” | Preload paragon data |

### Faction Data Fields

The `factionData` table contains:
- `factionID` â€” Unique faction ID
- `name` â€” Faction name
- `description` â€” Description text
- `reaction` â€” Standing index (1=Hated to 8=Exalted)
- `currentReactionThreshold` â€” Min rep for current standing
- `nextReactionThreshold` â€” Rep needed for next standing
- `currentStanding` â€” Current rep value
- `atWarWith` â€” At war? (PvP hostile)
- `canToggleAtWar` â€” Can toggle at war?
- `isChild` â€” Is sub-faction?
- `isHeader` â€” Is a header row?
- `isHeaderWithRep` â€” Header that has rep?
- `isCollapsed` â€” Is header collapsed?
- `isWatched` â€” Is watched faction?
- `hasBonusRepGain` â€” Has rep bonus?
- `canSetInactive` â€” Can set inactive?

### Watched Faction

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Reputation.GetWatchedFactionData()` | `factionData` | Watched faction info |
| `C_Reputation.SetWatchedFactionByIndex(index)` | â€” | Set watched by index |

### Faction List Management

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Reputation.ExpandFactionHeader(index)` | â€” | Expand header |
| `C_Reputation.CollapseFactionHeader(index)` | â€” | Collapse header |
| `C_Reputation.SetFactionActive(index)` | â€” | Set faction active |
| `C_Reputation.SetFactionInactive(index)` | â€” | Set faction inactive |
| `C_Reputation.ToggleAtWar(index)` | â€” | Toggle at war |

### Standing Names

| Index | Standing |
|-------|----------|
| 1 | Hated |
| 2 | Hostile |
| 3 | Unfriendly |
| 4 | Neutral |
| 5 | Friendly |
| 6 | Honored |
| 7 | Revered |
| 8 | Exalted |

---

## C_MajorFactions â€” Renown System

Major factions use renown levels instead of traditional reputation standings.

| Function | Returns | Description |
|----------|---------|-------------|
| `C_MajorFactions.GetMajorFactionData(factionID)` | `majorFactionData` | Major faction info |
| `C_MajorFactions.GetMajorFactionIDs(expansionID)` | `factionIDs` | Major factions for expansion |
| `C_MajorFactions.GetCurrentRenownLevel(factionID)` | `renownLevel` | Current renown level |
| `C_MajorFactions.GetRenownLevels(factionID)` | `levels` | All renown levels |
| `C_MajorFactions.GetRenownRewardsForLevel(factionID, renownLevel)` | `rewards` | Rewards at level |
| `C_MajorFactions.HasMaximumRenown(factionID)` | `hasMax` | At max renown? |
| `C_MajorFactions.IsWeeklyRenownCapped(factionID)` | `isCapped` | Weekly cap reached? |
| `C_MajorFactions.GetMajorFactionRenownInfo(factionID)` | `renownInfo` | Renown progress info |

### Major Faction Data Fields

- `factionID` â€” Faction ID
- `name` â€” Faction name
- `celebrationSoundKit` â€” Sound on level up
- `renownLevel` â€” Current renown level
- `renownReputationEarned` â€” Rep earned toward next level
- `renownLevelThreshold` â€” Rep needed for next level
- `textureKit` â€” UI texture kit
- `expansionID` â€” Which expansion
- `isUnlocked` â€” Is faction unlocked?
- `unlockDescription` â€” How to unlock

---

## Friendship Reputations

Some factions use friendship instead of traditional reputation.

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Reputation.GetFriendshipReputation(factionID)` | `friendshipData` | Friendship rep info |
| `C_Reputation.IsFactionFriendship(factionID)` | `isFriendship` | Uses friendship? |

### Friendship Data Fields

- `friendshipFactionID` â€” Faction ID
- `standing` â€” Current standing text (e.g., "Good Friend")
- `maxRep` â€” Max rep for current tier
- `reputation` â€” Current rep value
- `nextThreshold` â€” Next tier threshold
- `text` â€” Standing description
- `texture` â€” Standing icon
- `reaction` â€” Reaction index
- `reversedColor` â€” Reverse progress bar color?

---

## C_NeighborhoodInitiative â€” Housing Neighborhood (12.0.0)

New in 12.0.0 for the player housing system.

| Function | Returns | Description |
|----------|---------|-------------|
| `C_NeighborhoodInitiative.GetCurrentInitiative()` | `initiativeInfo` | Current initiative |
| `C_NeighborhoodInitiative.GetInitiativeProgress()` | `progress` | Progress info |
| `C_NeighborhoodInitiative.GetInitiativeRewards()` | `rewards` | Initiative rewards |

---

## Common Patterns

### List All Factions with Standing

```lua
local numFactions = C_Reputation.GetNumFactions()
for i = 1, numFactions do
    local data = C_Reputation.GetFactionDataByIndex(i)
    if data and not data.isHeader then
        local standingNames = {"Hated","Hostile","Unfriendly","Neutral","Friendly","Honored","Revered","Exalted"}
        local standing = standingNames[data.reaction] or "Unknown"
        print(data.name, standing, data.currentStanding)
    end
end
```

### Check Renown Level

```lua
local function GetRenownProgress(factionID)
    if C_Reputation.IsMajorFaction(factionID) then
        local data = C_MajorFactions.GetMajorFactionData(factionID)
        if data then
            print(data.name, "Renown:", data.renownLevel)
            print("Progress:", data.renownReputationEarned, "/", data.renownLevelThreshold)
            return data.renownLevel
        end
    end
    return nil
end
```

### Check Paragon Reward

```lua
local function CheckParagonReward(factionID)
    if C_Reputation.IsFactionParagon(factionID) then
        local currentValue, threshold, questID, hasReward = 
            C_Reputation.GetFactionParagonInfo(factionID)
        if hasReward then
            print("Paragon reward available for faction", factionID)
        end
        return hasReward
    end
    return false
end
```

---

## Key Events

| Event | Payload | Description |
|-------|---------|-------------|
| `UPDATE_FACTION` | â€” | Reputation changed |
| `QUEST_LOG_UPDATE` | â€” | Quest/rep update (shared) |
| `MAJOR_FACTION_RENOWN_LEVEL_CHANGED` | factionID, newRenownLevel, oldRenownLevel | Renown level up |
| `MAJOR_FACTION_UNLOCKED` | factionID | Major faction unlocked |
| `UPDATE_EXPANSION_LEVEL` | â€” | Expansion level changed |

---

## Gotchas & Restrictions

1. **Headers in faction list** â€” `C_Reputation.GetFactionDataByIndex()` returns headers. Check `isHeader` to skip.
2. **Major factions vs traditional** â€” Check `C_Reputation.IsMajorFaction()` to determine which API to use.
3. **Paragon is post-exalted** â€” `GetFactionParagonInfo()` only works for factions at Exalted (or max renown for major factions).
4. **Friendship rep display** â€” Friendship factions show custom standing names. Use `GetFriendshipReputation()` for proper display text.
5. **Account-wide rep** â€” Some 12.0.0 reps are account-wide. Check `IsAccountWideReputation()`.
6. **Collapsed headers** â€” Collapsed headers hide child factions from the indexed list. Expand before iterating.
7. **Faction IDs are stable** â€” Unlike indices, factionIDs are stable and can be persisted in SavedVariables.
8. **Neighborhood initiative** â€” New 12.0.0 system; APIs may evolve.
