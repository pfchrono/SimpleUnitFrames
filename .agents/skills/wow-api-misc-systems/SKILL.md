---
name: wow-api-misc-systems
description: "Catch-all reference for smaller WoW Retail API systems that don't warrant individual skills. Covers Tutorial, ReportSystem, SplashScreen, Cinematic, ChromieTimeInfo, AlliedRaces, UserFeedback, WarbandSceneInfo, ResearchInfo (archaeology), Log, EventUtils, SlashCommand, ClickBindings, TooltipInfo, TooltipComparison, GossipInfo (NPC dialog), PlayerChoice, PlayerInteractionManager, ImmersiveInteraction, Localization, Locale, MirrorTimer, ModelInfo, Movie, ParentalControls, PerksActivities, RecruitAFriend, ContributionCollector, GarrisonInfo (legacy), Covenant/Soulbinds (legacy), AzeriteItem (legacy), and other utility namespaces. Use when working with NPC gossip/dialog, player choices, tooltips, tutorials, cinematics, Chromie Time, allied races, warbands, report system, or any miscellaneous game system."
---

# Miscellaneous Systems API (Retail â€” Patch 12.0.0)

Catch-all reference for smaller API systems that don't warrant individual skills.

> **Source:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
> **Current as of:** Patch 12.0.0 (Build 65655) â€” January 28, 2026
> **Scope:** Retail only.

---

## Scope

This skill covers ~40 smaller API systems grouped by category:

- **NPC Interaction** â€” GossipInfo, PlayerChoice, PlayerInteractionManager, ImmersiveInteraction
- **Tooltips** â€” TooltipInfo, TooltipComparison
- **UI Systems** â€” Tutorial, SplashScreen, SlashCommand, ClickBindings, MirrorTimer
- **Cinematics & Media** â€” Cinematic, Movie, ModelInfo
- **Social/Account** â€” ReportSystem, UserFeedback, ParentalControls, RecruitAFriend
- **Game Systems** â€” ChromieTimeInfo, AlliedRaces, WarbandSceneInfo, PerksActivities
- **Utility** â€” Log, EventUtils, Localization, Locale
- **Legacy** â€” GarrisonInfo, Covenant/Soulbinds, AzeriteItem, ResearchInfo, ContributionCollector

---

## NPC Interaction

### C_GossipInfo â€” NPC Dialog

| Function | Returns | Description |
|----------|---------|-------------|
| `C_GossipInfo.GetOptions()` | `options` | Available dialog options |
| `C_GossipInfo.GetText()` | `text` | NPC dialog text |
| `C_GossipInfo.GetNumOptions()` | `numOptions` | Number of options |
| `C_GossipInfo.SelectOption(optionID, text, confirmed)` | â€” | Select dialog option |
| `C_GossipInfo.SelectOptionByIndex(index)` | â€” | Select by index |
| `C_GossipInfo.GetNumAvailableQuests()` | `numQuests` | Available quests |
| `C_GossipInfo.GetAvailableQuests()` | `quests` | Available quest list |
| `C_GossipInfo.GetNumActiveQuests()` | `numQuests` | Active quests |
| `C_GossipInfo.GetActiveQuests()` | `quests` | Active quest list |
| `C_GossipInfo.SelectAvailableQuest(questID)` | â€” | Select available quest |
| `C_GossipInfo.SelectActiveQuest(questID)` | â€” | Select active quest |
| `C_GossipInfo.ForceGossip()` | `forceGossip` | Force gossip display? |
| `C_GossipInfo.CloseGossip()` | â€” | Close gossip window |
| `C_GossipInfo.GetPoiForUiMapID(uiMapID)` | `poiInfo` | POI for map |
| `C_GossipInfo.GetPoiInfo(uiMapID, gossipPoiID)` | `poiInfo` | Specific POI info |
| `C_GossipInfo.GetCustomGossipDescriptionString()` | `description` | Custom description |
| `C_GossipInfo.RefreshOptions()` | â€” | Refresh options |

#### Gossip Option Fields

