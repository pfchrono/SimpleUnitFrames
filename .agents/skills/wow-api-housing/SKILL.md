---
name: wow-api-housing
description: "Complete reference for WoW Retail Player Housing APIs (new in Patch 12.0.0). Covers HousingUI (core housing system), C_HouseEditorUI (placement/editing modes), C_HousingCatalog (decoration catalog), HousingBasicModeUI, HousingCleanupModeUI, HousingCustomizeModeUI, HousingDecorUI, HousingExpertModeUI, C_HouseExteriorUI (exterior customization), HousingLayoutUI, C_HousingNeighborhood (neighborhoods/visiting), C_NeighborhoodInitiative (community goals), and CatalogShop. Use when working with player housing placement, decoration, editing modes, neighborhoods, housing catalogs, exterior customization, or neighborhood initiatives."
---

# Housing API (Retail â€” Patch 12.0.0)

Comprehensive reference for the player housing system, brand new in Patch 12.0.0.

> **Source:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
> **Current as of:** Patch 12.0.0 (Build 65655) â€” January 28, 2026
> **Scope:** Retail only. This entire system is new in 12.0.0.

---

## Scope

- **HousingUI** â€” Core housing system frame and state
- **C_HouseEditorUI** â€” Placement and editing (position, rotate, scale)
- **C_HousingCatalog** â€” Decoration catalog browsing
- **HousingBasicModeUI** â€” Simplified placement mode
- **HousingCleanupModeUI** â€” Bulk cleanup/removal mode
- **HousingCustomizeModeUI** â€” Customization mode
- **HousingDecorUI** â€” Decoration management
- **HousingExpertModeUI** â€” Advanced/expert placement
- **C_HouseExteriorUI** â€” Exterior appearance customization
- **HousingLayoutUI** â€” Layout save/load
- **C_HousingNeighborhood** â€” Neighborhoods and visiting
- **C_NeighborhoodInitiative** â€” Community initiative goals
- **CatalogShop** â€” Housing shop/catalog purchase system

---

## HousingUI â€” Core Housing System

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingUI.IsHousingModeActive()` | `isActive` | Is housing editing active? |
| `HousingUI.EnterHousingMode()` | â€” | Enter housing edit mode |
| `HousingUI.ExitHousingMode()` | â€” | Exit housing edit mode |
| `HousingUI.GetCurrentHouseInfo()` | `houseInfo` | Current house data |
| `HousingUI.GetHouseOwner()` | `ownerInfo` | House owner info |
| `HousingUI.IsPlayerInOwnHouse()` | `isOwn` | In own house? |
| `HousingUI.IsPlayerInHouse()` | `inHouse` | In any house? |
| `HousingUI.GetHousingPlotInfo()` | `plotInfo` | Plot/lot info |

---

## C_HouseEditorUI â€” Placement & Editing

The editor is the core system for placing, moving, rotating, and scaling decorations.

### Object Selection & Manipulation

| Function | Returns | Description |
|----------|---------|-------------|
| `C_HouseEditorUI.SelectObject(objectID)` | â€” | Select decoration |
| `C_HouseEditorUI.DeselectObject()` | â€” | Deselect current |
| `C_HouseEditorUI.GetSelectedObject()` | `objectInfo` | Current selection |
| `C_HouseEditorUI.DeleteSelectedObject()` | â€” | Delete selection |
| `C_HouseEditorUI.MoveObject(objectID, x, y, z)` | â€” | Move decoration |
| `C_HouseEditorUI.RotateObject(objectID, yaw, pitch, roll)` | â€” | Rotate decoration |
| `C_HouseEditorUI.ScaleObject(objectID, scale)` | â€” | Scale decoration |
| `C_HouseEditorUI.GetObjectPosition(objectID)` | `x, y, z` | Object position |
| `C_HouseEditorUI.GetObjectRotation(objectID)` | `yaw, pitch, roll` | Object rotation |
| `C_HouseEditorUI.GetObjectScale(objectID)` | `scale` | Object scale |

### Placement

| Function | Returns | Description |
|----------|---------|-------------|
| `C_HouseEditorUI.PlaceObject(catalogItemID)` | â€” | Start placing item |
| `C_HouseEditorUI.ConfirmPlacement()` | â€” | Confirm current placement |
| `C_HouseEditorUI.CancelPlacement()` | â€” | Cancel placement |
| `C_HouseEditorUI.IsPlacing()` | `isPlacing` | In placement mode? |
| `C_HouseEditorUI.GetPlacedObjects()` | `objects` | All placed objects |
| `C_HouseEditorUI.GetPlacementLimits()` | `current, max` | Decoration limits |

### Undo/Redo

| Function | Returns | Description |
|----------|---------|-------------|
| `C_HouseEditorUI.Undo()` | â€” | Undo last action |
| `C_HouseEditorUI.Redo()` | â€” | Redo last undo |
| `C_HouseEditorUI.CanUndo()` | `canUndo` | Has undo? |
| `C_HouseEditorUI.CanRedo()` | `canRedo` | Has redo? |

---

## C_HousingCatalog â€” Decoration Catalog

| Function | Returns | Description |
|----------|---------|-------------|
| `C_HousingCatalog.GetCategories()` | `categories` | All categories |
| `C_HousingCatalog.GetCategoryInfo(categoryID)` | `categoryInfo` | Category details |
| `C_HousingCatalog.GetItemsInCategory(categoryID)` | `items` | Items in category |
| `C_HousingCatalog.GetItemInfo(catalogItemID)` | `itemInfo` | Catalog item info |
| `C_HousingCatalog.GetOwnedItems()` | `ownedItems` | Player's owned items |
| `C_HousingCatalog.IsItemOwned(catalogItemID)` | `isOwned` | Player owns item? |
| `C_HousingCatalog.GetItemCount(catalogItemID)` | `count` | How many owned |
| `C_HousingCatalog.SearchCatalog(searchText)` | `results` | Search items |
| `C_HousingCatalog.GetFilteredItems(filters)` | `items` | Filter items |

---

## HousingBasicModeUI â€” Simplified Mode

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingBasicModeUI.EnterBasicMode()` | â€” | Enter basic edit mode |
| `HousingBasicModeUI.ExitBasicMode()` | â€” | Exit basic mode |
| `HousingBasicModeUI.IsInBasicMode()` | `isBasic` | In basic mode? |

