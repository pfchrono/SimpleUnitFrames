---
name: wow-api-group-lfg
description: "Complete reference for WoW Retail Party, Raid, Dungeon Finder, Premade Groups (LFG List), Social Queue, Lobby Matchmaker, and Raid Marker APIs. Covers C_PartyInfo (party management, invites, conversion, ready check, countdown), C_LFGInfo (dungeon finder queue, role selection), C_LFGList (premade groups listing, search, application, creation), C_SocialQueue (friend queue tracking), C_LobbyMatchmakerInfo, raid markers, and group-related events. Use when working with party/raid management, group finder, premade group listing, dungeon queue, role selection, ready checks, or raid markers."
---

# Group & LFG API (Retail â€” Patch 12.0.0)

Comprehensive reference for party/raid management, dungeon finder, premade groups, and related APIs.

> **Source:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
> **Current as of:** Patch 12.0.0 (Build 65655) â€” January 28, 2026
> **Scope:** Retail only.

---

## Scope

- **C_PartyInfo** â€” Party management, invites, conversion
- **C_LFGInfo** â€” Dungeon Finder queue system
- **C_LFGList** â€” Premade Groups (Group Finder)
- **C_SocialQueue** â€” Social queue tracking
- **C_LobbyMatchmakerInfo** â€” Lobby matchmaker
- **Raid Markers** â€” World and target markers
- **Group utility** â€” Ready check, countdown, roles

---

## C_PartyInfo â€” Party Management

### Core Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `C_PartyInfo.InviteUnit(name)` | â€” | Invite player to group |
| `C_PartyInfo.UninviteUnit(name [, reason])` | â€” | Kick player from group |
| `C_PartyInfo.LeaveParty([category])` | â€” | Leave group |
| `C_PartyInfo.ConvertToParty()` | â€” | Convert raid to party |
| `C_PartyInfo.ConvertToRaid()` | â€” | Convert party to raid |
| `C_PartyInfo.CanInvite()` | `canInvite` | Can invite to group? |
| `C_PartyInfo.IsPartyFull([category])` | `isFull` | Is group full? |
| `C_PartyInfo.IsPartyInJailersTower()` | `isInTorghast` | In Torghast? |
| `C_PartyInfo.GetActiveCategories()` | `categories` | Active party categories |
| `C_PartyInfo.GetMinLevel([category])` | `minLevel` | Minimum level requirement |
| `C_PartyInfo.GetInviteReferralInfo(inviteGUID)` | `referredByGUID, referredByName, ...` | Invite referral info |
| `C_PartyInfo.GetInviteConfirmationInvalidQueues(inviteGUID)` | `queues` | Invalid queues for invite |
| `C_PartyInfo.ConfirmInviteUnit(name)` | â€” | Confirm pending invite |
| `C_PartyInfo.DoCountdown(seconds)` | â€” | Start raid countdown |
| `C_PartyInfo.DoReadyCheck()` | â€” | Initiate ready check |
| `C_PartyInfo.GetRestrictPingsTo()` | `restrictTo` | Ping restriction setting |
| `C_PartyInfo.SetRestrictPingsTo(restrictTo)` | â€” | Set ping restriction |
| `C_PartyInfo.AllowIncomingDelves(allow)` | â€” | Allow incoming Delve invites |
| `C_PartyInfo.IsCrossFactionParty([category])` | `isCrossFaction` | Is cross-faction group? |

### Group Query Functions (Global)

| Function | Returns | Description |
|----------|---------|-------------|
| `IsInGroup([category])` | `inGroup` | In any group? |
| `IsInRaid([category])` | `inRaid` | In a raid? |
| `GetNumGroupMembers([category])` | `numMembers` | Group member count |
| `GetNumSubgroupMembers([category])` | `numSubMembers` | Party-size count |
| `UnitInParty(unit)` | `inParty` | Is unit in party? |
| `UnitInRaid(unit)` | `inRaid` | Is unit in raid? |
| `GetRaidRosterInfo(raidIndex)` | `name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole` | Raid roster info |
| `IsPartyLFG()` | `isLFG` | In LFG group? |
| `IsInInstance()` | `inInstance, instanceType` | In instance? |
| `GetInstanceInfo()` | `name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID` | Instance info |
| `SetRaidSubgroup(memberIndex, subgroup)` | â€” | Move member to subgroup |
| `SwapRaidSubgroup(index1, index2)` | â€” | Swap two members |
| `PromoteToLeader(unit)` | â€” | Promote to leader |
| `DemoteAssistant(unit)` | â€” | Demote assistant |
| `PromoteToAssistant(unit)` | â€” | Promote to assistant |
| `UnitIsGroupLeader(unit [, category])` | `isLeader` | Is unit the leader? |
| `UnitIsGroupAssistant(unit)` | `isAssistant` | Is unit assistant? |