- `gossipOptionID` â€” Unique option ID
- `name` â€” Option text
- `icon` â€” Option icon
- `status` â€” Status enum
- `orderIndex` â€” Sort order
- `flags` â€” Option flags
- `overrideIconID` â€” Override icon
- `selectOptionWhenOnlyOption` â€” Auto-select?
- `spellID` â€” Associated spell

### C_PlayerChoice â€” Player Choices

| Function | Returns | Description |
|----------|---------|-------------|
| `C_PlayerChoice.GetCurrentPlayerChoiceInfo()` | `choiceInfo` | Current choice |
| `C_PlayerChoice.GetNumPlayerChoices()` | `numChoices` | Number of choices |
| `C_PlayerChoice.GetPlayerChoiceOptionInfo(optionIndex)` | `optionInfo` | Option details |
| `C_PlayerChoice.GetPlayerChoiceRewardInfo(rewardIndex)` | `rewardInfo` | Reward details |
| `C_PlayerChoice.SendPlayerChoiceResponse(responseID)` | â€” | Make choice |
| `C_PlayerChoice.IsWaitingForPlayerChoiceResponse()` | `isWaiting` | Response pending? |
| `C_PlayerChoice.OnUIClosed()` | â€” | UI closed callback |
| `C_PlayerChoice.GetRemainingTime()` | `seconds` | Time limit |

### C_PlayerInteractionManager â€” Interaction Windows

| Function | Returns | Description |
|----------|---------|-------------|
| `C_PlayerInteractionManager.ClearInteraction(type)` | `cleared` | Close interaction |
| `C_PlayerInteractionManager.ReplaceInteraction(type, target)` | â€” | Replace interaction |
| `C_PlayerInteractionManager.IsInteractingWithNpcOfType(type)` | `isInteracting` | Interacting with type? |
| `C_PlayerInteractionManager.GetCurrentInteractionType()` | `type` | Current interaction |

#### Player Interaction Types (Enum.PlayerInteractionType)

| Name | Description |
|------|-------------|
| `Banker` | Bank NPC |
| `Merchant` | Vendor |
| `Trainer` | Trainer |
| `MailInfo` | Mailbox |
| `AuctionHouse` | Auction House |
| `GuildBanker` | Guild bank |
| `Transmogrifier` | Transmog NPC |
| `VoidStorageBanker` | Void storage |
| `StableManager` | Stable master |
| `BarberShop` | Barber shop |

### C_ImmersiveInteraction â€” Immersive NPC

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ImmersiveInteraction.GetCurrentInteraction()` | `interactionInfo` | Current immersive interaction |
| `C_ImmersiveInteraction.IsActive()` | `isActive` | Immersive mode active? |

---

## Tooltips

### C_TooltipInfo â€” Tooltip Data Provider

| Function | Returns | Description |
|----------|---------|-------------|
| `C_TooltipInfo.GetItemByID(itemID)` | `tooltipData` | Item tooltip data |
| `C_TooltipInfo.GetItemByItemLink(itemLink)` | `tooltipData` | Tooltip from link |
| `C_TooltipInfo.GetSpellByID(spellID)` | `tooltipData` | Spell tooltip |
| `C_TooltipInfo.GetUnitAura(unit, index, filter)` | `tooltipData` | Aura tooltip |
| `C_TooltipInfo.GetHyperlink(hyperlink)` | `tooltipData` | Generic hyperlink tooltip |
| `C_TooltipInfo.GetInventoryItem(unit, slot)` | `tooltipData` | Equipped item tooltip |
| `C_TooltipInfo.GetBagItem(bag, slot)` | `tooltipData` | Bag item tooltip |
| `C_TooltipInfo.GetGuildBankItem(tab, slot)` | `tooltipData` | Guild bank tooltip |
| `C_TooltipInfo.GetVoidStorageItem(slot)` | `tooltipData` | Void storage tooltip |
| `C_TooltipInfo.GetAchievementByID(achievementID)` | `tooltipData` | Achievement tooltip |
| `C_TooltipInfo.GetCurrencyByID(currencyID)` | `tooltipData` | Currency tooltip |
| `C_TooltipInfo.GetMountBySpellID(spellID)` | `tooltipData` | Mount tooltip |
| `C_TooltipInfo.GetPetByID(petID)` | `tooltipData` | Pet tooltip |
| `C_TooltipInfo.GetToyByItemID(itemID)` | `tooltipData` | Toy tooltip |
| `C_TooltipInfo.GetQuestItem(type, index)` | `tooltipData` | Quest reward tooltip |

### C_TooltipComparison â€” Item Comparison

| Function | Returns | Description |
|----------|---------|-------------|
| `C_TooltipComparison.GetItemComparisonInfo(tooltipData)` | `comparisonInfo` | Compare items |
| `C_TooltipComparison.GetItemComparisonDelta(tooltipData)` | `delta` | Stat differences |

---

## UI Systems

### Tutorial

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Tutorial.AcknowledgeTutorial(tutorialID)` | â€” | Mark tutorial seen |
| `C_Tutorial.IsTutorialFlagged(tutorialID)` | `isFlagged` | Already shown? |
| `C_Tutorial.SetTutorialFlag(tutorialID, flagged)` | â€” | Set flag |

