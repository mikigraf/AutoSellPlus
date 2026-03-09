local addonName, ns = ...

-- ============================================================
-- BuildDisplayList — Scan bags for vendorable items
-- ============================================================

function ns:BuildDisplayList()
    local list = {}
    for bag = 0, self:GetMaxBagID() do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local itemID = itemInfo.itemID
                local itemLink = itemInfo.hyperlink
                local quality = itemInfo.quality
                local isLocked = itemInfo.isLocked
                local hasNoValue = itemInfo.hasNoValue
                local stackCount = itemInfo.stackCount or 1

                if itemID and itemLink then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
                    local isAlwaysSell = self:IsAlwaysSell(itemID)
                    local isMarked = self:IsMarked(itemID)

                    local _, _, _, _, _, bClassID, bSubclassID = C_Item.GetItemInfoInstant(itemID)
                    if not self:IsNeverSell(itemID)
                        and not isLocked
                        and not self:IsRefundable(bag, slot)
                        and (sellPrice and sellPrice > 0 or isAlwaysSell)
                        and not hasNoValue
                        and not (self.db.protectMountEquipment and bClassID == 15 and bSubclassID == 6)
                        and not (self.db.protectEquipmentSets and self:IsInEquipmentSet(itemID))
                        and not (self.db.protectUncollectedTransmog and self:HasTransmogAppearance(itemID) and self:IsUncollectedTransmog(itemID))
                        and not (self.db.protectTransmogSource and self:HasTransmogAppearance(itemID) and self:IsUncollectedTransmogSource(itemID))
                    then
                        local isBoe = self:IsBindOnEquip(bag, slot)
                        if self.db.onlySoulbound and not self:IsSoulbound(bag, slot) and not isAlwaysSell then
                            -- Skip: soulbound-only mode, item is not bound to player
                        elseif self.db.protectBoE and isBoe and not self.db.allowBoESell and not isAlwaysSell then
                            -- Skip: BoE protection
                        elseif self.db.protectCurrentExpMaterials
                            and bClassID == 7
                            and self:GetItemExpansion(itemLink) == ns.CURRENT_EXPANSION
                            and not isAlwaysSell then
                            -- Skip current expansion trade goods
                        else
                            local ilvl = self:GetEffectiveItemLevel(itemLink)
                            local isEquippable = self:IsEquippable(itemID)
                            local equippedIlvl = isEquippable and self:GetEquippedIlvlForItem(itemID) or 0
                            local classID = bClassID
                            local expansionID = self:GetItemExpansion(itemLink)

                            -- AH value lookup
                            local ahValue = 0
                            if TSM_API and TSM_API.GetCustomPriceValue then
                                local ok, val = pcall(TSM_API.GetCustomPriceValue, "DBMarket", "i:" .. itemID)
                                if ok and val then ahValue = val end
                            elseif Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemLink then
                                local ok, val = pcall(Auctionator.API.v1.GetAuctionPriceByItemLink, "AutoSellPlus", itemLink)
                                if ok and val then ahValue = val end
                            end

                            list[#list + 1] = {
                                bag = bag,
                                slot = slot,
                                itemID = itemID,
                                itemLink = itemLink,
                                quality = quality,
                                ilvl = ilvl,
                                equippedIlvl = equippedIlvl,
                                sellPrice = sellPrice or 0,
                                stackCount = stackCount,
                                totalPrice = (sellPrice or 0) * stackCount,
                                isEquippable = isEquippable,
                                isAlwaysSell = isAlwaysSell,
                                isMarked = isMarked,
                                isBoe = isBoe,
                                classID = bClassID,
                                subclassID = bSubclassID,
                                expansionID = expansionID,
                                ahValue = ahValue,
                                checked = false,
                                visible = false,
                            }
                        end
                    end
                end
            end
        end
    end
    return list
end

-- ============================================================
-- ApplyFilters — Mark items as visible/checked by quality/ilvl/category
-- ============================================================

