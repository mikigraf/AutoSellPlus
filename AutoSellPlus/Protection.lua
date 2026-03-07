local addonName, ns = ...

-- ============================================================
-- Equipment Set Cache
-- ============================================================

ns.equipmentSetItems = {}

function ns:RebuildEquipmentSetCache()
    if not self.features.equipSets then return end
    wipe(self.equipmentSetItems)

    local setIDs = C_EquipmentSet.GetEquipmentSetIDs()
    if not setIDs then return end

    for _, setID in ipairs(setIDs) do
        local itemLocations = C_EquipmentSet.GetItemLocations(setID)
        if itemLocations then
            for _, location in pairs(itemLocations) do
                if location and location ~= 0 and location ~= 1 then
                    local onPlayer, inBank, inBags, inVaultTab, slot, bag, tab, vaultSlot =
                        EquipmentManager_UnpackLocation(location)

                    local itemID
                    if inBags and bag and slot then
                        local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                        if itemInfo then
                            itemID = itemInfo.itemID
                        end
                    elseif onPlayer and slot and not inBags then
                        itemID = GetInventoryItemID("player", slot)
                    end

                    if itemID then
                        self.equipmentSetItems[itemID] = true
                    end
                end
            end
        end
    end
end

function ns:IsInEquipmentSet(itemID)
    return self.equipmentSetItems[itemID] or false
end

-- ============================================================
-- Transmog Protection
-- ============================================================

function ns:IsUncollectedTransmog(itemID)
    if not self.features.transmog then return false end
    if not C_TransmogCollection or not C_TransmogCollection.PlayerHasTransmog then
        return false
    end
    return not C_TransmogCollection.PlayerHasTransmog(itemID)
end

-- Enhanced transmog source-level checking
function ns:IsUncollectedTransmogSource(itemID)
    if not C_TransmogCollection then return false end

    -- Basic check first
    if C_TransmogCollection.PlayerHasTransmog and C_TransmogCollection.PlayerHasTransmog(itemID) then
        return false
    end

    -- Source-level check if available
    if C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance then
        local allSources = C_TransmogCollection.GetAllAppearanceSources and
            C_TransmogCollection.GetAllAppearanceSources(itemID)
        if allSources then
            for _, sourceID in ipairs(allSources) do
                if not C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID) then
                    return true
                end
            end
            return false
        end
    end

    -- Fallback to basic check
    return not C_TransmogCollection.PlayerHasTransmog(itemID)
end

-- Third-party transmog addon integration
function ns:IsTransmogProtectedByAddon(itemID, bag, slot)
    -- AllTheThings integration
    if AllTheThings and AllTheThings.SearchForField then
        local results = AllTheThings.SearchForField("itemID", itemID)
        if results and #results > 0 then
            for _, result in ipairs(results) do
                if result.collected == false then
                    return true
                end
            end
        end
    end

    -- CanIMogIt integration
    if CanIMogIt and CanIMogIt.GetTooltipText then
        local itemLink = C_Container.GetContainerItemInfo(bag, slot)
        if itemLink then
            local text = CanIMogIt:GetTooltipText(itemLink.hyperlink or itemLink)
            if text and text:find("Cannot") == nil and text:find("Collected") == nil then
                return true
            end
        end
    end

    return false
end

-- ============================================================
-- Item Checks
-- ============================================================

function ns:IsRefundable(bag, slot)
    local info = C_Container.GetContainerItemPurchaseInfo(bag, slot, false)
    if info and info.refundSeconds and info.refundSeconds > 0 then
        return true
    end
    return false
end

function ns:IsEquippable(itemID)
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
    if not classID then return false end
    return classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor
end

-- Items in these equip slots have no visual transmog appearance
local NON_TRANSMOG_EQUIP_LOCS = {
    INVTYPE_NECK = true,
    INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true,
}

function ns:HasTransmogAppearance(itemID)
    if not self:IsEquippable(itemID) then return false end
    local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(itemID)
    if not itemEquipLoc or itemEquipLoc == "" then return false end
    return not NON_TRANSMOG_EQUIP_LOCS[itemEquipLoc]
end

-- BoE detection
function ns:IsBindOnEquip(bag, slot)
    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
    if not itemInfo or not itemInfo.hyperlink then return false end

    local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = C_Item.GetItemInfo(itemInfo.hyperlink)
    -- bindType 2 = BoE
    if bindType ~= 2 then return false end

    -- Check if already bound
    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if itemLoc and itemLoc:IsValid() and C_Item.IsBound(itemLoc) then
        return false
    end

    return true
end