### SplashScreen

| Function | Returns | Description |
|----------|---------|-------------|
| `C_SplashScreen.AcknowledgeSplash()` | â€” | Dismiss splash |
| `C_SplashScreen.CanViewSplashScreen()` | `canView` | Can show splash? |
| `C_SplashScreen.RequestLatestSplashScreen()` | â€” | Request latest |
| `C_SplashScreen.ShouldShowSplashScreen()` | `shouldShow` | Should display? |

### SlashCommand

| Function | Returns | Description |
|----------|---------|-------------|
| `SlashCmdList["COMMANDNAME"]` | â€” | Register slash command |
| `SLASH_COMMANDNAME1 = "/cmd"` | â€” | Define slash trigger |
| `hash_SlashCmdList` | â€” | Internal hash table |

### ClickBindings

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ClickBindings.GetBindingType(modifiers, button)` | `bindingType` | Binding at key combo |
| `C_ClickBindings.SetBindingType(modifiers, button, type)` | â€” | Set binding |
| `C_ClickBindings.ResetBindings()` | â€” | Reset all |
| `C_ClickBindings.GetProfileInfo()` | `profileInfo` | Profile data |

### MirrorTimer â€” Breath/Fatigue Bars

| Function | Returns | Description |
|----------|---------|-------------|
| `GetMirrorTimerInfo(index)` | `timer, initial, maxValue, scale, paused, label` | Timer info |
| `GetMirrorTimerProgress(timer)` | `value` | Timer value |
| `MIRRORTIMER_NUMTIMERS` | 3 | Max timers |

---

## Cinematics & Media

### Cinematic

| Function | Returns | Description |
|----------|---------|-------------|
| `OpeningCinematic()` | â€” | Play opening cinematic |
| `CinematicFinished(id, didCancel)` | â€” | Cinematic ended |
| `IsInCinematicScene()` | `inCinematic` | In cinematic? |
| `StopCinematic()` | â€” | Stop cinematic |
| `InCinematic()` | `inCinematic` | Legacy cinematic check |

### Movie

| Function | Returns | Description |
|----------|---------|-------------|
| `MovieFrame.PlayMovie(movieID)` | â€” | Play movie |
| `GameMovieFinished()` | â€” | Movie ended callback |

### C_ModelInfo â€” Model Data

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ModelInfo.GetModelSceneInfoByID(sceneID)` | `sceneInfo` | Scene info |
| `C_ModelInfo.GetModelSceneActorInfoByID(actorID)` | `actorInfo` | Actor info |
| `C_ModelInfo.GetModelSceneCameraInfoByID(cameraID)` | `cameraInfo` | Camera info |
| `C_ModelInfo.AddActiveModelScene(frame, sceneID)` | â€” | Add scene to frame |
| `C_ModelInfo.ClearActiveModelScene(frame)` | â€” | Clear scene |

---

## Social / Account

