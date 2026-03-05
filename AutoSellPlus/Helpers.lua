local addonName, ns = ...

ns.equipmentSetItems = {}

function ns:RebuildEquipmentSetCache()
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

function ns:IsUncollectedTransmog(itemID)
    if not C_TransmogCollection or not C_TransmogCollection.PlayerHasTransmog then
        return false
    end
    return not C_TransmogCollection.PlayerHasTransmog(itemID)
end

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

function ns:GetEffectiveItemLevel(itemLink)
    if not itemLink then return 0 end
    local effectiveIlvl = GetDetailedItemLevelInfo(itemLink)
    return effectiveIlvl or 0
end

function ns:FormatMoney(copper)
    if not copper or copper == 0 then return "0c" end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100

    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if cop > 0 then parts[#parts + 1] = cop .. "c" end

    return table.concat(parts, " ")
end

function ns:Print(msg)
    print("|cFF00CCFFAutoSellPlus|r: " .. tostring(msg))
end

-- Mapping from itemEquipLoc to inventory slot ID(s)
local EQUIP_LOC_TO_SLOTS = {
    INVTYPE_HEAD = {1},
    INVTYPE_NECK = {2},
    INVTYPE_SHOULDER = {3},
    INVTYPE_CHEST = {5},
    INVTYPE_ROBE = {5},
    INVTYPE_WAIST = {6},
    INVTYPE_LEGS = {7},
    INVTYPE_FEET = {8},
    INVTYPE_WRIST = {9},
    INVTYPE_HAND = {10},
    INVTYPE_FINGER = {11, 12},
    INVTYPE_TRINKET = {13, 14},
    INVTYPE_CLOAK = {15},
    INVTYPE_WEAPON = {16},
    INVTYPE_WEAPONMAINHAND = {16},
    INVTYPE_2HWEAPON = {16},
    INVTYPE_RANGED = {16},
    INVTYPE_RANGEDRIGHT = {16},
    INVTYPE_WEAPONOFFHAND = {17},
    INVTYPE_SHIELD = {17},
    INVTYPE_HOLDABLE = {17},
}

local GEAR_SLOTS = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}

function ns:GetEquippedIlvls()
    local ilvls = {}
    local total = 0
    local count = 0
    for _, slotID in ipairs(GEAR_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local ilvl = GetDetailedItemLevelInfo(link)
            ilvls[slotID] = ilvl or 0
            if ilvl and ilvl > 0 then
                total = total + ilvl
                count = count + 1
            end
        else
            ilvls[slotID] = 0
        end
    end
    local avgIlvl = count > 0 and math.floor(total / count) or 0
    local minIlvl = 0
    for _, slotID in ipairs(GEAR_SLOTS) do
        local v = ilvls[slotID]
        if v and v > 0 then
            if minIlvl == 0 or v < minIlvl then
                minIlvl = v
            end
        end
    end
    return ilvls, avgIlvl, minIlvl
end

function ns:GetEquippedIlvlForItem(itemID)
    local _, _, _, itemEquipLoc = C_Item.GetItemInfoInstant(itemID)
    if not itemEquipLoc then return 0 end

    local slots = EQUIP_LOC_TO_SLOTS[itemEquipLoc]
    if not slots then return 0 end

    if not self._equippedIlvls then
        self._equippedIlvls = self:GetEquippedIlvls()
    end

    if #slots == 1 then
        return self._equippedIlvls[slots[1]] or 0
    else
        -- For dual-slot items (rings/trinkets), return the lower ilvl
        local ilvl1 = self._equippedIlvls[slots[1]] or 0
        local ilvl2 = self._equippedIlvls[slots[2]] or 0
        return math.min(ilvl1, ilvl2)
    end
end