### Role Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `UnitGroupRolesAssigned(unit)` | `role` | TANK, HEALER, DAMAGER, NONE |
| `UnitSetRole(unit, role)` | â€” | Set unit's role |
| `GetSpecializationRole(specIndex)` | `role` | Spec's default role |
| `UnitGetAvailableRoles(unit)` | `canTank, canHeal, canDPS` | Available roles |

### Ready Check Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `GetReadyCheckStatus(unit)` | `status` | ready, notready, waiting |
| `GetReadyCheckTimeLeft()` | `timeLeft` | Seconds remaining |
| `ConfirmReadyCheck(isReady)` | â€” | Respond to ready check |

---

## C_LFGInfo â€” Dungeon Finder

| Function | Returns | Description |
|----------|---------|-------------|
| `C_LFGInfo.GetAllEntriesForCategory(category)` | `entries` | All LFG entries |
| `C_LFGInfo.GetLFGDungeonInfo(dungeonID)` | `info` | Dungeon info |
| `C_LFGInfo.GetRoleCheckDifficultyDetails()` | `difficultyID, isBlocked` | Role check details |
| `C_LFGInfo.CanPlayerUseLFD()` | `canUse` | Can use dungeon finder? |
| `C_LFGInfo.CanPlayerUseScenarioFinder()` | `canUse` | Can use scenario finder? |
| `C_LFGInfo.CanPlayerUsePremadeGroup()` | `canUse` | Can use premade groups? |
| `C_LFGInfo.GetQueuedDungeons(category)` | `dungeons` | Currently queued dungeons |
| `C_LFGInfo.HideNameFromUI(dungeonID)` | `hidden` | Is name hidden? |

### LFG Global Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `GetLFGMode(category)` | `mode, subMode` | Current LFG mode |
| `GetLFGRoles()` | `isLeader, isTank, isHealer, isDPS` | Selected roles |
| `SetLFGRoles(isLeader, isTank, isHealer, isDPS)` | â€” | Set roles |
| `GetLFGProposal()` | `leaderName, category, dungeonID, ...` | Current proposal |
| `AcceptProposal()` | â€” | Accept dungeon proposal |
| `RejectProposal()` | â€” | Reject dungeon proposal |
| `GetLFGQueueStats(category)` | `hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceSubType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime` | Queue statistics |
| `JoinLFG(category)` | â€” | Join LFG queue |
| `LeaveLFG(category)` | â€” | Leave LFG queue |
| `CompleteLFGReadyCheck(isReady)` | â€” | Complete LFG ready check |
| `GetLFGDeserterExpiration()` | `expiration` | Deserter debuff time |
| `CompleteLFGRoleCheck(isAccepted)` | â€” | Complete role check |

---

## C_LFGList â€” Premade Groups (Group Finder)

### Search & Browse

