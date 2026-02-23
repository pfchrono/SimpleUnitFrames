---
name: wow-api-map-navigation
description: "Complete reference for WoW Retail Map, Navigation, Area POI, Taxi, Vignette, Minimap, Nameplate, Waypoint, Zone Ability, Fog of War, and Exploration APIs. Covers C_Map (50+ functions for map data, coordinates, map IDs, area info), C_MapExplorationInfo, C_AreaPoiInfo, C_TaxiMap (flight paths), C_Vignette, C_SuperTrackManager, C_Navigation (in-game navigation), C_ZoneAbility, C_FogOfWar, Minimap functions, C_NamePlateManager, and coordinate conversion. Use when working with maps, coordinates, waypoints, flight paths, minimap, nameplates, vignettes, exploration, zone abilities, or in-game navigation."
---

# Map & Navigation API (Retail â€” Patch 12.0.0)

Comprehensive reference for all map, navigation, and location APIs in WoW Retail.

> **Source:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
> **Current as of:** Patch 12.0.0 (Build 65655) â€” January 28, 2026
> **Scope:** Retail only.

---

## Scope

- **C_Map** â€” Map data, coordinates, map IDs, areas
- **C_MapExplorationInfo** â€” Fog of war / exploration data
- **C_AreaPoiInfo** â€” Area Points of Interest
- **C_TaxiMap** â€” Flight master/taxi routes
- **C_Vignette** â€” Vignettes (rare mobs, treasures)
- **C_SuperTrackManager** â€” Super tracking (waypoint tracking)
- **C_Navigation** â€” In-game navigation system
- **C_ZoneAbility** â€” Zone-specific abilities
- **C_FogOfWar** â€” Fog of war system
- **Minimap** â€” Minimap functions
- **C_NamePlateManager** â€” Nameplate management

---

## C_Map â€” Core Map System

### Map Info & IDs

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Map.GetBestMapForUnit(unitToken)` | `uiMapID` | Best map for unit's location |
| `C_Map.GetMapInfo(uiMapID)` | `mapInfo` | Map name, type, parent |
| `C_Map.GetMapInfoAtPosition(uiMapID, x, y)` | `mapInfo` | Map info at coordinate |
| `C_Map.GetMapChildrenInfo(uiMapID [, mapType [, allDescendants]])` | `childrenInfo` | Child maps |
| `C_Map.GetMapGroupID(uiMapID)` | `mapGroupID` | Map group (floor group) |
| `C_Map.GetMapGroupMembersInfo(mapGroupID)` | `membersInfo` | Maps in group (floors) |
| `C_Map.GetMapLinksForMap(uiMapID)` | `mapLinks` | Map links (transitions) |
| `C_Map.GetMapRectOnMap(uiMapID, parentMapID)` | `minX, maxX, minY, maxY` | Map rect on parent |
| `C_Map.GetPlayerMapPosition(uiMapID, unitToken)` | `position` | Player position on map |
| `C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition)` | `continentID, worldPosition` | Map â†’ world coords |
| `C_Map.GetMapPosFromWorldPos(continentID, worldPosition [, overrideUiMapID])` | `uiMapID, mapPosition` | World â†’ map coords |
| `C_Map.GetFallbackWorldMapID()` | `uiMapID` | Default world map |
| `C_Map.GetBountySetMaps(bountySetID)` | `mapIDs` | Maps for bounty set |
| `C_Map.GetAreaInfo(areaID)` | `areaName` | Area name by ID |
| `C_Map.GetMapArtID(uiMapID)` | `mapArtID` | Art asset ID |
| `C_Map.GetMapArtBackgroundAtlas(uiMapID)` | `atlasName` | Background atlas |
| `C_Map.GetMapArtHelpTextPosition(uiMapID)` | `position` | Help text position |
| `C_Map.GetMapArtLayerTextures(uiMapID, layerIndex)` | `textures` | Layer texture files |
| `C_Map.GetNumMapArtLayers(uiMapID)` | `numLayers` | Number of art layers |
| `C_Map.GetMapArtLayers(uiMapID)` | `layers` | All art layer info |
| `C_Map.GetMapDisplayInfo(uiMapID)` | `hideIcons` | Display flags |
| `C_Map.GetMapHighlightInfoAtPosition(uiMapID, x, y)` | `fileDataID, atlasID, texturePercentageX, texturePercentageY, textureX, textureY, scrollChildX, scrollChildY` | Highlight at position |
| `C_Map.HasArt(uiMapID)` | `hasArt` | Has map art? |
| `C_Map.IsMapValidForNavBarDropdown(uiMapID)` | `isValid` | Valid for navbar? |
| `C_Map.MapHasArt(uiMapID)` | `hasArt` | Alias for HasArt |
| `C_Map.RequestPreloadMap(uiMapID)` | â€” | Preload map data |
| `C_Map.SetUserWaypoint(uiMapID, position)` | â€” | Set user waypoint |
| `C_Map.GetUserWaypoint()` | `point` | Get user waypoint |
| `C_Map.HasUserWaypoint()` | `hasWaypoint` | Has user waypoint? |
| `C_Map.ClearUserWaypoint()` | â€” | Clear user waypoint |
| `C_Map.CanSetUserWaypointOnMap(uiMapID)` | `canSet` | Can set waypoint? |
| `C_Map.GetUserWaypointHyperlink()` | `hyperlink` | Waypoint hyperlink |
| `C_Map.GetUserWaypointFromHyperlink(hyperlink)` | `point` | Parse waypoint link |
| `C_Map.GetUserWaypointPositionForMap(uiMapID)` | `mapPosition` | Waypoint on map |

### Map Types (Enum.UIMapType)

| Value | Type | Description |
|-------|------|-------------|
| 0 | Cosmic | All continents |
| 1 | World | Shows continents |
| 2 | Continent | Single continent |
| 3 | Zone | Zone (e.g., Durotar) |
| 4 | Dungeon | Dungeon floors |
| 5 | Micro | Subzone |
| 6 | Orphan | Standalone map |

---

## C_MapExplorationInfo â€” Exploration

| Function | Returns | Description |
|----------|---------|-------------|
| `C_MapExplorationInfo.GetExploredMapTextures(uiMapID)` | `textures` | Explored area textures |
| `C_MapExplorationInfo.GetExploredAreaIDsAtPosition(uiMapID, position)` | `areaIDs` | Explored area IDs at pos |

---

## C_AreaPoiInfo â€” Area Points of Interest

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AreaPoiInfo.GetAreaPOIForMap(uiMapID)` | `poiIDs` | All POIs on map |
| `C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, poiID)` | `poiInfo` | POI details |
| `C_AreaPoiInfo.GetAreaPOISecondsLeft(poiID)` | `secondsLeft` | Time-limited POI timer |
| `C_AreaPoiInfo.GetAreaPOITimeOfDay()` | `hours, minutes` | POI time context |
| `C_AreaPoiInfo.IsAreaPOITimed(poiID)` | `isTimed` | Is POI time-limited? |