### C_ReportSystem â€” Player Reports

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ReportSystem.CanReportPlayer(playerLocation)` | `canReport` | Can report? |
| `C_ReportSystem.SendReport(reportInfo)` | â€” | Submit report |
| `C_ReportSystem.GetMajorCategoriesForReportType(reportType)` | `categories` | Report categories |
| `C_ReportSystem.GetMinorCategoriesForMajorCategory(majorCategory)` | `minorCategories` | Sub-categories |
| `C_ReportSystem.InitiateReportPlayer(complaintType, playerName)` | â€” | Start report flow |

### C_UserFeedback â€” Feedback System

| Function | Returns | Description |
|----------|---------|-------------|
| `C_UserFeedback.SubmitBug(description)` | â€” | Submit bug report |
| `C_UserFeedback.SubmitSuggestion(description)` | â€” | Submit suggestion |

### C_ParentalControls â€” Parental Controls

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ParentalControls.GetRemainingPlayTime()` | `minutes` | Play time left |
| `C_ParentalControls.IsPlayTimeActive()` | `isActive` | Play time limit? |

### C_RecruitAFriend â€” Recruit A Friend

| Function | Returns | Description |
|----------|---------|-------------|
| `C_RecruitAFriend.GetRecruitInfo()` | `recruitInfo` | RAF info |
| `C_RecruitAFriend.IsEnabled()` | `enabled` | RAF enabled? |
| `C_RecruitAFriend.IsRecruitingEnabled()` | `enabled` | Can recruit? |
| `C_RecruitAFriend.GenerateLink()` | `link` | Generate RAF link |
| `C_RecruitAFriend.ClaimActivityReward(activityID)` | â€” | Claim RAF reward |
| `C_RecruitAFriend.ClaimNextReward()` | â€” | Claim next |

---

## Game Systems

### C_ChromieTimeInfo â€” Chromie Time (Level Scaling)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ChromieTimeInfo.GetChromieTimeExpansionOptions()` | `options` | Available expansions |
| `C_ChromieTimeInfo.SelectChromieTimeExpansionOption(optionID)` | â€” | Select expansion |
| `C_ChromieTimeInfo.GetChromieTimeExpansionOption(optionID)` | `optionInfo` | Option info |
| `C_ChromieTimeInfo.GetCurrentChromieTimeExpansionOption()` | `optionInfo` | Current selection |
| `C_ChromieTimeInfo.CloseChromieTimeUI()` | â€” | Close UI |

### C_AlliedRaces â€” Allied Races

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AlliedRaces.GetAllRacialAbilitiesForRace(raceID)` | `abilities` | Race abilities |
| `C_AlliedRaces.GetRaceInfoByID(raceID)` | `raceInfo` | Race info |
| `C_AlliedRaces.ClearAlliedRaceDetailsGiver()` | â€” | Clear details |
| `C_AlliedRaces.GetAlliedRaceInfo(raceID)` | `info` | Allied race details |

### C_WarbandSceneInfo â€” Warband Scenes

| Function | Returns | Description |
|----------|---------|-------------|
| `C_WarbandSceneInfo.GetWarbandSceneInfo()` | `sceneInfo` | Warband scene data |
| `C_WarbandSceneInfo.GetCharacterEntries()` | `entries` | Character positions |
| `C_WarbandSceneInfo.SetCharacterEntry(index, characterInfo)` | â€” | Set character slot |
| `C_WarbandSceneInfo.GetAvailableCharacters()` | `characters` | Available characters |
| `C_WarbandSceneInfo.SaveScene()` | â€” | Save warband scene |

### C_PerksActivities â€” Monthly Activities

| Function | Returns | Description |
|----------|---------|-------------|
| `C_PerksActivities.GetPerksActivitiesInfo()` | `info` | Activities overview |
| `C_PerksActivities.GetTrackedPerksActivities()` | `activities` | Tracked activities |
| `C_PerksActivities.AddTrackedPerksActivity(activityID)` | â€” | Track activity |
| `C_PerksActivities.RemoveTrackedPerksActivity(activityID)` | â€” | Untrack |
| `C_PerksActivities.GetPerksActivityInfo(activityID)` | `activityInfo` | Activity details |
| `C_PerksActivities.GetAllPerksActivityTags()` | `tags` | All tags/categories |

---

## Utility Systems

### C_Localization / Locale

| Function | Returns | Description |
|----------|---------|-------------|
| `GetLocale()` | `locale` | Game locale (e.g., "enUS") |
| `GetCurrentRegion()` | `regionID` | Current region |
| `GetCurrentRegionName()` | `regionName` | Region name |

### Log

| Function | Returns | Description |
|----------|---------|-------------|
| `LoggingCombat(enable)` | â€” | Toggle combat log file |
| `LoggingChat(enable)` | â€” | Toggle chat log file |
| `IsLoggingCombat()` | `isLogging` | Combat logging? |
| `IsLoggingChat()` | `isLogging` | Chat logging? |

### C_EventUtils

| Function | Returns | Description |
|----------|---------|-------------|
| `C_EventUtils.IsEventValid(event)` | `isValid` | Is event string valid? |

---

## Legacy Systems (Deprecated/Maintained)

These systems originated in earlier expansions. APIs may still function but the content is legacy.

### GarrisonInfo (WoD/Legion)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Garrison.GetFollowerInfo(followerID)` | `followerInfo` | Follower data |
| `C_Garrison.GetFollowers(followerType)` | `followers` | Follower list |
| `C_Garrison.GetLandingPageInfo(garrType)` | `info` | Landing page |
| `C_Garrison.GetBuildings(garrType)` | `buildings` | Building list |
| `C_Garrison.GetMissions(garrType)` | `missions` | Available missions |
| `C_Garrison.IsOnGarrisonMap()` | `onMap` | In garrison? |