function ns:ApplyFilters(displayList, userUnchecked)
    local db = self.db
    for _, item in ipairs(displayList) do repeat
        local visible = false
        local autoChecked = false

        item.isUpgrade = item.isEquippable and item.equippedIlvl > 0 and item.ilvl > item.equippedIlvl

        -- Expansion filter
        if db.filterExpansion > 0 and item.expansionID ~= db.filterExpansion then
            item.visible = false
            item.checked = false
            break
        end

        -- Exclude current expansion filter
        if db.excludeCurrentExpansion and item.expansionID == ns.CURRENT_EXPANSION then
            item.visible = false
            item.checked = false
            break
        end

        -- Equipment slot filter
        local filterSlots = db.filterSlots
        if filterSlots and next(filterSlots) then
            if item.isEquippable then
                local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(item.itemID)
                local slots = ns.EQUIP_LOC_TO_SLOTS and ns.EQUIP_LOC_TO_SLOTS[itemEquipLoc]
                local slotMatch = false
                if slots then
                    for _, slotID in ipairs(slots) do
                        if filterSlots[slotID] then
                            slotMatch = true
                            break
                        end
                    end
                end
                if not slotMatch then
                    item.visible = false
                    item.checked = false
                    break
                end
            else
                item.visible = false
                item.checked = false
                break
            end
        end

        -- Always-sell and marked items
        if item.isAlwaysSell or item.isMarked then
            visible = true
            autoChecked = true
        elseif item.quality == Enum.ItemQuality.Poor then
            -- Grays
            if db.sellGrays then
                visible = true
                autoChecked = true
            end
        elseif item.quality == Enum.ItemQuality.Common then
            -- Whites
            if db.sellWhites then
                if db.onlyEquippable and not item.isEquippable then
                    visible = false
                else
                    visible = true
                    if item.ilvl > 0 and db.whiteMaxIlvl > 0 and item.ilvl <= db.whiteMaxIlvl then
                        autoChecked = not item.isUpgrade
                    end
                end
            end
        elseif item.quality == Enum.ItemQuality.Uncommon then
            -- Greens
            if db.sellGreens then
                if db.onlyEquippable and not item.isEquippable then
                    visible = false
                else
                    visible = true
                    if item.ilvl > 0 and db.greenMaxIlvl > 0 and item.ilvl <= db.greenMaxIlvl then
                        autoChecked = not item.isUpgrade
                    end
                end
            end
        elseif item.quality == Enum.ItemQuality.Rare then
            -- Blues
            if db.sellBlues then
                if db.onlyEquippable and not item.isEquippable then
                    visible = false
                else
                    visible = true
                    if item.ilvl > 0 and db.blueMaxIlvl > 0 and item.ilvl <= db.blueMaxIlvl then
                        autoChecked = not item.isUpgrade
                    end
                end
            end
        elseif item.quality == Enum.ItemQuality.Epic then
            -- Epics
            if db.sellEpics then
                if db.onlyEquippable and not item.isEquippable then
                    visible = false
                else
                    visible = true
                    if item.ilvl > 0 and db.epicMaxIlvl > 0 and item.ilvl <= db.epicMaxIlvl then
                        autoChecked = not item.isUpgrade
                    end
                end
            end
        end

        -- Category filters (non-equippable items)
        if not visible then
            local isMountEquip = (item.classID == 15 and item.subclassID == 6)
            if item.classID == 0 and db.sellConsumables then
                visible = true
                autoChecked = true
            elseif item.classID == 7 and db.sellTradeGoods then
                visible = true
                autoChecked = true
            elseif item.classID == 12 and db.sellQuestItems then
                visible = true
                autoChecked = not db.protectQuestItems
            elseif item.classID == 15 and db.sellMiscItems then
                if db.protectMountEquipment and isMountEquip then
                    visible = false
                    autoChecked = false
                else
                    visible = true
                    autoChecked = true
                end
            end
        end

        item.visible = visible

        local key = item.bag .. ":" .. item.slot
        if userUnchecked[key] then
            item.checked = false
        elseif visible then
            item.checked = autoChecked
        else
            item.checked = false
        end

    until true end
end

-- ============================================================
-- Sort Comparator
-- ============================================================

function ns:SortDisplayItems(items)
    table.sort(items, function(a, b)
        local col = ns.sortColumn
        local dir = ns.sortDirection

        local va, vb
        if col == "quality" then
            if a.quality ~= b.quality then
                va, vb = a.quality, b.quality
            elseif a.ilvl ~= b.ilvl then
                va, vb = a.ilvl, b.ilvl
            else
                va, vb = (a.itemLink or ""), (b.itemLink or "")
            end
        elseif col == "ilvl" then
            if a.ilvl ~= b.ilvl then
                va, vb = a.ilvl, b.ilvl
            else
                va, vb = a.quality, b.quality
            end
        elseif col == "price" then
            if a.totalPrice ~= b.totalPrice then
                va, vb = a.totalPrice, b.totalPrice
            else
                va, vb = a.quality, b.quality
            end
        elseif col == "ah" then
            local ahA = a.ahValue or 0
            local ahB = b.ahValue or 0
            if ahA ~= ahB then
                va, vb = ahA, ahB
            else
                va, vb = a.totalPrice, b.totalPrice
            end
        else
            va, vb = a.quality, b.quality
        end

        if dir == "desc" then
            return va > vb
        else
            return va < vb
        end
    end)
end