### POI Info Fields

- `areaPoiID` â€” Unique POI ID
- `position` â€” `{x, y}` on map
- `name` â€” Display name
- `description` â€” Description text
- `textureIndex` â€” POI icon index
- `atlasName` â€” Atlas for icon
- `uiTextureKit` â€” Texture kit
- `tooltipWidgetSet` â€” Tooltip widget set
- `iconWidgetSet` â€” Icon widget set
- `availableInPlayerChoice` â€” Available in player choice

---

## C_TaxiMap â€” Flight Paths / Taxi

| Function | Returns | Description |
|----------|---------|-------------|
| `C_TaxiMap.GetAllTaxiNodes(uiMapID)` | `nodes` | All flight nodes on map |
| `C_TaxiMap.GetTaxiNodesForMap(uiMapID)` | `nodes` | Available taxi nodes |
| `C_TaxiMap.ShouldMapShowTaxiNodes(uiMapID)` | `shouldShow` | Show taxi nodes on map? |
| `NumTaxiNodes()` | `numNodes` | Available nodes at taxi NPC |
| `TaxiNodeName(index)` | `name` | Node name |
| `TaxiNodePosition(index)` | `x, y` | Node position |
| `TaxiNodeGetType(index)` | `nodeType` | REACHABLE, UNREACHABLE, CURRENT |
| `TaxiGetDestX(index, i)` | `x` | Route destination X |
| `TaxiGetDestY(index, i)` | `y` | Route destination Y |
| `TaxiGetSrcX(index, i)` | `x` | Route source X |
| `TaxiGetSrcY(index, i)` | `y` | Route source Y |
| `GetNumRoutes(index)` | `numRoutes` | Route segments count |
| `TakeTaxiNode(index)` | â€” | Take flight to node |
| `CloseTaxiMap()` | â€” | Close taxi map |
| `TaxiRequestEarlyLanding()` | â€” | Request early landing |
| `UnitOnTaxi(unit)` | `onTaxi` | Is unit on a taxi? |

---

## C_Vignette â€” Vignettes (Rare Mobs, Treasures, Events)