---

## HousingCleanupModeUI â€” Cleanup Mode

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingCleanupModeUI.EnterCleanupMode()` | â€” | Enter cleanup mode |
| `HousingCleanupModeUI.ExitCleanupMode()` | â€” | Exit cleanup mode |
| `HousingCleanupModeUI.SelectForCleanup(objectID)` | â€” | Tag for cleanup |
| `HousingCleanupModeUI.ConfirmCleanup()` | â€” | Execute cleanup |
| `HousingCleanupModeUI.GetCleanupCount()` | `count` | Items tagged |

---

## HousingCustomizeModeUI â€” Customization

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingCustomizeModeUI.EnterCustomizeMode()` | â€” | Enter customize mode |
| `HousingCustomizeModeUI.ExitCustomizeMode()` | â€” | Exit customize mode |
| `HousingCustomizeModeUI.GetCustomizationOptions(objectID)` | `options` | Object options |
| `HousingCustomizeModeUI.ApplyCustomization(objectID, optionID)` | â€” | Apply option |

---

## HousingDecorUI â€” Decoration Management

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingDecorUI.GetDecorInventory()` | `inventory` | Stored decorations |
| `HousingDecorUI.GetDecorInfo(decorID)` | `decorInfo` | Decoration details |
| `HousingDecorUI.StoreDecoration(objectID)` | â€” | Store placed item |
| `HousingDecorUI.GetDecorCategories()` | `categories` | Inventory categories |

---

## HousingExpertModeUI â€” Expert Placement

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingExpertModeUI.EnterExpertMode()` | â€” | Enter expert mode |
| `HousingExpertModeUI.ExitExpertMode()` | â€” | Exit expert mode |
| `HousingExpertModeUI.IsInExpertMode()` | `isExpert` | In expert mode? |
| `HousingExpertModeUI.SetSnapping(enabled)` | â€” | Toggle grid snap |
| `HousingExpertModeUI.GetSnapping()` | `enabled` | Snap enabled? |
| `HousingExpertModeUI.SetPrecisionMode(enabled)` | â€” | Toggle precision |
| `HousingExpertModeUI.GetPrecisionMode()` | `enabled` | Precision on? |