| Function | Returns | Description |
|----------|---------|-------------|
| `C_LFGList.Search(categoryID, filter [, preferredFilters [, languages [, ...] ] ])` | â€” | Search for groups |
| `C_LFGList.GetSearchResults()` | `totalResultsFound, results` | Get search results |
| `C_LFGList.GetSearchResultInfo(searchResultID)` | `resultInfo` | Single result info |
| `C_LFGList.GetSearchResultMemberInfo(searchResultID, memberIndex)` | `memberInfo` | Result member info |
| `C_LFGList.GetSearchResultMemberCounts(searchResultID)` | `numMembers, numTanks, numHealers, numDPS` | Member count per role |
| `C_LFGList.HasSearchResultInfo(searchResultID)` | `hasInfo` | Has result info? |
| `C_LFGList.GetFilteredSearchResults()` | `totalResults, filteredResults` | Filtered results |
| `C_LFGList.GetAvailableCategories()` | `categoryIDs` | Available categories |
| `C_LFGList.GetCategoryInfo(categoryID)` | `name, ...` | Category info |
| `C_LFGList.GetAvailableActivities(categoryID [, groupID [, filter]])` | `activityIDs` | Available activities |
| `C_LFGList.GetActivityInfoTable(activityID)` | `info` | Activity info |
| `C_LFGList.GetActivityFullName(activityID [, questID [, isWarModeDesired]])` | `fullName` | Full activity name |
| `C_LFGList.GetAvailableLanguageSearchFilter()` | `languages` | Available languages |

### Create & Manage Listing

| Function | Returns | Description |
|----------|---------|-------------|
| `C_LFGList.CreateListing(activityID, itemLevel, autoAccept, privateGroup, questID, ...)` | â€” | Create group listing |
| `C_LFGList.UpdateListing(activityID, itemLevel, autoAccept, privateGroup, questID, ...)` | â€” | Update listing |
| `C_LFGList.RemoveListing()` | â€” | Remove your listing |
| `C_LFGList.GetActiveEntryInfo()` | `entryInfo` | Your listing info |
| `C_LFGList.HasActiveEntryInfo()` | `hasInfo` | Have active listing? |

### Applications

| Function | Returns | Description |
|----------|---------|-------------|
| `C_LFGList.ApplyToGroup(searchResultID, comment, tankRole, healerRole, dpsRole)` | â€” | Apply to group |
| `C_LFGList.CancelApplication(searchResultID)` | â€” | Cancel application |
| `C_LFGList.GetApplications()` | `applications` | Your applications |
| `C_LFGList.GetApplicationInfo(searchResultID)` | `appStatus, pendingStatus, appDuration, ...` | Application status |
| `C_LFGList.GetApplicants()` | `applicantIDs` | Applicants to your group |
| `C_LFGList.GetApplicantInfo(applicantID)` | `info` | Applicant info |
| `C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)` | `memberInfo` | Applicant member info |
| `C_LFGList.InviteApplicant(applicantID)` | â€” | Invite applicant |
| `C_LFGList.DeclineApplicant(applicantID)` | â€” | Decline applicant |

---

## Raid Markers

| Function | Returns | Description |
|----------|---------|-------------|
| `SetRaidTarget(unit, markerIndex)` | â€” | Set raid target marker |
| `GetRaidTargetIndex(unit)` | `markerIndex` | Get target marker |
| `SetRaidTargetIcon(unit, icon)` | â€” | Set raid icon (same as above) |
| `IsRaidMarkerActive(markerIndex)` | `isActive` | Is world marker active? |
| `PlaceRaidMarker(markerIndex)` | â€” | Place world marker at cursor |
| `ClearRaidMarker(markerIndex)` | â€” | Clear world marker |
| `UnitPopupSetRaidTargetButton_OnClick(frame, unit, icon)` | â€” | Set from unit popup |

### Marker Index Values

| Index | Marker |
|-------|--------|
| 1 | Star (Yellow) |
| 2 | Circle (Orange) |
| 3 | Diamond (Purple) |
| 4 | Triangle (Green) |
| 5 | Moon (Silver) |
| 6 | Square (Blue) |
| 7 | Cross/X (Red) |
| 8 | Skull (White) |
| 0 | Clear |

---

## Common Patterns

### Check Group Type and Size

```lua
local function GetGroupInfo()
    if IsInRaid() then
        return "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        return "party", GetNumGroupMembers()
    else
        return "solo", 1
    end
end
```

### Iterate Group Members

```lua
local function ForEachGroupMember(callback)
    local prefix = IsInRaid() and "raid" or "party"
    local numMembers = GetNumGroupMembers()
    
    if IsInRaid() then
        for i = 1, numMembers do
            callback(prefix .. i)
        end
    else
        callback("player")
        for i = 1, numMembers - 1 do
            callback(prefix .. i)
        end
    end
end

ForEachGroupMember(function(unit)
    print(UnitName(unit), UnitGroupRolesAssigned(unit))
end)
```