| Function | Returns | Description |
|----------|---------|-------------|
| `C_VignetteInfo.GetVignetteInfo(vignetteGUID)` | `info` | Vignette details |
| `C_VignetteInfo.GetVignettes()` | `vignetteGUIDs` | All active vignettes |
| `C_VignetteInfo.GetVignettePosition(vignetteGUID, uiMapID)` | `position` | Vignette position on map |
| `C_VignetteInfo.FindBestUniqueVignette(vignetteID)` | `bestGUID` | Best unique vignette |

### Vignette Info Fields

- `vignetteGUID` â€” Unique identifier
- `objectGUID` â€” Object GUID (unit, object, etc.)
- `name` â€” Display name
- `atlasName` â€” Icon atlas
- `type` â€” Vignette type (Normal, PvPBounty, Torghast, etc.)
- `isDead` â€” Is the linked unit dead?
- `onWorldMap` â€” Shows on world map?
- `onMinimap` â€” Shows on minimap?
- `hasTooltip` â€” Has mouseover tooltip?
- `inFogOfWar` â€” In unexplored area?
- `widgetSetID` â€” UI widget set

---

## C_SuperTrackManager â€” Waypoint Super Tracking

| Function | Returns | Description |
|----------|---------|-------------|
| `C_SuperTrack.GetSuperTrackedContent()` | `trackableType, trackableID` | Currently tracked content |
| `C_SuperTrack.GetSuperTrackedMapPin()` | `type, typeID` | Tracked map pin |
| `C_SuperTrack.GetSuperTrackedQuestID()` | `questID` | Super tracked quest |
| `C_SuperTrack.SetSuperTrackedContent(trackableType, trackableID)` | â€” | Set tracked content |
| `C_SuperTrack.SetSuperTrackedMapPin(type, typeID)` | â€” | Set tracked map pin |
| `C_SuperTrack.SetSuperTrackedQuestID(questID)` | â€” | Track quest |
| `C_SuperTrack.SetSuperTrackedUserWaypoint(superTracked)` | â€” | Track user waypoint |
| `C_SuperTrack.IsSuperTrackingAnything()` | `isTracking` | Is tracking anything? |
| `C_SuperTrack.IsSuperTrackingCorpse()` | `isTrackingCorpse` | Tracking corpse? |
| `C_SuperTrack.IsSuperTrackingQuest()` | `isTracking` | Tracking a quest? |
| `C_SuperTrack.IsSuperTrackingUserWaypoint()` | `isTracking` | Tracking user waypoint? |
| `C_SuperTrack.ClearAllSuperTracked()` | â€” | Clear all tracking |

---

## C_Navigation â€” In-Game Navigation

| Function | Returns | Description |
|----------|---------|-------------|
| `C_Navigation.GetDistance()` | `distance` | Distance to tracked target |
| `C_Navigation.GetFrame()` | `frame` | Navigation frame |
| `C_Navigation.HasValidScreenPosition()` | `hasValidPos` | Is nav arrow valid? |
| `C_Navigation.WasClampedToScreen()` | `wasClamped` | Was arrow clamped? |

---

## C_ZoneAbility

| Function | Returns | Description |
|----------|---------|-------------|
| `C_ZoneAbility.GetActiveAbilities()` | `abilities` | Active zone abilities |

---

## C_FogOfWar

| Function | Returns | Description |
|----------|---------|-------------|
| `C_FogOfWar.GetFogOfWarForMap(uiMapID)` | `fogOfWarID` | Fog of war ID for map |
| `C_FogOfWar.GetFogOfWarInfo(fogOfWarID)` | `info` | Fog of war info |

---

## Minimap Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `GetMinimapZoneText()` | `zoneText` | Minimap zone text |
| `GetZoneText()` | `zoneText` | Current zone name |
| `GetSubZoneText()` | `subZoneText` | Current subzone |
| `GetRealZoneText()` | `zoneText` | Real zone text |
| `GetMinimapShape()` | `shape` | ROUND or SQUARE |
| `Minimap:SetZoom(zoomLevel)` | â€” | Set minimap zoom |
| `Minimap:GetZoom()` | `zoomLevel` | Get minimap zoom |
| `Minimap:GetZoomLevels()` | `numLevels` | Max zoom levels |
| `ToggleMinimap()` | â€” | Toggle minimap visibility |

---

## C_NamePlateManager / Nameplates