-- Feature availability flags (set by RunSelfTest in Core.lua)
ns.features = {
    selling = true,
    scanning = true,
    itemInfo = true,
    transmog = true,
    equipSets = true,
    destroying = true,
}

function ns:IsFeatureAvailable(name)
    return self.features[name] ~= false
end

-- ============================================================
-- ShouldSellItem — Data-driven quality and category checks
-- ============================================================

local QUALITY_CONFIG = {
    [0] = { flag = "sellGrays" },
    [1] = { flag = "sellWhites", ilvlKey = "whiteMaxIlvl" },
    [2] = { flag = "sellGreens", ilvlKey = "greenMaxIlvl" },
    [3] = { flag = "sellBlues",  ilvlKey = "blueMaxIlvl" },
    [4] = { flag = "sellEpics",  ilvlKey = "epicMaxIlvl" },
}

local function CheckQualityFilter(db, quality, itemLink, itemID, sellPrice, stackCount)
    local cfg = QUALITY_CONFIG[quality]
    if not cfg or not db[cfg.flag] then return false end
    if db.onlyEquippable and quality > 0 and not ns:IsEquippable(itemID) then return false end
    if not cfg.ilvlKey then return true, itemLink, sellPrice, stackCount end
    local ilvl = ns:GetEffectiveItemLevel(itemLink)
    if ilvl == 0 then return false end
    local maxIlvl = db[cfg.ilvlKey]
    if maxIlvl > 0 and ilvl <= maxIlvl then return true, itemLink, sellPrice, stackCount end
    return false
end

local CATEGORY_CONFIG = {
    [0]  = "sellConsumables",
    [7]  = "sellTradeGoods",
    [12] = "sellQuestItems",
    [15] = "sellMiscItems",
}

local function CheckCategoryFilter(db, itemID, itemLink, sellPrice, stackCount)
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
    local flag = CATEGORY_CONFIG[classID]
    if flag and db[flag] then return true, itemLink, sellPrice, stackCount end
    return false
end

function ns:ShouldSellItem(bag, slot)
    local db = self.db
    if not db.enabled then return false end

    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
    if not itemInfo then return false end

    local itemID = itemInfo.itemID
    local itemLink = itemInfo.hyperlink
    local quality = itemInfo.quality
    local isLocked = itemInfo.isLocked
    local hasNoValue = itemInfo.hasNoValue
    local stackCount = itemInfo.stackCount or 1

    if not itemID or not itemLink then return false end

    -- Priority 1: Never-sell list (global + per-char)
    if self:IsNeverSell(itemID) then return false end

    -- Priority 2: Always-sell list (must have sell price)
    if self:IsAlwaysSell(itemID) then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
        if sellPrice and sellPrice > 0 then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    -- Priority 2b: Marked items
    if self:IsMarked(itemID) then
        local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
        if sellPrice and sellPrice > 0 then
            return true, itemLink, sellPrice, stackCount
        end
        return false
    end

    -- Get sell price
    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
    if not sellPrice or sellPrice == 0 or hasNoValue then return false end

    -- Locked items cannot be sold
    if isLocked then return false end

    -- Equipment set protection
    if db.protectEquipmentSets and self:IsInEquipmentSet(itemID) then return false end

    -- Uncollected transmog protection (only items with visual appearances)
    if db.protectUncollectedTransmog and self:HasTransmogAppearance(itemID) then
        if self:IsUncollectedTransmog(itemID) then return false end
    end

    -- Source-level transmog protection
    if db.protectTransmogSource and self:HasTransmogAppearance(itemID) then
        if self:IsUncollectedTransmogSource(itemID) then return false end
    end

    -- Refundable protection
    if self:IsRefundable(bag, slot) then return false end

    -- Quest item protection
    if db.protectQuestItems then
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
        if classID == 12 then return false end
    end

    -- BoE protection
    if db.protectBoE and not db.allowBoESell then
        if self:IsBindOnEquip(bag, slot) then return false end
    end

    -- Soulbound-only mode: skip unbound BoE items
    if db.onlySoulbound then
        if self:IsBindOnEquip(bag, slot) then return false end
    end

    -- Current expansion materials protection
    if db.protectCurrentExpMaterials then
        local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
        if classID == 7 then
            local expansionID = ns:GetItemExpansion(itemLink)
            if expansionID == ns.CURRENT_EXPANSION then return false end
        end
    end

    -- Quality-based selling (data-driven)
    local shouldSell, link, price, count = CheckQualityFilter(db, quality, itemLink, itemID, sellPrice, stackCount)
    if shouldSell then return true, link, price, count end

    -- Category selling (data-driven)
    return CheckCategoryFilter(db, itemID, itemLink, sellPrice, stackCount)
end