### Search Premade Groups

```lua
-- Search for M+ groups
local CATEGORY_DUNGEON = 2
C_LFGList.Search(CATEGORY_DUNGEON, "")

local frame = CreateFrame("Frame")
frame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
frame:SetScript("OnEvent", function()
    local totalResults, results = C_LFGList.GetSearchResults()
    for _, resultID in ipairs(results) do
        local info = C_LFGList.GetSearchResultInfo(resultID)
        if info then
            print(info.name, info.comment, info.numMembers)
        end
    end
end)
```

---

## Key Events

| Event | Payload | Description |
|-------|---------|-------------|
| `GROUP_ROSTER_UPDATE` | â€” | Group composition changed |
| `GROUP_FORMED` | category | Group formed |
| `GROUP_LEFT` | category | Left group |
| `GROUP_JOINED` | category | Joined group |
| `PARTY_INVITE_REQUEST` | name, ... | Received party invite |
| `PARTY_INVITE_CANCEL` | â€” | Invite cancelled |
| `PARTY_LEADER_CHANGED` | â€” | Leader changed |
| `PARTY_MEMBER_ENABLE` | unitToken | Member came online |
| `PARTY_MEMBER_DISABLE` | unitToken | Member went offline |
| `ROLE_CHANGED_INFORM` | changedName, sourceName, oldRole, newRole | Role changed |
| `READY_CHECK` | initiatorName, readyCheckTimeLeft | Ready check started |
| `READY_CHECK_CONFIRM` | unit, isReady | Member responded |
| `READY_CHECK_FINISHED` | preempted | Ready check done |
| `START_TIMER` | timerType, timeRemaining, totalTime | Countdown timer |
| `LFG_LIST_SEARCH_RESULTS_RECEIVED` | â€” | Premade search done |
| `LFG_LIST_SEARCH_RESULT_UPDATED` | searchResultID | Result updated |
| `LFG_LIST_ACTIVE_ENTRY_UPDATE` | â€” | Your listing updated |
| `LFG_LIST_APPLICANT_UPDATED` | applicantID | Applicant updated |
| `LFG_LIST_APPLICANT_LIST_UPDATED` | â€” | Applicant list changed |
| `LFG_LIST_ENTRY_CREATION_FAILED` | â€” | Listing creation failed |
| `LFG_PROPOSAL_SHOW` | â€” | Dungeon proposal shown |
| `LFG_PROPOSAL_SUCCEEDED` | â€” | Proposal accepted |
| `LFG_PROPOSAL_FAILED` | â€” | Proposal failed |
| `LFG_QUEUE_STATUS_UPDATE` | â€” | Queue status changed |
| `LFG_UPDATE` | â€” | LFG system updated |
| `LFG_ROLE_CHECK_SHOW` | isRequeue | Role check shown |
| `RAID_TARGET_UPDATE` | â€” | Raid marker changed |
| `INSTANCE_GROUP_SIZE_CHANGED` | â€” | Instance group size changed |

---

## Gotchas & Restrictions

1. **InviteUnit requires hardware event** â€” Must be called from a user click/key handler.
2. **Party vs raid iteration** â€” Use different unit tokens: `"party1"-"party4"` vs `"raid1"-"raid40"`. Player is NOT in party tokens.
3. **Category matters** â€” `IsInGroup()` defaults to `LE_PARTY_CATEGORY_HOME`. Use `LE_PARTY_CATEGORY_INSTANCE` for LFG groups.
4. **GROUP_ROSTER_UPDATE fires often** â€” Debounce processing. Fires for role changes, joins, leaves, subgroup changes.
5. **LFG search is async** â€” `C_LFGList.Search()` is async. Wait for `LFG_LIST_SEARCH_RESULTS_RECEIVED`.
6. **SendAddonMessage in instances** â€” Blocked in 12.0.0. Group addons cannot communicate via addon messages in instances.
7. **Cross-faction groups** â€” Check `C_PartyInfo.IsCrossFactionParty()` to handle cross-faction UI properly.
8. **Raid markers require assist** â€” `SetRaidTarget()` requires leader or assistant in raids.