---

## C_HouseExteriorUI â€” Exterior Customization

| Function | Returns | Description |
|----------|---------|-------------|
| `C_HouseExteriorUI.GetExteriorOptions()` | `options` | Available exteriors |
| `C_HouseExteriorUI.GetCurrentExterior()` | `exteriorInfo` | Current exterior |
| `C_HouseExteriorUI.SetExterior(exteriorID)` | â€” | Change exterior |
| `C_HouseExteriorUI.PreviewExterior(exteriorID)` | â€” | Preview exterior |
| `C_HouseExteriorUI.GetExteriorCategories()` | `categories` | Exterior categories |

---

## HousingLayoutUI â€” Layout Save/Load

| Function | Returns | Description |
|----------|---------|-------------|
| `HousingLayoutUI.GetSavedLayouts()` | `layouts` | Saved layouts |
| `HousingLayoutUI.SaveLayout(name)` | â€” | Save current layout |
| `HousingLayoutUI.LoadLayout(layoutID)` | â€” | Load layout |
| `HousingLayoutUI.DeleteLayout(layoutID)` | â€” | Delete layout |
| `HousingLayoutUI.RenameLayout(layoutID, name)` | â€” | Rename layout |
| `HousingLayoutUI.GetLayoutInfo(layoutID)` | `layoutInfo` | Layout details |

---

## C_HousingNeighborhood â€” Neighborhoods

| Function | Returns | Description |
|----------|---------|-------------|
| `C_HousingNeighborhood.GetNeighborhoodInfo()` | `neighborhoodInfo` | Current neighborhood |
| `C_HousingNeighborhood.GetNeighbors()` | `neighbors` | Neighbor list |
| `C_HousingNeighborhood.GetNeighborInfo(neighborID)` | `neighborInfo` | Neighbor details |
| `C_HousingNeighborhood.VisitNeighbor(neighborID)` | â€” | Visit a neighbor |
| `C_HousingNeighborhood.GetVisitableHouses()` | `houses` | Visitable houses |
| `C_HousingNeighborhood.InviteToNeighborhood(playerName)` | â€” | Invite player |
| `C_HousingNeighborhood.LeaveNeighborhood()` | â€” | Leave neighborhood |
| `C_HousingNeighborhood.GetNeighborhoodMembers()` | `members` | All members |

---

## C_NeighborhoodInitiative â€” Community Goals

| Function | Returns | Description |
|----------|---------|-------------|
| `C_NeighborhoodInitiative.GetCurrentInitiative()` | `initiativeInfo` | Active initiative |
| `C_NeighborhoodInitiative.GetInitiativeProgress()` | `progress` | Current progress |
| `C_NeighborhoodInitiative.GetInitiativeRewards()` | `rewards` | Initiative rewards |
| `C_NeighborhoodInitiative.GetPlayerContribution()` | `contribution` | Player's contribution |
| `C_NeighborhoodInitiative.GetInitiativeHistory()` | `history` | Past initiatives |

---

## CatalogShop â€” Housing Store

| Function | Returns | Description |
|----------|---------|-------------|
| `CatalogShop.GetShopCategories()` | `categories` | Shop categories |
| `CatalogShop.GetShopItems(categoryID)` | `items` | Items for sale |
| `CatalogShop.GetShopItemInfo(shopItemID)` | `itemInfo` | Item details |
| `CatalogShop.PurchaseItem(shopItemID)` | â€” | Purchase item |
| `CatalogShop.CanPurchase(shopItemID)` | `canBuy, reason` | Can purchase? |
| `CatalogShop.GetBundleInfo(bundleID)` | `bundleInfo` | Bundle details |

---

## Common Patterns

### Check If Player Is Home

```lua
local function CheckHousingState()
    if HousingUI.IsPlayerInOwnHouse() then
        print("Welcome home!")
        local houseInfo = HousingUI.GetCurrentHouseInfo()
        if houseInfo then
            print("House:", houseInfo.name)
        end
    elseif HousingUI.IsPlayerInHouse() then
        local owner = HousingUI.GetHouseOwner()
        if owner then
            print("Visiting", owner.name, "'s house")
        end
    end
end
```