| Function | Returns | Description |
|----------|---------|-------------|
| `C_NamePlate.GetNamePlates([includeForbidden])` | `nameplates` | All activated nameplates |
| `C_NamePlate.GetNamePlateForUnit(unitToken [, includeForbidden])` | `nameplate` | Nameplate for unit |
| `C_NamePlate.GetNumNamePlates()` | `numActive` | Active nameplates count |
| `C_NamePlate.SetNamePlateFriendlySize(width, height)` | â€” | Set friendly plate size |
| `C_NamePlate.SetNamePlateEnemySize(width, height)` | â€” | Set enemy plate size |
| `C_NamePlate.SetNamePlateSelfSize(width, height)` | â€” | Set personal plate size |
| `C_NamePlate.SetNamePlateFriendlyClickThrough(clickThrough)` | â€” | Click through friendly |
| `C_NamePlate.SetNamePlateEnemyClickThrough(clickThrough)` | â€” | Click through enemy |
| `C_NamePlate.SetNamePlateSelfClickThrough(clickThrough)` | â€” | Click through personal |

> **12.0.0 Note:** Nameplates in instances are tightly restricted. Enemy nameplate unit tokens may expose only secret values for health, casting, etc.

---

## Coordinate Conversion

### Map Position Object

`C_Map.GetPlayerMapPosition()` returns a `Vector2DMixin` with:

```lua
local pos = C_Map.GetPlayerMapPosition(mapID, "player")
if pos then
    local x, y = pos:GetXY()
    -- x, y are 0-1 normalized coordinates on the map
    print(string.format("%.2f, %.2f", x * 100, y * 100))
end
```

### Convert Between Maps

```lua
-- Get player position on the current best map
local mapID = C_Map.GetBestMapForUnit("player")
if mapID then
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        -- Convert to world coordinates
        local continentID, worldPos = C_Map.GetWorldPosFromMapPos(mapID, pos)
        -- Convert back to a different map
        local otherMapID, otherPos = C_Map.GetMapPosFromWorldPos(continentID, worldPos)
    end
end
```

### User Waypoint

```lua
-- Set a waypoint on the map
local mapID = C_Map.GetBestMapForUnit("player")
if C_Map.CanSetUserWaypointOnMap(mapID) then
    local point = UiMapPoint.CreateFromCoordinates(mapID, 0.5, 0.5)
    C_Map.SetUserWaypoint(point)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
end
```

---

## Key Events

| Event | Payload | Description |
|-------|---------|-------------|
| `ZONE_CHANGED` | â€” | Subzone changed |
| `ZONE_CHANGED_INDOORS` | â€” | Indoor zone changed |
| `ZONE_CHANGED_NEW_AREA` | â€” | Major zone change |
| `NEW_WMO_CHUNK` | â€” | New world map object |
| `MAP_EXPLORATION_UPDATED` | â€” | Exploration updated |
| `WORLD_MAP_UPDATE` | â€” | World map data changed |
| `USER_WAYPOINT_UPDATED` | â€” | User waypoint changed |
| `SUPER_TRACKING_CHANGED` | â€” | Super tracking changed |
| `VIGNETTE_MINIMAP_UPDATED` | vignetteGUID, onMinimap | Vignette on minimap changed |
| `VIGNETTES_UPDATED` | â€” | Vignettes updated |
| `AREA_POIS_UPDATED` | â€” | Area POIs changed |
| `NAME_PLATE_CREATED` | namePlateFrame | Nameplate created |
| `NAME_PLATE_UNIT_ADDED` | unitToken | Unit added to nameplate |
| `NAME_PLATE_UNIT_REMOVED` | unitToken | Unit removed from nameplate |
| `PLAYER_STARTED_MOVING` | â€” | Player started moving |
| `PLAYER_STOPPED_MOVING` | â€” | Player stopped moving |
| `TAXIMAP_OPENED` | systemID | Taxi map opened |
| `TAXIMAP_CLOSED` | â€” | Taxi map closed |
| `NAVIGATION_FRAME_CREATED` | â€” | Nav frame created |
| `NAVIGATION_FRAME_DESTROYED` | â€” | Nav frame destroyed |

---

## Gotchas & Restrictions

1. **GetPlayerMapPosition returns nil** â€” Returns nil for units in instances where position tracking is restricted or for invalid map IDs.
2. **Map coordinates are 0-1 normalized** â€” Not world coordinates. Use `GetWorldPosFromMapPos()` to convert.
3. **uiMapID vs areaID** â€” These are different ID systems. `C_Map.GetAreaInfo()` takes areaID, not uiMapID.
4. **Nameplate secrets in 12.0.0** â€” In instances, enemy nameplate unit data (health, casting, name) may be secret values.
5. **TakeTaxiNode hardware event** â€” Requires a hardware event to execute (must be called from a click handler).
6. **Vignette GUIDs are transient** â€” Vignette GUIDs change when you zone or reload. Don't persist them.
7. **Map group = floors** â€” Dungeon maps with multiple floors use map groups. Each floor is a separate uiMapID in the group.
8. **Waypoint limit** â€” Only one user waypoint can exist at a time. Setting a new one replaces the old.
