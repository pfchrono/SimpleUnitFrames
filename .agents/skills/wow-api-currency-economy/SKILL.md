---
name: wow-api-currency-economy
description: "Complete reference for WoW Retail Currency, Auction House, Token, Store, Trading Post, Black Market, Mail, and Player Trading APIs. Covers C_CurrencyInfo (currency data, tracking, backpack), Auction House (full listing/bidding/buying/selling/search/commodity), C_WowTokenPublic (WoW Token market), AccountStore (in-game shop), CatalogShop, C_PerksProgram (Trading Post â€” Trader's Tender), BlackMarket (BMAH), TradeInfo (player trading), MailInfo (mailbox), and related events. Use when working with currencies, auction house UI, WoW Tokens, the in-game store, Trading Post, black market, mail, or player-to-player trading."
---

# Currency & Economy API (Retail â€” Patch 12.0.0)

Comprehensive reference for currency, auction house, store, token, trading post, mail, and trade APIs.

> **Source:** https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
> **Current as of:** Patch 12.0.0 (Build 65655) â€” January 28, 2026
> **Scope:** Retail only.

---

## Scope

- **C_CurrencyInfo** â€” Currency data, tracking, backpack display
- **Auction House** â€” Listing, bidding, buying, selling, commodities
- **C_WowTokenPublic / C_WowTokenUI** â€” WoW Token market
- **AccountStore / StorePublic** â€” In-game shop
- **CatalogShop** â€” Catalog shop system
- **C_PerksProgram** â€” Trading Post (Trader's Tender)
- **BlackMarket** â€” Black Market Auction House
- **TradeInfo** â€” Player-to-player trading
- **MailInfo** â€” Mailbox system

---

## C_CurrencyInfo â€” Currency System

### Currency Data

| Function | Returns | Description |
|----------|---------|-------------|
| `C_CurrencyInfo.GetCurrencyInfo(currencyType)` | `currencyInfo` | Currency info by type |
| `C_CurrencyInfo.GetCurrencyInfoFromLink(link)` | `currencyInfo` | From hyperlink |
| `C_CurrencyInfo.GetCurrencyIDFromLink(link)` | `currencyID` | ID from hyperlink |
| `C_CurrencyInfo.GetCurrencyLink(currencyType, amount)` | `link` | Currency hyperlink |
| `C_CurrencyInfo.GetCurrencyListSize()` | `size` | Number of entries |
| `C_CurrencyInfo.GetCurrencyListInfo(index)` | `info` | Entry at index |
| `C_CurrencyInfo.GetCurrencyListLink(index)` | `link` | Link at index |

### Currency Info Fields

- `name` â€” Currency name
- `description` â€” Description text
- `currencyID` â€” Unique ID
- `iconFileID` â€” Icon texture
- `quantity` â€” Current amount
- `maxQuantity` â€” Max cap (0 = none)
- `canEarnPerWeek` â€” Has weekly cap?
- `quantityEarnedThisWeek` â€” Earned this week
- `maxWeeklyQuantity` â€” Weekly max
- `totalEarned` â€” Total ever earned
- `isTradeable` â€” Can be traded?
- `quality` â€” Item quality
- `isDiscovered` â€” Has been discovered?
- `isShowInBackpack` â€” Shown in Backpack?

### Backpack & Tracking

| Function | Returns | Description |
|----------|---------|-------------|
| `C_CurrencyInfo.GetBackpackCurrencyInfo(index)` | `currencyData` | Backpack slot |
| `C_CurrencyInfo.GetNumBackpackCurrencies()` | `numSlots` | Num backpack slots |
| `C_CurrencyInfo.SetCurrencyBackpack(index, backpack)` | â€” | Toggle backpack |
| `C_CurrencyInfo.IsCurrencyTracked(currencyID)` | `isTracked` | Is tracked? |
| `C_CurrencyInfo.SetCurrencyTracked(currencyID, tracked)` | â€” | Set tracked |

### Currency List Management

| Function | Returns | Description |
|----------|---------|-------------|
| `C_CurrencyInfo.ExpandCurrencyList(index, expand)` | â€” | Expand/collapse header |
| `C_CurrencyInfo.IsCurrencyHeader(index)` | `isHeader` | Is header? |
| `C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID)` | `factionID` | Associated faction |
| `C_CurrencyInfo.DoesCurrentFilterPassFilter(currencyID)` | `passes` | Passes filter? |

### Gold Functions (Global)

| Function | Returns | Description |
|----------|---------|-------------|
| `GetMoney()` | `copper` | Player's money in copper |
| `GetCoinTextureString(copper)` | `text` | Gold/silver/copper string |
| `GetMoneyString(copper, ...)` | `text` | Formatted money string |

---

## Auction House

### Browse & Search

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AuctionHouse.SearchForItemKeys(itemKeys, sorts)` | â€” | Search by item keys |
| `C_AuctionHouse.SendBrowseQuery(query)` | â€” | Browse query |
| `C_AuctionHouse.SendSearchQuery(itemKey, sorts, separateOwnerItems)` | â€” | Item search |
| `C_AuctionHouse.GetBrowseResults()` | `browseResults` | Browse results |
| `C_AuctionHouse.GetNumItemSearchResults(itemKey)` | `numResults` | Num search results |
| `C_AuctionHouse.GetItemSearchResultInfo(itemKey, index)` | `resultInfo` | Search result info |
| `C_AuctionHouse.RefreshItemSearchResults(itemKey)` | â€” | Refresh search |
| `C_AuctionHouse.GetFilterGroups()` | `filterGroups` | Available filters |

### Commodities

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AuctionHouse.SendSellSearchQuery(itemKey, sorts, separateOwnerItems)` | â€” | Commodity search |
| `C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)` | `resultInfo` | Commodity result |
| `C_AuctionHouse.GetNumCommoditySearchResults(itemID)` | `numResults` | Num commodity results |
| `C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)` | â€” | Start commodity buy |
| `C_AuctionHouse.ConfirmCommoditiesPurchase()` | â€” | Confirm commodity buy |
| `C_AuctionHouse.CancelCommoditiesPurchase()` | â€” | Cancel commodity buy |
| `C_AuctionHouse.GetCommodityQuote(itemID)` | `quote` | Price quote |

### Listing & Selling

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AuctionHouse.PostItem(itemLocation, duration, quantity, bid, buyout)` | â€” | List item |
| `C_AuctionHouse.PostCommodity(itemLocation, duration, quantity, unitPrice)` | â€” | List commodity |
| `C_AuctionHouse.GetItemKeyInfo(itemKey)` | `keyInfo` | Item key info |
| `C_AuctionHouse.MakeItemKey(itemID, itemLevel, itemSuffix, battlePetSpeciesID)` | `itemKey` | Create item key |
| `C_AuctionHouse.GetAvailablePostCount(itemLocation)` | `count` | How many to list |
| `C_AuctionHouse.CalculateItemDeposit(itemLocation, duration, quantity)` | `deposit` | Deposit cost |
| `C_AuctionHouse.GetQuoteDurationRemaining()` | `seconds` | Quote time remaining |

### Bidding & Buying

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AuctionHouse.PlaceBid(auctionID, bidAmount)` | â€” | Place bid |
| `C_AuctionHouse.GetBidInfo(index)` | `bidInfo` | Bid info |
| `C_AuctionHouse.GetNumBids()` | `numBids` | Active bids |
| `C_AuctionHouse.HasFavorite(itemKey)` | `isFavorite` | Is favorited? |
| `C_AuctionHouse.SetFavoriteItem(itemKey, isFavorite)` | â€” | Set favorite |
| `C_AuctionHouse.GetFavoriteItems()` | `itemKeys` | All favorites |

### Own Auctions

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AuctionHouse.GetNumOwnedAuctions()` | `numAuctions` | Own auctions |
| `C_AuctionHouse.GetOwnedAuctionInfo(index)` | `auctionInfo` | Own auction info |
| `C_AuctionHouse.CancelAuction(auctionID)` | â€” | Cancel auction |
| `C_AuctionHouse.QueryOwnedAuctions(sorts)` | â€” | Query own auctions |

### Auction House State

| Function | Returns | Description |
|----------|---------|-------------|
| `C_AuctionHouse.IsAuctionHouseAvailable()` | `isAvailable` | AH available? |
| `C_AuctionHouse.CloseAuctionHouse()` | â€” | Close AH |
| `C_AuctionHouse.GetAuctionHouseTimeLeftBand(timeLeftEnum)` | `seconds` | Time left |
| `C_AuctionHouse.ReplicateItems()` | â€” | Full AH scan |
| `C_AuctionHouse.GetNumReplicateItems()` | `count` | Replicate count |
| `C_AuctionHouse.GetReplicateItemInfo(index)` | `info` | Replicate item |

---

## C_WowTokenPublic â€” WoW Token

| Function | Returns | Description |
|----------|---------|-------------|
| `C_WowTokenPublic.GetCurrentMarketPrice()` | `price` | Gold price |
| `C_WowTokenPublic.GetGuaranteedPrice()` | `price` | Guaranteed price |
| `C_WowTokenPublic.UpdateMarketPrice()` | â€” | Request update |
| `C_WowTokenPublic.GetCommerceSystemStatus()` | `status` | System status |
| `C_WowTokenPublic.BuyToken()` | â€” | Buy token (gold) |
| `C_WowTokenPublic.SellToken(auctionID)` | â€” | Sell token |

---

## AccountStore / StorePublic â€” In-Game Shop

| Function | Returns | Description |
|----------|---------|-------------|
| `C_StorePublic.IsEnabled()` | `enabled` | Shop enabled? |
| `C_StorePublic.IsDisabledByParentalControls()` | `disabled` | Parental block? |
| `C_StorePublic.DoesGroupHavePurchaseableProducts(group)` | `hasPurchaseable` | Has products? |

---

## C_PerksProgram â€” Trading Post

| Function | Returns | Description |
|----------|---------|-------------|
| `C_PerksProgram.GetAvailableActivities()` | `activities` | Current activities |
| `C_PerksProgram.GetPendingChestRewards()` | `rewards` | Pending rewards |
| `C_PerksProgram.GetTimeRemaining()` | `seconds` | Rotation time left |
| `C_PerksProgram.GetCurrencyAmount()` | `amount` | Trader's Tender |
| `C_PerksProgram.GetVendorItemInfo(perksVendorItemID)` | `itemInfo` | Vendor item |
| `C_PerksProgram.GetAvailableVendorItemIDs()` | `itemIDs` | Current rotation |
| `C_PerksProgram.GetFrozenPerksVendorItemInfo()` | `info` | Frozen item |
| `C_PerksProgram.RequestPurchase(perksVendorItemID)` | â€” | Purchase item |
| `C_PerksProgram.RequestRefund(perksVendorItemID)` | â€” | Refund item |
| `C_PerksProgram.GetDraggedPerksVendorItemInfo()` | `itemInfo` | Dragged item |
| `C_PerksProgram.IsFrozenItem(perksVendorItemID)` | `isFrozen` | Is frozen? |
| `C_PerksProgram.SetFrozenPerksVendorItem(perksVendorItemID)` | â€” | Freeze item |
| `C_PerksProgram.ClearFrozenPerksVendorItem()` | â€” | Unfreeze |
| `C_PerksProgram.GetPerksVendorCategoryIDs()` | `categoryIDs` | Category IDs |
| `C_PerksProgram.GetPerksVendorCategoryInfo(categoryID)` | `categoryInfo` | Category info |

---

## Black Market

| Function | Returns | Description |
|----------|---------|-------------|
| `C_BlackMarket.GetNumItems()` | `numItems` | Current BMAH items |
| `C_BlackMarket.GetItemInfoByIndex(index)` | `info` | BMAH item info |
| `C_BlackMarket.GetHotItem()` | `info` | Hot item of the day |
| `C_BlackMarket.ItemPlaceBid(index, amount)` | â€” | Place BMAH bid |
| `C_BlackMarket.RequestItems()` | â€” | Request item list |
| `C_BlackMarket.IsViewOnly()` | `isViewOnly` | View-only mode? |

---

## Trade (Player-to-Player)

| Function | Returns | Description |
|----------|---------|-------------|
| `InitiateTrade(unit)` | â€” | Start trade |
| `AcceptTrade()` | â€” | Accept trade |
| `CancelTrade()` | â€” | Cancel trade |
| `AddTradeMoney()` | â€” | Add gold offer |
| `SetTradeMoney(copper)` | â€” | Set gold amount |
| `GetTargetTradeMoney()` | `copper` | Their gold offer |
| `GetPlayerTradeMoney()` | `copper` | Your gold offer |
| `GetTradeTargetItemInfo(slotIndex)` | `name, texture, quantity, quality, isUsable, enchant` | Their item |
| `GetTradePlayerItemInfo(slotIndex)` | `name, texture, quantity, quality, isUsable, enchant` | Your item |
| `ClickTradeButton(slotIndex)` | â€” | Click trade slot |
| `GetNumTradeItems()` | `numPlayerItems, numTargetItems` | Item counts |

---

## Mail System

| Function | Returns | Description |
|----------|---------|-------------|
| `GetInboxNumItems()` | `numItems, totalItems` | Inbox count |
| `GetInboxHeaderInfo(index)` | `packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM` | Mail header |
| `GetInboxText(index)` | `bodyText, stationeryBG, stationeryBGR, stationeryBGG, stationeryBGB, color` | Mail body |
| `GetInboxItem(index, itemIndex)` | `name, itemID, texture, count, quality, canUse` | Attachment |
| `GetInboxItemLink(index, itemIndex)` | `link` | Attachment link |
| `TakeInboxItem(index, itemIndex)` | â€” | Take attachment |
| `TakeInboxMoney(index)` | â€” | Take gold |
| `TakeInboxTextItem(index)` | â€” | Take text item |
| `DeleteInboxItem(index)` | â€” | Delete mail |
| `ReturnInboxItem(index)` | â€” | Return mail |
| `AutoLootMailItem(index)` | â€” | Auto-loot all |
| `InboxItemCanDelete(index)` | `canDelete` | Can delete? |
| `SendMail(recipient, subject, body)` | â€” | Send mail |
| `SetSendMailMoney(copper)` | â€” | Set gold to send |
| `SetSendMailCOD(copper)` | â€” | Set COD amount |
| `GetSendMailPrice()` | `cost` | Sending cost |
| `GetSendMailItem(index)` | `name, texture, count, quality` | Attached item |
| `GetSendMailItemLink(index)` | `link` | Attached link |
| `ClickSendMailItemButton(itemIndex, clearItem)` | â€” | Add/remove attachment |
| `SendMailCanSend()` | `canSend` | Can send? |

---

## Common Patterns

### Display Currency with Cap

```lua
local function ShowCurrency(currencyID)
    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info then
        local text = info.name .. ": " .. info.quantity
        if info.maxQuantity > 0 then
            text = text .. " / " .. info.maxQuantity
        end
        if info.canEarnPerWeek and info.maxWeeklyQuantity > 0 then
            text = text .. " (Weekly: " .. info.quantityEarnedThisWeek .. "/" .. info.maxWeeklyQuantity .. ")"
        end
        print(text)
    end
end
```

### Auction House Search

```lua
-- Register for results
local f = CreateFrame("Frame")
f:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
f:SetScript("OnEvent", function(self, event, itemKey, ...)
    local numResults = C_AuctionHouse.GetNumItemSearchResults(itemKey)
    for i = 1, numResults do
        local result = C_AuctionHouse.GetItemSearchResultInfo(itemKey, i)
        if result then
            print(result.buyoutAmount, "copper -", result.quantity, "available")
        end
    end
end)

-- Initiate search
local itemKey = C_AuctionHouse.MakeItemKey(12345) -- itemID
C_AuctionHouse.SendSearchQuery(itemKey, {}, false)
```

### Check WoW Token Price

```lua
C_WowTokenPublic.UpdateMarketPrice()

local f = CreateFrame("Frame")
f:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED")
f:SetScript("OnEvent", function()
    local price = C_WowTokenPublic.GetCurrentMarketPrice()
    if price then
        print("WoW Token: " .. GetCoinTextureString(price))
    end
end)
```

---

## Key Events

| Event | Payload | Description |
|-------|---------|-------------|
| `CURRENCY_DISPLAY_UPDATE` | currencyType, quantity, quantityChange, quantityGainSource, quantityLostSource | Currency changed |
| `AUCTION_HOUSE_SHOW` | â€” | AH opened |
| `AUCTION_HOUSE_CLOSED` | â€” | AH closed |
| `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` | â€” | Browse results ready |
| `ITEM_SEARCH_RESULTS_UPDATED` | itemKey | Item search ready |
| `COMMODITY_SEARCH_RESULTS_UPDATED` | itemID | Commodity search ready |
| `AUCTION_HOUSE_NEW_RESULTS_RECEIVED` | itemKey | New results |
| `ITEM_SEARCH_RESULTS_ADDED` | itemKey | Result added |
| `AUCTION_HOUSE_AUCTION_CREATED` | auctionID | Auction posted |
| `AUCTION_CANCELED` | auctionID | Auction canceled |
| `TOKEN_MARKET_PRICE_UPDATED` | result | Token price updated |
| `TOKEN_STATUS_CHANGED` | â€” | Token status changed |
| `PERKS_PROGRAM_CURRENCY_REFRESH` | â€” | Trader's Tender updated |
| `PERKS_PROGRAM_PURCHASE_SUCCESS` | â€” | Trading Post purchase |
| `PERKS_PROGRAM_SET_FROZEN_ITEM` | â€” | Item frozen |
| `MAIL_INBOX_UPDATE` | â€” | Inbox updated |
| `MAIL_SEND_SUCCESS` | â€” | Mail sent |
| `MAIL_SHOW` | â€” | Mailbox opened |
| `MAIL_CLOSED` | â€” | Mailbox closed |
| `TRADE_SHOW` | â€” | Trade window opened |
| `TRADE_CLOSED` | â€” | Trade ended |
| `TRADE_ACCEPT_UPDATE` | playerAccept, targetAccept | Accept state |
| `TRADE_MONEY_CHANGED` | â€” | Gold offer changed |
| `TRADE_PLAYER_ITEM_CHANGED` | slotIndex | Player item changed |
| `TRADE_TARGET_ITEM_CHANGED` | slotIndex | Target item changed |
| `BLACK_MARKET_ITEM_UPDATE` | â€” | BMAH items updated |
| `BLACK_MARKET_OUTBID` | â€” | Outbid on BMAH |

---

## Gotchas & Restrictions

1. **Auction House hardware event** â€” Posting, buying, and bidding require hardware events (user clicks).
2. **Commodity vs. item** â€” Commodities (stackable) use a different API path than equipment/unique items.
3. **AH throttling** â€” Searches are rate-limited. Rapid queries get throttled by the server.
4. **Mail COD** â€” COD mail auto-deducts gold when attachment is taken. Test with `InboxItemCanDelete()`.
5. **GetMoney() returns copper** â€” Divide by 100 for silver, 10000 for gold.
6. **Currency caps** â€” Always check `maxQuantity` and `maxWeeklyQuantity` before displaying progress.
7. **WoW Token price is async** â€” Call `UpdateMarketPrice()` then wait for `TOKEN_MARKET_PRICE_UPDATED`.
8. **ReplicateItems() is slow** â€” Full AH scan is expensive. Use sparingly and handle results incrementally.