### Covenant / Soulbinds (Shadowlands)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Covenants.GetActiveCovenantID()` | `covenantID` | Active covenant |
| `C_Covenants.GetCovenantData(covenantID)` | `covenantData` | Covenant info |
| `C_Soulbinds.GetActiveSoulbindID()` | `soulbindID` | Active soulbind |
| `C_Soulbinds.GetSoulbindData(soulbindID)` | `soulbindData` | Soulbind info |
| `C_Soulbinds.GetConduitItemLevel(conduitID, conduitRank)` | `itemLevel` | Conduit ilvl |

### AzeriteItem (Battle for Azeroth)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AzeriteItem.IsAzeriteItem(itemLocation)` | `isAzerite` | Is Azerite item? |
| `C_AzeriteItem.GetPowerLevel(azeriteItemLocation)` | `powerLevel` | Necklace level |
| `C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)` | `xp, totalLevelXP` | XP info |
| `C_AzeriteEmpoweredItem.GetPowerInfo(powerID)` | `powerInfo` | Trait info |
| `C_AzeriteEmpoweredItem.SelectPower(azeriteItemLocation, powerID)` | â€” | Select trait |

### ResearchInfo (Archaeology â€” Removed)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ResearchInfo.GetDigSitesForMap(uiMapID)` | `digSites` | Dig sites (legacy) |

> **Note:** Archaeology as a profession was removed, but some API remnants persist.

### ContributionCollector (Legion)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ContributionCollector.GetState(contributionID)` | `state` | Contribution state |
| `C_ContributionCollector.GetName(contributionID)` | `name` | Contribution name |
| `C_ContributionCollector.Contribute(contributionID)` | â€” | Contribute |

---

## Common Patterns

### Handle NPC Gossip

```lua
local f = CreateFrame("Frame")
f:RegisterEvent("GOSSIP_SHOW")
f:SetScript("OnEvent", function()
    local options = C_GossipInfo.GetOptions()
    for i, option in ipairs(options) do
        print(i, option.name, option.gossipOptionID)
    end
    
    -- Auto-select if only one option
    if #options == 1 and options[1].selectOptionWhenOnlyOption then
        C_GossipInfo.SelectOption(options[1].gossipOptionID)
    end
end)
```

### Display Player Choice

```lua
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_CHOICE_UPDATE")
f:SetScript("OnEvent", function()
    local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
    if choiceInfo then
        print("Choice:", choiceInfo.questionText)
        for i = 1, C_PlayerChoice.GetNumPlayerChoices() do
            local option = C_PlayerChoice.GetPlayerChoiceOptionInfo(i)
            if option then
                print("  Option", i, ":", option.header, "-", option.description)
            end
        end
    end
end)
```

### Get Tooltip Data Programmatically