### Place a Decoration

```lua
-- Enter housing edit mode and place an item
local function PlaceDecoration(catalogItemID)
    if not HousingUI.IsHousingModeActive() then
        HousingUI.EnterHousingMode()
    end
    
    local current, max = C_HouseEditorUI.GetPlacementLimits()
    if current >= max then
        print("Decoration limit reached:", current, "/", max)
        return
    end
    
    C_HouseEditorUI.PlaceObject(catalogItemID)
end
```

### Browse Catalog

```lua
local function BrowseCatalog()
    local categories = C_HousingCatalog.GetCategories()
    for _, cat in ipairs(categories) do
        local catInfo = C_HousingCatalog.GetCategoryInfo(cat)
        if catInfo then
            print("Category:", catInfo.name)
            local items = C_HousingCatalog.GetItemsInCategory(cat)
            for _, item in ipairs(items) do
                local info = C_HousingCatalog.GetItemInfo(item)
                if info then
                    local owned = C_HousingCatalog.IsItemOwned(item)
                    print("  -", info.name, owned and "(Owned)" or "")
                end
            end
        end
    end
end
```

### Save and Load Layouts

```lua
-- Save current decoration layout
HousingLayoutUI.SaveLayout("My Living Room v2")

-- List saved layouts
local layouts = HousingLayoutUI.GetSavedLayouts()
for _, layout in ipairs(layouts) do
    local info = HousingLayoutUI.GetLayoutInfo(layout)
    if info then
        print(info.name, "-", info.objectCount, "objects")
    end
end
```

---

## Key Events

| Event | Payload | Description |
|-------|---------|-------------|
| `HOUSING_MODE_ENTERED` | â€” | Entered housing edit mode |
| `HOUSING_MODE_EXITED` | â€” | Exited housing edit mode |
| `HOUSING_OBJECT_PLACED` | objectID | Decoration placed |
| `HOUSING_OBJECT_REMOVED` | objectID | Decoration removed |
| `HOUSING_OBJECT_MOVED` | objectID | Decoration moved |
| `HOUSING_OBJECT_SELECTED` | objectID | Object selected |
| `HOUSING_OBJECT_DESELECTED` | â€” | Object deselected |
| `HOUSING_PLACEMENT_STARTED` | catalogItemID | Placement mode started |
| `HOUSING_PLACEMENT_CONFIRMED` | objectID | Placement confirmed |
| `HOUSING_PLACEMENT_CANCELED` | â€” | Placement canceled |
| `HOUSING_CATALOG_UPDATED` | â€” | Catalog data changed |
| `HOUSING_LAYOUT_SAVED` | layoutID | Layout saved |
| `HOUSING_LAYOUT_LOADED` | layoutID | Layout loaded |
| `HOUSING_EXTERIOR_CHANGED` | exteriorID | Exterior changed |
| `HOUSING_LIMIT_UPDATED` | current, max | Limit changed |
| `HOUSING_ENTERED_HOUSE` | houseInfo | Entered a house |
| `HOUSING_LEFT_HOUSE` | â€” | Left a house |
| `NEIGHBORHOOD_INITIATIVE_UPDATE` | â€” | Initiative progress changed |
| `NEIGHBORHOOD_MEMBER_JOINED` | memberInfo | New neighbor |

---

## Gotchas & Restrictions

1. **12.0.0 only** â€” The entire housing system is new in Patch 12.0.0. APIs may evolve in subsequent patches.
2. **Mode requirements** â€” Must call `HousingUI.EnterHousingMode()` before using editor functions.
3. **Placement limits** â€” Each house has a decoration cap. Check with `GetPlacementLimits()`.
4. **Expert vs Basic mode** â€” Expert mode allows full 3D positioning; basic mode uses simplified snapping.
5. **Own house only for editing** â€” Cannot edit decorations in someone else's house.
6. **Layout compatibility** â€” Layouts may not load correctly if decorations have been removed from the game.
7. **Neighborhood initiatives** â€” Shared community goals; progress is collective, not individual.
8. **Hardware events** â€” Purchasing catalog items requires user interaction (hardware clicks).