```lua
-- Get item tooltip text without showing tooltip
local tooltipData = C_TooltipInfo.GetItemByID(12345)
if tooltipData then
    TooltipUtil.SurfaceArgs(tooltipData)
    for _, line in ipairs(tooltipData.lines) do
        TooltipUtil.SurfaceArgs(line)
        print(line.leftText)
    end
end
```

### Check Chromie Time Status

```lua
local function ShowChromieTimeOptions()
    local options = C_ChromieTimeInfo.GetChromieTimeExpansionOptions()
    if options then
        for _, option in ipairs(options) do
            print(option.name, option.description, 
                  option.isCurrent and "(ACTIVE)" or "")
        end
    end
end
```

### Register Slash Commands

```lua
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"
SlashCmdList["MYADDON"] = function(msg)
    local cmd, args = msg:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or msg:lower()
    
    if cmd == "config" then
        -- Open config
    elseif cmd == "help" then
        print("/myaddon config - Open settings")
        print("/myaddon help - Show help")
    else
        print("Unknown command. Use /myaddon help")
    end
end
```

---

## Key Events

| Event | Payload | Description |
|-------|---------|-------------|
| `GOSSIP_SHOW` | uiTextureKit | NPC gossip opened |
| `GOSSIP_CLOSED` | â€” | Gossip window closed |
| `GOSSIP_CONFIRM` | gossipID, text, cost | Gossip confirmation |
| `PLAYER_CHOICE_UPDATE` | â€” | Player choice available |
| `PLAYER_CHOICE_CLOSE` | â€” | Choice closed |
| `PLAYER_INTERACTION_MANAGER_FRAME_SHOW` | type | Interaction opened |
| `PLAYER_INTERACTION_MANAGER_FRAME_HIDE` | type | Interaction closed |
| `CINEMATIC_START` | canBeCancelled | Cinematic starting |
| `CINEMATIC_STOP` | â€” | Cinematic ended |
| `PLAY_MOVIE` | movieID | Movie playing |
| `STOP_MOVIE` | â€” | Movie stopped |
| `SPLASH_SCREEN_SHOW` | â€” | Show splash screen |
| `SPLASH_SCREEN_HIDE` | â€” | Hide splash screen |
| `TUTORIAL_TRIGGER` | tutorialID | Tutorial triggered |
| `MIRROR_TIMER_START` | timer, value, maxValue, scale, paused, label | Timer started |
| `MIRROR_TIMER_STOP` | timer | Timer stopped |
| `MIRROR_TIMER_PAUSE` | timer, paused | Timer paused |
| `CHROMIE_TIME_OPEN` | â€” | Chromie Time UI opened |
| `CHROMIE_TIME_CLOSE` | â€” | Chromie Time UI closed |
| `GARRISON_UPDATE` | â€” | Garrison data updated |
| `PERKS_ACTIVITIES_TRACKED_UPDATED` | â€” | Activity tracking changed |

---

## Gotchas & Restrictions

1. **Gossip auto-select** â€” `selectOptionWhenOnlyOption` flag means the game may auto-select; don't assume GOSSIP_SHOW always waits for input.
2. **PlayerInteractionManager types** â€” Use `Enum.PlayerInteractionType` for type-safe checks; don't hardcode integers.
3. **Tooltip data API (12.0.0)** â€” Use `C_TooltipInfo` for programmatic tooltip access rather than scraping GameTooltip text lines.
4. **Legacy API availability** â€” Garrison, Covenant, and Azerite APIs still exist but content is no longer current. Some may be removed in future patches.
5. **Cinematic blocking** â€” Some cinematics block all addon UI; plan for `CINEMATIC_START` / `CINEMATIC_STOP`.
6. **Player choices are timed** â€” Some choices have countdowns. Check `GetRemainingTime()`.
7. **SlashCmdList keys** â€” Command names in SlashCmdList must be UPPERCASE. The slash aliases (SLASH_NAME1) are case-insensitive for matching.
8. **Chromie Time level cap** â€” Chromie Time is only available to characters below the expansion's level range.
9. **Gossip POI** â€” `GetPoiForUiMapID()` returns quest giver locations on the map, useful for minimap tracking.
10. **Report system** â€” Reports require valid player locations; use `C_ReportSystem.CanReportPlayer()` first.
